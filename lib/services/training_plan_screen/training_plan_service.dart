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

  // Neu: Methode zum Hinzufügen eines einzelnen neuen Trainingsplans
  Future<bool> addSingleTrainingPlan(TrainingPlanModel plan) async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print('Kein User angemeldet, kann Trainingsplan nicht speichern');
        return false;
      }

      print('Speichere neuen Plan: ${plan.id} - ${plan.name}');

      // Prüfen, ob bereits ein Plan mit dieser ID existiert
      final existingDoc =
          await _getTrainingPlansCollection().doc(plan.id).get();

      if (existingDoc.exists) {
        print('Plan mit ID ${plan.id} existiert bereits, generiere neue ID');
        // Neue eindeutige ID generieren
        final newId =
            'plan_${DateTime.now().millisecondsSinceEpoch}_${plan.id.hashCode}';
        // Neuen Plan mit neuer ID erstellen
        final updatedPlan = plan.copyWith(id: newId);
        // JSON für den aktualisierten Plan erhalten
        final updatedJson = _encodePlanToJson(updatedPlan);
        // Plan mit der neuen ID speichern
        await _getTrainingPlansCollection().doc(newId).set(updatedJson);
        print('Plan mit neuer ID $newId erfolgreich gespeichert');
      } else {
        // Der Plan existiert noch nicht, speichere ihn mit der ursprünglichen ID
        final planJson = _encodePlanToJson(plan);
        await _getTrainingPlansCollection().doc(plan.id).set(planJson);
        print('Plan ${plan.id} erfolgreich gespeichert');
      }

      return true;
    } catch (e) {
      print('Fehler beim Speichern des Plans: $e');
      return false;
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

  // NEU: Trainingstag löschen
  Future<bool> deleteTrainingDay(String dayId) async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print('Kein User angemeldet, kann Trainingstag nicht löschen');
        return false;
      }

      print('Lösche Trainingstag mit ID: $dayId aus Trainingshistorie...');

      // Lösche den Trainingstag aus der Trainingshistorie
      await _historyService.cleanupTrainingDayFromSessions(dayId);

      print('Trainingstag $dayId erfolgreich aus Trainingshistorie bereinigt');
      return true;
    } catch (e) {
      print('Fehler beim Löschen des Trainingstags aus Firestore: $e');
      return false;
    }
  }

  // VERBESSERTE METHODE: Aktualisiert alle Übungen nach Löschen eines Progressionsprofils
  Future<bool> updateExercisesAfterProfileDeletion(String profileId) async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print('Kein User angemeldet, kann Übungen nicht aktualisieren');
        return false;
      }

      print('Aktualisiere Übungen nach Löschung des Profils: $profileId');

      // Alle Trainingspläne laden
      final plans = await loadTrainingPlans();
      print('${plans.length} Trainingspläne gefunden zum Durchsuchen');

      bool anyUpdated = false;
      int totalUpdatedExercises = 0;

      // Für jeden Plan...
      for (var plan in plans) {
        print('Überprüfe Plan: ${plan.name} (${plan.id})');
        bool planUpdated = false;
        final updatedDays = <TrainingDayModel>[];

        // Jede Tagesübung durchgehen...
        for (var day in plan.days) {
          print(
              'Überprüfe Tag: ${day.name} mit ${day.exercises.length} Übungen');
          final updatedExercises = <ExerciseModel>[];

          for (var exercise in day.exercises) {
            // WICHTIG: Ausführlichere Protokollierung
            print(
                'Übung ${exercise.name} (${exercise.id}) - ProfileId: ${exercise.progressionProfileId}');

            // Prüfen, ob die Übung das gelöschte Profil verwendet
            if (exercise.progressionProfileId == profileId) {
              // Kopie der Übung mit Profil-ID auf null setzen
              updatedExercises
                  .add(exercise.copyWith(progressionProfileId: null));
              planUpdated = true;
              totalUpdatedExercises++;
              print(
                  '⚠️ Aktualisiere Übung ${exercise.name} (${exercise.id}): Profil entfernt');
            } else {
              // Übung unverändert übernehmen
              updatedExercises.add(exercise);
            }
          }

          // Neuen Tag mit aktualisierten Übungen erstellen
          updatedDays.add(day.copyWith(exercises: updatedExercises));
        }

        // Wenn Übungen im Plan aktualisiert wurden, Plan speichern
        if (planUpdated) {
          final updatedPlan = plan.copyWith(days: updatedDays);

          try {
            // WICHTIG: Neuer Code - Pläne immer einzeln speichern
            final planJson = _encodePlanToJson(updatedPlan);
            await _getTrainingPlansCollection().doc(plan.id).set(planJson);

            anyUpdated = true;
            print('✅ Plan ${plan.name} (${plan.id}) aktualisiert in Firestore');
          } catch (e) {
            print('❌ Fehler beim Speichern des Plans: $e');
            return false; // Bei Fehler sofort abbrechen
          }
        }
      }

      if (anyUpdated) {
        print(
            '✅ Alle Übungen erfolgreich aktualisiert: $totalUpdatedExercises Übungen');
      } else {
        print('ℹ️ Keine Übungen gefunden, die das gelöschte Profil verwenden');
      }

      return true;
    } catch (e) {
      print('❌ Fehler beim Aktualisieren der Übungen nach Profilöschung: $e');
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
