// lib/providers/create_training_plan_screen/create_training_plan_provider.dart
import 'package:flutter/material.dart';
import '../../models/training_plan_screen/training_plan_model.dart';
import '../../models/training_plan_screen/training_day_model.dart';
import '../../models/training_plan_screen/exercise_model.dart';
import '../../services/training_plan_screen/training_plan_service.dart'; // Neu importiert

class CreateTrainingPlanProvider extends ChangeNotifier {
  // Service für Löschoperationen
  final TrainingPlanService _trainingPlanService =
      TrainingPlanService(); // Neu hinzugefügt

  // Zustand für den ersten Screen
  String _planName = '';
  int _frequency = 3; // Standardwert: 3 Tage
  List<String> _dayNames = [
    'Tag 1',
    'Tag 2',
    'Tag 3'
  ]; // Initialisieren mit Standardwerten

  // Zustand für den zweiten Screen
  TrainingPlanModel? _draftPlan;
  int _selectedDayIndex = 0;

  // Modus-Tracking - neu hinzugefügt
  bool _isEditMode = false;
  String? _editingPlanId;

  // Neu: Set zum Verfolgen von gelöschten Übungs-IDs
  final Set<String> _deletedExerciseIds = {};

  // Neu: Set zum Verfolgen von gelöschten Trainingstag-IDs
  final Set<String> _deletedDayIds = {};

  // Getter
  String get planName => _planName;
  int get frequency => _frequency;
  List<String> get dayNames => _dayNames;
  TrainingPlanModel? get draftPlan => _draftPlan;
  int get selectedDayIndex => _selectedDayIndex;
  bool get isEditMode => _isEditMode; // Neuer Getter
  String? get editingPlanId => _editingPlanId; // Neuer Getter

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

  void setFrequency(int freq) {
    if (freq >= 1 && freq <= 7) {
      _frequency = freq;
      _ensureDayNamesInitialized();
      notifyListeners();
    }
  }

  void setDayName(int index, String name) {
    if (index >= 0 && index < _dayNames.length) {
      _dayNames[index] = name;
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
    // Stellen wir sicher, dass die Tagnamen richtig initialisiert sind
    _ensureDayNamesInitialized();

    final id = 'plan_${DateTime.now().millisecondsSinceEpoch}';

    // Sicherstellen, dass wir keine Index-Fehler bekommen
    final days = List<TrainingDayModel>.generate(
      _frequency,
      (index) => TrainingDayModel(
        id: 'day_${DateTime.now().millisecondsSinceEpoch}_$index',
        name: index < _dayNames.length ? _dayNames[index] : 'Tag ${index + 1}',
        exercises: [],
      ),
    );

    _draftPlan = TrainingPlanModel(
      id: id,
      name: _planName.isNotEmpty ? _planName : 'Neuer Trainingsplan',
      days: days,
      isActive: false,
    );

    notifyListeners();
  }

  // NEU: Methode zum Laden eines existierenden Plans zum Bearbeiten
  void loadExistingPlanForEditing(TrainingPlanModel plan) {
    _isEditMode = true;
    _editingPlanId = plan.id;
    _planName = plan.name;
    _frequency = plan.days.length;

    // Tagnamen aus dem Plan übernehmen
    _dayNames = plan.days.map((day) => day.name).toList();

    // Plan-Kopie als Draft-Plan setzen
    _draftPlan = plan.copyWith();

    notifyListeners();
  }

  // Methode für direkten Einstieg in den Editor (ohne den ersten Screen)
  void skipToEditor(TrainingPlanModel plan) {
    loadExistingPlanForEditing(plan);
  }

  // Methoden für den zweiten Screen (Übungseditor)
  void setSelectedDayIndex(int index) {
    if (index >= 0 && index < _draftPlan!.days.length) {
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

      notifyListeners();
    }
  }

  void updateExercise(int exerciseIndex, ExerciseModel updatedExercise) {
    if (_draftPlan != null) {
      final updatedDays = List<TrainingDayModel>.from(_draftPlan!.days);
      final currentDay = updatedDays[_selectedDayIndex];

      if (exerciseIndex >= 0 && exerciseIndex < currentDay.exercises.length) {
        final updatedExercises = List<ExerciseModel>.from(currentDay.exercises);
        updatedExercises[exerciseIndex] = updatedExercise;

        updatedDays[_selectedDayIndex] = currentDay.copyWith(
          exercises: updatedExercises,
        );

        _draftPlan = _draftPlan!.copyWith(days: updatedDays);

        notifyListeners();
      }
    }
  }

  // GEÄNDERT: Übung entfernen ohne sofortiges Löschen der Historie
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

        notifyListeners();
      }
    }
  }

  // NEU: Trainingstag hinzufügen
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

  // NEU: Trainingstag entfernen
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

  // NEU: Gelöschte Übungen aus der Datenbank entfernen
  Future<void> cleanupDeletedExercises() async {
    // Lösche alle Übungen, die seit dem letzten Speichern entfernt wurden
    for (final exerciseId in _deletedExerciseIds) {
      await _trainingPlanService.deleteExercise(exerciseId);
    }

    // Liste der gelöschten Übungen zurücksetzen
    _deletedExerciseIds.clear();
  }

  // NEU: Gelöschte Trainingstage aus der Datenbank entfernen
  Future<void> cleanupDeletedDays() async {
    // Lösche alle Trainingstage, die seit dem letzten Speichern entfernt wurden
    for (final dayId in _deletedDayIds) {
      await _trainingPlanService.deleteTrainingDay(dayId);
    }

    // Liste der gelöschten Trainingstage zurücksetzen
    _deletedDayIds.clear();
  }

  // NEU: Kombinierte Cleanup-Methode für vereinfachten Aufruf
  Future<void> cleanupDeletedItems() async {
    await cleanupDeletedExercises();
    await cleanupDeletedDays();
  }

  // Zustand zurücksetzen, wenn fertig
  void reset() {
    _planName = '';
    _frequency = 3;
    _dayNames = ['Tag 1', 'Tag 2', 'Tag 3'];
    _draftPlan = null;
    _selectedDayIndex = 0;
    _isEditMode = false;
    _editingPlanId = null;
    _deletedExerciseIds.clear(); // Leere die Liste der gelöschten Übungen
    _deletedDayIds.clear(); // Leere die Liste der gelöschten Trainingstage
    notifyListeners();
  }
}
