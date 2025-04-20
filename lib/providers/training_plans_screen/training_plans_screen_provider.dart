// lib/providers/training_plans_screen/training_plans_screen_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // Für StreamSubscription
import '../../models/training_plan_screen/training_plan_model.dart';
import '../../services/training_plan_screen/training_plan_service.dart';

class TrainingPlansProvider extends ChangeNotifier {
  final TrainingPlanService _trainingPlanService = TrainingPlanService();
  List<TrainingPlanModel> _trainingPlans = [];
  bool _isLoading = false;

  // Subscription für den Auth-Listener
  late final StreamSubscription<User?> _authSubscription;

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

  // Konstruktor mit Initialisierung und Auth-Listener
  TrainingPlansProvider() {
    _loadTrainingPlans();

    // Auf Authentifizierungsänderungen hören
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // Benutzer hat sich angemeldet - Pläne neu laden
        print(
            'Benutzer angemeldet (${user.uid}) - Trainingspläne werden neu geladen');
        _loadTrainingPlans();
      } else {
        // Benutzer hat sich abgemeldet - Pläne löschen
        print('Benutzer abgemeldet - Trainingspläne werden gelöscht');
        _trainingPlans = [];
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    // Aufräumen, um Speicherlecks zu vermeiden
    _authSubscription.cancel();
    super.dispose();
  }

  // Alle Trainingspläne laden
  Future<void> _loadTrainingPlans() async {
    _isLoading = true;
    notifyListeners();

    try {
      _trainingPlans = await _trainingPlanService.loadTrainingPlans();
      print('${_trainingPlans.length} Trainingspläne erfolgreich geladen');
      notifyListeners();
    } catch (e) {
      print('Fehler beim Laden der Trainingspläne: $e');
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

        // Plan zur Liste hinzufügen oder aktualisieren
        final existingIndex =
            _trainingPlans.indexWhere((p) => p.id == updatedPlan.id);
        if (existingIndex >= 0) {
          _trainingPlans[existingIndex] = updatedPlan;
        } else {
          _trainingPlans.add(updatedPlan);
        }
      } else {
        // Nur den Plan hinzufügen oder aktualisieren
        final existingIndex = _trainingPlans.indexWhere((p) => p.id == plan.id);
        if (existingIndex >= 0) {
          _trainingPlans[existingIndex] = plan;
        } else {
          _trainingPlans.add(plan);
        }
      }

      // Im Speicher sichern
      await _trainingPlanService.saveTrainingPlans(_trainingPlans);
      print(
          'Trainingsplan "${plan.name}" (ID: ${plan.id}) erfolgreich gespeichert');

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
      // Alle Pläne deaktivieren und nur den mit der angegebenen ID aktivieren
      _trainingPlans = _trainingPlans
          .map((p) => p.copyWith(isActive: p.id == planId))
          .toList();

      // Im Speicher sichern
      await _trainingPlanService.saveTrainingPlans(_trainingPlans);
      print('Trainingsplan (ID: $planId) erfolgreich aktiviert');

      notifyListeners();
      return true;
    } catch (e) {
      print('Fehler beim Aktivieren des Trainingsplans: $e');
      return false;
    }
  }

  // Trainingsplan löschen mit kaskadierender Löschung
  Future<bool> deleteTrainingPlan(String planId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Überprüfen, ob der Plan der aktive Plan ist
      final isActivePlan =
          _trainingPlans.any((p) => p.id == planId && p.isActive);

      // Plan-Name für besseres Logging speichern
      final planName = _trainingPlans
          .firstWhere((p) => p.id == planId,
              orElse: () =>
                  TrainingPlanModel(id: planId, name: "Unbekannt", days: []))
          .name;

      // Zuerst in Firestore löschen (und alle abhängigen Trainingshistorien)
      final firestoreSuccess = await _trainingPlanService.deletePlan(planId);

      if (!firestoreSuccess) {
        print(
            'Warnung: Plan "$planName" (ID: $planId) konnte nicht aus Firestore gelöscht werden');
      }

      // Dann aus lokaler Liste entfernen
      _trainingPlans.removeWhere((p) => p.id == planId);
      print('Trainingsplan "$planName" (ID: $planId) erfolgreich gelöscht');

      // Lokalen Speicher aktualisieren
      await _trainingPlanService.saveTrainingPlans(_trainingPlans);

      // Wenn der gelöschte Plan der aktive war und es andere Pläne gibt, den ersten aktivieren
      if (isActivePlan && _trainingPlans.isNotEmpty) {
        await activateTrainingPlan(_trainingPlans.first.id);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Fehler beim Löschen des Trainingsplans: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Manuelles Neuladen der Trainingspläne
  Future<void> refreshTrainingPlans() async {
    print('Manuelles Neuladen der Trainingspläne gestartet');
    await _loadTrainingPlans();
  }
}
