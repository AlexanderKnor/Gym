// lib/models/training_history/training_session_model.dart
import 'exercise_history_model.dart';

class TrainingSessionModel {
  final String id;
  final String trainingPlanId;
  final String trainingDayId;
  final String trainingDayName;
  final DateTime date;
  final List<ExerciseHistoryModel> exercises;
  final bool isCompleted;

  TrainingSessionModel({
    required this.id,
    required this.trainingPlanId,
    required this.trainingDayId,
    required this.trainingDayName,
    required this.date,
    required this.exercises,
    this.isCompleted = false,
  });

  // Kopieren mit geänderten Werten
  TrainingSessionModel copyWith({
    String? id,
    String? trainingPlanId,
    String? trainingDayId,
    String? trainingDayName,
    DateTime? date,
    List<ExerciseHistoryModel>? exercises,
    bool? isCompleted,
  }) {
    return TrainingSessionModel(
      id: id ?? this.id,
      trainingPlanId: trainingPlanId ?? this.trainingPlanId,
      trainingDayId: trainingDayId ?? this.trainingDayId,
      trainingDayName: trainingDayName ?? this.trainingDayName,
      date: date ?? this.date,
      exercises: exercises ?? this.exercises,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // Konvertierung zu Map für Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trainingPlanId': trainingPlanId,
      'trainingDayId': trainingDayId,
      'trainingDayName': trainingDayName,
      'date': date.toIso8601String(),
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'isCompleted': isCompleted,
    };
  }

  // Alias für JSON-Serialisierung
  Map<String, dynamic> toJson() => toMap();

  // Erstellen aus Map von Firestore
  factory TrainingSessionModel.fromMap(Map<String, dynamic> map) {
    return TrainingSessionModel(
      id: map['id'],
      trainingPlanId: map['trainingPlanId'],
      trainingDayId: map['trainingDayId'],
      trainingDayName: map['trainingDayName'],
      date: DateTime.parse(map['date']),
      exercises: (map['exercises'] as List)
          .map((e) => ExerciseHistoryModel.fromMap(e))
          .toList(),
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  // Alias für JSON-Deserialisierung
  factory TrainingSessionModel.fromJson(Map<String, dynamic> json) => TrainingSessionModel.fromMap(json);

  // Factory für neue Session
  factory TrainingSessionModel.create(
    String trainingPlanId,
    String trainingDayId,
    String trainingDayName,
  ) {
    return TrainingSessionModel(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      trainingPlanId: trainingPlanId,
      trainingDayId: trainingDayId,
      trainingDayName: trainingDayName,
      date: DateTime.now(),
      exercises: [],
      isCompleted: false,
    );
  }
}
