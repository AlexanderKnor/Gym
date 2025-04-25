// lib/providers/training_session_screen/training_session_provider.dart
import 'package:flutter/material.dart';
import 'dart:async';

import '../../models/training_plan_screen/training_plan_model.dart';
import '../../models/training_plan_screen/training_day_model.dart';
import '../../models/training_plan_screen/exercise_model.dart';
import '../../models/progression_manager_screen/training_set_model.dart';
import '../../models/progression_manager_screen/progression_profile_model.dart';
import '../../models/training_history/training_session_model.dart';
import '../../models/training_history/exercise_history_model.dart';
import '../../models/training_history/set_history_model.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../services/training_history/training_history_service.dart';

/// Provider für die Verwaltung einer aktiven Trainings-Session
class TrainingSessionProvider with ChangeNotifier {
  // Daten des aktiven Trainingsplans
  TrainingPlanModel? _trainingPlan;
  TrainingDayModel? _trainingDay;
  int _dayIndex = 0;

  // Tracking für aktuelle Übung und Sätze
  int _currentExerciseIndex = 0;
  Map<int, List<TrainingSetModel>> _exerciseSets = {};
  Map<int, int> _activeSetByExercise = {};
  Map<int, bool> _exerciseCompletionStatus = {};

  // Timer-Status
  bool _isResting = false;
  int _restTimeRemaining = 0;
  Timer? _restTimer;

  // Training-Status
  bool _isTrainingCompleted = false;
  bool _hasBeenSaved = false; // Flag zur Verhinderung mehrfacher Speicherungen

  // Aktuelle Trainingssession
  TrainingSessionModel? _currentSession;

  // Service für die Trainingshistorie
  final TrainingHistoryService _historyService = TrainingHistoryService();

  // Konstruktor
  TrainingSessionProvider() {
    // Beim Erstellen des Providers wird noch kein Training geladen
  }

  // Getter
  TrainingPlanModel? get trainingPlan => _trainingPlan;
  TrainingDayModel? get trainingDay => _trainingDay;
  int get dayIndex => _dayIndex;

  int get currentExerciseIndex => _currentExerciseIndex;
  ExerciseModel? get currentExercise => _trainingDay != null &&
          _currentExerciseIndex < _trainingDay!.exercises.length
      ? _trainingDay!.exercises[_currentExerciseIndex]
      : null;

  List<TrainingSetModel> get currentExerciseSets =>
      _exerciseSets[_currentExerciseIndex] ?? [];

  int get activeSetIndex => _activeSetByExercise[_currentExerciseIndex] ?? 0;

  bool get isCurrentExerciseCompleted =>
      _exerciseCompletionStatus[_currentExerciseIndex] ?? false;

  bool get isResting => _isResting;
  int get restTimeRemaining => _restTimeRemaining;

  bool get isTrainingCompleted => _isTrainingCompleted;

  List<ExerciseModel> get exercises => _trainingDay?.exercises ?? [];

  TrainingSessionModel? get currentSession => _currentSession;

  // Initialisiert eine neue Trainings-Session
  Future<void> startTrainingSession(
      TrainingPlanModel plan, int dayIndex) async {
    // Vollständiges Zurücksetzen sicherstellen
    _completeReset();

    // Setze die Trainingsplan-Daten
    _trainingPlan = plan;
    _dayIndex = dayIndex;

    if (dayIndex < plan.days.length) {
      _trainingDay = plan.days[dayIndex];

      // Erstelle eine neue Trainingssession
      _currentSession = TrainingSessionModel.create(
        plan.id,
        _trainingDay!.id,
        _trainingDay!.name,
      );

      // Initialisiere die Tracking-Daten für jede Übung
      for (int i = 0; i < _trainingDay!.exercises.length; i++) {
        final exercise = _trainingDay!.exercises[i];

        // Übungshistorie erstellen
        final exerciseHistory = ExerciseHistoryModel.fromExerciseModel(
          exercise.id,
          exercise.name,
          exercise.primaryMuscleGroup,
          exercise.secondaryMuscleGroup,
          exercise.standardIncrease,
          exercise.restPeriodSeconds,
          exercise.progressionProfileId,
        );

        // Zur Session hinzufügen
        _currentSession!.exercises.add(exerciseHistory);

        // Lade die letzten Trainingsdaten für diese Übung
        List<SetHistoryModel> lastSetData =
            await _historyService.getLastTrainingDataForExercise(exercise.id);

        // Erstelle die Sets für diese Übung
        List<TrainingSetModel> sets = List.generate(
          exercise.numberOfSets,
          (setIndex) {
            // Versuche, die Daten aus dem letzten Training zu verwenden
            double lastKg = 0;
            int lastReps = 0;
            int lastRir = 0;

            if (lastSetData.isNotEmpty && setIndex < lastSetData.length) {
              final lastSet = lastSetData[setIndex];
              lastKg = lastSet.kg;
              lastReps = lastSet.reps;
              lastRir = lastSet.rir;
            }

            return TrainingSetModel(
              id: setIndex + 1,
              kg: lastKg,
              wiederholungen: lastReps,
              rir: lastRir,
            );
          },
        );

        _exerciseSets[i] = sets;
        _activeSetByExercise[i] = 0;
        _exerciseCompletionStatus[i] = false;
      }

      // Setze den Training-Status
      _isTrainingCompleted = false;
      _hasBeenSaved = false;
    }

    notifyListeners();
  }

  // Vollständigere Reset-Methode
  void _completeReset() {
    _trainingPlan = null;
    _trainingDay = null;
    _dayIndex = 0;
    _currentExerciseIndex = 0;
    _exerciseSets = {};
    _activeSetByExercise = {};
    _exerciseCompletionStatus = {};
    _isResting = false;
    _restTimeRemaining = 0;
    _cancelRestTimer();
    _isTrainingCompleted = false;
    _currentSession = null;
    _hasBeenSaved = false;
  }

  // Setzt alle Trainings-Session-Daten zurück
  void _resetTrainingSession() {
    _completeReset();
  }

  // Wechselt zur nächsten Übung
  void moveToNextExercise() {
    if (_trainingDay == null) return;

    // Prüfe, ob es noch eine weitere Übung gibt
    if (_currentExerciseIndex < _trainingDay!.exercises.length - 1) {
      _currentExerciseIndex++;
      notifyListeners();
    } else {
      // Alle Übungen wurden abgeschlossen
      _isTrainingCompleted = true;

      // Markiere die Session als abgeschlossen
      if (_currentSession != null) {
        _currentSession = _currentSession!.copyWith(isCompleted: true);
      }

      notifyListeners();
    }
  }

  // Wechselt zu einer bestimmten Übung
  void selectExercise(int exerciseIndex) {
    if (_trainingDay == null) return;

    // Prüfe, ob der Index gültig ist
    if (exerciseIndex >= 0 && exerciseIndex < _trainingDay!.exercises.length) {
      _currentExerciseIndex = exerciseIndex;
      notifyListeners();
    }
  }

  // Aktualisiert die Daten eines bestimmten Satzes für die aktuelle Übung
  void updateSet(int setId, String field, dynamic value) {
    if (_trainingDay == null) return;

    final sets = _exerciseSets[_currentExerciseIndex];
    if (sets == null) return;

    final setIndex = setId - 1; // setId beginnt bei 1, Index bei 0
    if (setIndex < 0 || setIndex >= sets.length) return;

    final updatedSets = List<TrainingSetModel>.from(sets);
    final currentSet = updatedSets[setIndex];

    TrainingSetModel updatedSet;
    switch (field) {
      case 'kg':
        if (value is String && value.isEmpty) {
          // Leere Werte während der Bearbeitung zulassen
        } else {
          final newValue = double.tryParse(value.toString()) ?? currentSet.kg;
          updatedSet = currentSet.copyWith(kg: newValue);
          updatedSets[setIndex] = updatedSet;
          _exerciseSets[_currentExerciseIndex] = updatedSets;
        }
        break;
      case 'wiederholungen':
        if (value is String && value.isEmpty) {
          // Leere Werte während der Bearbeitung zulassen
        } else {
          final newValue =
              int.tryParse(value.toString()) ?? currentSet.wiederholungen;
          updatedSet = currentSet.copyWith(wiederholungen: newValue);
          updatedSets[setIndex] = updatedSet;
          _exerciseSets[_currentExerciseIndex] = updatedSets;
        }
        break;
      case 'rir':
        if (value is String && value.isEmpty) {
          // Leere Werte während der Bearbeitung zulassen
        } else {
          final newValue = int.tryParse(value.toString()) ?? currentSet.rir;
          updatedSet = currentSet.copyWith(rir: newValue);
          updatedSets[setIndex] = updatedSet;
          _exerciseSets[_currentExerciseIndex] = updatedSets;
        }
        break;
      default:
        return; // Ungültiges Feld, nichts tun
    }

    notifyListeners();
  }

  // Markiert den aktuellen Satz als abgeschlossen und bereitet den nächsten Satz vor
  Future<void> completeCurrentSet() async {
    if (_trainingDay == null || _currentSession == null) return;

    final exerciseIndex = _currentExerciseIndex;
    final setIndex = _activeSetByExercise[exerciseIndex] ?? 0;

    final sets = _exerciseSets[exerciseIndex];
    if (sets == null || setIndex >= sets.length) return;

    // Markiere den aktuellen Satz als abgeschlossen
    final updatedSets = List<TrainingSetModel>.from(sets);
    updatedSets[setIndex] = updatedSets[setIndex].copyWith(abgeschlossen: true);
    _exerciseSets[exerciseIndex] = updatedSets;

    // Aktuellen Satz zur Übungshistorie hinzufügen
    final exercise = _trainingDay!.exercises[exerciseIndex];
    final currentSet = updatedSets[setIndex];

    // Erstelle ein SetHistoryModel
    final setHistory = SetHistoryModel.fromTrainingSet(setIndex + 1,
        currentSet.kg, currentSet.wiederholungen, currentSet.rir, true);

    // Aktualisiere die Session im Speicher (nicht in der Datenbank!)
    final updatedExercises =
        List<ExerciseHistoryModel>.from(_currentSession!.exercises);
    if (exerciseIndex < updatedExercises.length) {
      final currentExerciseHistory = updatedExercises[exerciseIndex];
      final updatedSetsHistory =
          List<SetHistoryModel>.from(currentExerciseHistory.sets);

      // Überschreibe den Satz, wenn er bereits existiert, andernfalls füge ihn hinzu
      if (setIndex < updatedSetsHistory.length) {
        updatedSetsHistory[setIndex] = setHistory;
      } else {
        updatedSetsHistory.add(setHistory);
      }

      // Aktualisiere die Übungshistorie
      updatedExercises[exerciseIndex] = currentExerciseHistory.copyWith(
        sets: updatedSetsHistory,
      );
    }

    // Aktualisiere die Session im Speicher
    _currentSession = _currentSession!.copyWith(
      exercises: updatedExercises,
    );

    // Prüfe, ob noch weitere Sätze für diese Übung verfügbar sind
    if (setIndex < sets.length - 1) {
      // Es gibt noch weitere Sätze, aktiviere den nächsten Satz
      _activeSetByExercise[exerciseIndex] = setIndex + 1;

      // Starte den Ruhe-Timer für die aktuelle Übung
      startRestTimer();
    } else {
      // Alle Sätze für diese Übung sind abgeschlossen
      _exerciseCompletionStatus[exerciseIndex] = true;

      // Aktualisiere die Übungshistorie als abgeschlossen
      final updatedExercises =
          List<ExerciseHistoryModel>.from(_currentSession!.exercises);
      updatedExercises[exerciseIndex] =
          updatedExercises[exerciseIndex].copyWith(
        isCompleted: true,
      );

      _currentSession = _currentSession!.copyWith(
        exercises: updatedExercises,
      );

      // Warte kurz und wechsle dann zur nächsten Übung
      Future.delayed(const Duration(seconds: 1), () {
        moveToNextExercise();
      });
    }

    notifyListeners();
  }

  // Startet den Ruhe-Timer für den aktuellen Satz
  void startRestTimer() {
    if (_trainingDay == null || currentExercise == null) return;

    // Setze den Timer auf die für die Übung konfigurierte Ruhezeit
    _restTimeRemaining = currentExercise!.restPeriodSeconds;
    _isResting = true;

    _cancelRestTimer(); // Sicherheitshalber vorherigen Timer abbrechen

    // Starte einen neuen Timer
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restTimeRemaining > 0) {
        _restTimeRemaining--;
        notifyListeners();
      } else {
        // Timer ist abgelaufen
        _isResting = false;
        _cancelRestTimer();
        notifyListeners();
      }
    });

    notifyListeners();
  }

  // Bricht den Ruhe-Timer ab
  void skipRestTimer() {
    _isResting = false;
    _restTimeRemaining = 0;
    _cancelRestTimer();
    notifyListeners();
  }

  // Hilfsmethode zum Abbrechen des Timers
  void _cancelRestTimer() {
    _restTimer?.cancel();
    _restTimer = null;
  }

  // Schließt das gesamte Training ab und speichert es nur dann in die Datenbank!
  Future<void> completeTraining() async {
    // Prüfen, ob das Training schon gespeichert wurde
    if (_hasBeenSaved) {
      return; // Verhindert mehrfaches Speichern
    }

    _isTrainingCompleted = true;
    _cancelRestTimer();

    // Aktualisiere die Session als abgeschlossen
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        isCompleted: true,
      );

      // Jetzt erst die Session in die Datenbank speichern!
      await _historyService.saveTrainingSession(_currentSession!);

      // Setze den Flag, dass gespeichert wurde
      _hasBeenSaved = true;
    }

    notifyListeners();
  }

  // Berechnet die Progression für einen Satz einmalig und speichert sie
  void calculateProgressionForSet(int exerciseIndex, int setId,
      String profileId, ProgressionManagerProvider progressionProvider) {
    final sets = _exerciseSets[exerciseIndex];
    if (sets == null) return;

    final setIndex = setId - 1;
    if (setIndex < 0 || setIndex >= sets.length) return;

    final set = sets[setIndex];

    // Nur berechnen, wenn noch nicht berechnet wurde
    if (!set.empfehlungBerechnet) {
      // Standard-Steigerungswert holen
      final exercise = _trainingDay?.exercises[exerciseIndex];
      final customIncrement = exercise?.standardIncrease ?? 2.5;

      // Empfehlung berechnen mit der angepassten Methode
      final empfehlung = progressionProvider.berechneEmpfehlungMitProfil(
          set, profileId, sets,
          customIncrement: customIncrement);

      // Empfehlung im Set speichern
      final updatedSets = List<TrainingSetModel>.from(sets);
      updatedSets[setIndex] = set.copyWith(
        empfKg: empfehlung['kg'],
        empfWiederholungen: empfehlung['wiederholungen'],
        empfRir: empfehlung['rir'],
        empfehlungBerechnet: true,
      );

      _exerciseSets[exerciseIndex] = updatedSets;
      notifyListeners();
    }
  }

  // Prüft, ob Empfehlungen angezeigt werden sollen
  bool shouldShowRecommendation(int exerciseIndex, int setId) {
    final sets = _exerciseSets[exerciseIndex];
    if (sets == null) return false;

    final setIndex = setId - 1;
    if (setIndex < 0 || setIndex >= sets.length) return false;

    final set = sets[setIndex];

    // Keine Empfehlung anzeigen, wenn der Satz nicht aktiv ist
    final isActiveSet = setId == getActiveSetIdForCurrentExercise() &&
        exerciseIndex == _currentExerciseIndex &&
        !_isTrainingCompleted;
    if (!isActiveSet) return false;

    // Keine Empfehlung anzeigen, wenn keine berechnet wurde
    if (!set.empfehlungBerechnet) return false;

    // Keine Empfehlung anzeigen, wenn alle empfohlenen Werte 0 oder null sind
    if ((set.empfKg == null || set.empfKg == 0) &&
        (set.empfWiederholungen == null || set.empfWiederholungen == 0) &&
        (set.empfRir == null || set.empfRir == 0)) {
      return false;
    }

    // Keine Empfehlung anzeigen, wenn alle Werte exakt der Empfehlung entsprechen
    if (set.kg == set.empfKg &&
        set.wiederholungen == set.empfWiederholungen &&
        set.rir == set.empfRir) {
      return false;
    }

    // Ansonsten Empfehlung anzeigen
    return true;
  }

  // Bereitet die Progression Manager Integration vor
  List<TrainingSetModel> getProgressionSetsForCurrentExercise() {
    return _exerciseSets[_currentExerciseIndex] ?? [];
  }

  int getActiveSetIdForCurrentExercise() {
    final activeSetIndex = _activeSetByExercise[_currentExerciseIndex] ?? 0;
    // Die Set-ID beginnt bei 1, während der Index bei 0 beginnt
    return activeSetIndex + 1;
  }

  // Übernimmt Empfehlungen vom Progression Manager
  void applyProgressionRecommendation(
      int setId, double? kg, int? wiederholungen, int? rir) {
    final sets = _exerciseSets[_currentExerciseIndex];
    if (sets == null) return;

    final setIndex = setId - 1; // setId beginnt bei 1, Index bei 0
    if (setIndex < 0 || setIndex >= sets.length) return;

    final updatedSets = List<TrainingSetModel>.from(sets);
    final currentSet = updatedSets[setIndex];

    updatedSets[setIndex] = currentSet.copyWith(
      kg: kg ?? currentSet.kg,
      wiederholungen: wiederholungen ?? currentSet.wiederholungen,
      rir: rir ?? currentSet.rir,
    );

    _exerciseSets[_currentExerciseIndex] = updatedSets;

    notifyListeners();
  }

  /// Wendet benutzerdefinierte Werte vom Kraftrechner auf einen bestimmten Satz an
  void applyCustomValues(
    int exerciseIndex,
    int setId,
    double weight,
    int reps,
    int rir,
  ) {
    try {
      final sets = _exerciseSets[exerciseIndex];
      if (sets == null) return;

      final setIndex = setId - 1; // setId beginnt bei 1, Index bei 0
      if (setIndex < 0 || setIndex >= sets.length) return;

      // Aktualisiere die Werte des Sets
      final updatedSets = List<TrainingSetModel>.from(sets);
      final currentSet = updatedSets[setIndex];

      updatedSets[setIndex] = currentSet.copyWith(
        kg: weight,
        wiederholungen: reps,
        rir: rir,
      );

      _exerciseSets[exerciseIndex] = updatedSets;

      notifyListeners();
    } catch (e) {
      print('Fehler beim Anwenden der Kraftrechner-Werte: $e');
    }
  }

  // Getter für die standardIncrease des aktuellen Exercises
  double get currentExerciseStandardIncrease {
    return currentExercise?.standardIncrease ?? 2.5;
  }

  // Getter für den Fortschritt des Trainings
  double get trainingProgress {
    if (_trainingDay == null || _trainingDay!.exercises.isEmpty) return 0.0;

    // Berechne den Gesamtfortschritt basierend auf abgeschlossenen Übungen
    double totalCompletedExercises = 0.0;

    for (int i = 0; i < _trainingDay!.exercises.length; i++) {
      if (_exerciseCompletionStatus[i] == true) {
        totalCompletedExercises += 1.0; // Eine vollständig abgeschlossene Übung
      } else {
        // Bei der aktuellen Übung, füge den Fortschritt der Sätze hinzu
        if (i == _currentExerciseIndex) {
          final sets = _exerciseSets[i] ?? [];
          if (sets.isNotEmpty) {
            int completedSets = sets.where((set) => set.abgeschlossen).length;
            totalCompletedExercises +=
                completedSets / sets.length; // Partieller Fortschritt
          }
        }
      }
    }

    return totalCompletedExercises / _trainingDay!.exercises.length;
  }

  @override
  void dispose() {
    _cancelRestTimer();
    super.dispose();
  }
}
