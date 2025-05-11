// lib/models/training_plan_screen/training_day_model.dart
import 'exercise_model.dart';

class TrainingDayModel {
  final String id;
  String name;
  List<ExerciseModel> exercises;

  TrainingDayModel({
    required this.id,
    required this.name,
    required this.exercises,
  });

  // Copy-Methode
  TrainingDayModel copyWith({
    String? id,
    String? name,
    List<ExerciseModel>? exercises,
  }) {
    return TrainingDayModel(
      id: id ?? this.id,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
    );
  }

  // Methode zum Konvertieren in Map für Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  // Factory-Methode zum Erstellen aus Map von Firestore
  factory TrainingDayModel.fromMap(Map<String, dynamic> map) {
    return TrainingDayModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      exercises: (map['exercises'] as List?)
              ?.map((e) => ExerciseModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
