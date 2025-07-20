import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/exercise_database/predefined_exercise_model.dart';

class ExerciseDatabaseService {
  static ExerciseDatabaseService? _instance;
  List<PredefinedExercise>? _exercises;

  ExerciseDatabaseService._();

  static ExerciseDatabaseService get instance {
    _instance ??= ExerciseDatabaseService._();
    return _instance!;
  }

  Future<List<PredefinedExercise>> getAllExercises() async {
    if (_exercises != null) {
      return _exercises!;
    }

    try {
      final String jsonString = await rootBundle.loadString('assets/data/exercises_database.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> exercisesJson = jsonData['exercises'];
      
      _exercises = exercisesJson
          .map((json) => PredefinedExercise.fromJson(json))
          .toList();
      
      return _exercises!;
    } catch (e) {
      throw Exception('Failed to load exercises database: $e');
    }
  }

  Future<List<PredefinedExercise>> searchExercises(String query) async {
    final exercises = await getAllExercises();
    final lowercaseQuery = query.toLowerCase();
    
    return exercises.where((exercise) {
      return exercise.name.toLowerCase().contains(lowercaseQuery) ||
             exercise.primaryMuscleGroup.toLowerCase().contains(lowercaseQuery) ||
             exercise.equipment.toLowerCase().contains(lowercaseQuery) ||
             exercise.secondaryMuscleGroups.any((muscle) => 
                 muscle.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  Future<List<PredefinedExercise>> getExercisesByMuscleGroup(String muscleGroup) async {
    final exercises = await getAllExercises();
    
    return exercises.where((exercise) {
      return exercise.primaryMuscleGroup.toLowerCase() == muscleGroup.toLowerCase() ||
             exercise.secondaryMuscleGroups.any((muscle) => 
                 muscle.toLowerCase() == muscleGroup.toLowerCase());
    }).toList();
  }

  Future<List<PredefinedExercise>> getExercisesByEquipment(String equipment) async {
    final exercises = await getAllExercises();
    
    return exercises.where((exercise) {
      return exercise.equipment.toLowerCase() == equipment.toLowerCase();
    }).toList();
  }

  Future<List<String>> getAllMuscleGroups() async {
    final exercises = await getAllExercises();
    final Set<String> muscleGroups = {};
    
    for (final exercise in exercises) {
      muscleGroups.add(exercise.primaryMuscleGroup);
      muscleGroups.addAll(exercise.secondaryMuscleGroups);
    }
    
    final List<String> sortedMuscleGroups = muscleGroups.toList()..sort();
    return sortedMuscleGroups;
  }

  Future<List<String>> getAllEquipment() async {
    final exercises = await getAllExercises();
    final Set<String> equipment = {};
    
    for (final exercise in exercises) {
      equipment.add(exercise.equipment);
    }
    
    final List<String> sortedEquipment = equipment.toList()..sort();
    return sortedEquipment;
  }
}