// lib/models/exercise_database/predefined_exercise_model.dart

class PredefinedExercise {
  final int id;
  final String name;
  final String primaryMuscleGroup;
  final List<String> secondaryMuscleGroups;
  final String equipment;
  
  // Erweiterte Details
  final String? movementPattern;
  final String? movementDescription;
  final List<String>? affectedJoints;
  final bool? useBackView;
  final ExerciseMetrics? metrics;
  final String? technique;
  final List<String>? commonMistakes;
  final List<String>? tips;

  PredefinedExercise({
    required this.id,
    required this.name,
    required this.primaryMuscleGroup,
    required this.secondaryMuscleGroups,
    required this.equipment,
    this.movementPattern,
    this.movementDescription,
    this.affectedJoints,
    this.useBackView,
    this.metrics,
    this.technique,
    this.commonMistakes,
    this.tips,
  });

  factory PredefinedExercise.fromJson(Map<String, dynamic> json) {
    return PredefinedExercise(
      id: json['id'] as int,
      name: json['name'] as String,
      primaryMuscleGroup: json['primaryMuscleGroup'] as String,
      secondaryMuscleGroups: List<String>.from(json['secondaryMuscleGroups'] as List),
      equipment: json['equipment'] as String,
      movementPattern: json['movementPattern'] as String?,
      movementDescription: json['movementDescription'] as String?,
      affectedJoints: json['affectedJoints'] != null 
          ? List<String>.from(json['affectedJoints'] as List)
          : null,
      useBackView: json['useBackView'] as bool?,
      metrics: json['metrics'] != null 
          ? ExerciseMetrics.fromJson(json['metrics'] as Map<String, dynamic>)
          : null,
      technique: json['technique'] as String?,
      commonMistakes: json['commonMistakes'] != null
          ? List<String>.from(json['commonMistakes'] as List)
          : null,
      tips: json['tips'] != null
          ? List<String>.from(json['tips'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'primaryMuscleGroup': primaryMuscleGroup,
      'secondaryMuscleGroups': secondaryMuscleGroups,
      'equipment': equipment,
      'movementPattern': movementPattern,
      'movementDescription': movementDescription,
      'affectedJoints': affectedJoints,
      'useBackView': useBackView,
      'metrics': metrics?.toJson(),
      'technique': technique,
      'commonMistakes': commonMistakes,
      'tips': tips,
    };
  }
}

class ExerciseMetrics {
  final int rangeOfMotion;
  final int stability;
  final int jointStress;
  final int systemicStress;

  ExerciseMetrics({
    required this.rangeOfMotion,
    required this.stability,
    required this.jointStress,
    required this.systemicStress,
  });

  factory ExerciseMetrics.fromJson(Map<String, dynamic> json) {
    return ExerciseMetrics(
      rangeOfMotion: json['rangeOfMotion'] as int,
      stability: json['stability'] as int,
      jointStress: json['jointStress'] as int,
      systemicStress: json['systemicStress'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rangeOfMotion': rangeOfMotion,
      'stability': stability,
      'jointStress': jointStress,
      'systemicStress': systemicStress,
    };
  }
}