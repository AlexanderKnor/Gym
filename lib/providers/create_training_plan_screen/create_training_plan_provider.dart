// lib/providers/create_training_plan_screen/create_training_plan_provider.dart
import 'package:flutter/material.dart';
import '../../models/training_plan_screen/training_plan_model.dart';
import '../../models/training_plan_screen/training_day_model.dart';
import '../../models/training_plan_screen/exercise_model.dart';
import '../../models/training_plan_screen/periodization_model.dart';
import '../../services/training_plan_screen/training_plan_service.dart';

class CreateTrainingPlanProvider extends ChangeNotifier {
  // Service für Löschoperationen
  final TrainingPlanService _trainingPlanService = TrainingPlanService();

  // Zustand für den ersten Screen
  String _planName = '';
  String _gym = '';
  int _frequency = 3; // Standardwert: 3 Tage
  List<String> _dayNames = [
    'Tag 1',
    'Tag 2',
    'Tag 3'
  ]; // Initialisieren mit Standardwerten

  // Neue Felder für Periodisierung
  bool _isPeriodized = false;
  int _numberOfWeeks = 4; // Standard: 4 Wochen
  int _activeWeekIndex = 0; // Aktive Woche für Bearbeitung

  // Zustand für den zweiten Screen
  TrainingPlanModel? _draftPlan;
  int _selectedDayIndex = 0;

  // Modus-Tracking
  bool _isEditMode = false;
  String? _editingPlanId;

  // Set zum Verfolgen von gelöschten Übungs-IDs
  final Set<String> _deletedExerciseIds = {};

  // Set zum Verfolgen von gelöschten Trainingstag-IDs
  final Set<String> _deletedDayIds = {};

  // Getter
  String get planName => _planName;
  String get gym => _gym;
  int get frequency => _frequency;
  List<String> get dayNames => _dayNames;
  TrainingPlanModel? get draftPlan => _draftPlan;
  int get selectedDayIndex => _selectedDayIndex;
  bool get isEditMode => _isEditMode;
  String? get editingPlanId => _editingPlanId;

  // Neue Getter für Periodisierung
  bool get isPeriodized => _isPeriodized;
  int get numberOfWeeks => _numberOfWeeks;
  int get activeWeekIndex => _activeWeekIndex;

  // Konstruktor mit Initialisierung
  CreateTrainingPlanProvider() {
    // Stelle sicher, dass dayNames immer die richtige Größe hat
    _ensureDayNamesInitialized();
  }

  // Methoden für den ersten Screen
  void setPlanName(String name) {
    _planName = name;
    notifyListeners();
  }

  void setGym(String gym) {
    _gym = gym;
    notifyListeners();
  }

  void setFrequency(int freq) {
    if (freq >= 1 && freq <= 7) {
      _frequency = freq;
      _ensureDayNamesInitialized();
      notifyListeners();
    }
  }

  void setPeriodization(bool isPeriodized) {
    _isPeriodized = isPeriodized;
    notifyListeners();
  }

  // Generiere einen Draft Plan basierend auf den aktuellen Einstellungen
  void generateDraftPlan() {
    try {
      final id = 'plan_${DateTime.now().millisecondsSinceEpoch}';
      
      // Erstelle Trainingstage basierend auf der Frequenz
      final days = List<TrainingDayModel>.generate(
        _frequency,
        (index) => TrainingDayModel(
          id: 'day_${DateTime.now().millisecondsSinceEpoch}_$index',
          name: index < _dayNames.length ? _dayNames[index] : 'Tag ${index + 1}',
          exercises: [], // Leere Übungsliste
        ),
      );

      if (_isPeriodized) {
        _draftPlan = TrainingPlanModel(
          id: id,
          name: _planName.isNotEmpty ? _planName : 'Neuer Trainingsplan',
          days: days,
          isActive: false,
          gym: _gym.isNotEmpty ? _gym : null,
          isPeriodized: true,
          numberOfWeeks: _numberOfWeeks,
          periodization: PeriodizationModel(
            weeks: _numberOfWeeks,
            dayConfigurations: {},
            startDate: DateTime.now(),
          ),
        );
      } else {
        _draftPlan = TrainingPlanModel(
          id: id,
          name: _planName.isNotEmpty ? _planName : 'Neuer Trainingsplan',
          days: days,
          isActive: false,
          gym: _gym.isNotEmpty ? _gym : null,
        );
      }

      notifyListeners();
    } catch (e) {
      print('Fehler beim Generieren des Draft Plans: $e');
    }
  }

  // Sichere Methode zum Setzen eines Tagesnamens
  void setDayName(int index, String name) {
    try {
      if (index < 0 || index >= _dayNames.length) {
        print(
            'Ungültiger Index für setDayName: $index von ${_dayNames.length}');
        return;
      }

      print('Aktualisiere Trainingstag-Namen: $index -> "$name"');

      // _dayNames-Liste aktualisieren
      _dayNames[index] = name;

      // Auch den Trainingstag im draftPlan aktualisieren, falls vorhanden
      if (_draftPlan != null) {
        if (index < _draftPlan!.days.length) {
          // Erstelle eine tiefe Kopie aller Tage
          final updatedDays = List<TrainingDayModel>.from(_draftPlan!.days);
          // Aktualisiere den spezifischen Tag
          updatedDays[index] = updatedDays[index].copyWith(name: name);
          // Erstelle eine neue Planinstanz mit den aktualisierten Tagen
          _draftPlan = _draftPlan!.copyWith(days: updatedDays);

          print('Trainingstag im draftPlan erfolgreich aktualisiert');
        } else {
          print(
              'Warnung: Index $index existiert nicht im draftPlan (nur ${_draftPlan!.days.length} Tage)');
        }
      }

      // UI aktualisieren
      notifyListeners();
    } catch (e) {
      print('Fehler in setDayName: $e');
    }
  }

  // Neue Methoden für Periodisierung
  void setIsPeriodized(bool value) {
    _isPeriodized = value;
    notifyListeners();
  }

  void setNumberOfWeeks(int weeks) {
    if (weeks >= 1 && weeks <= 16) {
      // Max 16 Wochen erlauben
      _numberOfWeeks = weeks;
      notifyListeners();
    }
  }

  void setActiveWeekIndex(int weekIndex) {
    if (weekIndex >= 0 && weekIndex < _numberOfWeeks) {
      _activeWeekIndex = weekIndex;
      notifyListeners();
    }
  }

  // Sicherstellen, dass die Tagnamen-Liste korrekt initialisiert ist
  void _ensureDayNamesInitialized() {
    // Wenn die Liste leer ist oder nicht die richtige Größe hat
    if (_dayNames.length != _frequency) {
      // Bestehende Namen behalten und neue hinzufügen oder überschüssige entfernen
      List<String> newNames = List<String>.filled(_frequency, '');

      // Bestehende Namen übernehmen
      for (int i = 0; i < _frequency && i < _dayNames.length; i++) {
        newNames[i] = _dayNames[i];
      }

      // Neue Namen für zusätzliche Tage generieren
      for (int i = _dayNames.length; i < _frequency; i++) {
        newNames[i] = 'Tag ${i + 1}';
      }

      _dayNames = newNames;
    }
  }

  // Entwurfsplan aus Anfangsdaten erstellen
  void createDraftPlan() {
    try {
      // Stellen wir sicher, dass die Tagnamen richtig initialisiert sind
      _ensureDayNamesInitialized();

      // Entscheiden, ob ein periodisierter oder normaler Plan erstellt wird
      if (_isPeriodized) {
        final id = 'plan_${DateTime.now().millisecondsSinceEpoch}';

        // Sicherstellen, dass wir keine Index-Fehler bekommen
        final days = List<TrainingDayModel>.generate(
          _frequency,
          (index) => TrainingDayModel(
            id: 'day_${DateTime.now().millisecondsSinceEpoch}_$index',
            name: index < _dayNames.length
                ? _dayNames[index]
                : 'Tag ${index + 1}',
            exercises: [],
          ),
        );

        _draftPlan = TrainingPlanModel(
          id: id,
          name: _planName.isNotEmpty ? _planName : 'Neuer Trainingsplan',
          days: days,
          isActive: false,
          gym: _gym.isNotEmpty ? _gym : null,
          isPeriodized: true,
          numberOfWeeks: _numberOfWeeks,
          periodization: PeriodizationModel(
            weeks: _numberOfWeeks,
            dayConfigurations: {},
          ),
        );
      } else {
        // Normaler Plan ohne Periodisierung
        final id = 'plan_${DateTime.now().millisecondsSinceEpoch}';

        // Sicherstellen, dass wir keine Index-Fehler bekommen
        final days = List<TrainingDayModel>.generate(
          _frequency,
          (index) => TrainingDayModel(
            id: 'day_${DateTime.now().millisecondsSinceEpoch}_$index',
            name: index < _dayNames.length
                ? _dayNames[index]
                : 'Tag ${index + 1}',
            exercises: [],
          ),
        );

        _draftPlan = TrainingPlanModel(
          id: id,
          name: _planName.isNotEmpty ? _planName : 'Neuer Trainingsplan',
          days: days,
          isActive: false,
          gym: _gym.isNotEmpty ? _gym : null,
        );
      }

      notifyListeners();
    } catch (e) {
      print('Fehler in createDraftPlan: $e');
    }
  }

  // Methode zum Laden eines existierenden Plans zum Bearbeiten
  void loadExistingPlanForEditing(TrainingPlanModel plan) {
    try {
      _isEditMode = true;
      _editingPlanId = plan.id;
      _planName = plan.name;
      _gym = plan.gym ?? '';
      _frequency = plan.days.length;
      _isPeriodized = plan.isPeriodized;
      _numberOfWeeks = plan.numberOfWeeks;

      // Tagnamen aus dem Plan übernehmen
      _dayNames = plan.days.map((day) => day.name).toList();

      // Plan-Kopie als Draft-Plan setzen
      _draftPlan = plan.copyWith();

      notifyListeners();
    } catch (e) {
      print('Fehler in loadExistingPlanForEditing: $e');
    }
  }

  // Methode für direkten Einstieg in den Editor (ohne den ersten Screen)
  void skipToEditor(TrainingPlanModel plan) {
    loadExistingPlanForEditing(plan);
  }

  // Methoden für den zweiten Screen (Übungseditor)
  void setSelectedDayIndex(int index) {
    if (index >= 0 && _draftPlan != null && index < _draftPlan!.days.length) {
      _selectedDayIndex = index;
      notifyListeners();
    }
  }

  void addExercise(ExerciseModel exercise) {
    if (_draftPlan != null) {
      final updatedDays = List<TrainingDayModel>.from(_draftPlan!.days);
      final currentDay = updatedDays[_selectedDayIndex];

      final updatedExercises = List<ExerciseModel>.from(currentDay.exercises)
        ..add(exercise);

      updatedDays[_selectedDayIndex] = currentDay.copyWith(
        exercises: updatedExercises,
      );

      _draftPlan = _draftPlan!.copyWith(days: updatedDays);

      // Wenn periodisiert, füge Standardkonfigurationen für jede Woche hinzu
      if (_draftPlan!.isPeriodized) {
        final dayId = currentDay.id;
        final exerciseId = exercise.id;

        for (int weekIndex = 0; weekIndex < _numberOfWeeks; weekIndex++) {
          if (weekIndex == _activeWeekIndex) {
            // Für die aktive Woche verwenden wir die Standardwerte der Übung
            _draftPlan!.addExerciseMicrocycle(
                exerciseId,
                _selectedDayIndex,
                weekIndex,
                exercise.numberOfSets,
                exercise.repRangeMin,
                exercise.repRangeMax,
                exercise.rirRangeMin,
                exercise.rirRangeMax,
                exercise.progressionProfileId);
          } else {
            // Für andere Wochen kopieren wir erstmal die Werte
            _draftPlan!.addExerciseMicrocycle(
                exerciseId,
                _selectedDayIndex,
                weekIndex,
                exercise.numberOfSets,
                exercise.repRangeMin,
                exercise.repRangeMax,
                exercise.rirRangeMin,
                exercise.rirRangeMax,
                exercise.progressionProfileId);
          }
        }
      }

      notifyListeners();
    }
  }

  void updateExercise(int exerciseIndex, ExerciseModel updatedExercise) {
    if (_draftPlan != null) {
      final updatedDays = List<TrainingDayModel>.from(_draftPlan!.days);
      final currentDay = updatedDays[_selectedDayIndex];

      if (exerciseIndex >= 0 && exerciseIndex < currentDay.exercises.length) {
        final updatedExercises = List<ExerciseModel>.from(currentDay.exercises);
        final originalExercise = updatedExercises[exerciseIndex];
        updatedExercises[exerciseIndex] = updatedExercise;

        updatedDays[_selectedDayIndex] = currentDay.copyWith(
          exercises: updatedExercises,
        );

        _draftPlan = _draftPlan!.copyWith(days: updatedDays);

        // Wenn periodisiert, aktualisiere die Mikrozyklus-Konfiguration für die aktuelle Woche
        if (_draftPlan!.isPeriodized) {
          _draftPlan!.addExerciseMicrocycle(
              updatedExercise.id,
              _selectedDayIndex,
              _activeWeekIndex,
              updatedExercise.numberOfSets,
              updatedExercise.repRangeMin,
              updatedExercise.repRangeMax,
              updatedExercise.rirRangeMin,
              updatedExercise.rirRangeMax,
              updatedExercise.progressionProfileId);
        }

        notifyListeners();
      }
    }
  }

  // Methode zum Aktualisieren einer Mikrozyklus-Konfiguration
  void updateMicrocycle(
      int exerciseIndex,
      int weekIndex,
      int numberOfSets,
      int repRangeMin,
      int repRangeMax,
      int rirRangeMin,
      int rirRangeMax,
      String? progressionProfileId) {
    if (_draftPlan != null && _draftPlan!.isPeriodized) {
      final currentDay = _draftPlan!.days[_selectedDayIndex];

      if (exerciseIndex >= 0 && exerciseIndex < currentDay.exercises.length) {
        final exercise = currentDay.exercises[exerciseIndex];

        _draftPlan!.addExerciseMicrocycle(
            exercise.id,
            _selectedDayIndex,
            weekIndex,
            numberOfSets,
            repRangeMin,
            repRangeMax,
            rirRangeMin,
            rirRangeMax,
            progressionProfileId);

        notifyListeners();
      }
    }
  }

  // Übung entfernen ohne sofortiges Löschen der Historie
  void removeExercise(int exerciseIndex) {
    if (_draftPlan != null) {
      final updatedDays = List<TrainingDayModel>.from(_draftPlan!.days);
      final currentDay = updatedDays[_selectedDayIndex];

      if (exerciseIndex >= 0 && exerciseIndex < currentDay.exercises.length) {
        // Übungs-ID speichern, bevor die Übung entfernt wird
        final exerciseId = currentDay.exercises[exerciseIndex].id;

        // Übungs-ID zur Liste der zu löschenden Übungen hinzufügen
        _deletedExerciseIds.add(exerciseId);

        final updatedExercises = List<ExerciseModel>.from(currentDay.exercises);
        updatedExercises.removeAt(exerciseIndex);

        updatedDays[_selectedDayIndex] = currentDay.copyWith(
          exercises: updatedExercises,
        );

        _draftPlan = _draftPlan!.copyWith(days: updatedDays);

        // Wenn periodisiert, entferne alle Mikrozyklus-Konfigurationen für diese Übung
        if (_draftPlan!.isPeriodized && _draftPlan!.periodization != null) {
          final dayId = currentDay.id;
          if (_draftPlan!.periodization!.dayConfigurations.containsKey(dayId)) {
            _draftPlan!.periodization!.dayConfigurations[dayId]
                ?.remove(exerciseId);
          }
        }

        notifyListeners();
      }
    }
  }

  // Trainingstag hinzufügen
  void addTrainingDay(String dayName) {
    if (_draftPlan != null) {
      final updatedDays = List<TrainingDayModel>.from(_draftPlan!.days);

      final newDayId = 'day_${DateTime.now().millisecondsSinceEpoch}';

      // Neuen Trainingstag erstellen
      final newDay = TrainingDayModel(
        id: newDayId,
        name: dayName.isNotEmpty ? dayName : 'Tag ${updatedDays.length + 1}',
        exercises: [],
      );

      // Tag zur Tagesliste hinzufügen
      updatedDays.add(newDay);

      // Aktualisiere Entwurfsplan
      _draftPlan = _draftPlan!.copyWith(days: updatedDays);

      // Aktualisiere _frequency und _dayNames
      _frequency = updatedDays.length;
      _dayNames = updatedDays.map((day) => day.name).toList();

      // Optional: Gleich zum neuen Tag wechseln
      _selectedDayIndex = updatedDays.length - 1;

      notifyListeners();
    }
  }

  // Trainingstag entfernen
  void removeTrainingDay(int dayIndex) {
    if (_draftPlan != null && _draftPlan!.days.length > 1) {
      final updatedDays = List<TrainingDayModel>.from(_draftPlan!.days);

      if (dayIndex >= 0 && dayIndex < updatedDays.length) {
        // Tag-ID speichern, bevor der Tag entfernt wird
        final dayId = updatedDays[dayIndex].id;

        // Tag-ID zur Liste der zu löschenden Tage hinzufügen
        _deletedDayIds.add(dayId);

        // Für alle Übungen in diesem Tag die IDs zur Löschliste hinzufügen
        for (final exercise in updatedDays[dayIndex].exercises) {
          _deletedExerciseIds.add(exercise.id);
        }

        // Wenn periodisiert, entferne alle Mikrozyklus-Konfigurationen für diesen Tag
        if (_draftPlan!.isPeriodized && _draftPlan!.periodization != null) {
          _draftPlan!.periodization!.dayConfigurations.remove(dayId);
        }

        // Tag entfernen
        updatedDays.removeAt(dayIndex);

        // Falls der ausgewählte Tag gelöscht wurde, wähle den vorherigen aus
        if (_selectedDayIndex >= updatedDays.length) {
          _selectedDayIndex = updatedDays.length - 1;
        }

        // Aktualisiere Entwurfsplan
        _draftPlan = _draftPlan!.copyWith(days: updatedDays);

        // Aktualisiere _frequency und _dayNames
        _frequency = updatedDays.length;
        _dayNames = updatedDays.map((day) => day.name).toList();

        notifyListeners();
      }
    }
  }

  // Gelöschte Übungen aus der Datenbank entfernen
  Future<void> cleanupDeletedExercises() async {
    // Lösche alle Übungen, die seit dem letzten Speichern entfernt wurden
    for (final exerciseId in _deletedExerciseIds) {
      await _trainingPlanService.deleteExercise(exerciseId);
    }

    // Liste der gelöschten Übungen zurücksetzen
    _deletedExerciseIds.clear();
  }

  // Gelöschte Trainingstage aus der Datenbank entfernen
  Future<void> cleanupDeletedDays() async {
    // Lösche alle Trainingstage, die seit dem letzten Speichern entfernt wurden
    for (final dayId in _deletedDayIds) {
      await _trainingPlanService.deleteTrainingDay(dayId);
    }

    // Liste der gelöschten Trainingstage zurücksetzen
    _deletedDayIds.clear();
  }

  // Kombinierte Cleanup-Methode für vereinfachten Aufruf
  Future<void> cleanupDeletedItems() async {
    await cleanupDeletedExercises();
    await cleanupDeletedDays();
  }

  // Methode zum Kopieren aller Mikrozyklen von einer Woche zur anderen
  void copyMicrocycleSettings(int fromWeekIndex, int toWeekIndex) {
    if (_draftPlan == null ||
        !_draftPlan!.isPeriodized ||
        _draftPlan!.periodization == null) return;

    if (fromWeekIndex < 0 ||
        fromWeekIndex >= _numberOfWeeks ||
        toWeekIndex < 0 ||
        toWeekIndex >= _numberOfWeeks) return;

    // Für jeden Tag im Plan
    for (int dayIndex = 0; dayIndex < _draftPlan!.days.length; dayIndex++) {
      final dayId = _draftPlan!.days[dayIndex].id;

      // Für jede Übung in diesem Tag
      for (final exercise in _draftPlan!.days[dayIndex].exercises) {
        final exerciseId = exercise.id;

        // Prüfe, ob es für diese Übung eine Konfiguration in der Quellwoche gibt
        final sourceConfig = _draftPlan!
            .getExerciseMicrocycle(exerciseId, dayIndex, fromWeekIndex);

        if (sourceConfig != null) {
          // Kopiere die Konfiguration zur Zielwoche
          _draftPlan!.addExerciseMicrocycle(
              exerciseId,
              dayIndex,
              toWeekIndex,
              sourceConfig.numberOfSets,
              sourceConfig.repRangeMin,
              sourceConfig.repRangeMax,
              sourceConfig.rirRangeMin,
              sourceConfig.rirRangeMax,
              sourceConfig.progressionProfileId);
        }
      }
    }

    notifyListeners();
  }

  // Zustand zurücksetzen, wenn fertig
  void reset() {
    _planName = '';
    _gym = '';
    _frequency = 3;
    _dayNames = ['Tag 1', 'Tag 2', 'Tag 3'];
    _draftPlan = null;
    _selectedDayIndex = 0;
    _isEditMode = false;
    _editingPlanId = null;
    _deletedExerciseIds.clear();
    _deletedDayIds.clear();
    _isPeriodized = false;
    _numberOfWeeks = 4;
    _activeWeekIndex = 0;

    notifyListeners();
  }

  // Methode zum Abrufen der Übungskonfiguration für die aktuelle Woche im Editor
  ExerciseModel getExerciseForCurrentWeek(int exerciseIndex) {
    if (_draftPlan == null ||
        !_draftPlan!.isPeriodized ||
        exerciseIndex < 0 ||
        _selectedDayIndex >= _draftPlan!.days.length ||
        exerciseIndex >= _draftPlan!.days[_selectedDayIndex].exercises.length) {
      // Wenn keine Periodisierung oder ungültiger Index, gib die Originalübung zurück
      return _draftPlan!.days[_selectedDayIndex].exercises[exerciseIndex];
    }

    final exercise =
        _draftPlan!.days[_selectedDayIndex].exercises[exerciseIndex];
    final config = _draftPlan!.getExerciseMicrocycle(
        exercise.id, _selectedDayIndex, _activeWeekIndex);

    if (config == null) {
      return exercise;
    }

    // Erstelle eine Kopie der Übung mit den Werten aus der Mikrozyklus-Konfiguration
    return exercise.copyWith(
      numberOfSets: config.numberOfSets,
      repRangeMin: config.repRangeMin,
      repRangeMax: config.repRangeMax,
      rirRangeMin: config.rirRangeMin,
      rirRangeMax: config.rirRangeMax,
      progressionProfileId: config.progressionProfileId,
    );
  }

  // Implementierung der Methode zum Umordnen der Trainingstage
  void reorderTrainingDays(int oldIndex, int newIndex) {
    if (_draftPlan == null) return;

    // Sicherstellen, dass die Indizes gültig sind
    if (oldIndex < 0 ||
        oldIndex >= _draftPlan!.days.length ||
        newIndex < 0 ||
        newIndex >= _draftPlan!.days.length) return;

    // Erstelle eine Kopie der Tage-Liste
    final updatedDays = List<TrainingDayModel>.from(_draftPlan!.days);

    // Verschiebe den Tag (Element entfernen und an neuer Position einfügen)
    final movedDay = updatedDays.removeAt(oldIndex);
    updatedDays.insert(newIndex, movedDay);

    // Plan aktualisieren mit den neu geordneten Tagen
    _draftPlan = _draftPlan!.copyWith(days: updatedDays);

    // dayNames aktualisieren, um die neue Reihenfolge zu reflektieren
    _dayNames = updatedDays.map((day) => day.name).toList();

    // Den ausgewählten Tab-Index aktualisieren, wenn der verschobene Tab der aktuell ausgewählte war
    if (_selectedDayIndex == oldIndex) {
      _selectedDayIndex = newIndex;
    }
    // Oder wenn sich durch die Umordnung der Index des ausgewählten Tabs geändert hat
    else if (oldIndex < _selectedDayIndex && newIndex >= _selectedDayIndex) {
      _selectedDayIndex--;
    } else if (oldIndex > _selectedDayIndex && newIndex <= _selectedDayIndex) {
      _selectedDayIndex++;
    }

    // UI aktualisieren
    notifyListeners();
  }

  // Implementierung der Methode zum Umordnen der Übungen innerhalb eines Trainingstages
  void reorderExercises(int dayIndex, int oldIndex, int newIndex) {
    if (_draftPlan == null) return;

    // Sicherstellen, dass der Tagesindex gültig ist
    if (dayIndex < 0 || dayIndex >= _draftPlan!.days.length) return;

    final day = _draftPlan!.days[dayIndex];
    
    // Sicherstellen, dass die Übungsindizes gültig sind
    if (oldIndex < 0 ||
        oldIndex >= day.exercises.length ||
        newIndex < 0 ||
        newIndex >= day.exercises.length) return;

    // Erstelle eine Kopie der Übungsliste
    final updatedExercises = List<ExerciseModel>.from(day.exercises);

    // Verschiebe die Übung (Element entfernen und an neuer Position einfügen)
    final movedExercise = updatedExercises.removeAt(oldIndex);
    updatedExercises.insert(newIndex, movedExercise);

    // Trainingstag mit den neu geordneten Übungen aktualisieren
    final updatedDay = day.copyWith(exercises: updatedExercises);
    
    // Tage-Liste aktualisieren
    final updatedDays = List<TrainingDayModel>.from(_draftPlan!.days);
    updatedDays[dayIndex] = updatedDay;

    // Plan aktualisieren mit den neu geordneten Übungen
    _draftPlan = _draftPlan!.copyWith(days: updatedDays);

    // UI aktualisieren
    notifyListeners();
  }

  // Speichere den aktuellen Plan
  Future<bool> savePlan() async {
    if (_draftPlan == null) return false;
    
    try {
      final success = await _trainingPlanService.addSingleTrainingPlan(_draftPlan!);
      if (success) {
        // Nach erfolgreichem Speichern zurücksetzen
        reset();
      }
      return success;
    } catch (e) {
      print('Fehler beim Speichern des Plans: $e');
      return false;
    }
  }

  // Aktualisiere den Draft Plan mit neuen Grundinformationen
  void updateDraftPlan(TrainingPlanModel updatedPlan) {
    _draftPlan = updatedPlan;
    
    // Synchronisiere Provider-Eigenschaften mit dem aktualisierten Plan
    _planName = updatedPlan.name;
    _gym = updatedPlan.gym ?? '';
    _frequency = updatedPlan.days.length;
    _dayNames = updatedPlan.days.map((day) => day.name).toList();
    _isPeriodized = updatedPlan.isPeriodized;
    _numberOfWeeks = updatedPlan.numberOfWeeks;
    
    // Stelle sicher, dass selectedDayIndex im gültigen Bereich liegt
    if (_selectedDayIndex >= _frequency) {
      _selectedDayIndex = _frequency - 1;
    }
    if (_selectedDayIndex < 0) {
      _selectedDayIndex = 0;
    }
    
    notifyListeners();
  }
}
