// lib/models/exercise_database/exercise_detail_model.dart

/// Model für erweiterte Übungsdetails mit anatomischen und biomechanischen Informationen
class ExerciseDetailModel {
  final String exerciseId;
  final String exerciseName;
  
  // Muskelgruppen
  final String primaryMuscleGroup;
  final List<String> secondaryMuscleGroups;
  
  // Anatomische SVG IDs für Highlighting
  final List<String> primaryMuscleIds;
  final List<String> secondaryMuscleIds;
  final bool useBackView; // true = back view, false = front view
  
  // Belastete Gelenke
  final List<String> affectedJoints;
  
  // Bewegungsmuster
  final String movementPattern;
  final String movementDescription;
  
  // Metriken (1-5 Bewertung)
  final int rangeOfMotion;      // Bewegungsumfang
  final int stability;           // Stabilität
  final int jointStress;         // Gelenkbelastung
  final int systemicStress;      // Systematische Belastung
  
  // Zusätzliche Informationen
  final String? technique;
  final List<String>? commonMistakes;
  final List<String>? tips;
  
  ExerciseDetailModel({
    required this.exerciseId,
    required this.exerciseName,
    required this.primaryMuscleGroup,
    required this.secondaryMuscleGroups,
    required this.primaryMuscleIds,
    required this.secondaryMuscleIds,
    required this.useBackView,
    required this.affectedJoints,
    required this.movementPattern,
    required this.movementDescription,
    required this.rangeOfMotion,
    required this.stability,
    required this.jointStress,
    required this.systemicStress,
    this.technique,
    this.commonMistakes,
    this.tips,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'primaryMuscleGroup': primaryMuscleGroup,
      'secondaryMuscleGroups': secondaryMuscleGroups,
      'primaryMuscleIds': primaryMuscleIds,
      'secondaryMuscleIds': secondaryMuscleIds,
      'useBackView': useBackView,
      'affectedJoints': affectedJoints,
      'movementPattern': movementPattern,
      'movementDescription': movementDescription,
      'rangeOfMotion': rangeOfMotion,
      'stability': stability,
      'jointStress': jointStress,
      'systemicStress': systemicStress,
      'technique': technique,
      'commonMistakes': commonMistakes,
      'tips': tips,
    };
  }
  
  factory ExerciseDetailModel.fromMap(Map<String, dynamic> map) {
    return ExerciseDetailModel(
      exerciseId: map['exerciseId'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      primaryMuscleGroup: map['primaryMuscleGroup'] ?? '',
      secondaryMuscleGroups: List<String>.from(map['secondaryMuscleGroups'] ?? []),
      primaryMuscleIds: List<String>.from(map['primaryMuscleIds'] ?? []),
      secondaryMuscleIds: List<String>.from(map['secondaryMuscleIds'] ?? []),
      useBackView: map['useBackView'] ?? false,
      affectedJoints: List<String>.from(map['affectedJoints'] ?? []),
      movementPattern: map['movementPattern'] ?? '',
      movementDescription: map['movementDescription'] ?? '',
      rangeOfMotion: map['rangeOfMotion'] ?? 3,
      stability: map['stability'] ?? 3,
      jointStress: map['jointStress'] ?? 3,
      systemicStress: map['systemicStress'] ?? 3,
      technique: map['technique'],
      commonMistakes: map['commonMistakes'] != null 
          ? List<String>.from(map['commonMistakes']) 
          : null,
      tips: map['tips'] != null 
          ? List<String>.from(map['tips']) 
          : null,
    );
  }
}