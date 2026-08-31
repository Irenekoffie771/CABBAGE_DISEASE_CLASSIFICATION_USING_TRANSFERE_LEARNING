import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'tflite_service_interface.dart';

class TFLiteService implements TFLiteServiceInterface {
  final List<String> _labels = [
    'Alternaria Leaf Spot',
    'Black Rot',
    'Downy Mildew',
    'Healthy'
  ];

  @override
  Future<void> loadModel() async {
    debugPrint('TFLite Service (Web): Using Render-hosted Python API.');
  }

  @override
  Future<Map<String, dynamic>?> classifyImage(String imageSource) async {
    try {
      debugPrint('TFLite Web: Sending image bytes to Render API...');
      
      // 1. Fetch image bytes directly from the URL provided (blob or network)
      final response = await http.get(Uri.parse(imageSource));
      final Uint8List imageBytes = response.bodyBytes;

      // 2. Call Render API
      const String apiUrl = 'https://capii.onrender.com/predict';
      
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'image.jpg',
      ));

      final streamedResponse = await request.send();
      final apiResponse = await http.Response.fromStream(streamedResponse);

      if (apiResponse.statusCode == 200) {
        final dynamic data = jsonDecode(apiResponse.body);
        String label = data['disease'] ?? 'Healthy';
        double confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;

        // Threshold check: if confidence is too low, treat as unidentified
        if (confidence < 0.67) {
          return {
            'label': 'Unidentified / Not a Leaf',
            'confidence': confidence,
            'index': 3,
            'isLeaf': false,
          };
        }

        return {
          'label': label,
          'confidence': confidence,
          'index': _labels.contains(label) ? _labels.indexOf(label) : 3,
          'isLeaf': true,
        };
      } else {
        debugPrint('TFLite Web: Render API Error: ${apiResponse.statusCode} - ${apiResponse.body}');
        return null;
      }
    } catch (e) {
      debugPrint('TFLite Web Error: $e');
      return null;
    }
  }

  @override
  void dispose() {}
}
