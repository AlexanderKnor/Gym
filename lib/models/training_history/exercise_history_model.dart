// lib/models/training_history/exercise_history_model.dart
import 'set_history_model.dart';

class ExerciseHistoryModel {
  final String id;
  final String exerciseId;
  final String name;
  final String primaryMuscleGroup;
  final String secondaryMuscleGroup;
  final double standardIncrease;
  final int restPeriodSeconds;
  final List<SetHistoryModel> sets;
  final bool isCompleted;
  final String? progressionProfileId;

  ExerciseHistoryModel({
    required this.id,
    required this.exerciseId,
    required this.name,
    required this.primaryMuscleGroup,
    required this.secondaryMuscleGroup,
    required this.standardIncrease,
    required this.restPeriodSeconds,
    required this.sets,
    this.isCompleted = false,
    this.progressionProfileId,
  });

  // Kopieren mit geänderten Werten
  ExerciseHistoryModel copyWith({
    String? id,
    String? exerciseId,
    String? name,
    String? primaryMuscleGroup,
    String? secondaryMuscleGroup,
    double? standardIncrease,
    int? restPeriodSeconds,
    List<SetHistoryModel>? sets,
    bool? isCompleted,
    String? progressionProfileId,
  }) {
    return ExerciseHistoryModel(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      primaryMuscleGroup: primaryMuscleGroup ?? this.primaryMuscleGroup,
      secondaryMuscleGroup: secondaryMuscleGroup ?? this.secondaryMuscleGroup,
      standardIncrease: standardIncrease ?? this.standardIncrease,
      restPeriodSeconds: restPeriodSeconds ?? this.restPeriodSeconds,
      sets: sets ?? this.sets,
      isCompleted: isCompleted ?? this.isCompleted,
      progressionProfileId: progressionProfileId ?? this.progressionProfileId,
    );
  }

  // Konvertierung zu Map für Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'name': name,
      'primaryMuscleGroup': primaryMuscleGroup,
      'secondaryMuscleGroup': secondaryMuscleGroup,
      'standardIncrease': standardIncrease,
      'restPeriodSeconds': restPeriodSeconds,
      'sets': sets.map((s) => s.toMap()).toList(),
      'isCompleted': isCompleted,
      'progressionProfileId': progressionProfileId,
    };
  }

  // Alias für JSON-Serialisierung
  Map<String, dynamic> toJson() => toMap();

  // Erstellen aus Map von Firestore
  factory ExerciseHistoryModel.fromMap(Map<String, dynamic> map) {
    return ExerciseHistoryModel(
      id: map['id'],
      exerciseId: map['exerciseId'],
      name: map['name'],
      primaryMuscleGroup: map['primaryMuscleGroup'],
      secondaryMuscleGroup: map['secondaryMuscleGroup'],
      standardIncrease: map['standardIncrease']?.toDouble() ?? 2.5,
      restPeriodSeconds: map['restPeriodSeconds'] ?? 90,
      sets:
          (map['sets'] as List).map((s) => SetHistoryModel.fromMap(s)).toList(),
      isCompleted: map['isCompleted'] ?? false,
      progressionProfileId: map['progressionProfileId'],
    );
  }

  // Alias für JSON-Deserialisierung
  factory ExerciseHistoryModel.fromJson(Map<String, dynamic> json) => ExerciseHistoryModel.fromMap(json);

  // Factory für neue Exercise History
  factory ExerciseHistoryModel.fromExerciseModel(
    String exerciseId,
    String name,
    String primaryMuscleGroup,
    String secondaryMuscleGroup,
    double standardIncrease,
    int restPeriodSeconds,
    String? progressionProfileId,
  ) {
    return ExerciseHistoryModel(
      id: 'exercise_history_${DateTime.now().millisecondsSinceEpoch}_${exerciseId.hashCode}',
      exerciseId: exerciseId,
      name: name,
      primaryMuscleGroup: primaryMuscleGroup,
      secondaryMuscleGroup: secondaryMuscleGroup,
      standardIncrease: standardIncrease,
      restPeriodSeconds: restPeriodSeconds,
      sets: [],
      progressionProfileId: progressionProfileId,
    );
  }
}
