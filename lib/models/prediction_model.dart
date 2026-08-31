class Prediction {
  final String diseaseName;
  final double confidence;
  final String description;
  final String treatment;
  final String imagePath;
  final DateTime dateTime;
  final bool isAsset;
  final bool isLeaf;
  final bool isNetwork; // Added to identify cloud images

  Prediction({
    required this.diseaseName,
    required this.confidence,
    required this.description,
    required this.treatment,
    required this.imagePath,
    required this.dateTime,
    this.isAsset = false,
    this.isLeaf = true,
    this.isNetwork = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'diseaseName': diseaseName,
      'confidence': confidence,
      'description': description,
      'treatment': treatment,
      'imagePath': imagePath,
      'dateTime': dateTime.toIso8601String(),
      'isAsset': isAsset,
      'isLeaf': isLeaf,
      'isNetwork': isNetwork,
    };
  }

  factory Prediction.fromMap(Map<String, dynamic> map) {
    return Prediction(
      diseaseName: map['diseaseName'],
      confidence: map['confidence'],
      description: map['description'],
      treatment: map['treatment'],
      imagePath: map['imagePath'],
      dateTime: DateTime.parse(map['dateTime']),
      isAsset: map['isAsset'] ?? false,
      isLeaf: map['isLeaf'] ?? true,
      isNetwork: map['isNetwork'] ?? false,
    );
  }
}
