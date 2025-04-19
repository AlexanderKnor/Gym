// lib/services/training_history/training_history_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/training_history/training_session_model.dart';
import '../../models/training_history/exercise_history_model.dart';
import '../../models/training_history/set_history_model.dart';

class TrainingHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Hilfsmethode zum Abrufen der Benutzer-ID
  String? _getUserId() {
    return _auth.currentUser?.uid;
  }

  // Referenz zur Trainingshistorie-Sammlung eines Benutzers
  CollectionReference _getTrainingHistoryCollection() {
    final userId = _getUserId();
    if (userId == null) throw Exception('Benutzer ist nicht angemeldet');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('training_history');
  }

  // Eine Trainingssession speichern
  Future<bool> saveTrainingSession(TrainingSessionModel session) async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print(
            'Kann Trainingssession nicht speichern, Benutzer nicht angemeldet');
        return false;
      }

      await _getTrainingHistoryCollection()
          .doc(session.id)
          .set(session.toMap());

      print('Trainingssession erfolgreich gespeichert: ${session.id}');
      return true;
    } catch (e) {
      print('Fehler beim Speichern der Trainingssession: $e');
      return false;
    }
  }

  // Alle Trainingssessions eines Benutzers abrufen
  Future<List<TrainingSessionModel>> getTrainingSessions() async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print(
            'Kann Trainingssessions nicht abrufen, Benutzer nicht angemeldet');
        return [];
      }

      final snapshot = await _getTrainingHistoryCollection()
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              TrainingSessionModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Fehler beim Abrufen der Trainingssessions: $e');
      return [];
    }
  }

  // Letzte Trainingsdaten für eine bestimmte Übung abrufen
  Future<List<SetHistoryModel>> getLastTrainingDataForExercise(
      String exerciseId) async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print(
            'Kann letzte Trainingsdaten nicht abrufen, Benutzer nicht angemeldet');
        return [];
      }

      // Finde die neueste Session, die diese Übung enthält
      final querySnapshot = await _getTrainingHistoryCollection()
          .orderBy('date', descending: true)
          .limit(10) // Beschränke auf die letzten 10 Sessions für Performance
          .get();

      // Iteriere durch die Sessions und suche die letzte mit dieser Übung
      for (var doc in querySnapshot.docs) {
        final session =
            TrainingSessionModel.fromMap(doc.data() as Map<String, dynamic>);

        // Suche die Übung in dieser Session
        final matchingExercise = session.exercises.firstWhere(
          (exercise) => exercise.exerciseId == exerciseId,
          orElse: () => ExerciseHistoryModel(
            id: '',
            exerciseId: '',
            name: '',
            primaryMuscleGroup: '',
            secondaryMuscleGroup: '',
            standardIncrease: 0,
            restPeriodSeconds: 0,
            sets: [],
          ),
        );

        // Wenn die Übung gefunden wurde und abgeschlossene Sätze hat
        if (matchingExercise.id.isNotEmpty &&
            matchingExercise.sets.isNotEmpty) {
          return matchingExercise.sets;
        }
      }

      return []; // Keine Daten gefunden
    } catch (e) {
      print('Fehler beim Abrufen der letzten Trainingsdaten: $e');
      return [];
    }
  }

  // Eine bestehende Trainingssession aktualisieren
  Future<bool> updateTrainingSession(TrainingSessionModel session) async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print(
            'Kann Trainingssession nicht aktualisieren, Benutzer nicht angemeldet');
        return false;
      }

      await _getTrainingHistoryCollection()
          .doc(session.id)
          .update(session.toMap());

      print('Trainingssession erfolgreich aktualisiert: ${session.id}');
      return true;
    } catch (e) {
      print('Fehler beim Aktualisieren der Trainingssession: $e');
      return false;
    }
  }
}
