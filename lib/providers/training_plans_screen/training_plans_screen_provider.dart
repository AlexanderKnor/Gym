// lib/providers/training_plans_screen/training_plans_screen_provider.dart
import 'package:flutter/material.dart';
import '../../models/training_plan_screen/training_plan_model.dart';
import '../../services/training_plan_screen/training_plan_service.dart';

class TrainingPlansProvider extends ChangeNotifier {
  final TrainingPlanService _trainingPlanService = TrainingPlanService();
  List<TrainingPlanModel> _trainingPlans = [];
  bool _isLoading = false;

  // Getter
  List<TrainingPlanModel> get trainingPlans => _trainingPlans;
  bool get isLoading => _isLoading;

  TrainingPlanModel? get activePlan {
    try {
      return _trainingPlans.firstWhere((plan) => plan.isActive);
    } catch (e) {
      return null;
    }
  }

  // Konstruktor mit Initialisierung
  TrainingPlansProvider() {
    _loadTrainingPlans();
  }

  // Alle TrainingsplÃ¤ne laden
  Future<void> _loadTrainingPlans() async {
    _isLoading = true;
    notifyListeners();

    try {
      _trainingPlans = await _trainingPlanService.loadTrainingPlans();
      notifyListeners();
    } catch (e) {
      print('Fehler beim Laden der TrainingsplÃ¤ne: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Trainingsplan speichern
  Future<bool> saveTrainingPlan(TrainingPlanModel plan, bool activate) async {
    try {
      // Wenn dieser Plan aktiviert werden soll, alle anderen deaktivieren
      if (activate) {
        _trainingPlans =
            _trainingPlans.map((p) => p.copyWith(isActive: false)).toList();

        // Den neuen Plan als aktiv setzen
        final updatedPlan = plan.copyWith(isActive: true);

        // Plan zur Liste hinzufÃ¼gen oder aktualisieren
        final existingIndex =
            _trainingPlans.indexWhere((p) => p.id == updatedPlan.id);
        if (existingIndex >= 0) {
          _trainingPlans[existingIndex] = updatedPlan;
        } else {
          _trainingPlans.add(updatedPlan);
        }
      } else {
        // Nur den Plan hinzufÃ¼gen oder aktualisieren
        final existingIndex = _trainingPlans.indexWhere((p) => p.id == plan.id);
        if (existingIndex >= 0) {
          _trainingPlans[existingIndex] = plan;
        } else {
          _trainingPlans.add(plan);
        }
      }

      // Im Speicher sichern
      await _trainingPlanService.saveTrainingPlans(_trainingPlans);

      notifyListeners();
      return true;
    } catch (e) {
      print('Fehler beim Speichern des Trainingsplans: $e');
      return false;
    }
  }

  // Bestimmten Plan aktivieren
  Future<bool> activateTrainingPlan(String planId) async {
    try {
      // Alle PlÃ¤ne deaktivieren und nur den mit der angegebenen ID aktivieren
      _trainingPlans = _trainingPlans
          .map((p) => p.copyWith(isActive: p.id == planId))
          .toList();

      // Im Speicher sichern
      await _trainingPlanService.saveTrainingPlans(_trainingPlans);

      notifyListeners();
      return true;
    } catch (e) {
      print('Fehler beim Aktivieren des Trainingsplans: $e');
      return false;
    }
  }

  // Trainingsplan löschen - AKTUALISIERT
  Future<bool> deleteTrainingPlan(String planId) async {
    try {
      // Zuerst aus Firestore löschen
      final firestoreSuccess = await _trainingPlanService.deletePlan(planId);

      if (!firestoreSuccess) {
        print('Warnung: Plan konnte nicht aus Firestore gelöscht werden');
      }

      // Dann aus lokaler Liste entfernen
      _trainingPlans.removeWhere((p) => p.id == planId);

      // Lokalen Speicher aktualisieren
      await _trainingPlanService.saveTrainingPlans(_trainingPlans);

      notifyListeners();
      return true;
    } catch (e) {
      print('Fehler beim Löschen des Trainingsplans: $e');
      return false;
    }
  }
}
