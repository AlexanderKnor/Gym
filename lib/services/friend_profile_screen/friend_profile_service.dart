// lib/services/friend_profile_screen/friend_profile_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/training_plan_screen/training_plan_model.dart';
import '../../models/training_plan_screen/training_day_model.dart';
import '../../models/training_plan_screen/exercise_model.dart';
import '../../models/progression_manager_screen/progression_profile_model.dart';
import '../../models/progression_manager_screen/progression_rule_model.dart';
import '../../services/progression_manager_screen/firestore_profile_service.dart';
import '../../services/training_plan_screen/training_plan_service.dart';

class FriendProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreProfileService _profileService = FirestoreProfileService();
  final TrainingPlanService _trainingPlanService = TrainingPlanService();

  // Aktueller Benutzer-ID
  String? _getUserId() {
    return _auth.currentUser?.uid;
  }

  // Prüft, ob eine Freundschaft zu einem Benutzer besteht
  Future<bool> isFriendWith(String friendId) async {
    try {
      final userId = _getUserId();
      if (userId == null) return false;

      final friendshipId = 'friendship_${userId}_$friendId';
      final friendshipDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('friends')
          .doc(friendshipId)
          .get();

      return friendshipDoc.exists;
    } catch (e) {
      print('Fehler beim Prüfen der Freundschaft: $e');
      return false;
    }
  }

  // Trainingspläne eines Freundes laden - KORRIGIERTE VERSION
  Future<List<TrainingPlanModel>> getTrainingPlansFromFriend(
      String friendId) async {
    try {
      final userId = _getUserId();
      if (userId == null) throw Exception('Nicht angemeldet');

      // Prüfen, ob eine Freundschaft besteht
      if (!await isFriendWith(friendId)) {
        throw Exception('Keine Freundschaft mit diesem Benutzer');
      }

      // Trainingspläne des Freundes abrufen
      final trainingPlansSnapshot = await _firestore
          .collection('users')
          .doc(friendId)
          .collection('training_plans')
          .get();

      final List<TrainingPlanModel> trainingPlans = [];

      for (var doc in trainingPlansSnapshot.docs) {
        try {
          final planData = doc.data();

          print('Lade Trainingsplan: ${doc.id}, Name: ${planData['name']}');

          // Hier ist der Unterschied: wir extrahieren die Tage direkt aus den Plandaten
          final List<dynamic> daysData = planData['days'] ?? [];
          print('Anzahl der Tage im Plan: ${daysData.length}');

          List<TrainingDayModel> days = [];

          for (var dayData in daysData) {
            // Wir extrahieren die Übungen direkt aus den Tagdaten
            final List<dynamic> exercisesData = dayData['exercises'] ?? [];
            print(
                'Tag ${dayData['name']}: ${exercisesData.length} Übungen gefunden');

            List<ExerciseModel> exercises = [];

            for (var exerciseData in exercisesData) {
              print(
                  'Übung gefunden: ${exerciseData['name']}, ProgressionProfileId: ${exerciseData['progressionProfileId']}');

              exercises.add(ExerciseModel(
                id: exerciseData['id'] ?? '',
                name: exerciseData['name'] ?? 'Unbekannte Übung',
                primaryMuscleGroup: exerciseData['primaryMuscleGroup'] ?? '',
                secondaryMuscleGroup:
                    exerciseData['secondaryMuscleGroup'] ?? '',
                standardIncrease:
                    exerciseData['standardIncrease']?.toDouble() ?? 2.5,
                restPeriodSeconds: exerciseData['restPeriodSeconds'] ?? 90,
                numberOfSets: exerciseData['numberOfSets'] ?? 3,
                progressionProfileId: exerciseData['progressionProfileId'],
              ));
            }

            days.add(TrainingDayModel(
              id: dayData['id'] ?? '',
              name: dayData['name'] ?? 'Tag',
              exercises: exercises,
            ));
          }

          trainingPlans.add(TrainingPlanModel(
            id: doc.id,
            name: planData['name'] ?? 'Unbenannter Plan',
            days: days,
            isActive: planData['isActive'] ?? false,
          ));

          print(
              'Trainingsplan komplett geladen: ${doc.id} mit ${days.length} Tagen');
        } catch (e) {
          print('Fehler beim Laden eines Trainingsplans: $e');
        }
      }

      return trainingPlans;
    } catch (e) {
      print('Fehler beim Laden der Trainingspläne des Freundes: $e');
      return [];
    }
  }

  // Progressionsprofile eines Freundes laden
  Future<List<ProgressionProfileModel>> getProgressionProfilesFromFriend(
      String friendId) async {
    try {
      final userId = _getUserId();
      if (userId == null) throw Exception('Nicht angemeldet');

      // Prüfen, ob eine Freundschaft besteht
      if (!await isFriendWith(friendId)) {
        throw Exception('Keine Freundschaft mit diesem Benutzer');
      }

      // Progressionsprofile des Freundes abrufen
      final profilesSnapshot = await _firestore
          .collection('users')
          .doc(friendId)
          .collection('profiles')
          .get();

      final List<ProgressionProfileModel> profiles = [];

      for (var doc in profilesSnapshot.docs) {
        try {
          final profileData = doc.data();
          profiles
              .add(FirestoreProfileService.decodeProfileFromJson(profileData));
        } catch (e) {
          print('Fehler beim Dekodieren eines Profils: $e');
        }
      }

      return profiles;
    } catch (e) {
      print('Fehler beim Laden der Progressionsprofile des Freundes: $e');
      return [];
    }
  }

  // Aktives Progressionsprofil eines Freundes abrufen
  Future<String> getActiveProfileFromFriend(String friendId) async {
    try {
      final userId = _getUserId();
      if (userId == null) throw Exception('Nicht angemeldet');

      // Prüfen, ob eine Freundschaft besteht
      if (!await isFriendWith(friendId)) {
        throw Exception('Keine Freundschaft mit diesem Benutzer');
      }

      final userDoc = await _firestore.collection('users').doc(friendId).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('activeProfileId')) {
          return data['activeProfileId'] as String;
        }
      }

      return '';
    } catch (e) {
      print('Fehler beim Laden des aktiven Profils des Freundes: $e');
      return '';
    }
  }

  // Aktiven Trainingsplan eines Freundes abrufen
  Future<String> getActiveTrainingPlanFromFriend(String friendId) async {
    try {
      final userId = _getUserId();
      if (userId == null) throw Exception('Nicht angemeldet');

      // Prüfen, ob eine Freundschaft besteht
      if (!await isFriendWith(friendId)) {
        throw Exception('Keine Freundschaft mit diesem Benutzer');
      }

      // Suche nach dem aktiven Trainingsplan
      final plansSnapshot = await _firestore
          .collection('users')
          .doc(friendId)
          .collection('training_plans')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (plansSnapshot.docs.isNotEmpty) {
        return plansSnapshot.docs.first.id;
      }

      return '';
    } catch (e) {
      print('Fehler beim Laden des aktiven Trainingsplans des Freundes: $e');
      return '';
    }
  }

  // Progressionsprofil eines Freundes kopieren
  Future<bool> copyProgressionProfile(ProgressionProfileModel profile) async {
    try {
      final userId = _getUserId();
      if (userId == null) throw Exception('Nicht angemeldet');

      // Prüfen, ob das Profil bereits existiert
      final existingProfile = await _firestore
          .collection('users')
          .doc(userId)
          .collection('profiles')
          .doc(profile.id)
          .get();

      // Neue ID für das kopierte Profil generieren
      final String newProfileId;
      if (existingProfile.exists) {
        // Wenn bereits ein Profil mit dieser ID existiert, generiere eine neue ID
        newProfileId = 'profile_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        // Sonst verwende die originale ID, damit Verknüpfungen in Trainingsplänen funktionieren
        newProfileId = profile.id;
      }

      // Kopie des Profils mit neuer ID erstellen
      final copiedProfile = ProgressionProfileModel(
        id: newProfileId,
        name: '${profile.name} (Kopie)',
        description: profile.description,
        config: Map<String, dynamic>.from(profile.config),
        rules: List.from(profile.rules),
      );

      // Profil in der eigenen Sammlung speichern
      await _profileService.saveProfileToFirestore(copiedProfile);

      print('Progressionsprofil erfolgreich kopiert: $newProfileId');
      return true;
    } catch (e) {
      print('Fehler beim Kopieren des Progressionsprofils: $e');
      return false;
    }
  }

  // Prüfen, welche Profile in einem Trainingsplan verwendet werden
  Set<String> getRequiredProfileIds(TrainingPlanModel plan) {
    final Set<String> profileIds = {};

    for (var day in plan.days) {
      for (var exercise in day.exercises) {
        if (exercise.progressionProfileId != null &&
            exercise.progressionProfileId!.isNotEmpty) {
          profileIds.add(exercise.progressionProfileId!);
        }
      }
    }

    return profileIds;
  }

  // Fehlende Profile ermitteln
  Future<Set<String>> getMissingProfileIds(
      Set<String> requiredProfileIds) async {
    try {
      final userId = _getUserId();
      if (userId == null) throw Exception('Nicht angemeldet');

      final Set<String> missingProfileIds = Set.from(requiredProfileIds);

      // Eigene Profile laden
      final ownProfiles = await _profileService.loadProfiles();

      // Vorhandene Profile aus der Liste der fehlenden entfernen
      for (var profile in ownProfiles) {
        missingProfileIds.remove(profile.id);
      }

      return missingProfileIds;
    } catch (e) {
      print('Fehler beim Ermitteln fehlender Profile: $e');
      return Set.from(requiredProfileIds);
    }
  }

  // Trainingsplan eines Freundes kopieren - AKTUALISIERT
  Future<Map<String, dynamic>> copyTrainingPlan(TrainingPlanModel plan,
      List<ProgressionProfileModel> friendProfiles) async {
    try {
      final userId = _getUserId();
      if (userId == null) throw Exception('Nicht angemeldet');

      // Verwendete Progressionsprofile ermitteln
      final requiredProfileIds = getRequiredProfileIds(plan);

      // Prüfen, welche Profile fehlen
      final missingProfileIds = await getMissingProfileIds(requiredProfileIds);

      // Neue ID für den kopierten Plan generieren - Sicherstellen, dass sie wirklich eindeutig ist
      final newPlanId =
          'plan_${DateTime.now().millisecondsSinceEpoch}_${userId.hashCode}';

      // Deep Copy des Plans erstellen
      final copiedPlan = TrainingPlanModel(
        id: newPlanId,
        name: '${plan.name} (Kopie)',
        days: plan.days.map((day) {
          // Neue ID für jeden Tag generieren
          final newDayId =
              'day_${DateTime.now().millisecondsSinceEpoch}_${day.id.hashCode}';

          return TrainingDayModel(
            id: newDayId,
            name: day.name,
            exercises: day.exercises.map((exercise) {
              // Neue ID für jede Übung generieren
              final newExerciseId =
                  'exercise_${DateTime.now().millisecondsSinceEpoch}_${exercise.id.hashCode}';

              return ExerciseModel(
                id: newExerciseId,
                name: exercise.name,
                primaryMuscleGroup: exercise.primaryMuscleGroup,
                secondaryMuscleGroup: exercise.secondaryMuscleGroup,
                standardIncrease: exercise.standardIncrease,
                restPeriodSeconds: exercise.restPeriodSeconds,
                numberOfSets: exercise.numberOfSets,
                progressionProfileId: exercise.progressionProfileId,
              );
            }).toList(),
          );
        }).toList(),
        isActive: false, // Kopierter Plan ist standardmäßig nicht aktiv
      );

      // Plan in der eigenen Sammlung speichern (neue Methode nutzen)
      final success =
          await _trainingPlanService.addSingleTrainingPlan(copiedPlan);

      if (!success) {
        throw Exception('Fehler beim Speichern des kopierten Plans');
      }

      print('Trainingsplan erfolgreich kopiert: $newPlanId');

      // Rückgabe mit Information über den kopierten Plan und fehlende Profile
      return {
        'success': true,
        'planId': newPlanId,
        'missingProfileIds': missingProfileIds.toList(),
        'plan': copiedPlan,
      };
    } catch (e) {
      print('Fehler beim Kopieren des Trainingsplans: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Spezifische Profile kopieren
  Future<List<String>> copySpecificProfiles(List<String> profileIds,
      List<ProgressionProfileModel> friendProfiles) async {
    final List<String> copiedProfileIds = [];

    try {
      if (profileIds.isEmpty) {
        return copiedProfileIds;
      }

      // Mehrere Profile parallel kopieren, um den Vorgang zu beschleunigen
      final futures = <Future<bool>>[];

      // Für jede Profil-ID das entsprechende Profil finden und kopieren
      for (var profileId in profileIds) {
        try {
          final profileToCopy = friendProfiles.firstWhere(
            (p) => p.id == profileId,
            orElse: () => throw Exception('Profil nicht gefunden: $profileId'),
          );

          // Kopieren in die Future-Liste hinzufügen
          futures.add(copyProgressionProfile(profileToCopy).then((success) {
            if (success) {
              copiedProfileIds.add(profileId);
            }
            return success;
          }));
        } catch (e) {
          print('Fehler beim Vorbereiten des Profils $profileId: $e');
        }
      }

      // Auf alle Kopiervorgänge warten
      await Future.wait(futures);

      return copiedProfileIds;
    } catch (e) {
      print('Fehler beim Kopieren spezifischer Profile: $e');
      return copiedProfileIds;
    }
  }
}
