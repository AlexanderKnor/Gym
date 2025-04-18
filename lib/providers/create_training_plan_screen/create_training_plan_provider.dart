// lib/providers/create_training_plan_screen/create_training_plan_provider.dart
import 'package:flutter/material.dart';
import '../../models/training_plan_screen/training_plan_model.dart';
import '../../models/training_plan_screen/training_day_model.dart';
import '../../models/training_plan_screen/exercise_model.dart';

class CreateTrainingPlanProvider extends ChangeNotifier {
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

  // Getter
  String get planName => _planName;
  int get frequency => _frequency;
  List<String> get dayNames => _dayNames;
  TrainingPlanModel? get draftPlan => _draftPlan;
  int get selectedDayIndex => _selectedDayIndex;

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

  void removeExercise(int exerciseIndex) {
    if (_draftPlan != null) {
      final updatedDays = List<TrainingDayModel>.from(_draftPlan!.days);
      final currentDay = updatedDays[_selectedDayIndex];

      if (exerciseIndex >= 0 && exerciseIndex < currentDay.exercises.length) {
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

  // Zustand zurücksetzen, wenn fertig
  void reset() {
    _planName = '';
    _frequency = 3;
    _dayNames = ['Tag 1', 'Tag 2', 'Tag 3'];
    _draftPlan = null;
    _selectedDayIndex = 0;
    notifyListeners();
  }
}
