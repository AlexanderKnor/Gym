import 'package:flutter/foundation.dart';
import '../../models/progression_manager_screen/progression_profile_model.dart';
import '../../models/progression_manager_screen/progression_rule_model.dart';
import '../../models/progression_manager_screen/progression_condition_model.dart';
import '../../models/progression_manager_screen/progression_action_model.dart';
import '../../services/progression_manager_screen/firestore_profile_service.dart';
import '../../services/training_plan_screen/training_plan_service.dart'; // Neu importiert
import 'progression_ui_provider.dart';

/// Provider für Progressionsprofile
/// Verantwortlich für Laden, Speichern und Bearbeiten von Profilen
class ProgressionProfileProvider with ChangeNotifier {
  // ===== STATE DECLARATIONS =====

  String _aktivesProgressionsProfil = 'double-progression';
  Map<String, dynamic> _progressionsConfig = {
    'targetRepsMin': 8,
    'targetRepsMax': 10,
    'targetRIRMin': 1,
    'targetRIRMax': 2,
    'increment': 2.5,
  };

  // Profileditor-Zustand
  ProgressionProfileModel? _bearbeitetesProfil;

  // Progressionsprofile
  List<ProgressionProfileModel> _progressionsProfile = [];

  // Hilfsvariable zum Tracken von Profilwechseln
  bool _profilWurdeGewechselt = false;

  // Firebase-Service für Profilspeicherung
  final FirestoreProfileService _profileStorageService =
      FirestoreProfileService();

  // Trainingsplan-Service für die Aktualisierung von Übungsreferenzen
  final TrainingPlanService _trainingPlanService = TrainingPlanService();

  // ===== KONSTRUKTOR =====

  ProgressionProfileProvider() {
    _initializeProfiles();
  }

  // ===== GETTERS =====

  String get aktivesProgressionsProfil => _aktivesProgressionsProfil;
  Map<String, dynamic> get progressionsConfig => _progressionsConfig;
  ProgressionProfileModel? get bearbeitetesProfil => _bearbeitetesProfil;
  List<ProgressionProfileModel> get progressionsProfile => _progressionsProfile;
  bool get profilWurdeGewechselt => _profilWurdeGewechselt;

  ProgressionProfileModel? get aktuellesProfil {
    try {
      return _progressionsProfile
          .firstWhere((p) => p.id == _aktivesProgressionsProfil);
    } catch (e) {
      return _progressionsProfile.isNotEmpty
          ? _progressionsProfile.first
          : null;
    }
  }

  // ===== METHODEN =====

  // Methode zum Laden gespeicherter Profile - AKTUALISIERT FÜR FIREBASE
  Future<void> loadSavedProfiles() async {
    try {
      print('Starte das Laden von Profilen aus Firestore...');

      // Zuerst die Standard-Profile an den Storage-Service übergeben
      FirestoreProfileService.setStandardProfiles(_progressionsProfile);
      print('Standardprofile an FirestoreProfileService übergeben');

      // Gespeicherte Profile (inklusive Standard-Profile) laden
      final savedProfiles = await _profileStorageService.loadProfiles();
      _progressionsProfile = savedProfiles;
      print('${savedProfiles.length} Profile aus Firestore geladen');

      // Aktives Profil laden
      final savedActiveProfileId =
          await _profileStorageService.loadActiveProfile();
      if (savedActiveProfileId.isNotEmpty) {
        _aktivesProgressionsProfil = savedActiveProfileId;
        print('Aktives Profil gesetzt: $_aktivesProgressionsProfil');

        // Konfiguration des aktiven Profils laden
        final aktivProfil = _progressionsProfile.firstWhere(
          (p) => p.id == _aktivesProgressionsProfil,
          orElse: () => _progressionsProfile.first,
        );
        _progressionsConfig = Map.from(aktivProfil.config);
        print('Profilkonfiguration geladen: $_progressionsConfig');
      }

      notifyListeners();
      print('Profile erfolgreich geladen und UI aktualisiert');
    } catch (e) {
      print('Fehler beim Laden der gespeicherten Profile: $e');
    }
  }

  // Methode zum Speichern der Profile
  Future<bool> saveProfiles() async {
    try {
      print('Starte das Speichern von Profilen in Firestore...');
      await _profileStorageService.saveProfiles(_progressionsProfile);
      await _profileStorageService
          .saveActiveProfile(_aktivesProgressionsProfil);
      print('Profile und aktives Profil erfolgreich in Firestore gespeichert');
      return true;
    } catch (e) {
      print('Fehler beim Speichern der Profile: $e');
      return false;
    }
  }

  void _initializeProfiles() {
    final doubleProgressionProfile = ProgressionProfileModel(
      id: 'double-progression',
      name: 'Doppelte Progression',
      description: 'Erhöhe Wiederholungen bis zum Maximum, dann erhöhe Gewicht',
      config: {
        'targetRepsMin': 8,
        'targetRepsMax': 10,
        'targetRIRMin': 1,
        'targetRIRMax': 2,
        'increment': 2.5,
      },
      rules: _createDoubleProgressionRules(),
    );

    final linearPeriodizationProfile = ProgressionProfileModel(
      id: 'linear-periodization',
      name: 'Lineare Periodisierung',
      description: 'Gewicht steigt, Wiederholungen nehmen ab',
      config: {
        'targetRepsMin': 6,
        'targetRepsMax': 8,
        'targetRIRMin': 1,
        'targetRIRMax': 3,
        'increment': 2.5,
      },
      rules: _createLinearPeriodizationRules(),
    );

    final rirBasedProfile = ProgressionProfileModel(
      id: 'rir-based',
      name: 'RIR-basiert',
      description: 'Progression basierend auf RIR-Werten',
      config: {
        'targetRepsMin': 6,
        'targetRepsMax': 12,
        'targetRIRMin': 0,
        'targetRIRMax': 2,
        'increment': 2.5,
      },
      rules: _createRirBasedRules(),
    );

    final setConsistencyProfile = ProgressionProfileModel(
      id: 'set-consistency',
      name: 'Satz-Konsistenz mit 1RM',
      description:
          'Vermeidet zu große Leistungsunterschiede zwischen Sätzen vor der linearen Progression',
      config: {
        'targetRepsMin': 8,
        'targetRepsMax': 10,
        'targetRIRMin': 1,
        'targetRIRMax': 2,
        'increment': 2.5,
      },
      rules: _createSetConsistencyRules(),
    );

    _progressionsProfile = [
      doubleProgressionProfile,
      linearPeriodizationProfile,
      rirBasedProfile,
      setConsistencyProfile,
    ];
  }

  // Regeln für doppelte Progression erstellen
  List<ProgressionRuleModel> _createDoubleProgressionRules() {
    return [
      // Regel 1: Wenn lastReps < targetRepsMax und lastRIR >= targetRIRMin
      ProgressionRuleModel(
        id: 'dp_rule1',
        type: 'condition',
        conditions: [
          ProgressionConditionModel(
            left: {'type': 'variable', 'value': 'lastReps'},
            operator: 'lt',
            right: {'type': 'variable', 'value': 'targetRepsMax'},
          ),
          ProgressionConditionModel(
            left: {'type': 'variable', 'value': 'lastRIR'},
            operator: 'gte',
            right: {'type': 'variable', 'value': 'targetRIRMin'},
          ),
        ],
        logicalOperator: 'AND',
        children: [
          ProgressionActionModel(
            id: 'dp_action1',
            type: 'assignment',
            target: 'kg',
            value: {'type': 'variable', 'value': 'lastKg'},
          ),
          ProgressionActionModel(
            id: 'dp_action2',
            type: 'assignment',
            target: 'reps',
            value: {
              'type': 'operation',
              'left': {'type': 'variable', 'value': 'lastReps'},
              'operator': 'add',
              'right': {'type': 'constant', 'value': 1},
            },
          ),
          ProgressionActionModel(
            id: 'dp_action3',
            type: 'assignment',
            target: 'rir',
            value: {'type': 'variable', 'value': 'lastRIR'},
          ),
        ],
      ),

      // Regel 2: Wenn lastReps >= targetRepsMax und lastRIR >= targetRIRMin
      ProgressionRuleModel(
        id: 'dp_rule2',
        type: 'condition',
        conditions: [
          ProgressionConditionModel(
            left: {'type': 'variable', 'value': 'lastReps'},
            operator: 'gte',
            right: {'type': 'variable', 'value': 'targetRepsMax'},
          ),
          ProgressionConditionModel(
            left: {'type': 'variable', 'value': 'lastRIR'},
            operator: 'gte',
            right: {'type': 'variable', 'value': 'targetRIRMin'},
          ),
        ],
        logicalOperator: 'AND',
        children: [
          ProgressionActionModel(
            id: 'dp_action4',
            type: 'assignment',
            target: 'kg',
            value: {'type': 'oneRM', 'percentage': 2.5},
          ),
          ProgressionActionModel(
            id: 'dp_action5',
            type: 'assignment',
            target: 'reps',
            value: {'type': 'variable', 'value': 'targetRepsMin'},
          ),
          ProgressionActionModel(
            id: 'dp_action6',
            type: 'assignment',
            target: 'rir',
            value: {'type': 'variable', 'value': 'targetRIRMax'},
          ),
        ],
      ),

      // Regel 3: Wenn lastRIR < targetRIRMin
      ProgressionRuleModel(
        id: 'dp_rule3',
        type: 'condition',
        conditions: [
          ProgressionConditionModel(
            left: {'type': 'variable', 'value': 'lastRIR'},
            operator: 'lt',
            right: {'type': 'variable', 'value': 'targetRIRMin'},
          ),
        ],
        logicalOperator: 'AND',
        children: [
          ProgressionActionModel(
            id: 'dp_action7',
            type: 'assignment',
            target: 'kg',
            value: {'type': 'variable', 'value': 'lastKg'},
          ),
          ProgressionActionModel(
            id: 'dp_action8',
            type: 'assignment',
            target: 'reps',
            value: {'type': 'variable', 'value': 'lastReps'},
          ),
          ProgressionActionModel(
            id: 'dp_action9',
            type: 'assignment',
            target: 'rir',
            value: {'type': 'variable', 'value': 'targetRIRMin'},
          ),
        ],
      ),
    ];
  }

  // Regeln für lineare Periodisierung erstellen
  List<ProgressionRuleModel> _createLinearPeriodizationRules() {
    return [
      // Gewicht erhöhen
      ProgressionRuleModel(
        id: 'lp_rule1',
        type: 'assignment',
        children: [
          ProgressionActionModel(
            id: 'lp_action1',
            type: 'assignment',
            target: 'kg',
            value: {
              'type': 'operation',
              'left': {'type': 'variable', 'value': 'lastKg'},
              'operator': 'add',
              'right': {'type': 'variable', 'value': 'increment'},
            },
          ),
        ],
      ),
      // Wiederholungen verringern
      ProgressionRuleModel(
        id: 'lp_rule2',
        type: 'assignment',
        children: [
          ProgressionActionModel(
            id: 'lp_action2',
            type: 'assignment',
            target: 'reps',
            value: {
              'type': 'operation',
              'left': {'type': 'variable', 'value': 'lastReps'},
              'operator': 'subtract',
              'right': {'type': 'constant', 'value': 1},
            },
          ),
        ],
      ),
      // RIR beibehalten
      ProgressionRuleModel(
        id: 'lp_rule3',
        type: 'assignment',
        children: [
          ProgressionActionModel(
            id: 'lp_action3',
            type: 'assignment',
            target: 'rir',
            value: {'type': 'variable', 'value': 'lastRIR'},
          ),
        ],
      ),
    ];
  }

  // Regeln für RIR-basiertes Profil erstellen
  List<ProgressionRuleModel> _createRirBasedRules() {
    return [
      // Regel 1: Wenn lastRIR == 0
      ProgressionRuleModel(
        id: 'rir_rule1',
        type: 'condition',
        conditions: [
          ProgressionConditionModel(
            left: {'type': 'variable', 'value': 'lastRIR'},
            operator: 'eq',
            right: {'type': 'constant', 'value': 0},
          ),
        ],
        logicalOperator: 'AND',
        children: [
          ProgressionActionModel(
            id: 'rir_action1',
            type: 'assignment',
            target: 'kg',
            value: {'type': 'variable', 'value': 'lastKg'},
          ),
          ProgressionActionModel(
            id: 'rir_action2',
            type: 'assignment',
            target: 'reps',
            value: {'type': 'variable', 'value': 'lastReps'},
          ),
          ProgressionActionModel(
            id: 'rir_action3',
            type: 'assignment',
            target: 'rir',
            value: {'type': 'constant', 'value': 1},
          ),
        ],
      ),
      // Regel 2: Wenn lastRIR > targetRIRMax
      ProgressionRuleModel(
        id: 'rir_rule2',
        type: 'condition',
        conditions: [
          ProgressionConditionModel(
            left: {'type': 'variable', 'value': 'lastRIR'},
            operator: 'gt',
            right: {'type': 'variable', 'value': 'targetRIRMax'},
          ),
        ],
        logicalOperator: 'AND',
        children: [
          ProgressionActionModel(
            id: 'rir_action4',
            type: 'assignment',
            target: 'kg',
            value: {
              'type': 'operation',
              'left': {'type': 'variable', 'value': 'lastKg'},
              'operator': 'add',
              'right': {'type': 'variable', 'value': 'increment'},
            },
          ),
          ProgressionActionModel(
            id: 'rir_action5',
            type: 'assignment',
            target: 'reps',
            value: {'type': 'variable', 'value': 'lastReps'},
          ),
          ProgressionActionModel(
            id: 'rir_action6',
            type: 'assignment',
            target: 'rir',
            value: {
              'type': 'operation',
              'left': {'type': 'variable', 'value': 'lastRIR'},
              'operator': 'subtract',
              'right': {'type': 'constant', 'value': 1},
            },
          ),
        ],
      ),
    ];
  }

  // Regeln für Satz-Konsistenz erstellen
  List<ProgressionRuleModel> _createSetConsistencyRules() {
    return [
      // Regel 1: Wenn last1RM > previous1RM
      ProgressionRuleModel(
        id: 'sc_rule1',
        type: 'condition',
        conditions: [
          ProgressionConditionModel(
            left: {'type': 'variable', 'value': 'last1RM'},
            operator: 'gt',
            right: {'type': 'variable', 'value': 'previous1RM'},
          ),
        ],
        logicalOperator: 'AND',
        children: [
          ProgressionActionModel(
            id: 'sc_action1',
            type: 'assignment',
            target: 'kg',
            value: {'type': 'variable', 'value': 'previousKg'},
          ),
          ProgressionActionModel(
            id: 'sc_action2',
            type: 'assignment',
            target: 'reps',
            value: {'type': 'variable', 'value': 'previousReps'},
          ),
          ProgressionActionModel(
            id: 'sc_action3',
            type: 'assignment',
            target: 'rir',
            value: {'type': 'variable', 'value': 'previousRIR'},
          ),
        ],
      ),
      // Regel 2: Wenn last1RM == previous1RM
      ProgressionRuleModel(
        id: 'sc_rule2',
        type: 'condition',
        conditions: [
          ProgressionConditionModel(
            left: {'type': 'variable', 'value': 'last1RM'},
            operator: 'eq',
            right: {'type': 'variable', 'value': 'previous1RM'},
          ),
        ],
        logicalOperator: 'AND',
        children: [
          ProgressionActionModel(
            id: 'sc_action4',
            type: 'assignment',
            target: 'kg',
            value: {'type': 'variable', 'value': 'lastKg'},
          ),
          ProgressionActionModel(
            id: 'sc_action5',
            type: 'assignment',
            target: 'reps',
            value: {'type': 'variable', 'value': 'lastReps'},
          ),
          ProgressionActionModel(
            id: 'sc_action6',
            type: 'assignment',
            target: 'rir',
            value: {'type': 'variable', 'value': 'lastRIR'},
          ),
        ],
      ),
      // Regel 3: Wenn lastReps <= targetRepsMax
      ProgressionRuleModel(
        id: 'sc_rule3',
        type: 'condition',
        conditions: [
          ProgressionConditionModel(
            left: {'type': 'variable', 'value': 'lastReps'},
            operator: 'lte',
            right: {'type': 'variable', 'value': 'targetRepsMax'},
          ),
        ],
        logicalOperator: 'AND',
        children: [
          ProgressionActionModel(
            id: 'sc_action7',
            type: 'assignment',
            target: 'kg',
            value: {'type': 'variable', 'value': 'lastKg'},
          ),
          ProgressionActionModel(
            id: 'sc_action8',
            type: 'assignment',
            target: 'reps',
            value: {
              'type': 'operation',
              'left': {'type': 'variable', 'value': 'lastReps'},
              'operator': 'add',
              'right': {'type': 'constant', 'value': 1},
            },
          ),
          ProgressionActionModel(
            id: 'sc_action9',
            type: 'assignment',
            target: 'rir',
            value: {'type': 'variable', 'value': 'lastRIR'},
          ),
        ],
      ),
    ];
  }

  void wechsleProgressionsProfil(String profilId) {
    _aktivesProgressionsProfil = profilId;

    final profil = _progressionsProfile.firstWhere(
      (p) => p.id == profilId,
      orElse: () => _progressionsProfile.first,
    );

    _progressionsConfig = Map.from(profil.config);
    _profilWurdeGewechselt = true;

    // Profil-Änderung speichern
    saveProfiles();

    notifyListeners();

    // Flag zurücksetzen
    _profilWurdeGewechselt = false;
  }

  void handleConfigChange(
      String key, dynamic value, ProgressionProfileModel? aktuellesProfil) {
    final newValue = double.tryParse(value.toString());
    if (newValue == null) return;

    _progressionsConfig[key] = newValue;

    _progressionsProfile = _progressionsProfile.map((profil) {
      if (profil.id == _aktivesProgressionsProfil) {
        final updatedConfig = Map<String, dynamic>.from(profil.config);
        updatedConfig[key] = newValue;
        return profil.copyWith(config: updatedConfig);
      }
      return profil;
    }).toList();

    // Konfigurationsänderungen speichern
    saveProfiles();

    notifyListeners();
  }

  void openProfileEditor(
      ProgressionProfileModel? profil, ProgressionUIProvider uiProvider) {
    if (profil != null) {
      _bearbeitetesProfil = profil.copyWith();
    } else {
      _bearbeitetesProfil = ProgressionProfileModel.empty(
          'profile_${DateTime.now().millisecondsSinceEpoch}');
    }

    uiProvider.showProfileEditor();
    notifyListeners();
  }

  void closeProfileEditor(ProgressionUIProvider uiProvider) {
    _bearbeitetesProfil = null;
    uiProvider.hideProfileEditor();
    notifyListeners();
  }

  void updateProfile(String feld, dynamic wert) {
    if (_bearbeitetesProfil == null) return;

    switch (feld) {
      case 'name':
        _bearbeitetesProfil = _bearbeitetesProfil!.copyWith(name: wert);
        break;
      case 'description':
        _bearbeitetesProfil = _bearbeitetesProfil!.copyWith(description: wert);
        break;
      default:
        if (feld.startsWith('config.')) {
          final configKey = feld.substring(7);
          final newValue = double.tryParse(wert.toString());
          if (newValue != null) {
            final updatedConfig =
                Map<String, dynamic>.from(_bearbeitetesProfil!.config);
            updatedConfig[configKey] = newValue;
            _bearbeitetesProfil =
                _bearbeitetesProfil!.copyWith(config: updatedConfig);
          }
        }
    }

    notifyListeners();
  }

  void saveProfile(ProgressionUIProvider uiProvider) {
    if (_bearbeitetesProfil == null) return;

    final existingIndex =
        _progressionsProfile.indexWhere((p) => p.id == _bearbeitetesProfil!.id);

    if (existingIndex != -1) {
      _progressionsProfile[existingIndex] = _bearbeitetesProfil!;
    } else {
      _progressionsProfile.add(_bearbeitetesProfil!);
    }

    _aktivesProgressionsProfil = _bearbeitetesProfil!.id;
    _progressionsConfig = Map.from(_bearbeitetesProfil!.config);
    _profilWurdeGewechselt = true;

    // Profil-Änderungen speichern
    saveProfiles();

    uiProvider.hideProfileEditor();
    _bearbeitetesProfil = null;
    notifyListeners();

    // Flag zurücksetzen
    _profilWurdeGewechselt = false;
  }

  void duplicateProfile(String profilId, ProgressionUIProvider uiProvider) {
    final originalIndex =
        _progressionsProfile.indexWhere((p) => p.id == profilId);
    if (originalIndex == -1) return;

    final original = _progressionsProfile[originalIndex];

    final newId =
        '${original.id}-copy-${DateTime.now().millisecondsSinceEpoch}';
    final newName = '${original.name} Kopie';

    final copy = original.copyWith(
      id: newId,
      name: newName,
    );

    openProfileEditor(copy, uiProvider);
  }

  // Methode zum Löschen eines Profils - ÜBERARBEITET
  Future<void> deleteProfile(String profileId) async {
    try {
      // Standard-Profile können nicht gelöscht werden
      if (profileId == 'double-progression' ||
          profileId == 'linear-periodization' ||
          profileId == 'rir-based' ||
          profileId == 'set-consistency') {
        return;
      }

      final profilIndex =
          _progressionsProfile.indexWhere((p) => p.id == profileId);
      if (profilIndex == -1) return;

      // NEUER CODE: Zuerst alle Übungen aktualisieren, die dieses Profil verwenden
      print('Aktualisiere Übungen, die Profil $profileId verwenden...');
      await _trainingPlanService.updateExercisesAfterProfileDeletion(profileId);

      // Profil aus der Liste entfernen
      _progressionsProfile.removeAt(profilIndex);

      // Wenn das aktive Profil gelöscht wurde, zum ersten Profil wechseln
      if (profileId == _aktivesProgressionsProfil) {
        _aktivesProgressionsProfil = _progressionsProfile.first.id;
        _progressionsConfig = Map.from(_progressionsProfile.first.config);
        _profilWurdeGewechselt = true;
      }

      // Änderungen speichern
      await saveProfiles();

      notifyListeners();

      // Flag zurücksetzen
      _profilWurdeGewechselt = false;

      print('Profil erfolgreich gelöscht und Übungen aktualisiert');
    } catch (e) {
      print('Fehler beim Löschen des Profils: $e');
    }
  }
}
