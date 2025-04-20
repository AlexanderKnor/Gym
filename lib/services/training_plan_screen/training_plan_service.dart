// lib/services/training_plan_screen/training_plan_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/training_plan_screen/training_plan_model.dart';
import '../../models/training_plan_screen/training_day_model.dart';
import '../../models/training_plan_screen/exercise_model.dart';
import '../training_history/training_history_service.dart';

class TrainingPlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TrainingHistoryService _historyService = TrainingHistoryService();

  // Hilfsmethoden
  String? _getUserId() {
    return _auth.currentUser?.uid;
  }

  CollectionReference _getTrainingPlansCollection() {
    final userId = _getUserId();
    if (userId == null) throw Exception('Benutzer ist nicht angemeldet');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('training_plans');
  }

  // TrainingsplãÂ¤ne laden
  Future<List<TrainingPlanModel>> loadTrainingPlans() async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        // Wenn nicht angemeldet, leere Liste zurückgeben
        print('Kein Benutzer angemeldet, kann keine Trainingspläne laden');
        return [];
      }

      final snapshot = await _getTrainingPlansCollection().get();
      final List<TrainingPlanModel> plans = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          plans.add(_decodePlanFromJson(data));
        } catch (e) {
          print('Fehler beim Dekodieren des Plans: $e');
        }
      }

      return plans;
    } catch (e) {
      print('Fehler beim Laden der Trainingspläne aus Firestore: $e');
      return [];
    }
  }

  // Trainingsplan speichern
  Future<bool> saveTrainingPlans(List<TrainingPlanModel> plans) async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print('Kein User angemeldet, kann Trainingspläne nicht speichern');
        return false;
      }

      print('Beginne das Speichern von ${plans.length} Trainingsplänen...');

      try {
        // Jeden Plan einzeln speichern statt als Batch
        for (final plan in plans) {
          print('Speichere Plan: ${plan.id} - ${plan.name}');
          final planJson = _encodePlanToJson(plan);
          await _getTrainingPlansCollection().doc(plan.id).set(planJson);
          print('Plan ${plan.id} erfolgreich gespeichert');
        }

        print('Alle Pläne gespeichert');
        return true;
      } catch (firestoreError) {
        print('Fehler bei der Firestore-Operation: $firestoreError');
        return false;
      }
    } catch (e) {
      print('Allgemeiner Fehler beim Speichern der Trainingspläne: $e');
      return false;
    }
  }

  // Trainingsplan aus Firestore löschen
  Future<bool> deletePlan(String planId) async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print('Kein User angemeldet, kann Plan nicht löschen');
        return false;
      }

      print('Lösche Plan mit ID: $planId aus Firestore...');

      // 1. Zuerst zugehörige Trainingshistorie löschen
      print('Lösche zugehörige Trainingshistorie...');
      await _historyService.deleteSessionsByPlanId(planId);

      // 2. Dann Dokument in Firestore löschen
      await _getTrainingPlansCollection().doc(planId).delete();
      print('Plan $planId erfolgreich aus Firestore gelöscht');

      return true;
    } catch (e) {
      print('Fehler beim Löschen des Plans aus Firestore: $e');
      return false;
    }
  }

  // Übung aus Firestore löschen (neue Methode)
  Future<bool> deleteExercise(String exerciseId) async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print('Kein User angemeldet, kann Übung nicht löschen');
        return false;
      }

      print('Lösche Übung mit ID: $exerciseId aus Trainingshistorie...');

      // Lösche die Übung aus der Trainingshistorie
      await _historyService.cleanupExerciseFromSessions(exerciseId);

      print('Übung $exerciseId erfolgreich aus Trainingshistorie bereinigt');
      return true;
    } catch (e) {
      print('Fehler beim Löschen der Übung aus Firestore: $e');
      return false;
    }
  }

  // JSON-Konvertierungsmethoden
  Map<String, dynamic> _encodePlanToJson(TrainingPlanModel plan) {
    return {
      'id': plan.id,
      'name': plan.name,
      'isActive': plan.isActive,
      'days': plan.days
          .map((day) => {
                'id': day.id,
                'name': day.name,
                'exercises': day.exercises
                    .map((exercise) => {
                          'id': exercise.id,
                          'name': exercise.name,
                          'primaryMuscleGroup': exercise.primaryMuscleGroup,
                          'secondaryMuscleGroup': exercise.secondaryMuscleGroup,
                          'standardIncrease': exercise.standardIncrease,
                          'restPeriodSeconds': exercise.restPeriodSeconds,
                          'numberOfSets': exercise.numberOfSets,
                          'progressionProfileId': exercise.progressionProfileId,
                        })
                    .toList(),
              })
          .toList(),
    };
  }

  TrainingPlanModel _decodePlanFromJson(Map<String, dynamic> json) {
    final List<dynamic> daysJson = json['days'] ?? [];

    final days = daysJson.map((dayJson) {
      final List<dynamic> exercisesJson = dayJson['exercises'] ?? [];

      final exercises = exercisesJson.map((exerciseJson) {
        return ExerciseModel(
          id: exerciseJson['id'],
          name: exerciseJson['name'],
          primaryMuscleGroup: exerciseJson['primaryMuscleGroup'],
          secondaryMuscleGroup: exerciseJson['secondaryMuscleGroup'],
          standardIncrease: exerciseJson['standardIncrease'].toDouble(),
          restPeriodSeconds: exerciseJson['restPeriodSeconds'],
          numberOfSets: exerciseJson['numberOfSets'] ?? 3,
          progressionProfileId: exerciseJson['progressionProfileId'],
        );
      }).toList();

      return TrainingDayModel(
        id: dayJson['id'],
        name: dayJson['name'],
        exercises: exercises,
      );
    }).toList();

    return TrainingPlanModel(
      id: json['id'],
      name: json['name'],
      days: days,
      isActive: json['isActive'] ?? false,
    );
  }
}
