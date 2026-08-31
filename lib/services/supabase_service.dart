import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/prediction_model.dart';
import '../models/schedule_model.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

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
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
        'surname': surname,
      },
    );

    if (response.user != null) {
      await _client.from('profiles').upsert({
        'id': response.user!.id,
        'first_name': firstName,
        'surname': surname,
        'dob': dob,
        'gender': gender,
        'profession': profession,
        'region': region,
        'phone_number': phone,
      });
    }
    return response;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.cabageai://reset-password/',
      );
    } catch (e) {
      debugPrint('Reset Password Error: $e');
      rethrow;
    }
  }

  Future<void> saveScan(Prediction scan, String filePath, Uint8List bytes) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$userId/$fileName';

    try {
      await _client.storage.from('leaf_scans').uploadBinary(
        path, 
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
      final imageUrl = _client.storage.from('leaf_scans').getPublicUrl(path);

      await _client.from('scan_history').insert({
        'user_id': userId,
        'disease_name': scan.diseaseName,
        'confidence': scan.confidence,
        'description': scan.description,
        'treatment': scan.treatment,
        'image_url': imageUrl,
        'is_leaf': scan.isLeaf,
      });
    } catch (e) {
      debugPrint('Supabase Save Scan Error: $e');
    }
  }

  Future<List<Prediction>> fetchScans() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('scan_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((e) {
        return Prediction(
          diseaseName: e['disease_name'],
          confidence: (e['confidence'] as num).toDouble(),
          description: e['description'],
          treatment: e['treatment'],
          imagePath: e['image_url'], 
          dateTime: DateTime.parse(e['created_at']),
          isAsset: false,
          isLeaf: e['is_leaf'] ?? true,
          isNetwork: true,
        );
      }).toList();
    } catch (e) {
      debugPrint('Fetch scans error: $e');
      return [];
    }
  }

  Future<void> deleteScan(String imageUrl) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    try {
      await _client.from('scan_history').delete().eq('image_url', imageUrl);
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;
      final path = '$userId/$fileName';
      await _client.storage.from('leaf_scans').remove([path]);
    } catch (e) {
      debugPrint('Supabase Delete Scan Error: $e');
    }
  }

  Future<String?> addSchedule(Schedule schedule) async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client.from('schedules').insert({
        'user_id': userId,
        'activity': schedule.activity,
        'date_time': schedule.dateTime.toIso8601String(),
        'is_completed': schedule.isCompleted,
      }).select('id').single();
      
      return response['id'].toString();
    } catch (e) {
      debugPrint('Supabase Add Schedule Error: $e');
      return null;
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    try {
      dynamic idToMatch = int.tryParse(scheduleId) ?? scheduleId;
      await _client.from('schedules').delete().eq('id', idToMatch).eq('user_id', userId);
    } catch (e) {
      debugPrint('Supabase Delete Schedule Error: $e');
    }
  }

  Future<List<Schedule>> fetchSchedules() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('schedules')
          .select()
          .eq('user_id', userId)
          .order('date_time', ascending: true);

      return (response as List).map((e) => Schedule.fromMap({
        'id': e['id'].toString(),
        'activity': e['activity'],
        'dateTime': e['date_time'],
        'isCompleted': e['is_completed'],
      })).toList();
    } catch (e) {
      debugPrint('Supabase Fetch Schedules Error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final response = await _client.from('profiles').select().eq('id', userId).single();
    return response;
  }

  Future<void> updateAvatarUrl(String url) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    await _client.from('profiles').update({'avatar_url': url}).eq('id', userId);
  }

  Future<void> updateUserProfile({
    required String firstName,
    required String surname,
    required String profession,
    required String region,
    required String phone,
    String? dob,
    String? gender,
    String? avatarUrl,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client.from('profiles').update({
      'first_name': firstName,
      'surname': surname,
      'profession': profession,
      'region': region,
      'phone_number': phone,
      if (dob != null) 'dob': dob,
      if (gender != null) 'gender': gender,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    }).eq('id', userId);
  }

  Future<String?> uploadAvatar(String path, Uint8List bytes) async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storagePath = '$userId/$fileName';

    try {
      await _client.storage.from('avatars').uploadBinary(
        storagePath, 
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
      return _client.storage.from('avatars').getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('Supabase Avatar Upload Error: $e');
      return null;
    }
  }

  Future<dynamic> callSmoothApi(Uint8List imageBytes) async {
    try {
      final response = await _client.functions.invoke(
        dotenv.env['SMOOTH_API_FUNCTION_NAME'] ?? 'smooth-api',
        body: imageBytes,
        headers: {
          'Content-Type': 'application/octet-stream',
        },
      );
      return response.data;
    } catch (e) {
      debugPrint('Supabase Smooth API Error: $e');
      return null;
    }
  }

  Future<String> askGemini(String prompt) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY']?.trim();
      if (apiKey == null || apiKey.isEmpty) {
        return 'Error: GEMINI_API_KEY is not set in assets/cab.env';
      }

      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );

      final fullPrompt = 'You are an expert Agricultural AI assistant specializing ONLY in cabbage farming. '
          'Your knowledge is restricted to cabbage cultivation, cabbage diseases, pests, soil management, and general agricultural advice for cabbage farmers. '
          'If the user asks about topics unrelated to cabbage or farming (like politics, entertainment, or other crops), '
          'politely decline and inform them that you are a dedicated Cabbage AI Assistant. '
          'A farmer is asking: "$prompt". '
          'Provide a concise, helpful, and professional answer. '
          'Always respond in English, even if the user asks in another language.';

      final content = [Content.text(fullPrompt)];
      final response = await model.generateContent(content);

      return response.text ?? 'AI returned an empty response.';
    } catch (e) {
      debugPrint('Gemini Direct Error: $e');
      return 'AI unreachable: $e';
    }
  }

  Future<String> askLlama(String prompt) async {
    try {
      final apiKey = dotenv.env['GROQ_API_KEY']?.trim();
      if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_GROQ_API_KEY_HERE') {
        return 'Error: GROQ_API_KEY is not set in assets/cab.env. Please get one from groq.com';
      }

      const url = 'https://api.groq.com/openai/v1/chat/completions';
      
      const systemPrompt = 'You are an expert Agricultural AI assistant specializing ONLY in cabbage farming. '
          'You must ONLY answer questions related to cabbage cultivation, cabbage diseases (like Black Rot, Downy Mildew), '
          'pests, soil health, and general cabbage farming practices. '
          'If the user asks about anything outside of cabbage farming (e.g., general knowledge, sports, other crops, or unrelated topics), '
          'politely decline and explain that you are specialized only in helping cabbage farmers. '
          'Keep answers professional and concise. Always respond in English, even if the user asks in another language like Twi.';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': dotenv.env['GROQ_MODEL'] ?? 'groq/compound',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'Llama returned an empty response.';
      } else {
        return 'Groq API Error: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      debugPrint('Llama (Groq) Error: $e');
      return 'AI unreachable: $e';
    }
  }
}
