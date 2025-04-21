import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/training_plan_screen/training_plan_model.dart';
import '../../models/training_plan_screen/training_day_model.dart';
import '../../models/training_plan_screen/exercise_model.dart';
import '../../models/progression_manager_screen/progression_profile_model.dart';
import '../../models/progression_manager_screen/progression_rule_model.dart';
import '../../services/progression_manager_screen/firestore_profile_service.dart';

class FriendProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  // Trainingspläne eines Freundes laden
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

          // Trainingstage laden
          final daysSnapshot = await _firestore
              .collection('users')
              .doc(friendId)
              .collection('training_plans')
              .doc(doc.id)
              .collection('days')
              .get();

          List<TrainingDayModel> days = [];

          for (var dayDoc in daysSnapshot.docs) {
            final dayData = dayDoc.data();

            // Übungen laden
            final exercisesSnapshot = await _firestore
                .collection('users')
                .doc(friendId)
                .collection('training_plans')
                .doc(doc.id)
                .collection('days')
                .doc(dayDoc.id)
                .collection('exercises')
                .get();

            List<ExerciseModel> exercises = [];

            for (var exerciseDoc in exercisesSnapshot.docs) {
              final exerciseData = exerciseDoc.data();

              exercises.add(ExerciseModel(
                id: exerciseDoc.id,
                name: exerciseData['name'] ?? 'Unbekannte Übung',
                primaryMuscleGroup: exerciseData['primaryMuscleGroup'] ?? '',
                secondaryMuscleGroup:
                    exerciseData['secondaryMuscleGroup'] ?? '',
                standardIncrease: exerciseData['standardIncrease'] ?? 2.5,
                restPeriodSeconds: exerciseData['restPeriodSeconds'] ?? 90,
                numberOfSets: exerciseData['numberOfSets'] ?? 3,
                progressionProfileId: exerciseData['progressionProfileId'],
              ));
            }

            days.add(TrainingDayModel(
              id: dayDoc.id,
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
}
