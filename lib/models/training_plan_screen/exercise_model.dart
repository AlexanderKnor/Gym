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

  // toMap() Methode für Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'primaryMuscleGroup': primaryMuscleGroup,
      'secondaryMuscleGroup': secondaryMuscleGroup,
      'standardIncrease': standardIncrease,
      'restPeriodSeconds': restPeriodSeconds,
      'numberOfSets': numberOfSets,
      'repRangeMin': repRangeMin,
      'repRangeMax': repRangeMax,
      'rirRangeMin': rirRangeMin,
      'rirRangeMax': rirRangeMax,
      'progressionProfileId': progressionProfileId,
    };
  }

  // Alias für JSON-Serialisierung
  Map<String, dynamic> toJson() => toMap();

  // fromMap() Factory-Methode für Firestore
  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    return ExerciseModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      primaryMuscleGroup: map['primaryMuscleGroup'] ?? '',
      secondaryMuscleGroup: map['secondaryMuscleGroup'] ?? '',
      standardIncrease: map['standardIncrease']?.toDouble() ?? 2.5,
      restPeriodSeconds: map['restPeriodSeconds'] ?? 90,
      numberOfSets: map['numberOfSets'] ?? 3,
      repRangeMin: map['repRangeMin'] ?? 8,
      repRangeMax: map['repRangeMax'] ?? 12,
      rirRangeMin: map['rirRangeMin'] ?? 1,
      rirRangeMax: map['rirRangeMax'] ?? 3,
      progressionProfileId: map['progressionProfileId'],
    );
  }

  // Alias für JSON-Deserialisierung
  factory ExerciseModel.fromJson(Map<String, dynamic> json) => ExerciseModel.fromMap(json);
}
