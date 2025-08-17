// lib/services/exercise_database/exercise_detail_service.dart

import '../../models/exercise_database/exercise_detail_model.dart';
import '../../models/exercise_database/predefined_exercise_model.dart';

class ExerciseDetailService {
  // Singleton pattern
  static final ExerciseDetailService _instance = ExerciseDetailService._internal();
  factory ExerciseDetailService() => _instance;
  ExerciseDetailService._internal();
  
  // SVG ID Mapping basierend auf male_ID_mapping.txt
  static const Map<String, List<String>> _muscleGroupSvgIds = {
    // Front View
    'Abs': ['_x34_3', '_x34_2', '_x34_6', '_x34_7', '_x34_5', '_x34_4', '_x31_8', '_x32_6', '_x32_9', '_x31_7', '_x32_5', '_x33_1'],
    'Biceps': ['_x36_3', '_x36_2'],
    'Triceps_Front': ['_x32_2', '_x32_4'],
    'Calves_Front': ['_x33_7', '_x34_0', '_x33_9'],
    'Chest': ['_x37_1', '_x37_0'],
    'Front Delts': ['_x35_2', '_x35_0'],
    'Quads': ['_x36_1', '_x36_4', '_x35_4', '_x35_6', '_x34_8', '_x32_1', '_x32_3', '_x34_9', '_x35_5', '_x35_3', '_x36_6', '_x36_0'],
    'Side Delts_Front': ['_x33_4', '_x35_1'],
    
    // Back View
    'Back': ['_x35_2', '_x35_0', '_x30_5', '_x30_4', '_x30_1', '_x33_7', '_x31_6', '_x33_5', '_x31_7', '_x35_5', '_x35_4'],
    'Triceps_Back': ['_x32_9', '_x32_6', '_x32_4', '_x32_8'],
    'Calves_Back': ['_x34_2', '_x34_7', '_x34_3', '_x34_4', '_x33_5'],
    'Glutes': ['_x35_1', '_x35_3', '_x33_4', '_x33_3'],
    'Hamstrings': ['_x32_5', '_x34_8', '_x31_3', '_x33_9', '_x32_1', '_x32_0', '_x34_0', '_x31_2', '_x34_9', '_x32_7'],
    'Rear Delts': ['_x34_6', '_x34_5'],
    'Traps': ['_x35_4', '_x35_5'],
  };
  
  /// Konvertiere PredefinedExercise zu ExerciseDetailModel
  ExerciseDetailModel convertFromPredefinedExercise(PredefinedExercise exercise) {
    // Hole SVG IDs basierend auf Muskelgruppen
    final primaryIds = _getMuscleGroupSvgIds(exercise.primaryMuscleGroup);
    final secondaryIds = _getSecondaryMuscleGroupSvgIds(exercise.secondaryMuscleGroups);
    
    return ExerciseDetailModel(
      exerciseId: exercise.name.toLowerCase().replaceAll(' ', '_'),
      exerciseName: exercise.name,
      primaryMuscleGroup: exercise.primaryMuscleGroup,
      secondaryMuscleGroups: exercise.secondaryMuscleGroups,
      primaryMuscleIds: primaryIds,
      secondaryMuscleIds: secondaryIds,
      useBackView: exercise.useBackView ?? _shouldUseBackView(exercise.primaryMuscleGroup),
      affectedJoints: exercise.affectedJoints ?? [],
      movementPattern: exercise.movementPattern ?? 'Standard',
      movementDescription: exercise.movementDescription ?? 'Standardübung für ${exercise.primaryMuscleGroup}',
      rangeOfMotion: exercise.metrics?.rangeOfMotion ?? 3,
      stability: exercise.metrics?.stability ?? 3,
      jointStress: exercise.metrics?.jointStress ?? 3,
      systemicStress: exercise.metrics?.systemicStress ?? 3,
      technique: exercise.technique,
      commonMistakes: exercise.commonMistakes,
      tips: exercise.tips,
    );
  }
  
  /// Hole erweiterte Details für eine Übung aus PredefinedExercise
  ExerciseDetailModel? getExerciseDetails(PredefinedExercise exercise) {
    return convertFromPredefinedExercise(exercise);
  }
  
  /// Bestimme SVG IDs für primäre Muskelgruppe
  List<String> _getMuscleGroupSvgIds(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case 'brust':
        return _muscleGroupSvgIds['Chest'] ?? [];
      case 'rücken':
        return _muscleGroupSvgIds['Back'] ?? [];
      case 'beine':
        return _muscleGroupSvgIds['Quads'] ?? [];
      case 'schultern':
        return [
          ..._muscleGroupSvgIds['Front Delts'] ?? [],
          ..._muscleGroupSvgIds['Side Delts_Front'] ?? [],
        ];
      case 'bizeps':
        return _muscleGroupSvgIds['Biceps'] ?? [];
      case 'trizeps':
        return _muscleGroupSvgIds['Triceps_Front'] ?? [];
      case 'bauch':
      case 'core':
        return _muscleGroupSvgIds['Abs'] ?? [];
      case 'waden':
        return _muscleGroupSvgIds['Calves_Front'] ?? [];
      case 'gesäß':
        return _muscleGroupSvgIds['Glutes'] ?? [];
      case 'trapezius':
        return _muscleGroupSvgIds['Traps'] ?? [];
      case 'unterer rücken':
        return _muscleGroupSvgIds['Back'] ?? [];
      default:
        return [];
    }
  }
  
  /// Bestimme SVG IDs für sekundäre Muskelgruppen
  List<String> _getSecondaryMuscleGroupSvgIds(List<String> muscleGroups) {
    List<String> ids = [];
    for (final group in muscleGroups) {
      ids.addAll(_getMuscleGroupSvgIds(group));
    }
    return ids;
  }
  
  /// Bestimme ob Rückansicht verwendet werden soll
  bool _shouldUseBackView(String primaryMuscleGroup) {
    final backViewGroups = [
      'rücken',
      'unterer rücken',
      'trapezius',
      'gesäß',
      'beinbeuger',
      'waden',
      'hintere schulter',
    ];
    
    return backViewGroups.contains(primaryMuscleGroup.toLowerCase());
  }
}