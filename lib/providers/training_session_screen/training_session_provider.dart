// lib/providers/training_session_screen/training_session_provider.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart'; // Für Vibrationsfeedback

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
import '../../services/training_plan_screen/training_plan_service.dart';

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

  // NEU: Tracking für Übungsänderungen
  final Map<int, ExerciseModel> _originalExercises =
      {}; // Speichert Original-Konfigurationen
  final Map<int, bool> _exerciseConfigModified =
      {}; // Markiert geänderte Übungen

  // NEU: Service für das Updaten des Trainingsplans
  final TrainingPlanService _trainingPlanService = TrainingPlanService();

  // FIX: Flag für Debug-Logging
  final bool _debugMode = true;

  // Neue Variablen zum Verhindern von wiederholten Updates
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

  // NEU: Getter für Übungsänderungen
  bool get hasModifiedExercises =>
      _exerciseConfigModified.values.any((modified) => modified);

  TrainingSessionModel? get currentSession => _currentSession;

  // FIX: Debug-Logging Methode
  void _log(String message) {
    if (_debugMode) {
      print('TrainingSessionProvider: $message');
    }
  }

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

        // NEU: Originalkonfiguration speichern
        _originalExercises[i] = exercise;
        _exerciseConfigModified[i] = false;

        _log(
            'Originalübung gespeichert: ${exercise.name} (${exercise.id}) - Pause: ${exercise.restPeriodSeconds} sek, Steigerung: ${exercise.standardIncrease} kg');

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

    // NEU: Tracking für Übungsänderungen zurücksetzen
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

    // FIX: Verwende die aktualisierte Pausenzeit aus dem aktuellen Übungsmodell
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

      // FIX: Stelle sicher, dass wir einen vollständigen Deep-Copy des Trainingsplans speichern
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

  @override
  void dispose() {
    _cancelRestTimer();
    super.dispose();
  }
}
