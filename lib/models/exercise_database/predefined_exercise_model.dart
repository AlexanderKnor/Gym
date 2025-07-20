class PredefinedExercise {
  final int id;
  final String name;
  final String primaryMuscleGroup;
  final List<String> secondaryMuscleGroups;
  final String equipment;

  PredefinedExercise({
    required this.id,
    required this.name,
    required this.primaryMuscleGroup,
    required this.secondaryMuscleGroups,
    required this.equipment,
  });

  factory PredefinedExercise.fromJson(Map<String, dynamic> json) {
    return PredefinedExercise(
      id: json['id'] as int,
      name: json['name'] as String,
      primaryMuscleGroup: json['primaryMuscleGroup'] as String,
      secondaryMuscleGroups: List<String>.from(json['secondaryMuscleGroups'] as List),
      equipment: json['equipment'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'primaryMuscleGroup': primaryMuscleGroup,
      'secondaryMuscleGroups': secondaryMuscleGroups,
      'equipment': equipment,
    };
  }
}