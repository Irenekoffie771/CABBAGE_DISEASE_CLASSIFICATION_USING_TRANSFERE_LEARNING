class Schedule {
  final String id;
  final String activity;
  final DateTime dateTime;
  final bool isCompleted;

  Schedule({
    required this.id,
    required this.activity,
    required this.dateTime,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activity': activity,
      'dateTime': dateTime.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'],
      activity: map['activity'],
      dateTime: DateTime.parse(map['dateTime']),
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}
