// lib/models/training_history/set_history_model.dart
class SetHistoryModel {
  final int setNumber;
  final double kg;
  final int reps;
  final int rir;
  final bool completed;
  final DateTime? timestamp;

  SetHistoryModel({
    required this.setNumber,
    required this.kg,
    required this.reps,
    required this.rir,
    this.completed = false,
    this.timestamp,
  });

  // Kopieren mit geänderten Werten
  SetHistoryModel copyWith({
    int? setNumber,
    double? kg,
    int? reps,
    int? rir,
    bool? completed,
    DateTime? timestamp,
  }) {
    return SetHistoryModel(
      setNumber: setNumber ?? this.setNumber,
      kg: kg ?? this.kg,
      reps: reps ?? this.reps,
      rir: rir ?? this.rir,
      completed: completed ?? this.completed,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // Konvertierung zu Map für Firestore
  Map<String, dynamic> toMap() {
    return {
      'setNumber': setNumber,
      'kg': kg,
      'reps': reps,
      'rir': rir,
      'completed': completed,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  // Alias für JSON-Serialisierung
  Map<String, dynamic> toJson() => toMap();

  // Erstellen aus Map von Firestore
  factory SetHistoryModel.fromMap(Map<String, dynamic> map) {
    return SetHistoryModel(
      setNumber: map['setNumber'],
      kg: map['kg']?.toDouble() ?? 0.0,
      reps: map['reps'] ?? 0,
      rir: map['rir'] ?? 0,
      completed: map['completed'] ?? false,
      timestamp:
          map['timestamp'] != null ? DateTime.parse(map['timestamp']) : null,
    );
  }

  // Alias für JSON-Deserialisierung
  factory SetHistoryModel.fromJson(Map<String, dynamic> json) => SetHistoryModel.fromMap(json);

  // Factory für einen neuen Satz aus TrainingSetModel
  factory SetHistoryModel.fromTrainingSet(
    int setNumber,
    double kg,
    int reps,
    int rir,
    bool completed,
  ) {
    return SetHistoryModel(
      setNumber: setNumber,
      kg: kg,
      reps: reps,
      rir: rir,
      completed: completed,
      timestamp: DateTime.now(),
    );
  }
}
