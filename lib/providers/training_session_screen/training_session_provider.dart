// lib/providers/training_session_screen/training_session_provider.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart'; // Für Vibrationsfeedback

import '../../models/training_plan_screen/training_plan_model.dart';
import '../../models/training_plan_screen/training_day_model.dart';
import '../../models/training_plan_screen/exercise_model.dart';
import '../../models/training_plan_screen/periodization_model.dart';
import '../../models/progression_manager_screen/training_set_model.dart';
import '../../models/progression_manager_screen/progression_profile_model.dart';
import '../../models/training_history/training_session_model.dart';
import '../../models/training_history/exercise_history_model.dart';
import '../../models/training_history/set_history_model.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../services/training_history/training_history_service.dart';
import '../../services/training_plan_screen/training_plan_service.dart';

/// Provider für die Verwaltung einer aktiven Trainings-Session
class TrainingSessionProvider with ChangeNotifier {
  // Daten des aktiven Trainingsplans
  TrainingPlanModel? _trainingPlan;
  TrainingDayModel? _trainingDay;
  int _dayIndex = 0;
  int _weekIndex = 0; // NEU: Variable für den aktuellen Mikrozyklus

  // Tracking für aktuelle Übung und Sätze
  int _currentExerciseIndex = 0;
  Map<int, List<TrainingSetModel>> _exerciseSets = {};
  Map<int, int> _activeSetByExercise = {};
  Map<int, bool> _exerciseCompletionStatus = {};
  Map<int, int> _lastCompletedSetIndexByExercise =
      {}; // Map für zuletzt abgeschlossene Sätze

  // Timer-Status
  bool _isResting = false;
  int _restTimeRemaining = 0;
  Timer? _restTimer;
  bool _isPaused = false; // Flag für Timer-Pause

  // Training-Status
  bool _isTrainingCompleted = false;
  bool _hasBeenSaved = false; // Flag zur Verhinderung mehrfacher Speicherungen

  // Aktuelle Trainingssession
  TrainingSessionModel? _currentSession;

  // Service für die Trainingshistorie
  final TrainingHistoryService _historyService = TrainingHistoryService();

  // Tracking für Übungsänderungen
  final Map<int, ExerciseModel> _originalExercises =
      {}; // Speichert Original-Konfigurationen
  final Map<int, bool> _exerciseConfigModified =
      {}; // Markiert geänderte Übungen

  // Service für das Updaten des Trainingsplans
  final TrainingPlanService _trainingPlanService = TrainingPlanService();

  // Tracking für hinzugefügte Übungen
  final List<ExerciseModel> _addedExercises = [];
  bool get hasAddedExercises => _addedExercises.isNotEmpty;

  // Liste für gelöschte Übungen
  final List<ExerciseModel> _deletedExercises = [];
  bool get hasDeletedExercises => _deletedExercises.isNotEmpty;

  // Flag für Debug-Logging
  final bool _debugMode = true;

  // Variablen zum Verhindern von wiederholten Updates
  bool _isUpdatingExerciseConfig = false;
  bool _isProcessingConfig = false;

  // Konstruktor
  TrainingSessionProvider() {
    // Beim Erstellen des Providers wird noch kein Training geladen
  }

  // Getter
  TrainingPlanModel? get trainingPlan => _trainingPlan;
  TrainingDayModel? get trainingDay => _trainingDay;
  int get dayIndex => _dayIndex;
  int get weekIndex => _weekIndex; // NEU: Getter für den Mikrozyklus-Index

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
  bool get isPaused => _isPaused;

  bool get isTrainingCompleted => _isTrainingCompleted;

  List<ExerciseModel> get exercises => _trainingDay?.exercises ?? [];

  // Getter für Übungsänderungen
  bool get hasModifiedExercises =>
      _exerciseConfigModified.values.any((modified) => modified);

  TrainingSessionModel? get currentSession => _currentSession;

  // Debug-Logging Methode
  void _log(String message) {
    if (_debugMode) {
      print('TrainingSessionProvider: $message');
    }
  }

  // Initialisiert eine neue Trainings-Session mit optionalem Mikrozyklus-Index
  Future<void> startTrainingSession(TrainingPlanModel plan, int dayIndex,
      [int weekIndex = 0]) async {
    // Vollständiges Zurücksetzen sicherstellen
    _completeReset();

    // Setze die Trainingsplan-Daten
    _trainingPlan = plan;
    _dayIndex = dayIndex;
    _weekIndex = weekIndex; // NEU: Mikrozyklus-Index speichern

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

        // NEU: Wenn der Plan periodisiert ist, prüfe auf Mikrozyklus-spezifische Konfiguration
        ExerciseModel adjustedExercise = exercise;
        if (plan.isPeriodized && plan.periodization != null) {
          final config =
              plan.getExerciseMicrocycle(exercise.id, dayIndex, weekIndex);
          if (config != null) {
            // Erstelle eine angepasste Version der Übung mit den Werten aus dem Mikrozyklus
            adjustedExercise = exercise.copyWith(
              numberOfSets: config.numberOfSets,
              progressionProfileId: config.progressionProfileId,
            );
          }
        }

        // Originalkonfiguration speichern (angepasst für Mikrozyklus)
        _originalExercises[i] = adjustedExercise;
        _exerciseConfigModified[i] = false;

        _log(
            'Originalübung gespeichert: ${adjustedExercise.name} (${adjustedExercise.id}) - Pause: ${adjustedExercise.restPeriodSeconds} sek, Steigerung: ${adjustedExercise.standardIncrease} kg');

        // Übungshistorie erstellen
        final exerciseHistory = ExerciseHistoryModel.fromExerciseModel(
          adjustedExercise.id,
          adjustedExercise.name,
          adjustedExercise.primaryMuscleGroup,
          adjustedExercise.secondaryMuscleGroup,
          adjustedExercise.standardIncrease,
          adjustedExercise.restPeriodSeconds,
          adjustedExercise.progressionProfileId,
        );

        // Zur Session hinzufügen
        _currentSession!.exercises.add(exerciseHistory);

        // Lade die letzten Trainingsdaten für diese Übung
        List<SetHistoryModel> lastSetData = await _historyService
            .getLastTrainingDataForExercise(adjustedExercise.id);

        // Erstelle die Sets für diese Übung - mit Anzahl aus dem Mikrozyklus
        List<TrainingSetModel> sets = List.generate(
          adjustedExercise.numberOfSets,
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
    _weekIndex = 0; // NEU: Mikrozyklus-Index zurücksetzen
    _currentExerciseIndex = 0;
    _exerciseSets = {};
    _activeSetByExercise = {};
    _exerciseCompletionStatus = {};
    _lastCompletedSetIndexByExercise = {};
    _isResting = false;
    _restTimeRemaining = 0;
    _isPaused = false;
    _cancelRestTimer();
    _isTrainingCompleted = false;
    _currentSession = null;
    _hasBeenSaved = false;
    _isUpdatingExerciseConfig = false;
    _isProcessingConfig = false;
    _addedExercises.clear();
    _deletedExercises.clear();
    _originalExercises.clear();
    _exerciseConfigModified.clear();
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
          // Verbesserte Wertebehandlung für double
          double? newValue;
          if (value is double) {
            newValue = value;
          } else {
            newValue = double.tryParse(value.toString());
          }

          if (newValue != null) {
            _log('Aktualisiere Gewicht: von ${currentSet.kg} zu $newValue');
            updatedSet = currentSet.copyWith(kg: newValue);
            updatedSets[setIndex] = updatedSet;
            _exerciseSets[_currentExerciseIndex] = updatedSets;
          }
        }
        break;

      case 'wiederholungen':
        if (value is String && value.isEmpty) {
          // Leere Werte während der Bearbeitung zulassen
        } else {
          // Verbesserte Wertebehandlung für int
          int? newValue;
          if (value is int) {
            newValue = value;
          } else {
            newValue = int.tryParse(value.toString());
          }

          if (newValue != null) {
            _log(
                'Aktualisiere Wiederholungen: von ${currentSet.wiederholungen} zu $newValue');
            updatedSet = currentSet.copyWith(wiederholungen: newValue);
            updatedSets[setIndex] = updatedSet;
            _exerciseSets[_currentExerciseIndex] = updatedSets;
          }
        }
        break;

      case 'rir':
        if (value is String && value.isEmpty) {
          // Leere Werte während der Bearbeitung zulassen
        } else {
          // Verbesserte Wertebehandlung für int
          int? newValue;
          if (value is int) {
            newValue = value;
          } else {
            newValue = int.tryParse(value.toString());
          }

          if (newValue != null) {
            _log('Aktualisiere RIR: von ${currentSet.rir} zu $newValue');
            updatedSet = currentSet.copyWith(rir: newValue);
            updatedSets[setIndex] = updatedSet;
            _exerciseSets[_currentExerciseIndex] = updatedSets;
          }
        }
        break;

      default:
        return; // Ungültiges Feld, nichts tun
    }

    notifyListeners();
  }

  // Reaktiviert den letzten abgeschlossenen Satz einer Übung
  void reactivateLastCompletedSet(int exerciseIndex) {
    if (_trainingDay == null || _currentSession == null) return;

    final sets = _exerciseSets[exerciseIndex];
    if (sets == null || sets.isEmpty) return;

    // Finde den letzten abgeschlossenen Satz
    int lastCompletedSetIndex = -1;
    for (int i = sets.length - 1; i >= 0; i--) {
      if (sets[i].abgeschlossen) {
        lastCompletedSetIndex = i;
        break;
      }
    }

    // Wenn kein abgeschlossener Satz gefunden wurde, nichts tun
    if (lastCompletedSetIndex == -1) return;

    // Setze den letzten abgeschlossenen Satz zurück auf aktiv
    final updatedSets = List<TrainingSetModel>.from(sets);
    updatedSets[lastCompletedSetIndex] =
        updatedSets[lastCompletedSetIndex].copyWith(abgeschlossen: false);
    _exerciseSets[exerciseIndex] = updatedSets;

    // Setze den aktiven Satz auf den reaktivierten Satz
    _activeSetByExercise[exerciseIndex] = lastCompletedSetIndex;

    // Prüfe, ob noch abgeschlossene Sätze vorhanden sind
    bool stillHasCompletedSets = false;
    for (final set in updatedSets) {
      if (set.abgeschlossen) {
        stillHasCompletedSets = true;
        break;
      }
    }

    // Setze den Übungs-Abschluss-Status zurück, wenn keine abgeschlossenen Sätze mehr vorhanden sind
    if (!stillHasCompletedSets) {
      _exerciseCompletionStatus[exerciseIndex] = false;
    }

    // Aktualisiere die Session im Speicher (nicht in der Datenbank!)
    final updatedExercises =
        List<ExerciseHistoryModel>.from(_currentSession!.exercises);
    if (exerciseIndex < updatedExercises.length) {
      final currentExerciseHistory = updatedExercises[exerciseIndex];
      final updatedSetsHistory =
          List<SetHistoryModel>.from(currentExerciseHistory.sets);

      // Entferne den letzten Satz, wenn er bereits existiert
      if (lastCompletedSetIndex < updatedSetsHistory.length) {
        updatedSetsHistory.removeAt(lastCompletedSetIndex);
      }

      // Aktualisiere die Übungshistorie
      updatedExercises[exerciseIndex] = currentExerciseHistory.copyWith(
        sets: updatedSetsHistory,
        isCompleted: stillHasCompletedSets,
      );
    }

    // Aktualisiere die Session im Speicher
    _currentSession = _currentSession!.copyWith(
      exercises: updatedExercises,
    );

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

    // Speichere den zuletzt abgeschlossenen Satz
    _lastCompletedSetIndexByExercise[exerciseIndex] = setIndex;

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

      // WICHTIG: Setze den aktiven Satz auf einen ungültigen Wert, um zu signalisieren, dass kein Satz mehr aktiv ist
      _activeSetByExercise[exerciseIndex] = -1;

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
    }

    notifyListeners();
  }

  // Findet den Index der nächsten offenen Übung (nicht abgeschlossen)
  int findNextOpenExerciseIndex() {
    if (_trainingDay == null) return 0;

    // Sammle alle nicht abgeschlossenen Übungen außer der aktuellen
    List<int> openExercisesIndices = [];
    for (int i = 0; i < _trainingDay!.exercises.length; i++) {
      if (_exerciseCompletionStatus[i] != true && i != _currentExerciseIndex) {
        openExercisesIndices.add(i);
      }
    }

    // Wenn keine offenen Übungen gefunden wurden, aktuellen Index zurückgeben
    if (openExercisesIndices.isEmpty) {
      return _currentExerciseIndex;
    }

    // Priorisiere die Trainingsreihenfolge:
    // 1. Wenn es offene Übungen vor der aktuellen gibt, nimm die erste davon
    List<int> previousOpenExercises =
        openExercisesIndices.where((i) => i < _currentExerciseIndex).toList();
    if (previousOpenExercises.isNotEmpty) {
      // Sortiere in aufsteigender Reihenfolge und nimm die erste offene Übung
      previousOpenExercises.sort();
      return previousOpenExercises.first;
    }

    // 2. Ansonsten nimm die erste offene Übung nach der aktuellen
    List<int> nextOpenExercises =
        openExercisesIndices.where((i) => i > _currentExerciseIndex).toList();
    if (nextOpenExercises.isNotEmpty) {
      // Sortiere in aufsteigender Reihenfolge und nimm die erste
      nextOpenExercises.sort();
      return nextOpenExercises.first;
    }

    // Sollte nie erreicht werden, da wir bereits überprüft haben, ob openExercisesIndices leer ist
    return _currentExerciseIndex;
  }

  // Schließt die aktuelle Übung ab und wechselt zur nächsten oder beendet das Training
  void completeCurrentExercise() {
    if (_trainingDay == null) return;

    // Setze den Übungsstatus als abgeschlossen
    _exerciseCompletionStatus[_currentExerciseIndex] = true;

    // Aktualisiere die Session im Speicher
    if (_currentSession != null) {
      final updatedExercises =
          List<ExerciseHistoryModel>.from(_currentSession!.exercises);
      if (_currentExerciseIndex < updatedExercises.length) {
        updatedExercises[_currentExerciseIndex] =
            updatedExercises[_currentExerciseIndex].copyWith(
          isCompleted: true,
        );

        _currentSession = _currentSession!.copyWith(
          exercises: updatedExercises,
        );
      }
    }

    // Finde die nächste offene Übung
    int nextOpenExerciseIndex = findNextOpenExerciseIndex();

    // Prüfe, ob es noch offene Übungen gibt
    bool allExercisesCompleted = _trainingDay!.exercises.length ==
        _exerciseCompletionStatus.values.where((completed) => completed).length;

    if (allExercisesCompleted) {
      // Alle Übungen sind abgeschlossen, beende das Training
      _isTrainingCompleted = true;

      if (_currentSession != null) {
        _currentSession = _currentSession!.copyWith(isCompleted: true);
      }
    } else {
      // Es gibt noch offene Übungen, wechsle zur nächsten
      _currentExerciseIndex = nextOpenExerciseIndex;
    }

    notifyListeners();
  }

  // Methode zur Prüfung, ob eine bestimmte Übung abgeschlossen ist
  bool isExerciseCompleted(int exerciseIndex) {
    if (exerciseIndex < 0 ||
        _trainingDay == null ||
        exerciseIndex >= _trainingDay!.exercises.length) {
      return false;
    }

    return _exerciseCompletionStatus[exerciseIndex] ?? false;
  }

  // Getter, der ein Map mit allen Übungs-Completion-Status zurückgibt (für das UI)
  Map<int, bool> get exerciseCompletionStatuses {
    return Map<int, bool>.from(_exerciseCompletionStatus);
  }

  // Startet den Ruhe-Timer für den aktuellen Satz
  void startRestTimer() {
    if (_trainingDay == null || currentExercise == null) return;

    // Verwende die aktualisierte Pausenzeit aus dem aktuellen Übungsmodell
    _restTimeRemaining = currentExercise!.restPeriodSeconds;
    _log('Starte Ruhe-Timer mit ${_restTimeRemaining} Sekunden');

    _isResting = true;
    _isPaused = false;

    _cancelRestTimer(); // Sicherheitshalber vorherigen Timer abbrechen

    // Starte einen neuen Timer
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restTimeRemaining > 0) {
        _restTimeRemaining--;

        // Vibrieren, wenn nur noch 3 Sekunden übrig sind
        if (_restTimeRemaining <= 3 && _restTimeRemaining > 0) {
          try {
            HapticFeedback.mediumImpact();
          } catch (e) {
            // Ignoriere Fehler bei Haptic Feedback
          }
        }

        notifyListeners();
      } else {
        // Timer ist abgelaufen
        _isResting = false;
        _cancelRestTimer();

        // Starke Vibration, wenn der Timer abgelaufen ist
        try {
          HapticFeedback.heavyImpact();
        } catch (e) {
          // Ignoriere Fehler bei Haptic Feedback
        }

        notifyListeners();
      }
    });

    notifyListeners();
  }

  // Pausiert oder setzt den Timer fort
  void toggleRestTimer() {
    if (_isResting) {
      if (_isPaused) {
        // Timer fortsetzen
        _isPaused = false;

        // Neuen Timer starten
        _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_restTimeRemaining > 0) {
            _restTimeRemaining--;

            // Vibrieren, wenn nur noch 3 Sekunden übrig sind
            if (_restTimeRemaining <= 3 && _restTimeRemaining > 0) {
              try {
                HapticFeedback.mediumImpact();
              } catch (e) {
                // Ignoriere Fehler bei Haptic Feedback
              }
            }

            notifyListeners();
          } else {
            // Timer ist abgelaufen
            _isResting = false;
            _isPaused = false;
            _cancelRestTimer();

            // Starke Vibration, wenn der Timer abgelaufen ist
            try {
              HapticFeedback.heavyImpact();
            } catch (e) {
              // Ignoriere Fehler bei Haptic Feedback
            }

            notifyListeners();
          }
        });
      } else {
        // Timer pausieren
        _isPaused = true;
        _cancelRestTimer();
      }

      notifyListeners();
    }
  }

  // Bricht den Ruhe-Timer ab
  void skipRestTimer() {
    _isResting = false;
    _isPaused = false;
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

      _log('Speichere Trainingssession in der Datenbank...');

      try {
        // Jetzt erst die Session in die Datenbank speichern!
        await _historyService.saveTrainingSession(_currentSession!);
        _log('Training erfolgreich in der Datenbank gespeichert.');

        // Setze den Flag, dass gespeichert wurde
        _hasBeenSaved = true;
      } catch (e) {
        _log('Fehler beim Speichern des Trainings: $e');
      }
    }

    notifyListeners();
  }

  // Berechnet die Progression für einen Satz und speichert sie
  Future<void> calculateProgressionForSet(int exerciseIndex, int setId,
      String profileId, ProgressionManagerProvider progressionProvider,
      {bool forceRecalculation = false}) async {
    final sets = _exerciseSets[exerciseIndex];
    if (sets == null) return;

    final setIndex = setId - 1;
    if (setIndex < 0 || setIndex >= sets.length) return;

    final set = sets[setIndex];

    // Nur berechnen, wenn noch nicht berechnet wurde oder eine Neuberechnung erzwungen wird
    if (!set.empfehlungBerechnet || forceRecalculation) {
      try {
        // Standard-Steigerungswert holen
        final exercise = _trainingDay?.exercises[exerciseIndex];
        if (exercise == null) return;

        final customIncrement = exercise.standardIncrease;

        // WICHTIG: Die historischen Trainingsdaten für diese Übung abrufen
        // statt die aktuellen Werte im Set zu verwenden
        List<SetHistoryModel> lastSetData =
            await _historyService.getLastTrainingDataForExercise(exercise.id);

        // Wenn keine historischen Daten verfügbar sind, können wir keine Empfehlung berechnen
        if (lastSetData.isEmpty) {
          _log(
              'Keine historischen Trainingsdaten für Übung ${exercise.id} gefunden');
          return;
        }

        // Erstelle ein temporäres Set-Objekt aus den historischen Daten
        // und verwende es für die Berechnung anstelle des aktuellen Sets
        TrainingSetModel historicalSet;

        // Finde den historischen Satz mit dem entsprechenden Index, falls verfügbar
        if (setIndex < lastSetData.length) {
          final lastSet = lastSetData[setIndex];
          historicalSet = TrainingSetModel(
              id: set.id,
              kg: lastSet.kg,
              wiederholungen: lastSet.reps,
              rir: lastSet.rir,
              abgeschlossen: false);
        } else {
          // Falls kein entsprechender Satz vorhanden ist, verwende den letzten verfügbaren
          final lastSet = lastSetData.last;
          historicalSet = TrainingSetModel(
              id: set.id,
              kg: lastSet.kg,
              wiederholungen: lastSet.reps,
              rir: lastSet.rir,
              abgeschlossen: false);
        }

        _log(
            'Berechne Progression auf Basis historischer Daten: ${historicalSet.kg}kg, ${historicalSet.wiederholungen} Wdh, ${historicalSet.rir} RIR');

        // Erstelle eine Liste von historischen Sets für die Berechnung
        List<TrainingSetModel> historicalSets = [];
        for (var histSet in lastSetData) {
          historicalSets.add(TrainingSetModel(
              id: histSet.setNumber,
              kg: histSet.kg,
              wiederholungen: histSet.reps,
              rir: histSet.rir,
              abgeschlossen: histSet.completed));
        }

        // Empfehlung berechnen mit den historischen Werten
        final empfehlung = progressionProvider.berechneEmpfehlungMitProfil(
            historicalSet, profileId, historicalSets,
            customIncrement: customIncrement);

        // Empfehlung im aktuellen Set speichern
        final updatedSets = List<TrainingSetModel>.from(sets);
        updatedSets[setIndex] = set.copyWith(
          empfKg: empfehlung['kg'],
          empfWiederholungen: empfehlung['wiederholungen'],
          empfRir: empfehlung['rir'],
          empfehlungBerechnet: true,
        );

        _exerciseSets[exerciseIndex] = updatedSets;
        notifyListeners();

        _log(
            'Progression berechnet: ${empfehlung['kg']}kg, ${empfehlung['wiederholungen']} Wdh, ${empfehlung['rir']} RIR');
      } catch (e) {
        _log('Fehler bei der Berechnung der Progression: $e');
      }
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

    // BUGFIX: Sicherstellen, dass exakte Werte (auch Dezimalwerte) direkt übernommen werden
    _log(
        'Übernehme Empfehlung: kg=${kg}, wiederholungen=${wiederholungen}, rir=${rir}');

    updatedSets[setIndex] = currentSet.copyWith(
      kg: kg ?? currentSet.kg,
      wiederholungen: wiederholungen ?? currentSet.wiederholungen,
      rir: rir ?? currentSet.rir,
    );

    _exerciseSets[_currentExerciseIndex] = updatedSets;

    // Sofort aktualisieren
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

  // Neue Methode: Progressionsprofil einer Übung während der Trainingseinheit aktualisieren
  void updateExerciseProgressionProfile(
      int exerciseIndex, String newProfileId) {
    try {
      if (_trainingDay == null || _currentSession == null) return;

      if (exerciseIndex < 0 || exerciseIndex >= _trainingDay!.exercises.length)
        return;

      // Aktualisiere das Profil in der aktuellen Session (ExerciseHistoryModel)
      final updatedExercises =
          List<ExerciseHistoryModel>.from(_currentSession!.exercises);
      if (exerciseIndex < updatedExercises.length) {
        updatedExercises[exerciseIndex] =
            updatedExercises[exerciseIndex].copyWith(
          progressionProfileId: newProfileId,
        );

        _currentSession = _currentSession!.copyWith(
          exercises: updatedExercises,
        );
      }

      // Wenn die aktive Übung betroffen ist, setze die Empfehlungen zurück
      if (exerciseIndex == _currentExerciseIndex) {
        final activeSetIndex = _activeSetByExercise[exerciseIndex] ?? 0;
        final sets = _exerciseSets[exerciseIndex];

        if (sets != null && activeSetIndex < sets.length) {
          final updatedSets = List<TrainingSetModel>.from(sets);
          // Setze die Empfehlung für den aktiven Satz zurück
          updatedSets[activeSetIndex] = updatedSets[activeSetIndex].copyWith(
            empfehlungBerechnet: false,
            empfKg: null,
            empfWiederholungen: null,
            empfRir: null,
          );

          _exerciseSets[exerciseIndex] = updatedSets;
        }
      }

      notifyListeners();
    } catch (e) {
      print('Fehler beim Aktualisieren des Progressionsprofils: $e');
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

  // Prüft, ob alle Sätze der aktuellen Übung abgeschlossen sind
  bool areAllSetsCompletedForCurrentExercise() {
    final sets = _exerciseSets[_currentExerciseIndex];
    if (sets == null || sets.isEmpty) return false;

    return sets.every((set) => set.abgeschlossen);
  }

  // Prüft, ob es noch weitere Übungen nach der aktuellen gibt
  bool hasMoreExercisesAfterCurrent() {
    if (_trainingDay == null) return false;
    return _currentExerciseIndex < _trainingDay!.exercises.length - 1;
  }

  // ÜBERARBEITETE Methode zur Aktualisierung der Übungskonfiguration
  void updateExerciseConfig(int exerciseIndex, String field, dynamic value) {
    // Guard clauses to prevent redundant updates or recursion
    if (_isUpdatingExerciseConfig || _isProcessingConfig) return;
    if (_trainingDay == null || _trainingPlan == null) return;
    if (exerciseIndex < 0 || exerciseIndex >= _trainingDay!.exercises.length)
      return;

    _isUpdatingExerciseConfig = true;

    try {
      _log(
          'Anfrage zur Aktualisierung von $field für Übung $exerciseIndex mit Wert $value');

      // Get the current exercise
      final currentExercise = _trainingDay!.exercises[exerciseIndex];

      // Parse and validate the new value
      dynamic newValue;

      if (field == 'standardIncrease') {
        newValue = double.tryParse(value.toString());
        if (newValue == null || newValue <= 0) {
          _isUpdatingExerciseConfig = false;
          return;
        }
        _log(
            'Ändere Standardsteigerung für Übung $exerciseIndex von ${currentExercise.standardIncrease} auf $newValue');
      } else if (field == 'restPeriodSeconds') {
        newValue = int.tryParse(value.toString());
        if (newValue == null || newValue <= 0) {
          _isUpdatingExerciseConfig = false;
          return;
        }
        _log(
            'Ändere Pausenzeit für Übung $exerciseIndex von ${currentExercise.restPeriodSeconds} auf $newValue');
      } else {
        // Invalid field
        _isUpdatingExerciseConfig = false;
        return;
      }

      // Create a new updated exercise with the new value
      ExerciseModel updatedExercise;
      if (field == 'standardIncrease') {
        updatedExercise = currentExercise.copyWith(
          standardIncrease: newValue,
        );
      } else {
        // restPeriodSeconds
        updatedExercise = currentExercise.copyWith(
          restPeriodSeconds: newValue,
        );
      }

      // Create safe copies of all the objects to avoid state inconsistencies
      final updatedExercises =
          List<ExerciseModel>.from(_trainingDay!.exercises);
      updatedExercises[exerciseIndex] = updatedExercise;

      final updatedDay = _trainingDay!.copyWith(
        exercises: updatedExercises,
      );

      final updatedDays = List<TrainingDayModel>.from(_trainingPlan!.days);
      updatedDays[_dayIndex] = updatedDay;

      final updatedPlan = _trainingPlan!.copyWith(
        days: updatedDays,
      );

      // Update provider state in a single step
      _trainingPlan = updatedPlan;
      _trainingDay = updatedDay;

      // Mark exercise as modified
      _exerciseConfigModified[exerciseIndex] = true;

      // Update timer if the rest period is changed and timer is active
      if (field == 'restPeriodSeconds' &&
          _isResting &&
          exerciseIndex == _currentExerciseIndex) {
        // Update timer if the current rest time is greater than the new value
        if (_restTimeRemaining > newValue) {
          _log(
              'Aktualisiere aktiven Timer von $_restTimeRemaining auf $newValue');
          _restTimeRemaining = newValue;
        }
      }

      // Also update the history model
      _updateExerciseHistory(exerciseIndex, field, newValue);

      // Delay the notification to avoid rebuilds during processing
      Future.microtask(() {
        _isUpdatingExerciseConfig = false;
        notifyListeners();
      });
    } catch (e) {
      _log('Fehler beim Aktualisieren der Übungskonfiguration: $e');
      _isUpdatingExerciseConfig = false;
    }
  }

  // Helper method to update exercise history
  void _updateExerciseHistory(int exerciseIndex, String field, dynamic value) {
    if (_currentSession == null ||
        exerciseIndex >= _currentSession!.exercises.length) return;

    try {
      // Get current exercise history
      final updatedSessionExercises =
          List<ExerciseHistoryModel>.from(_currentSession!.exercises);
      final currentExerciseHistory = updatedSessionExercises[exerciseIndex];

      // Create updated copy
      ExerciseHistoryModel updatedExerciseHistory;

      if (field == 'standardIncrease') {
        updatedExerciseHistory = currentExerciseHistory.copyWith(
          standardIncrease: value,
        );
      } else {
        // restPeriodSeconds
        updatedExerciseHistory = currentExerciseHistory.copyWith(
          restPeriodSeconds: value,
        );
      }

      // Replace in the session
      updatedSessionExercises[exerciseIndex] = updatedExerciseHistory;

      // Update the session
      _currentSession = _currentSession!.copyWith(
        exercises: updatedSessionExercises,
      );
    } catch (e) {
      _log('Fehler beim Aktualisieren der Übungshistorie: $e');
    }
  }

  // NEU: Fügt einen Satz zur aktuellen Übung hinzu
  void addSetToCurrentExercise() {
    if (_trainingDay == null ||
        _currentExerciseIndex < 0 ||
        _currentExerciseIndex >= _trainingDay!.exercises.length) {
      return;
    }

    // Guard against concurrent modifications
    if (_isProcessingConfig) return;
    _isProcessingConfig = true;

    try {
      // Get the current exercise and create a safe copy
      final exercise = _trainingDay!.exercises[_currentExerciseIndex];
      final updatedExercise = exercise.copyWith(
        numberOfSets: exercise.numberOfSets + 1,
      );

      // Update training day and plan safely
      final updatedExercises =
          List<ExerciseModel>.from(_trainingDay!.exercises);
      updatedExercises[_currentExerciseIndex] = updatedExercise;

      final updatedDay = _trainingDay!.copyWith(
        exercises: updatedExercises,
      );

      final updatedDays = List<TrainingDayModel>.from(_trainingPlan!.days);
      updatedDays[_dayIndex] = updatedDay;

      final updatedPlan = _trainingPlan!.copyWith(
        days: updatedDays,
      );

      // Update provider state
      _trainingPlan = updatedPlan;
      _trainingDay = updatedDay;

      // Add new set to exercise sets
      final currentSets = _exerciseSets[_currentExerciseIndex] ?? [];
      final newSetId = currentSets.length + 1;

      // Use the last set values as template if available
      double newKg = 0.0;
      int newReps = 0;
      int newRir = 0;

      if (currentSets.isNotEmpty) {
        final lastSet = currentSets.last;
        newKg = lastSet.kg;
        newReps = lastSet.wiederholungen;
        newRir = lastSet.rir;
      }

      // Create the new set
      final newSet = TrainingSetModel(
        id: newSetId,
        kg: newKg,
        wiederholungen: newReps,
        rir: newRir,
      );

      // Update sets
      final updatedSets = List<TrainingSetModel>.from(currentSets)..add(newSet);
      _exerciseSets[_currentExerciseIndex] = updatedSets;

      // Mark as modified
      _exerciseConfigModified[_currentExerciseIndex] = true;

      _log(
          'Satz hinzugefügt: Übung $_currentExerciseIndex hat jetzt ${updatedSets.length} Sätze');

      _isProcessingConfig = false;
      notifyListeners();
    } catch (e) {
      _log('Fehler beim Hinzufügen eines Satzes: $e');
      _isProcessingConfig = false;
    }
  }

  // NEU: Entfernt den letzten nicht abgeschlossenen Satz der aktuellen Übung
  bool removeSetFromCurrentExercise() {
    if (_trainingDay == null ||
        _currentExerciseIndex < 0 ||
        _currentExerciseIndex >= _trainingDay!.exercises.length) {
      return false;
    }

    // Guard against concurrent modifications
    if (_isProcessingConfig) return false;
    _isProcessingConfig = true;

    try {
      // Get current exercise and sets
      final exercise = _trainingDay!.exercises[_currentExerciseIndex];
      final sets = _exerciseSets[_currentExerciseIndex] ?? [];

      // Validation checks
      if (sets.length <= 1) {
        _isProcessingConfig = false;
        return false; // At least one set must remain
      }

      if (sets.last.abgeschlossen) {
        _isProcessingConfig = false;
        return false; // Cannot remove completed set
      }

      // Update exercise with reduced sets count
      final updatedExercise = exercise.copyWith(
        numberOfSets: exercise.numberOfSets - 1,
      );

      // Update training day and plan safely
      final updatedExercises =
          List<ExerciseModel>.from(_trainingDay!.exercises);
      updatedExercises[_currentExerciseIndex] = updatedExercise;

      final updatedDay = _trainingDay!.copyWith(
        exercises: updatedExercises,
      );

      final updatedDays = List<TrainingDayModel>.from(_trainingPlan!.days);
      updatedDays[_dayIndex] = updatedDay;

      final updatedPlan = _trainingPlan!.copyWith(
        days: updatedDays,
      );

      // Update provider state
      _trainingPlan = updatedPlan;
      _trainingDay = updatedDay;

      // Remove the last set
      final updatedSets = List<TrainingSetModel>.from(sets);
      updatedSets.removeLast();
      _exerciseSets[_currentExerciseIndex] = updatedSets;

      // Mark as modified
      _exerciseConfigModified[_currentExerciseIndex] = true;

      _log(
          'Satz entfernt: Übung $_currentExerciseIndex hat jetzt ${updatedSets.length} Sätze');

      _isProcessingConfig = false;
      notifyListeners();
      return true;
    } catch (e) {
      _log('Fehler beim Entfernen eines Satzes: $e');
      _isProcessingConfig = false;
      return false;
    }
  }

  // NEU: Speichert Änderungen am Trainingsplan in der Datenbank
  Future<bool> saveModificationsToTrainingPlan() async {
    try {
      // Prüfe, ob es Änderungen gibt und ein Trainingsplan vorhanden ist
      if (_trainingPlan == null || !hasModifiedExercises) {
        _log('Keine Änderungen zu speichern oder kein Trainingsplan vorhanden');
        return false;
      }

      _log(
          'Speichere Änderungen am Trainingsplan: ${_trainingPlan!.id} - ${_trainingPlan!.name}');

      // Stelle sicher, dass wir einen vollständigen Deep-Copy des Trainingsplans speichern
      final planToSave = _trainingPlan!.copyWith();

      // Speichere den aktualisierten Trainingsplan
      final success =
          await _trainingPlanService.saveTrainingPlans([planToSave]);

      if (success) {
        _log('Änderungen erfolgreich in der Datenbank gespeichert');
        // Setze Änderungsstatus zurück
        _exerciseConfigModified.clear();
      } else {
        _log('Fehler beim Speichern der Änderungen');
      }

      return success;
    } catch (e) {
      _log('Fehler beim Speichern der Änderungen am Trainingsplan: $e');
      return false;
    }
  }

  // NEU: Methode zum Hinzufügen einer neuen Übung zur Session
  Future<void> addNewExerciseToSession(ExerciseModel exercise) async {
    try {
      if (_trainingDay == null || _trainingPlan == null) return;

      _log('Neue Übung zur Session hinzufügen: ${exercise.name}');

      // Übung zur Liste der hinzugefügten Übungen hinzufügen
      _addedExercises.add(exercise);

      // Übung zum Trainingstag hinzufügen
      final updatedExercises = List<ExerciseModel>.from(_trainingDay!.exercises)
        ..add(exercise);

      // Trainingstag aktualisieren
      final updatedDay = _trainingDay!.copyWith(
        exercises: updatedExercises,
      );

      // Trainingsplan aktualisieren
      final updatedDays = List<TrainingDayModel>.from(_trainingPlan!.days);
      updatedDays[_dayIndex] = updatedDay;

      final updatedPlan = _trainingPlan!.copyWith(
        days: updatedDays,
      );

      // Provider-Status aktualisieren
      _trainingPlan = updatedPlan;
      _trainingDay = updatedDay;

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

      // Sätze für die neue Übung erstellen
      List<TrainingSetModel> sets = List.generate(
        exercise.numberOfSets,
        (setIndex) => TrainingSetModel(
          id: setIndex + 1,
          kg: 0,
          wiederholungen: 0,
          rir: 0,
        ),
      );

      // Setze die Tracking-Daten für die neue Übung
      final newExerciseIndex = _trainingDay!.exercises.length - 1;
      _exerciseSets[newExerciseIndex] = sets;
      _activeSetByExercise[newExerciseIndex] = 0;
      _exerciseCompletionStatus[newExerciseIndex] = false;

      // TabController muss vom UI aktualisiert werden

      notifyListeners();
    } catch (e) {
      _log('Fehler beim Hinzufügen einer neuen Übung: $e');
    }
  }

  // NEU: Methode zum Speichern hinzugefügter Übungen im Trainingsplan
  Future<bool> saveAddedExercisesToTrainingPlan() async {
    try {
      // Prüfe, ob es hinzugefügte Übungen gibt
      if (_addedExercises.isEmpty || _trainingPlan == null) {
        return false;
      }

      _log(
          'Speichere ${_addedExercises.length} hinzugefügte Übungen im Trainingsplan: ${_trainingPlan!.id}');

      // Trainingsplan speichern
      final success =
          await _trainingPlanService.saveTrainingPlans([_trainingPlan!]);

      if (success) {
        _log('Hinzugefügte Übungen erfolgreich gespeichert');
        // Liste der hinzugefügten Übungen leeren
        _addedExercises.clear();
      }

      return success;
    } catch (e) {
      _log('Fehler beim Speichern hinzugefügter Übungen: $e');
      return false;
    }
  }

  // NEU: Methode zum Löschen einer Übung aus der Session
  Future<bool> removeExerciseFromSession(int exerciseIndex,
      {Function? onTabsChanged}) async {
    try {
      if (_trainingDay == null || _trainingPlan == null) return false;

      // Sicherstellen, dass mindestens eine Übung bleibt
      if (_trainingDay!.exercises.length <= 1) {
        _log(
            'Löschen nicht möglich: Es muss mindestens eine Übung vorhanden sein');
        return false;
      }

      // Guard gegen gleichzeitige Änderungen
      if (_isProcessingConfig) return false;
      _isProcessingConfig = true;

      try {
        _log('Entferne Übung mit Index $exerciseIndex');

        // Die zu löschende Übung speichern
        final exerciseToDelete = _trainingDay!.exercises[exerciseIndex];
        _deletedExercises.add(exerciseToDelete);

        // Übung aus dem Trainingstag entfernen
        final updatedExercises =
            List<ExerciseModel>.from(_trainingDay!.exercises);
        updatedExercises.removeAt(exerciseIndex);

        // Trainingstag aktualisieren
        final updatedDay = _trainingDay!.copyWith(
          exercises: updatedExercises,
        );

        // Trainingsplan aktualisieren
        final updatedDays = List<TrainingDayModel>.from(_trainingPlan!.days);
        updatedDays[_dayIndex] = updatedDay;

        final updatedPlan = _trainingPlan!.copyWith(
          days: updatedDays,
        );

        // Provider-Status aktualisieren
        _trainingPlan = updatedPlan;
        _trainingDay = updatedDay;

        // Tracking-Daten anpassen
        _adjustTrackingDataAfterExerciseRemoval(exerciseIndex);

        // Erst TabController aktualisieren
        if (onTabsChanged != null) {
          await Future.microtask(() => onTabsChanged());
        }

        // Verzögerung, um UI-Updates abzuschließen
        await Future.delayed(const Duration(milliseconds: 100));

        // Erst JETZT zur nächsten offenen Übung navigieren
        int nextExerciseIndex = findNextOpenExerciseIndex();
        if (nextExerciseIndex >= _trainingDay!.exercises.length) {
          nextExerciseIndex = _trainingDay!.exercises.isEmpty
              ? 0
              : _trainingDay!.exercises.length - 1;
        }
        _currentExerciseIndex = nextExerciseIndex;

        // Status aktualisieren, erst NACHDEM alles andere erledigt ist
        _isProcessingConfig = false;
        notifyListeners();

        return true;
      } catch (e) {
        _log('Fehler im Löschvorgang: $e');
        _isProcessingConfig = false;
        return false;
      }
    } catch (e) {
      _log('Fehler beim Entfernen der Übung: $e');
      _isProcessingConfig = false;
      return false;
    }
  }

  // NEU: Hilfsmethode zum Anpassen der Tracking-Daten nach dem Entfernen einer Übung
  void _adjustTrackingDataAfterExerciseRemoval(int removedIndex) {
    // Temporäre Maps für die aktualisierten Tracking-Daten
    Map<int, List<TrainingSetModel>> updatedExerciseSets = {};
    Map<int, int> updatedActiveSetByExercise = {};
    Map<int, bool> updatedExerciseCompletionStatus = {};
    Map<int, int> updatedLastCompletedSetIndexByExercise = {};

    // Für jeden Index in den Tracking-Maps
    for (int i = 0; i < _trainingDay!.exercises.length + 1; i++) {
      if (i < removedIndex) {
        // Indizes vor dem entfernten bleiben gleich
        if (_exerciseSets.containsKey(i))
          updatedExerciseSets[i] = _exerciseSets[i]!;
        if (_activeSetByExercise.containsKey(i))
          updatedActiveSetByExercise[i] = _activeSetByExercise[i]!;
        if (_exerciseCompletionStatus.containsKey(i))
          updatedExerciseCompletionStatus[i] = _exerciseCompletionStatus[i]!;
        if (_lastCompletedSetIndexByExercise.containsKey(i))
          updatedLastCompletedSetIndexByExercise[i] =
              _lastCompletedSetIndexByExercise[i]!;
      } else if (i > removedIndex) {
        // Indizes nach dem entfernten werden um 1 verringert
        if (_exerciseSets.containsKey(i))
          updatedExerciseSets[i - 1] = _exerciseSets[i]!;
        if (_activeSetByExercise.containsKey(i))
          updatedActiveSetByExercise[i - 1] = _activeSetByExercise[i]!;
        if (_exerciseCompletionStatus.containsKey(i))
          updatedExerciseCompletionStatus[i - 1] =
              _exerciseCompletionStatus[i]!;
        if (_lastCompletedSetIndexByExercise.containsKey(i))
          updatedLastCompletedSetIndexByExercise[i - 1] =
              _lastCompletedSetIndexByExercise[i]!;
      }
      // Der entfernte Index wird übersprungen
    }

    // Tracking-Maps aktualisieren
    _exerciseSets = updatedExerciseSets;
    _activeSetByExercise = updatedActiveSetByExercise;
    _exerciseCompletionStatus = updatedExerciseCompletionStatus;
    _lastCompletedSetIndexByExercise = updatedLastCompletedSetIndexByExercise;

    // Auch die Übungshistorie aktualisieren (aus dem currentSession)
    if (_currentSession != null) {
      final updatedExercises =
          List<ExerciseHistoryModel>.from(_currentSession!.exercises);
      if (removedIndex < updatedExercises.length) {
        updatedExercises.removeAt(removedIndex);
        _currentSession = _currentSession!.copyWith(
          exercises: updatedExercises,
        );
      }
    }
  }

  // NEU: Methode zum Speichern der gelöschten Übungen im Trainingsplan
  Future<bool> saveDeletedExercisesToTrainingPlan() async {
    try {
      // Prüfe, ob es gelöschte Übungen gibt
      if (_deletedExercises.isEmpty || _trainingPlan == null) {
        return false;
      }

      _log(
          'Speichere ${_deletedExercises.length} gelöschte Übungen im Trainingsplan: ${_trainingPlan!.id}');

      // Trainingsplan speichern
      final success =
          await _trainingPlanService.saveTrainingPlans([_trainingPlan!]);

      if (success) {
        _log('Gelöschte Übungen erfolgreich gespeichert');
        // Liste der gelöschten Übungen leeren
        _deletedExercises.clear();
      }

      return success;
    } catch (e) {
      _log('Fehler beim Speichern gelöschter Übungen: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _cancelRestTimer();
    super.dispose();
  }

  // Umfassende Aktualisierung einer Übung mit vollständigen Details
  Future<void> updateExerciseFullDetails(
      int exerciseIndex, ExerciseModel updatedExercise) async {
    if (_trainingDay == null || _trainingPlan == null) return;
    if (exerciseIndex < 0 || exerciseIndex >= _trainingDay!.exercises.length)
      return;

    try {
      // Guard gegen gleichzeitige Änderungen
      if (_isProcessingConfig) return;
      _isProcessingConfig = true;

      // Aktuelle Übung abrufen
      final currentExercise = _trainingDay!.exercises[exerciseIndex];

      // Übung mit allen aktualisierten Details erstellen
      final newExercise = ExerciseModel(
        id: currentExercise.id, // ID beibehalten
        name: updatedExercise.name,
        primaryMuscleGroup: updatedExercise.primaryMuscleGroup,
        secondaryMuscleGroup: updatedExercise.secondaryMuscleGroup,
        standardIncrease: updatedExercise.standardIncrease,
        restPeriodSeconds: updatedExercise.restPeriodSeconds,
        numberOfSets: updatedExercise.numberOfSets,
        progressionProfileId: updatedExercise.progressionProfileId,
      );

      // Trainingsplan aktualisieren
      final updatedExercises =
          List<ExerciseModel>.from(_trainingDay!.exercises);
      updatedExercises[exerciseIndex] = newExercise;

      final updatedDay = _trainingDay!.copyWith(
        exercises: updatedExercises,
      );

      final updatedDays = List<TrainingDayModel>.from(_trainingPlan!.days);
      updatedDays[_dayIndex] = updatedDay;

      final updatedPlan = _trainingPlan!.copyWith(
        days: updatedDays,
      );

      // Provider-Status aktualisieren
      _trainingPlan = updatedPlan;
      _trainingDay = updatedDay;

      // Als geändert markieren
      _exerciseConfigModified[exerciseIndex] = true;

      // Anzahl der Sätze anpassen, wenn sie sich geändert hat
      final currentSets = _exerciseSets[exerciseIndex] ?? [];
      if (newExercise.numberOfSets != currentSets.length) {
        // Sätze hinzufügen oder entfernen
        List<TrainingSetModel> updatedSets =
            List<TrainingSetModel>.from(currentSets);

        if (newExercise.numberOfSets > currentSets.length) {
          // Sätze hinzufügen
          for (int i = currentSets.length; i < newExercise.numberOfSets; i++) {
            // Wenn vorhanden, verwende Werte aus dem letzten Satz als Vorlage
            double newKg = 0.0;
            int newReps = 0;
            int newRir = 0;

            if (currentSets.isNotEmpty) {
              final lastSet = currentSets.last;
              newKg = lastSet.kg;
              newReps = lastSet.wiederholungen;
              newRir = lastSet.rir;
            }

            updatedSets.add(TrainingSetModel(
              id: i + 1,
              kg: newKg,
              wiederholungen: newReps,
              rir: newRir,
            ));
          }
        } else if (newExercise.numberOfSets < currentSets.length) {
          // Sätze entfernen (nur nicht abgeschlossene vom Ende)
          int setsToRemove = currentSets.length - newExercise.numberOfSets;
          for (int i = 0; i < setsToRemove; i++) {
            if (updatedSets.isNotEmpty && !updatedSets.last.abgeschlossen) {
              updatedSets.removeLast();
            } else {
              break; // Keine weiteren nicht abgeschlossenen Sätze mehr
            }
          }

          // Wenn wir noch nicht genug entfernt haben, Warnung ausgeben
          if (updatedSets.length > newExercise.numberOfSets) {
            _log(
                'Warnung: Konnte nicht alle Sätze entfernen, da einige bereits abgeschlossen sind');
          }
        }

        // Aktualisiere die Sätze
        _exerciseSets[exerciseIndex] = updatedSets;
      }

      // Auch die Übungshistorie aktualisieren
      _updateExerciseHistoryFull(exerciseIndex, newExercise);

      // Benachrichtigung verzögern, um Neuaufbau während der Verarbeitung zu vermeiden
      Future.microtask(() {
        _isProcessingConfig = false;
        notifyListeners();
      });

      _log(
          'Vollständige Details der Übung $exerciseIndex aktualisiert: ${newExercise.name}');

      return;
    } catch (e) {
      _log('Fehler bei der vollständigen Aktualisierung der Übung: $e');
      _isProcessingConfig = false;
      rethrow;
    }
  }

// Hilfsmethode zum Aktualisieren der Übungshistorie mit allen Details
  void _updateExerciseHistoryFull(int exerciseIndex, ExerciseModel exercise) {
    if (_currentSession == null ||
        exerciseIndex >= _currentSession!.exercises.length) return;

    try {
      // Aktuelle Übungshistorie abrufen
      final updatedSessionExercises =
          List<ExerciseHistoryModel>.from(_currentSession!.exercises);
      final currentExerciseHistory = updatedSessionExercises[exerciseIndex];

      // Aktualisierte Übungshistorie erstellen
      final updatedExerciseHistory = currentExerciseHistory.copyWith(
        name: exercise.name,
        primaryMuscleGroup: exercise.primaryMuscleGroup,
        secondaryMuscleGroup: exercise.secondaryMuscleGroup,
        standardIncrease: exercise.standardIncrease,
        restPeriodSeconds: exercise.restPeriodSeconds,
        progressionProfileId: exercise.progressionProfileId,
      );

      // In der Session ersetzen
      updatedSessionExercises[exerciseIndex] = updatedExerciseHistory;

      // Session aktualisieren
      _currentSession = _currentSession!.copyWith(
        exercises: updatedSessionExercises,
      );
    } catch (e) {
      _log(
          'Fehler beim Aktualisieren der Übungshistorie mit vollständigen Details: $e');
    }
  }

  // Empfehlungen für einen bestimmten Satz zurücksetzen
  void resetProgressionRecommendations(int exerciseIndex, int setId) {
    final sets = _exerciseSets[exerciseIndex];
    if (sets == null) return;

    final setIndex = setId - 1; // setId beginnt bei 1, Index bei 0
    if (setIndex < 0 || setIndex >= sets.length) return;

    final updatedSets = List<TrainingSetModel>.from(sets);
    updatedSets[setIndex] = updatedSets[setIndex].copyWith(
      empfehlungBerechnet: false,
      empfKg: null,
      empfWiederholungen: null,
      empfRir: null,
    );

    _exerciseSets[exerciseIndex] = updatedSets;
    notifyListeners();
  }

  // Hilfsmethode, um eine Übung für den aktuellen Mikrozyklus zu bekommen
  ExerciseModel getExerciseForMicrocycle(int exerciseIndex) {
    if (_trainingPlan == null ||
        !_trainingPlan!.isPeriodized ||
        _trainingDay == null ||
        exerciseIndex < 0 ||
        exerciseIndex >= _trainingDay!.exercises.length) {
      // Wenn keine Periodisierung oder ungültiger Index, gib die Originalübung zurück
      return _trainingDay!.exercises[exerciseIndex];
    }

    final exercise = _trainingDay!.exercises[exerciseIndex];

    // Prüfe, ob es eine Mikrozyklus-spezifische Konfiguration gibt
    final config = _trainingPlan!
        .getExerciseMicrocycle(exercise.id, _dayIndex, _weekIndex);

    if (config == null) {
      return exercise; // Keine spezifische Konfiguration vorhanden
    }

    // Erstelle eine angepasste Version der Übung mit den Werten aus dem Mikrozyklus
    return exercise.copyWith(
      numberOfSets: config.numberOfSets,
      progressionProfileId: config.progressionProfileId,
    );
  }
}
