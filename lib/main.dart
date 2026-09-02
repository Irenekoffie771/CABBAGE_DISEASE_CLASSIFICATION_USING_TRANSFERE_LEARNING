import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/app_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/reset_password_screen.dart';
import 'services/notification_service.dart';

void main() async {
  try {
    FlutterError.onError = (details) {
      debugPrint('Flutter Error: ${details.exception}');
    };

    WidgetsFlutterBinding.ensureInitialized();
    
    try {
      // On Web, the assets path is handled differently by the loader
      const String envPath = kIsWeb ? "cab.env" : "assets/cab.env";
      await dotenv.load(fileName: envPath);
    } catch (e) {
      debugPrint('Warning: Could not load env file ($e). Trying fallback...');
      try {
        await dotenv.load(fileName: "assets/cab.env");
      } catch (e2) {
        debugPrint('Error: Environment file loading failed: $e2');
      }
    }
    
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseKey,
      );
    } catch (e) {
      debugPrint('Supabase Init Error: $e');
    }
    
    try {
      await Hive.initFlutter();
      await Hive.openBox('settings');
      await Hive.openBox('scan_history');
      await Hive.openBox('schedules');
    } catch (e) {
      debugPrint('Hive Init Error: $e');
    }
    
    try {
      await NotificationService().init();
    } catch (e) {
      debugPrint('Notifications Init Error: $e');
    }
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
        ],
        child: const CabbageDoctorApp(),
      ),
    );
  } catch (error, stackTrace) {
    debugPrint('CRITICAL APP CRASH: $error');
    debugPrint(stackTrace.toString());
  }
}

class CabbageDoctorApp extends StatefulWidget {
  const CabbageDoctorApp({super.key});

  @override
  State<CabbageDoctorApp> createState() => _CabbageDoctorAppState();
}

class _CabbageDoctorAppState extends State<CabbageDoctorApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Cabbage disease classification app',
          debugShowCheckedModeBanner: false,
          themeMode: provider.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFFFFFFF),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2E7D32),
              primary: const Color(0xFF2E7D32),
              secondary: const Color(0xFFFBC02D),
              surface: const Color(0xFFFFFFFF),
              onSurface: const Color(0xFF1B5E20),
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.plusJakartaSansTextTheme(
              ThemeData.light().textTheme,
            ).apply(
              bodyColor: const Color(0xFF1B5E20),
              displayColor: const Color(0xFF1B5E20),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: const Color(0xFFF1F8E9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
            ),
            appBarTheme: AppBarTheme(
              centerTitle: true,
              elevation: 0,
              titleTextStyle: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B5E20),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF0A0C0A),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4CAF50),
              primary: const Color(0xFF4CAF50),
              secondary: const Color(0xFFFFEB3B),
              surface: const Color(0xFF151A15),
              onSurface: Colors.white,
              brightness: Brightness.dark,
            ),
            textTheme: GoogleFonts.plusJakartaSansTextTheme(
              ThemeData.dark().textTheme,
            ).apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: const Color(0xFF1B241B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
            ),
            appBarTheme: AppBarTheme(
              centerTitle: true,
              elevation: 0,
              titleTextStyle: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
