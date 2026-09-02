import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/prediction_model.dart';
import '../models/schedule_model.dart';
import 'tflite_service.dart';
import 'supabase_service.dart';
import 'notification_service.dart';

class AppProvider with ChangeNotifier {
  final TFLiteService _tfLiteService = TFLiteService();
  final SupabaseService _supabaseService = SupabaseService();
  final NotificationService _notificationService = NotificationService();
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts();
  
  io.File? _selectedImage;
  Prediction? _currentPrediction;
  bool _isLoading = false;
  String _analysisMessage = 'ANALYZING LEAF...';
  List<Prediction> _history = [];
  List<Schedule> _schedules = [];
  
  ThemeMode _themeMode = ThemeMode.light;
  String _language = 'English';
  String _userName = 'Guest';
  String? _avatarUrl;
  String _locationName = 'Kumasi';
  double _lat = 6.6666;
  double _lon = -1.6163;
  bool _notificationsEnabled = true;

  // Weather properties
  double _temp = 28.0;
  String _weatherDesc = 'Sunny';
  bool _isWeatherLoading = false;

  // AI Chat properties
  bool _isChatLoading = false;
  String _selectedAiModel = 'Llama';

  io.File? get selectedImage => _selectedImage;
  Prediction? get currentPrediction => _currentPrediction;
  bool get isLoading => _isLoading;
  String get analysisMessage => _analysisMessage;
  List<Prediction> get history => _history;
  List<Schedule> get schedules => _schedules;
  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  String get userName => _userName;
  String? get avatarUrl => _avatarUrl;
  String get locationName => _locationName;
  double get lat => _lat;
  double get lon => _lon;
  bool get isGuest => _supabaseService.currentUser == null;
  bool get notificationsEnabled => _notificationsEnabled;
  
  double get temp => _temp;
  String get weatherDesc => _weatherDesc;
  bool get isWeatherLoading => _isWeatherLoading;
  bool get isChatLoading => _isChatLoading;
  String get selectedAiModel => _selectedAiModel;

  String get firstName {
    if (_userName == 'Guest' || _userName.isEmpty) return 'Guest';
    return _userName.split(' ').first;
  }

  String get timeBasedGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return _language == 'Twi' ? 'Maakye' : 'Good Morning';
    if (hour < 17) return _language == 'Twi' ? 'Maaha' : 'Good Afternoon';
    return _language == 'Twi' ? 'Maadwo' : 'Good Evening';
  }

  AppProvider() {
    _loadData();
    _tfLiteService.loadModel();
    _initTts();
  }

  Future<void> _loadData() async {
    final settingsBox = Hive.box('settings');
    _userName = settingsBox.get('userName', defaultValue: 'Guest');
    _avatarUrl = settingsBox.get('avatarUrl');
    _language = settingsBox.get('language', defaultValue: 'English');
    _themeMode = settingsBox.get('isDarkMode', defaultValue: false) ? ThemeMode.dark : ThemeMode.light;
    _locationName = settingsBox.get('locationName', defaultValue: 'Kumasi');
    _lat = settingsBox.get('lat', defaultValue: 6.6666);
    _lon = settingsBox.get('lon', defaultValue: -1.6163);
    _notificationsEnabled = settingsBox.get('notificationsEnabled', defaultValue: true);
    _selectedAiModel = settingsBox.get('selectedAiModel', defaultValue: 'Llama');

    await _loadUserHistoryAndSchedules();
    
    if (_supabaseService.currentUser != null) {
      await _loadUserData();
      await syncWithCloud();
    }
    
    await fetchWeather();
    notifyListeners();
  }

  Future<void> _loadUserHistoryAndSchedules() async {
    final userId = _supabaseService.currentUser?.id ?? 'guest';
    
    final historyBox = Hive.box('scan_history');
    final List<dynamic> historyData = historyBox.get('history_$userId', defaultValue: []);
    _history = historyData.map((e) => Prediction.fromMap(Map<String, dynamic>.from(e))).toList();

    final scheduleBox = Hive.box('schedules');
    final List<dynamic> scheduleData = scheduleBox.get('list_$userId', defaultValue: []);
    _schedules = scheduleData.map((e) => Schedule.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> fetchWeather() async {
    _isWeatherLoading = true;
    notifyListeners();
    try {
      final url = 'https://api.open-meteo.com/v1/forecast?latitude=$_lat&longitude=$_lon&current=temperature_2m,weather_code&timezone=auto';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _temp = data['current']['temperature_2m'].toDouble();
        _weatherDesc = _getWeatherDescription(data['current']['weather_code']);
      }
    } catch (e) {
      debugPrint('Weather fetch error: $e');
    } finally {
      _isWeatherLoading = false;
      notifyListeners();
    }
  }

  String _getWeatherDescription(int code) {
    if (code == 0) return 'Sunny';
    if (code <= 3) return 'Cloudy';
    if (code >= 51 && code <= 67) return 'Rainy';
    if (code >= 95) return 'Stormy';
    return 'Clear';
  }

  Future<void> syncWithCloud() async {
    try {
      final cloudScans = await _supabaseService.fetchScans();
      final cloudSchedules = await _supabaseService.fetchSchedules();
      
      _history = cloudScans;
      _schedules = cloudSchedules;
      
      _saveHistory();
      _saveSchedules();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Cloud sync error: $e');
    }
  }

  void _initTts() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      debugPrint('TTS Init Error: $e');
    }
  }

  Future<void> speak(String text) async {
    if (_language == 'Twi') {
      await _flutterTts.setLanguage("ak-GH");
    } else {
      await _flutterTts.setLanguage("en-US");
    }
    await _flutterTts.speak(text);
  }

  void toggleTheme(bool isDarkMode) {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    Hive.box('settings').put('isDarkMode', isDarkMode);
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    Hive.box('settings').put('notificationsEnabled', value);
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    Hive.box('settings').put('language', lang);
    notifyListeners();
  }

  void setUserName(String name) {
    _userName = name;
    Hive.box('settings').put('userName', name);
    notifyListeners();
  }

  void setAvatarUrl(String? url) {
    if (url != null && url.isNotEmpty) {
      // Add a timestamp query parameter to bypass potential CDN/local caching
      final cacheBuster = 'cb=${DateTime.now().millisecondsSinceEpoch}';
      _avatarUrl = url.contains('?') ? '$url&$cacheBuster' : '$url?$cacheBuster';
    } else {
      _avatarUrl = null;
    }
    Hive.box('settings').put('avatarUrl', _avatarUrl);
    notifyListeners();
  }

  void setAiModel(String model) {
    _selectedAiModel = model;
    Hive.box('settings').put('selectedAiModel', model);
    notifyListeners();
  }

  void setGuestUser() {
    setUserName('Guest');
    setAvatarUrl(null);
  }

  void setLocation(double lat, double lon, String name) {
    _lat = lat;
    _lon = lon;
    _locationName = name;
    Hive.box('settings').put('lat', lat);
    Hive.box('settings').put('lon', lon);
    Hive.box('settings').put('locationName', name);
    fetchWeather();
    notifyListeners();
  }

  Future<void> useCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied, we cannot request permissions.');
        return;
      }

      // On web, sometimes it's better to use a timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      
      _lat = position.latitude;
      _lon = position.longitude;

      if (!kIsWeb) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(_lat, _lon);
          if (placemarks.isNotEmpty) {
            _locationName = placemarks[0].locality ?? placemarks[0].administrativeArea ?? 'My Farm';
          }
        } catch (e) {
          debugPrint('Geocoding error: $e');
          _locationName = 'Current Location';
        }
      } else {
        // Fallback for web since geocoding package doesn't support it
        _locationName = 'Browser Location';
      }
      
      Hive.box('settings').put('lat', _lat);
      Hive.box('settings').put('lon', _lon);
      Hive.box('settings').put('locationName', _locationName);
      
      await fetchWeather();
      notifyListeners();
    } catch (e) {
      debugPrint('Location error: $e');
      // If it fails on web, we might still want to try to fetch weather with default or last known
    }
  }

  final Map<String, Map<String, dynamic>> _diseaseData = {
    'Black Rot': {
      'description': 'A serious bacterial disease causing V-shaped yellow lesions on leaf margins.',
      'symptoms': '• V-shaped yellow lesions on leaf edges\n• Darkening of leaf veins (blackening)\n• Stunted plant growth\n• Head rot in severe cases',
      'causes': '• Bacterial pathogen Xanthomonas campestris\n• High humidity and warm temperatures\n• Spread via water splashes and infected seeds',
      'prevention': '• Use certified disease-free seeds\n• Practice 3-year crop rotation\n• Control cruciferous weeds',
      'treatment': '• Apply copper-based fungicides\n• Remove and destroy infected plants immediately\n• Avoid working in the field when wet',
      'twi_name': 'Black Rot Yadeɛ',
      'twi_description': 'Yadeɛ yi firi mmoawa bi a ɛma nhaban no ano yɛ akokoɔsradeɛ na ɛporɔ.',
      'twi_treatment': 'Fa aba a ho tɛ, sesa nnɔbae no, na fa nnuru a kɔperea wom gu so.',
      'image': 'assets/images/c2.jpg'
    },
    'Downy Mildew': {
      'description': 'A fungal-like disease appearing as yellow spots on top of leaves and white mold underneath.',
      'symptoms': '• Small yellow patches on upper leaf surfaces\n• White, fuzzy mold growth on leaf undersides\n• Leaves turning brown and paper-like\n• Seedling death',
      'causes': '• Oomycete pathogen Hyaloperonospora parasitica\n• Cool, wet weather conditions\n• Poor air circulation between plants',
      'prevention': '• Space plants for better air flow\n• Avoid overhead irrigation (use drip)\n• Plant resistant varieties',
      'treatment': '• Use fungicides containing Mancozeb or Metalaxyl\n• Improve field drainage\n• Harvest early if infection starts',
      'twi_name': 'Downy Mildew Yadeɛ',
      'twi_description': 'Yadeɛ yi ma nhaban no so yɛ nsuwa-nsuwa akokoɔsradeɛ na ase yɛ mfutuo fitaa.',
      'twi_treatment': 'Ma mframa mbɔ mu yiye, mma nsuo nka nhaban no so pii, na fa nnuru a ɛfata gu so.',
      'image': 'assets/images/c3.jpg'
    },
    'Alternaria Leaf Spot': {
      'description': 'Caused by Alternaria fungi, resulting in small, dark spots that often develop a target-like appearance.',
      'symptoms': '• Small dark circular spots on older leaves\n• Concentric rings within spots (target appearance)\n• Yellowing around the spots\n• Premature leaf drop',
      'causes': '• Fungi Alternaria brassicicola or A. brassicae\n• Warm temperatures with frequent rain\n• Spread by wind and water splash',
      'prevention': '• Crop rotation with non-brassica crops\n• Prompt removal of crop debris\n• Use high-quality, treated seeds',
      'treatment': '• Apply chlorothalonil or copper fungicides\n• Avoid overhead watering late in the day\n• Balanced fertilization to maintain plant vigor',
      'twi_name': 'Alternaria Spot Yadeɛ',
      'twi_description': 'Yadeɛ yi firi mmoawa a ɛma nhaban no so yɛ ntokuro ntokuro kɔkɔɔ anaa tuntum.',
      'twi_treatment': 'Sesa nnɔbae no, fa aba a ho tɛ yɛ adwuma, na fa nnuru a ɛfata gu so.',
      'image': 'assets/images/c4.jpg'
    },
    'Healthy': {
      'description': 'The cabbage leaf appears healthy with no visible signs of disease.',
      'symptoms': '• Vibrant green color\n• Firm leaf texture\n• No spots or discolorations\n• Strong, upright stems',
      'causes': '• Optimal growing conditions\n• Good nutrient management\n• Effective pest and disease control',
      'prevention': '• Maintain regular scouting schedule\n• Ensure consistent watering\n• Regular soil testing',
      'treatment': '• Continue regular monitoring\n• Maintain good agricultural practices\n• Apply preventative organic neem spray',
      'twi_name': 'Nhyehyɛe Pa',
      'twi_description': 'Kabeji nhaban yi ho yɛ, yadeɛ biara nni ho.',
      'twi_treatment': 'Kɔ so hwɛ wo nnɔbae no so yiye na kɔ so yɛ adwuma pa.',
      'image': 'assets/images/c1.jpg'
    },
    'Bacterial Soft Rot': {
      'description': 'A severe bacterial infection that causes water-soaked lesions and rapid rotting of cabbage heads.',
      'symptoms': '• Water-soaked, soft, slimy leaf lesions\n• Foul, offensive odor\n• Collapse of whole cabbage heads\n• Discolored vascular tissues',
      'causes': '• Pectobacterium carotovorum (Erwinia carotovora)\n• High moisture and warm weather\n• Plant injuries from insects or handling',
      'prevention': '• Avoid physical injury during harvesting/cultivation\n• Ensure good field drainage and air flow\n• Rotate crops with non-susceptible plants',
      'treatment': '• Remove and destroy infected plants\n• Apply copper bactericides early\n• Allow soil to dry between waterings',
      'twi_name': 'Bacterial Soft Rot Yadeɛ',
      'twi_description': 'Yadeɛ yi firi mmoawa a ɛma kabeji no fɔm yɛ meree na ɛbɔ bon bi kɛseɛ.',
      'twi_treatment': 'Yi nkabeji a afei pɔrɔ no fi afuo no mu, na hwɛ ma asase no so nyina ne ho nsuo.',
      'image': 'assets/images/c5.jpg'
    },
    'Cabbage Aphid Infestation': {
      'description': 'Pest infestation caused by gray-green aphids feeding on cabbage leaf sap.',
      'symptoms': '• Curled, distorted, or yellowing leaves\n• Sticky honeydew on leaf surfaces\n• Clusters of small gray-green insects\n• Stunted plant growth',
      'causes': '• Brevicoryne brassicae (Cabbage aphids)\n• Dry, warm weather favoring rapid reproduction\n• Lack of natural aphid predators',
      'prevention': '• Inspect leaves regularly\n• Encourage natural predators like ladybugs\n• Use floating row covers on young plants',
      'treatment': '• Spray insecticidal soap or neem oil\n• Apply systemic or contact insecticides if severe\n• Wash off aphids with strong water spray',
      'twi_name': 'Kabeji Mmoawa Nkitinkiti',
      'twi_description': 'Mmoawa nkitinkiti a wɔnom nhaban no nsuo na ɛma nhaban no bɔ kinkyim na ɛyɛ kokoo.',
      'twi_treatment': 'Fa Neem ngo anaa samina aduru gu nhaban no so na kum mmoawa no.',
      'image': 'assets/images/c6.jpg'
    },
    'Club Root': {
      'description': 'A soil-borne disease causing distorted, swollen root galls and wilting leaves.',
      'symptoms': '• Swollen, knobby, or distorted roots\n• Wilting leaves during hot daytime hours\n• Yellowing and stunted growth\n• Reduced head formation',
      'causes': '• Plasmodiophora brassicae pathogen\n• Acidic, poorly-drained soil\n• Spores persisting in soil for many years',
      'prevention': '• Maintain soil pH above 7.2 using lime\n• Ensure proper field drainage\n• Practice long crop rotations (5–7 years)',
      'treatment': '• Apply soil lime to raise pH\n• Use soil fungicides at planting\n• Destroy infected root systems after harvest',
      'twi_name': 'Club Root Yadeɛ',
      'twi_description': 'Yadeɛ yi ma nhini no nhro na ɛyɛ akuro ma nhaban no gow awia keteke.',
      'twi_treatment': 'Fa gyata/lime kɔ dɔteɛ no mu ma yɛnnyɛ nkyene pii, na gyae brassica nnɔbae dua mfe pii.',
      'image': 'assets/images/c7.jpg'
    },
    'Ring Spot': {
      'description': 'Fungal leaf disease causing dark circular spots with yellow borders.',
      'symptoms': '• Dark brown spots with concentric ring patterns\n• Yellow halos surrounding leaf spots\n• Small black specks within spots\n• Premature leaf senescence',
      'causes': '• Mycosphaerella brassicicola fungal pathogen\n• Cool, wet, moist weather\n• Infected crop residues left in field',
      'prevention': '• Bury or burn crop residues after harvest\n• Use disease-free certified seeds\n• Rotate with non-cruciferous crops',
      'treatment': '• Spray recommended fungicides\n• Avoid overhead irrigation\n• Remove heavily infected leaves',
      'twi_name': 'Ring Spot Yadeɛ',
      'twi_description': 'Yadeɛ yi firi mmoawa a ɛyɛ ahinime ne nkuru nkuru kɔkɔɔ wɔ nhaban no so.',
      'twi_treatment': 'Sesa aduane no na fa nnuru a ɛfata gu so ntɛm.',
      'image': 'assets/images/c8.jpg'
    },
    'Not a Cabbage Leaf': {
      'description': 'The scanned image does not appear to be a cabbage leaf.',
      'symptoms': '• Image shows non-cabbage plants, objects, or blurred backgrounds.',
      'causes': '• Photo taken of non-cabbage subject or poor lighting/focus.',
      'prevention': '• Ensure proper lighting and focus directly on a cabbage leaf.',
      'treatment': '• Please retake the photo focusing clearly on a single cabbage leaf.',
      'twi_name': 'Ɛnyɛ Kabeji Nhaban',
      'twi_description': 'Mfonini no nyɛ kabeji nhaban anaa ɛnyɛ fann.',
      'twi_treatment': 'Sane yɛ mfonini foforɔ a ɛfa kabeji nhaban ho.',
      'image': 'assets/images/c9.jpg'
    },
  };

  Map<String, dynamic>? getDiseaseDetails(String diseaseName) {
    // Handle Twi names by finding the English key
    if (_language == 'Twi') {
      for (var entry in _diseaseData.entries) {
        if (entry.value['twi_name'] == diseaseName) {
          return entry.value;
        }
      }
    }
    return _diseaseData[diseaseName];
  }


  Future<io.File?> _cropImage(String path, ThemeData theme, ColorScheme colorScheme) async {
    if (kIsWeb) return null; // Image cropper might not support web in this direct way
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: _language == 'Twi' ? 'Twia mfonini no' : 'Focus on the Leaf',
            toolbarColor: colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: colorScheme.secondary,
            backgroundColor: theme.scaffoldBackgroundColor,
            statusBarColor: colorScheme.primary,
            showCropGrid: true,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
          IOSUiSettings(
            title: _language == 'Twi' ? 'Twia mfonini no' : 'Focus on the Leaf',
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
        ],
      );
      if (croppedFile != null) {
        return io.File(croppedFile.path);
      }
    } catch (e) {
      debugPrint('Cropping error: $e');
    }
    return null;
  }

  Future<void> pickImage(ImageSource source, BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      
      if (pickedFile != null) {
        // Essential delay to prevent race condition on some Android devices
        await Future.delayed(const Duration(milliseconds: 300));
        
        String imagePath = pickedFile.path;
        io.File finalImage = io.File(pickedFile.path);

        if (!kIsWeb) {
          final cropped = await _cropImage(pickedFile.path, theme, colorScheme);
          if (cropped != null) {
            finalImage = cropped;
            imagePath = cropped.path;
          }
        }

        _isLoading = true;
        _currentPrediction = null;
        _analysisMessage = 'SCANNING...';
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 500));
        _analysisMessage = 'EXTRACTING FEATURES...';
        notifyListeners();
        
        // For web, read bytes directly to avoid blob URL issues
        final dynamic input = kIsWeb ? await pickedFile.readAsBytes() : imagePath;
        final result = await _tfLiteService.classifyImage(input);
        
        await Future.delayed(const Duration(milliseconds: 500));
        _analysisMessage = 'MODEL DECIDING...';
        notifyListeners();

        if (!kIsWeb) {
          final directory = await getApplicationDocumentsDirectory();
          final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final savedImage = await finalImage!.copy('${directory.path}/$fileName');
          _selectedImage = savedImage;
          imagePath = savedImage.path;
        } else {
           imagePath = pickedFile.path; // Web uses blob URLs
        }

        if (result != null) {
          if (result['isLeaf'] == false) {
            _currentPrediction = Prediction(
              diseaseName: _language == 'Twi' ? 'Mfomsoɔ' : 'Invalid Image',
              confidence: result['confidence'],
              description: _language == 'Twi' 
                  ? 'Mfonini a woyiiɛ no nsɛ kabeji nhaban anaa ɛnyɛ fann. Yɛpa wo kyɛw scan kabeji nhaban a ɛfata na fann.' 
                  : 'The image captured does not look like a cabbage leaf or is not clear enough. Please try again with a clear photo of a cabbage leaf.',
              treatment: _language == 'Twi' ? 'Sane yɛ mfonini foforɔ.' : 'Please retake the photo.',
              imagePath: imagePath,
              dateTime: DateTime.now(),
              isAsset: false,
              isLeaf: false,
            );
          } else {
            String label = result['label'];
            double confidence = result['confidence'];
            final data = _diseaseData[label];
            
            _currentPrediction = Prediction(
              diseaseName: _language == 'Twi' ? (data?['twi_name'] ?? label) : label,
              confidence: confidence,
              description: _language == 'Twi' ? (data?['twi_description'] ?? 'Ankyerɛmu biara nni hɔ') : (data?['description'] ?? 'Unknown'),
              treatment: _language == 'Twi' ? (data?['twi_treatment'] ?? 'Ayaresa biara nni hɔ') : (data?['treatment'] ?? 'No treatment info available.'),
              imagePath: imagePath,
              dateTime: DateTime.now(),
              isAsset: false,
              isLeaf: true,
            );
          }
          
          // 1. Update local state immediately
          _history.insert(0, _currentPrediction!);
          _saveHistory();
          _checkAndNotifyAnalytics();
          
          // 2. Stop loading so UI can navigate to ResultScreen
          _isLoading = false;
          notifyListeners();

          // 3. Save to cloud in the background WITHOUT blocking the UI
          if (!isGuest) {
            final scanToSave = _currentPrediction!;
            final pathForCloud = imagePath;
            
            pickedFile.readAsBytes().then((bytes) {
              _supabaseService.saveScan(scanToSave, pathForCloud, bytes).then((_) {
                debugPrint('Cloud save successful');
                syncWithCloud();
              }).catchError((e) {
                debugPrint('Cloud save failed: $e');
              });
            });
          }
          return; // Exit early to skip the generic _isLoading = false in finally
        } else {
          _currentPrediction = Prediction(
            diseaseName: _language == 'Twi' ? 'Mfomsoɔ' : 'Analysis Error',
            confidence: 0.0,
            description: _language == 'Twi' ? 'Yɛantumi anhunu yadeɛ no. Yɛpa wo kyɛw sane bɔ mmɔden.' : 'We could not analyze the image. Please try again.',
            treatment: _language == 'Twi' ? 'Sane yɛ mfonini foforɔ.' : 'Please retake the photo.',
            imagePath: imagePath,
            dateTime: DateTime.now(),
            isAsset: false,
          );
        }
      }
    } catch (e) {
      debugPrint('Error during selection/classification: $e');
      _currentPrediction = Prediction(
        diseaseName: 'Error',
        confidence: 0.0,
        description: 'A critical error occurred: $e',
        treatment: 'Please restart the app or try again.',
        imagePath: '',
        dateTime: DateTime.now(),
        isAsset: false,
      );
    } finally {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> processLiveScanResult(String imagePath, Map<String, dynamic> result) async {
    try {
      _isLoading = true;
      notifyListeners();

      String savedPath = imagePath;
      if (!kIsWeb) {
        final file = io.File(imagePath);
        if (file.existsSync()) {
          final directory = await getApplicationDocumentsDirectory();
          final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final savedImage = await file.copy('${directory.path}/$fileName');
          _selectedImage = savedImage;
          savedPath = savedImage.path;
        }
      }

      if (result['isLeaf'] == false) {
        _currentPrediction = Prediction(
          diseaseName: _language == 'Twi' ? 'Mfomsoɔ' : 'Invalid Image',
          confidence: (result['confidence'] as num?)?.toDouble() ?? 0.0,
          description: _language == 'Twi' 
              ? 'Mfonini a woyiiɛ no nsɛ kabeji nhaban anaa ɛnyɛ fann. Yɛpa wo kyɛw scan kabeji nhaban a ɛfata na fann.' 
              : 'The image captured does not look like a cabbage leaf or is not clear enough. Please try again with a clear photo of a cabbage leaf.',
          treatment: _language == 'Twi' ? 'Sane yɛ mfonini foforɔ.' : 'Please retake the photo.',
          imagePath: savedPath,
          dateTime: DateTime.now(),
          isAsset: false,
          isLeaf: false,
        );
      } else {
        String label = result['label'];
        double confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
        final data = _diseaseData[label];
        
        _currentPrediction = Prediction(
          diseaseName: _language == 'Twi' ? (data?['twi_name'] ?? label) : label,
          confidence: confidence,
          description: _language == 'Twi' ? (data?['twi_description'] ?? 'Ankyerɛmu biara nni hɔ') : (data?['description'] ?? 'Unknown'),
          treatment: _language == 'Twi' ? (data?['twi_treatment'] ?? 'Ayaresa biara nni hɔ') : (data?['treatment'] ?? 'No treatment info available.'),
          imagePath: savedPath,
          dateTime: DateTime.now(),
          isAsset: false,
          isLeaf: true,
        );
      }

      _history.insert(0, _currentPrediction!);
      _saveHistory();
      _checkAndNotifyAnalytics();
      _isLoading = false;
      notifyListeners();

      if (!isGuest) {
        final scanToSave = _currentPrediction!;
        final fileForCloud = io.File(savedPath);
        if (fileForCloud.existsSync()) {
          final bytes = await fileForCloud.readAsBytes();
          _supabaseService.saveScan(scanToSave, savedPath, bytes).then((_) {
            debugPrint('Cloud save successful');
            syncWithCloud();
          }).catchError((e) {
            debugPrint('Cloud save failed: $e');
          });
        }
      }
    } catch (e) {
      debugPrint('Error processing live scan result: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void _checkAndNotifyAnalytics() {
    if (!_notificationsEnabled) return;
    if (_history.length >= 3) {
      int healthyCount = _history.where((s) => s.diseaseName.toLowerCase().contains('healthy') || s.diseaseName.contains('Nhyehy')).length;
      int diseasedCount = _history.length - healthyCount;
      
      String summary = "You've completed ${_history.length} scans. $healthyCount healthy, $diseasedCount diseased.";
      if (_language == 'Twi') {
        summary = "Woayɛ nhwehwɛmu ${_history.length}. $healthyCount ho yɛ den, $diseasedCount yadeƐ bi wɔ ho.";
      }
      
      _notificationService.showInstantNotification(
        100,
        _language == 'Twi' ? 'Nkabom NhwehwƐmu' : 'Farm Health Summary',
        summary
      );
    }
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String surname,
    required String dob,
    required String gender,
    required String profession,
    required String region,
    required String phone,
  }) async {
    final res = await _supabaseService.signUp(
      email: email,
      password: password,
      firstName: firstName,
      surname: surname,
      dob: dob,
      gender: gender,
      profession: profession,
      region: region,
      phone: phone,
    );
    if (res.user != null) {
      setUserName('$firstName $surname');
    }
    return res;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    final res = await _supabaseService.signIn(email, password);
    if (res.user != null) {
      await _loadUserData();
      await syncWithCloud();
    }
    return res;
  }

  Future<void> _loadUserData() async {
    if (_supabaseService.currentUser != null) {
      final profile = await _supabaseService.fetchUserProfile();
      if (profile != null) {
        setUserName('${profile['first_name']} ${profile['surname']}');
        setAvatarUrl(profile['avatar_url']);
        setLocation(_lat, _lon, profile['region'] ?? 'Unknown');
      }
    }
  }

  Future<void> updateAvatar(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final url = await _supabaseService.uploadAvatar(file.path, bytes);
      if (url != null) {
        await _supabaseService.updateAvatarUrl(url);
        setAvatarUrl(url);
        debugPrint('Avatar updated successfully: $url');
      }
    } catch (e) {
      debugPrint('Error updating avatar: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabaseService.signOut();
    setGuestUser();
    // Load guest history immediately
    await _loadUserHistoryAndSchedules();
    notifyListeners();
  }

  void setCurrentPrediction(Prediction prediction) {
    _currentPrediction = prediction;
    notifyListeners();
  }

  Future<void> deleteScan(Prediction prediction) async {
    _history.removeWhere((item) => item.dateTime == prediction.dateTime && item.imagePath == prediction.imagePath);
    
    if (!isGuest && (prediction.isNetwork || prediction.imagePath.startsWith('http'))) {
      await _supabaseService.deleteScan(prediction.imagePath);
    }

    if (!prediction.isAsset && !kIsWeb) {
      try {
        final file = io.File(prediction.imagePath);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        debugPrint('Error deleting local file: $e');
      }
    }
    
    _saveHistory();
    notifyListeners();
  }

  Future<void> deleteMultipleScans(List<Prediction> scansToDelete) async {
    for (var scan in scansToDelete) {
      await deleteScan(scan);
    }
  }

  Future<void> deleteAllHistory() async {
    final scansToDelete = List<Prediction>.from(_history);
    for (var scan in scansToDelete) {
      await deleteScan(scan);
    }
  }

  void _saveHistory() {
    final userId = _supabaseService.currentUser?.id ?? 'guest';
    final historyBox = Hive.box('scan_history');
    final historyData = _history.map((e) => e.toMap()).toList();
    historyBox.put('history_$userId', historyData);
  }

  Future<void> addSchedule(Schedule schedule) async {
    _schedules.add(schedule);
    _schedules.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    _saveSchedules();
    
    if (_supabaseService.currentUser != null) {
      await _supabaseService.addSchedule(schedule);
    }

    notifyListeners();
  }

  Future<void> deleteSchedule(String id) async {
    _schedules.removeWhere((s) => s.id == id);
    _saveSchedules();
    
    if (!isGuest) {
      await _supabaseService.deleteSchedule(id);
    }
    
    notifyListeners();
  }

  void _saveSchedules() {
    final userId = _supabaseService.currentUser?.id ?? 'guest';
    final scheduleBox = Hive.box('schedules');
    final scheduleData = _schedules.map((e) => e.toMap()).toList();
    scheduleBox.put('list_$userId', scheduleData);
  }

  Future<String> askAi(String prompt) async {
    _isChatLoading = true;
    notifyListeners();
    try {
      if (_selectedAiModel == 'Llama') {
        return await _supabaseService.askLlama(prompt);
      }
      return await _supabaseService.askGemini(prompt);
    } finally {
      _isChatLoading = false;
      notifyListeners();
    }
  }

  Future<String> askGemini(String prompt) async {
    return askAi(prompt); // Maintain backward compatibility
  }

  String tr(String key) {
    if (_language != 'Twi') return key;
    
    final twiMap = {
      'DASHBOARD': 'ADWUMAYƐBEA',
      'Scan your leaves for health status.': 'Hwɛ wo nnɔbae ahoɔden.',
      'Sunny': 'Wiem Ayɛ Hyɛ',
      'Scans': 'NhwehwƐmu',
      'Diagnosis Tools': 'NhwehwƐmu Akwan',
      'Camera': 'Kamera',
      'Gallery': 'Adaka',
      'Recent Scans': 'NhwehwƐmu a Atwam',
      'View all': 'Hwɛ ne nyinaa',
      'LIVE': 'ƐREKƆ SO',
      'Daily Recommendation': 'Afutuo',
      'Based on crop cycle': 'Ɛgyina nnɔbae mmerɛ so',
      'CROP CARE TIP': 'AFUTUO PA',
      'Home': 'Efie',
      'Farm Weather': 'Wiem mberɛ',
      'Weather': 'Wiem mberɛ',
      'Scan Schedule': 'Hyehyɛɛ',
      'Schedule': 'Hyehyɛɛ',
      'Field Analytics': 'Akontaabuo',
      'Analytics': 'Akontaabuo',
      'Scan History': 'Abakɔsɛm',
      'History': 'Abakɔsɛm',
      'Settings': 'Nhyehyɛe',
      'About Doctor': 'Fa fa ho',
      'Help & About': 'Mmoa ne Ho Asɛm',
      'Logout': 'Firi mu',
      'Standard Access': 'Mmoa Baako',
      'Pro Farmer': 'Okuafoɔ Panin',
      'Guest User': 'Ɔhɔhoɔ',
      'DIAGNOSIS': 'NHWEHWƐMU',
      'Description': 'Nkyerɛmu',
      'Recommended Treatment': 'SƐnea yƐsa yadeƐ no',
      'Back to Dashboard': 'Kɔ Fie',
      'Listen to Advice': 'Tie afutuo no',
      'Stop Listening': 'Gyae tie',
      'Tie afutuo no wɔ Twi mu': 'Tie afutuo no',
      'ANALYZING LEAF...': 'YƐREHWƐ NHABAN NO...',
      'Our AI is detecting diseases': 'YƐREHWƐ SƐ YADEƐ BIARA WƆ HO',
      'No history yet.\nStart by scanning a leaf!': 'Abakɔsɛm biara nni hɔ.\nFa scan nhaban bi fiti ase!',
      'Detection History': 'Nhwehwɛmu Abakɔsɛm',
      'Delete Scan?': 'Popa Nhwehwɛmu no?',
      'This action cannot be undone.': 'Sɛ wopopa a, ɛrentumi nsan mma bio.',
      'CANCEL': 'TWƐN',
      'DELETE': 'POPA',
      'Scan deleted': 'Yɛapopa nhwehwɛmu no',
      'Upcoming Schedule': 'Hyehyɛɛ a ɛreba',
      'No tasks scheduled.': 'Hyehyɛɛ biara nni hɔ.',
      'Scanning': 'NhwehwƐmu',
      'Watering': 'Nsuo gu',
      'Pruning': 'Nhyehyɛe',
      'Fertilizing': 'Duane gu',
      'Pest Control': 'Mmoawa kum',
      'Invalid Image': 'Mfonini no nyɛ papa',
      'Please scan a valid cabbage leaf. Our AI only recognizes cabbage leaves for now.': 'Yɛpa wo kyɛw scan kabeji nhaban a ɛfata. Yɛn AI no hu kabeji nhaban nko ara mprempren.',
      'Delete Selected?': 'Popa deɛ woapaw no?',
      'Delete All History?': 'Popa Abakɔsɛm nyinaa?',
      'Are you sure you want to delete all scans?': 'Wopɛ sɛ wopopa nhwehwƐmu nyinaa?',
      'ALL SCANS DELETED': 'YƐAPOPA NHWEHWƐMU NYINAA',
      'Selected': 'Paw',
      'Select Scans': 'Paw NhwehwƐmu',
      'Delete All': 'Popa Ne Nyinaa',
      'Delete Selected Scans': 'Popa NhwehwƐmu a woapaw',
      'Language': 'Kasa',
      'Dark Mode': 'Anadwo mberɛ',
      'Enable Notifications': 'Ma kwan ma nkaebɔ',
      'Receive scan reminders': 'Nya scan nkaebɔ',
      'About Doctor & AI': 'Fa fa Doctor ne AI ho',
      'App info and developer details': 'App ho asƐm ne nkurɔfoɔ a wɔyƐeƐ',
      'Appearance': 'SƐnea ɛteƐ',
      'Preferences': 'NhyehyƐe',
      'Help': 'Mmoa',
      'Select Date': 'Paw Da',
      'Plan Your Task': 'Hyehyɛ wo adwuma',
      'Reminder Time': 'Nkaebɔ mberɛ',
      'Set Reminder for': 'Hyehyɛ nkaebɔ ma',
      'SMART SUGGESTION FOR': 'AFUTUO MA',
      'Farm Planner': 'Afuo Nhyehyɛe',
      'Delete Schedule?': 'Popa Nhyehyɛe?',
      'Schedule deleted permanently': 'YƐapopa nhyehyɛe no koraa',
      'Plan More': 'Hyehyɛ foforɔ',
      'Recent Activity': 'Nhwehwɛmu a atwam',
      'See All': 'Hwɛ ne nyinaa',
      'Scan Analytics': 'Nhwehwɛmu akontaabuo',
      'Total Scans': 'Nhwehwɛmu nyinaa',
      'Next Task': 'Adwuma a ɛdi hɔ',
      'ACTIVE': 'ƐKƆ SO',
      'CABBAGE DOCTOR': 'KABEJI DOCTOR',
      'How to use': 'SƐnea wɔde di dwuma',
      'HOW TO DO IT': 'SƐNEA WƆYƐ NO',
      'Time': 'Mberɛ',
      'Add to Field Schedule': 'Fa ka nhyehyɛe ho',
      'EXPERT CHOICE': 'AFUTUO PA',
      'For': 'Ma',
      'Click to plan it below.': 'Pia ase ha na hyehyɛ.',
      'Use AI to check for diseases early.': 'Fa AI hwehwɛ yadeɛ mu ntɛm.',
      'Maintain consistent soil moisture.': 'Hwɛ sɛ nsuo wɔ asase no mu.',
      'Remove damaged or infected parts.': 'Tu nhaban a ayɛ yadeɛ gu.',
      'Apply nitrogen-rich nutrients.': 'Fa duane gu mu.',
      'Monitor for caterpillars & aphids.': 'Hwɛ mmoawa ahorow.',
      'Walk diagonally across field': 'Fante-fante kɔ afuo mu',
      'Select 10 random leaves': 'Paw nhaban du',
      'Scan with Cabbage Doctor': 'Scan wɔ Cabbage Doctor mu',
      'Note high-risk areas': 'Hwɛ baabi a yadeɛ wɔ paa',
      'Check soil 2-inches deep': 'Hwɛ asase no mu paa',
      'Water at the base of plants': 'Gugu nsuo wɔ aseɛ',
      'Avoid wetting leaves': 'Mma nsuo nka nhaban',
      'Best done before 9 AM': 'Yɛ no anɔpa paa',
      'Identify V-shaped lesions': 'Hwehwɛ nhaban a ayɛ yadeɛ',
      'Use sterilized tools': 'Fa nninnuadeɛ a ho tɛ',
      'Remove lower yellow leaves': 'Tu nhaban a ayɛ kɔkɔɔ',
      'Dispose debris away from field': 'Tu gu baabi a ɛware',
      'Apply 3 weeks after planting': 'Yɛ no adapɛn mmiɛnsa akyi',
      'Side-dress 6 inches from stem': 'Fa gu nkyɛn kakra',
      'Water immediately after': 'Gugu nsuo ntɛm',
      'Follow local dosage guide': 'Di akwankyerɛ so',
      'Look under leaf surfaces': 'Hwɛ nhaban no ase',
      'Check for silk or holes': 'Hwɛ ntontan anaa ntokuro',
      'Identify beneficial insects': 'Hwɛ mmoawa pa',
      'Use organic neem spray if needed': 'Fa neem spray gu so',
      'No upcoming tasks.': 'Hyehyɛɛ biara nni hɔ.',
      'Selected Scans Deleted': 'Nhwehwɛmu a woapaw no yɛapopa',
      'SYMPTOMS': 'YADEƐ NO NGYINAEƐ',
      'CAUSES': 'DEƐ ƐDE BA',
      'PREVENTION': 'SƐNEA YƐSIW KWAN',
      'Disease Info': 'Yadeɛ Ho Asɛm',
      'View Detailed Disease Info': 'Hwɛ Yadeɛ no ho asɛm pii',
      'AI ANALYSIS REPORT': 'AI NHWEHWƐMU AMANNEƐBƆ',
      'User Guide': 'Mmoa',
      'How to Use the App': 'Sɛnea wɔde App no di dwuma',
      'Capture Image': 'Yi Mfonini',
      'Use the camera to take a clear photo of the cabbage leaf.': 'Fa kamera no yi kabeji nhaban no mfonini a emu yɛ fann.',
      'Upload': 'Upload',
      'Select a cabbage leaf image from your gallery.': 'Paw kabeji nhaban mfonini firi wo mfonini adaka mu.',
      'Wait': 'Twɛn kakra',
      'Our AI analyzes the biological features of the leaf.': 'Yɛn AI no bɛhwehwɛ nhaban no mu yiye.',
      'View Result': 'Hwɛ deɛ ɛfiri mu baeɛ',
      'Get instant diagnosis and treatment recommendations.': 'Nya yadeɛ no din ne snea wɔsa no ntɛm paa.',
      'Friendly Tip: For the best results, please take a clear photo of the leaf. Occasionally, other objects might be mistaken for a cabbage leaf.': 'Afutuo Pa: Yi mfonini no fann ma nhwehwɛmu no nyɛ pɛpɛɛpɛ. Ɛtɔ da bi a, nneɛma foforɔ bɛtumi ayɛ sɛ kabeji nhaban.',
      'Cabbage Focus': 'Kabeji Nko Ara',
      'To get the most accurate results, please ensure you are scanning a cabbage leaf. Other objects or non-cabbage plants might be misidentified as diseased cabbage.': 'Boa yɛn na yɛmmoa wo! Sɛ wopɛ sɛ yenya yadeɛ no din pɛpɛɛpɛ a, yɛpa wo kyɛw scan kabeji nhaban nko ara. Ɛtɔ da bi a, AI no bɛtumi abu nnɔbae foforɔ sɛ kabeji a ayɛ yadeɛ, enti kabeji nhaban nko ara a wobɛscan no bɛboa wo afuo paa.',
      'PROCEED': 'KƆ SO',
    };

    return twiMap[key] ?? key;
  }

  String getSuggestedActivity(DateTime day) {
    if (_history.isNotEmpty) {
      String latestDisease = _history.first.diseaseName;
      if (latestDisease.contains('Black Rot') && (day.weekday == DateTime.tuesday || day.weekday == DateTime.friday)) {
        return _language == 'Twi' ? 'Wuo Aduane ma Black Rot' : 'Copper Fungicide Spray';
      }
      if (latestDisease.contains('Downy') && day.weekday == DateTime.monday) {
        return _language == 'Twi' ? 'Hwɛ nhaban no ase' : 'Check Leaf Undersides';
      }
    }

    if (day.weekday == DateTime.monday || day.weekday == DateTime.thursday) {
      return _language == 'Twi' ? 'Gugu nsuo paa' : 'Deep Watering';
    } else if (day.weekday == DateTime.wednesday) {
      return _language == 'Twi' ? 'Fa AI hwehwɛ nhaban mu' : 'AI Leaf Scanning';
    } else if (day.weekday == DateTime.saturday) {
      return _language == 'Twi' ? 'Popa afuo no mu' : 'Field Pruning & Clearing';
    } else if (day.day % 10 == 0) {
      return _language == 'Twi' ? 'Fa duane gu mu' : 'Fertilizer Application';
    }
    return _language == 'Twi' ? 'Hwɛ afuo no mu' : 'General Field Scouting';
  }

  @override
  void dispose() {
    _tfLiteService.dispose();
    super.dispose();
  }
}
