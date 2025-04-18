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
}
