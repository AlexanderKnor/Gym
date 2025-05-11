// lib/models/training_plan_screen/exercise_model.dart
class ExerciseModel {
  final String id;
  String name;
  String primaryMuscleGroup;
  String secondaryMuscleGroup;
  double standardIncrease;
  int restPeriodSeconds;
  int numberOfSets; // Neues Feld für die Anzahl der Sätze
  int repRangeMin; // Neues Feld für minimale Wiederholungen
  int repRangeMax; // Neues Feld für maximale Wiederholungen
  int rirRangeMin; // Neues Feld für minimalen RIR-Wert
  int rirRangeMax; // Neues Feld für maximalen RIR-Wert
  String? progressionProfileId; // Neues Feld für das Progressionsprofil

  ExerciseModel({
    required this.id,
    required this.name,
    required this.primaryMuscleGroup,
    required this.secondaryMuscleGroup,
    required this.standardIncrease,
    required this.restPeriodSeconds,
    this.numberOfSets = 3, // Standardmäßig 3 Sätze
    this.repRangeMin = 8, // Standardmäßig 8 Wiederholungen minimal
    this.repRangeMax = 12, // Standardmäßig 12 Wiederholungen maximal
    this.rirRangeMin = 1, // Standardmäßig 1 RIR minimal
    this.rirRangeMax = 3, // Standardmäßig 3 RIR maximal
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
    int? repRangeMin,
    int? repRangeMax,
    int? rirRangeMin,
    int? rirRangeMax,
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
      repRangeMin: repRangeMin ?? this.repRangeMin,
      repRangeMax: repRangeMax ?? this.repRangeMax,
      rirRangeMin: rirRangeMin ?? this.rirRangeMin,
      rirRangeMax: rirRangeMax ?? this.rirRangeMax,
      // Spezielle Behandlung für progressionProfileId, damit null explizit gesetzt werden kann
      progressionProfileId: progressionProfileId != const Object()
          ? progressionProfileId as String?
          : this.progressionProfileId,
    );
  }
}
