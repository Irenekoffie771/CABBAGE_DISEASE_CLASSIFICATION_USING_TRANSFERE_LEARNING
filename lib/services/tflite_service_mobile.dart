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
    'Bacterial Soft Rot',
    'Black Rot',
    'Cabbage Aphid Infestation',
    'Downy Mildew',
    'Healthy',
    'Not a Cabbage Leaf',
    'Club Root',
    'Ring Spot',
  ];

  @override
  Future<void> loadModel() async {
    if (_interpreter != null) return;
    try {
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(
        'assets/model/cabbage_float32.tflite',
        options: options,
      );
      _interpreter!.allocateTensors();
      
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      debugPrint('TFLite Model Metadata: Input Shape=${inputTensor.shape}, Type=${inputTensor.type}; Output Shape=${outputTensor.shape}');

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

      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);

      // Input dimension specified as 299x299 (NHWC RGB)
      final int inputHeight = inputTensor.shape.length > 1 ? inputTensor.shape[1] : 299;
      final int inputWidth = inputTensor.shape.length > 2 ? inputTensor.shape[2] : 299;

      img.Image resizedImage = img.copyResize(image, width: inputWidth, height: inputHeight);

      // Allocate the Float32 buffer (1 * height * width * 3)
      var inputBuffer = Float32List(1 * inputHeight * inputWidth * 3);
      int index = 0;

      // Extract channels sequentially (RGB sequence) using raw 0.0 - 255.0 floats (normalisation is baked into the model)
      for (int y = 0; y < inputHeight; y++) {
        for (int x = 0; x < inputWidth; x++) {
          var pixel = resizedImage.getPixel(x, y);
          
          inputBuffer[index++] = pixel.r.toDouble();
          inputBuffer[index++] = pixel.g.toDouble();
          inputBuffer[index++] = pixel.b.toDouble();
        }
      }

      int numClasses = outputTensor.shape.length > 1 ? outputTensor.shape[1] : _labels.length;
      var output = Float32List(numClasses).reshape([1, numClasses]);
      _interpreter!.run(inputBuffer.reshape([1, inputHeight, inputWidth, 3]), output);

      List<double> probabilities = List<double>.from(output[0]);
      double maxScore = 0.0;
      int maxIndex = 0;

      debugPrint('--- AI DEBUG SCORES (RAW 0-255 RGB) ---');
      for (int i = 0; i < probabilities.length && i < _labels.length; i++) {
        debugPrint('${_labels[i]}: ${(probabilities[i] * 100).toStringAsFixed(2)}%');
        if (probabilities[i] > maxScore) {
          maxScore = probabilities[i];
          maxIndex = i;
        }
      }
      debugPrint('---------------------------------------');

      // Model specification: confidence threshold = 0.891
      const double threshold = 0.891;
      bool isConfident = maxScore >= threshold;
      String predictedLabel = maxIndex < _labels.length ? _labels[maxIndex] : 'Unidentified';
      bool isNotLeaf = maxIndex == 6 || predictedLabel == 'Not a Cabbage Leaf' || predictedLabel == 'Not cabbage';

      if (!isConfident || isNotLeaf) {
        return {
          'label': isNotLeaf ? 'Not a Cabbage Leaf' : 'Unidentified / Not a Leaf',
          'confidence': maxScore,
          'index': maxIndex,
          'isLeaf': false,
        };
      }

      return {
        'label': predictedLabel,
        'confidence': maxScore,
        'index': maxIndex,
        'isLeaf': true, 
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
