import 'dart:io';
// Removed unused dart:math and dart:typed_data imports

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'tflite_service_interface.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class TFLiteService implements TFLiteServiceInterface {
  Interpreter? _interpreter;
  List<String> _labels = [
    'Alternaria Leaf Spot',
    'Black Rot',
    'Downy Mildew',
    'Healthy'
  ];

  @override
  Future<void> loadModel() async {
    if (_interpreter != null) return;
    try {
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(
        'assets/mobilev2/cabbage_mobilenetv2.tflite',
        options: options,
      );
      _interpreter!.allocateTensors();
      
      final inputTensor = _interpreter!.getInputTensor(0);
      debugPrint('TFLite Model Metadata: Shape=${inputTensor.shape}, Type=${inputTensor.type}');

      try {
        final labelsData = await rootBundle.loadString('assets/model/cabbage_labels.txt');
        _labels = labelsData.split('\n').where((s) => s.isNotEmpty).map((s) => s.trim()).toList();
        debugPrint('TFLite: Labels loaded: $_labels');
      } catch (e) {
        debugPrint('TFLite: Using default labels: $_labels');
      }
    } catch (e) {
      debugPrint('TFLite Error (Load): $e');
    }
  }

  Future<String> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final documentDirectory = await getTemporaryDirectory();
      final file = File('${documentDirectory.path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } catch (e) {
      throw Exception('TFLite: Failed to download image: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> classifyImage(String imageSource) async {
    try {
      if (_interpreter == null) await loadModel();
      if (_interpreter == null) return null;

      final File imageFile = File(imageSource.startsWith('http') ? await _downloadImage(imageSource) : imageSource);
      if (!imageFile.existsSync()) return null;

      var image = img.decodeImage(imageFile.readAsBytesSync());
      if (image == null) return null;
      image = img.bakeOrientation(image);

      // MobileNetV2 dimensions as requested
      const int inputSize = 224;
      img.Image resizedImage = img.copyResize(image, width: inputSize, height: inputSize);

      // Allocate the Float32 buffer (1 * 224 * 224 * 3)
      var inputBuffer = Float32List(1 * inputSize * inputSize * 3);
      int index = 0;

      // Extract channels sequentially (RGB sequence) using raw 0.0 - 255.0 floats
      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          var pixel = resizedImage.getPixel(x, y);
          
          // Pass clean raw 0.0 - 255.0 floats directly. No manual division required!
          inputBuffer[index++] = pixel.r.toDouble();
          inputBuffer[index++] = pixel.g.toDouble();
          inputBuffer[index++] = pixel.b.toDouble();
        }
      }

      var output = Float32List(_labels.length).reshape([1, _labels.length]);
      _interpreter!.run(inputBuffer.reshape([1, inputSize, inputSize, 3]), output);

      List<double> probabilities = List<double>.from(output[0]);
      double maxScore = 0.0;
      int maxIndex = 0;

      debugPrint('--- AI DEBUG SCORES (RAW 0-255 RGB) ---');
      for (int i = 0; i < probabilities.length; i++) {
        debugPrint('${_labels[i]}: ${(probabilities[i] * 100).toStringAsFixed(2)}%');
        if (probabilities[i] > maxScore) {
          maxScore = probabilities[i];
          maxIndex = i;
        }
      }
      debugPrint('---------------------------------------');

      const double threshold = 0.67;
      bool isConfident = maxScore >= threshold;

      if (!isConfident) {
        return {
          'label': 'Unidentified / Not a Leaf',
          'confidence': maxScore,
          'index': 3,
          'isLeaf': false,
        };
      }

      return {
        'label': _labels[maxIndex],
        'confidence': maxScore,
        'index': maxIndex,
        'isLeaf': isConfident, 
        'all_scores': probabilities,
      };
    } catch (e) {
      debugPrint('TFLite Inference Error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
