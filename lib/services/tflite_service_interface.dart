abstract class TFLiteServiceInterface {
  Future<void> loadModel();
  Future<Map<String, dynamic>?> classifyImage(String imagePath);
  void dispose();
}
