// lib/services/training_plan_screen/training_plan_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/training_plan_screen/training_plan_model.dart';
import '../../models/training_plan_screen/training_day_model.dart';
import '../../models/training_plan_screen/exercise_model.dart';
import '../training_history/training_history_service.dart'; // Importiere TrainingHistoryService

class TrainingPlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TrainingHistoryService _historyService =
      TrainingHistoryService(); // Neue Instanz

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
        // Wenn nicht angemeldet, aus lokalem Speicher laden
        return await _loadFromLocalStorage();
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
      print('Fehler beim Laden der TrainingsplãÂ¤ne aus Firestore: $e');
      // Fallback auf lokalen Speicher
      return await _loadFromLocalStorage();
    }
  }

  // TrainingsplãÂ¤ne speichern
  Future<bool> saveTrainingPlans(List<TrainingPlanModel> plans) async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        // Wenn nicht angemeldet, im lokalen Speicher speichern
        print('Kein User angemeldet, speichere lokal');
        return await _saveToLocalStorage(plans);
      }

      print('Beginne das Speichern von ${plans.length} TrainingsplãÂ¤nen...');

      try {
        // Jeden Plan einzeln speichern statt als Batch
        for (final plan in plans) {
          print('Speichere Plan: ${plan.id} - ${plan.name}');
          final planJson = _encodePlanToJson(plan);
          await _getTrainingPlansCollection().doc(plan.id).set(planJson);
          print('Plan ${plan.id} erfolgreich gespeichert');
        }

        print('Alle PlãÂ¤ne gespeichert, speichere jetzt lokal als Backup');
        // Auch im lokalen Speicher als Backup speichern
        await _saveToLocalStorage(plans);

        return true;
      } catch (firestoreError) {
        print('Fehler bei der Firestore-Operation: $firestoreError');
        // Bei Firestore-Fehler trotzdem versuchen, lokal zu speichern
        return await _saveToLocalStorage(plans);
      }
    } catch (e) {
      print('Allgemeiner Fehler beim Speichern der TrainingsplãÂ¤ne: $e');
      // Fallback auf lokalen Speicher
      return await _saveToLocalStorage(plans);
    }
  }

  // Trainingsplan aus Firestore löschen - AKTUALISIERT
  Future<bool> deletePlan(String planId) async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        // Wenn nicht angemeldet, kann nur lokal gelöscht werden
        print('Kein User angemeldet, lösche nur lokal');
        // Wir geben true zurück, da die lokale Löschung im Provider erfolgt
        return true;
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
        // Wenn nicht angemeldet, kann nur lokal gelöscht werden
        print('Kein User angemeldet, lösche nur lokal');
        return true;
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

  // Methoden fãÂ¼r lokalen Speicher
  Future<List<TrainingPlanModel>> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plansJson = prefs.getString('training_plans');

      if (plansJson == null || plansJson.isEmpty) {
        return [];
      }

      final List<dynamic> decodedPlans = jsonDecode(plansJson);
      return decodedPlans
          .map((planJson) =>
              _decodePlanFromJson(Map<String, dynamic>.from(planJson)))
          .toList();
    } catch (e) {
      print(
          'Fehler beim Laden der TrainingsplãÂ¤ne aus dem lokalen Speicher: $e');
      return [];
    }
  }

  Future<bool> _saveToLocalStorage(List<TrainingPlanModel> plans) async {
    try {
      print('Speichere ${plans.length} PlãÂ¤ne im lokalen Speicher');
      final prefs = await SharedPreferences.getInstance();
      final plansJson =
          jsonEncode(plans.map((p) => _encodePlanToJson(p)).toList());

      await prefs.setString('training_plans', plansJson);
      print('PlãÂ¤ne erfolgreich im lokalen Speicher gespeichert');
      return true;
    } catch (e) {
      print(
          'Fehler beim Speichern der TrainingsplãÂ¤ne im lokalen Speicher: $e');
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
                          'numberOfSets':
                              exercise.numberOfSets, // Neues Feld hinzugefügt
                          'progressionProfileId':
                              exercise.progressionProfileId, // Neu hinzugefügt
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
          numberOfSets:
              exerciseJson['numberOfSets'] ?? 3, // Neues Feld mit Standardwert
          progressionProfileId:
              exerciseJson['progressionProfileId'], // Neu hinzugefügt
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
