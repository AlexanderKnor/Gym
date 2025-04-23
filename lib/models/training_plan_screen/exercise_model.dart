// lib/models/training_plan_screen/exercise_model.dart
class ExerciseModel {
  final String id;
  String name;
  String primaryMuscleGroup;
  String secondaryMuscleGroup;
  double standardIncrease;
  int restPeriodSeconds;
  int numberOfSets; // Neues Feld für die Anzahl der Sätze
  String? progressionProfileId; // Neues Feld für das Progressionsprofil

  ExerciseModel({
    required this.id,
    required this.name,
    required this.primaryMuscleGroup,
    required this.secondaryMuscleGroup,
    required this.standardIncrease,
    required this.restPeriodSeconds,
    this.numberOfSets = 3, // Standardmäßig 3 Sätze
    this.progressionProfileId, // Optional, kann null sein
  });

  // Copy-Methode - VERBESSERT FÜR NULL-WERTE
  ExerciseModel copyWith({
    String? id,
    String? name,
    String? primaryMuscleGroup,
    String? secondaryMuscleGroup,
    double? standardIncrease,
    int? restPeriodSeconds,
    int? numberOfSets,
    // Wichtig: Object? statt String? damit null explizit gesetzt werden kann
    Object? progressionProfileId = const Object(),
  }) {
    return ExerciseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      primaryMuscleGroup: primaryMuscleGroup ?? this.primaryMuscleGroup,
      secondaryMuscleGroup: secondaryMuscleGroup ?? this.secondaryMuscleGroup,
      standardIncrease: standardIncrease ?? this.standardIncrease,
      restPeriodSeconds: restPeriodSeconds ?? this.restPeriodSeconds,
      numberOfSets: numberOfSets ?? this.numberOfSets,
      // Spezielle Behandlung für progressionProfileId, damit null explizit gesetzt werden kann
      progressionProfileId: progressionProfileId != const Object()
          ? progressionProfileId as String?
          : this.progressionProfileId,
    );
  }
}
