import 'package:flutter/foundation.dart';
import '../../models/progression_manager_screen/progression_profile_model.dart';
import '../../models/progression_manager_screen/progression_rule_model.dart';
import '../../models/progression_manager_screen/progression_condition_model.dart';
import '../../models/progression_manager_screen/progression_action_model.dart';
import '../../services/progression_manager_screen/firestore_profile_service.dart';
import '../../services/training_plan_screen/training_plan_service.dart';
import 'progression_ui_provider.dart';

/// Provider für Progressionsprofile
/// Verantwortlich für Laden, Speichern und Bearbeiten von Profilen
class ProgressionProfileProvider with ChangeNotifier {
  // ===== STATE DECLARATIONS =====

  // Profileditor-Zustand
  ProgressionProfileModel? _bearbeitetesProfil;

  // Progressionsprofile
  List<ProgressionProfileModel> _progressionsProfile = [];

  // Firebase-Service für Profilspeicherung
  final FirestoreProfileService _profileStorageService =
      FirestoreProfileService();

  // Trainingsplan-Service für die Aktualisierung von Übungsreferenzen
  final TrainingPlanService _trainingPlanService = TrainingPlanService();

  // Flag, um zu verfolgen, ob gerade eine Speicheroperation läuft
  bool _isSaving = false;

  // ===== KONSTRUKTOR =====

  ProgressionProfileProvider() {
    _initializeProfiles();
  }

  // ===== GETTERS =====

  ProgressionProfileModel? get bearbeitetesProfil => _bearbeitetesProfil;
  List<ProgressionProfileModel> get progressionsProfile => _progressionsProfile;
  bool get isSaving => _isSaving;

  // ===== METHODEN =====

  // Hilfsmethode, um ein Profil anhand seiner ID zu erhalten
  ProgressionProfileModel? getProfileById(String? profileId) {
    if (profileId == null) return null;

    try {
      return _progressionsProfile.firstWhere((p) => p.id == profileId);
    } catch (e) {
      return _progressionsProfile.isNotEmpty
          ? _progressionsProfile.first
          : null;
    }
  }

  // VERBESSERTE METHODE: Laden gespeicherter Profile mit zuverlässigerer Benachrichtigung
  Future<void> loadSavedProfiles() async {
    try {
      print('Starte das Laden von Profilen aus Firestore...');

      // Zuerst die Standard-Profile an den Storage-Service übergeben
      FirestoreProfileService.setStandardProfiles(_progressionsProfile);
      print('Standardprofile an FirestoreProfileService übergeben');

      // Gespeicherte Profile (inklusive Standard-Profile) laden
      final savedProfiles = await _profileStorageService.loadProfiles();

      // Wichtig: Lokale Liste aktualisieren bevor notifyListeners aufgerufen wird
      _progressionsProfile = savedProfiles;
      print('${savedProfiles.length} Profile aus Firestore geladen');

      // Explizite Benachrichtigung an alle Listeners
      notifyListeners();
      print('UI über neu geladene Profile benachrichtigt');
    } catch (e) {
      print('Fehler beim Laden der gespeicherten Profile: $e');
    }
  }

  // Methode zum Speichern der Profile mit verbesserten Fehlermeldungen und Retry-Logik
  Future<bool> saveProfiles() async {
    if (_isSaving) {
      print('Eine Speicheroperation läuft bereits, überspringe diesen Aufruf');
      return false;
    }

    _isSaving = true;

    try {
      print('Starte das Speichern von Profilen in Firestore...');

      // Maximale Anzahl von Versuchen
      const maxRetries = 3;
      int retryCount = 0;
      bool success = false;

      while (!success && retryCount < maxRetries) {
        try {
          await _profileStorageService.saveProfiles(_progressionsProfile);
          success = true;
          print('Profile erfolgreich in Firestore gespeichert');
        } catch (firestoreError) {
          retryCount++;
          print(
              'Fehler beim Speichern in Firestore (Versuch $retryCount/$maxRetries): $firestoreError');

          if (retryCount < maxRetries) {
            // Kurze Verzögerung vor dem nächsten Versuch
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
          }
        }
      }

      if (!success) {
        print('Alle Versuche zum Speichern der Profile sind fehlgeschlagen');
        return false;
      }

      return true;
    } catch (e) {
      print('Allgemeiner Fehler beim Speichern der Profile: $e');
      return false;
    } finally {
      _isSaving = false;
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

  void handleConfigChange(String key, dynamic value,
      ProgressionProfileModel? aktuellesProfil) async {
    if (aktuellesProfil == null) return;

    final newValue = double.tryParse(value.toString());
    if (newValue == null) return;

    _progressionsProfile = _progressionsProfile.map((profil) {
      if (profil.id == aktuellesProfil.id) {
        final updatedConfig = Map<String, dynamic>.from(profil.config);
        updatedConfig[key] = newValue;
        return profil.copyWith(config: updatedConfig);
      }
      return profil;
    }).toList();

    // Konfigurationsänderungen speichern
    await saveProfiles();

    // Refreshe die Profile von Firestore, um sicherzustellen, dass alles aktuell ist
    await loadSavedProfiles();

    notifyListeners();
  }

  void openProfileEditor(
      ProgressionProfileModel? profil, ProgressionUIProvider uiProvider) {
    if (profil != null) {
      _bearbeitetesProfil = profil.copyWith();
    } else {
      // Hier wird ein leeres Profil erstellt - rules sollte eine leere Liste sein
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

  // VERBESSERTE METHODE: saveProfile mit zuverlässigerer UI-Aktualisierung
  Future<void> saveProfile(ProgressionUIProvider uiProvider) async {
    if (_bearbeitetesProfil == null) return;

    try {
      print('Starte Speichern des Profils: ${_bearbeitetesProfil!.id}');

      // Lokale Kopie des zu bearbeitenden Profils erstellen, bevor wir die UI schließen
      final profilToSave = _bearbeitetesProfil!;

      // UI-Status aktualisieren vor dem Speichern in Firebase
      final existingIndex =
          _progressionsProfile.indexWhere((p) => p.id == profilToSave.id);

      List<ProgressionProfileModel> updatedProfiles =
          List.from(_progressionsProfile);
      if (existingIndex != -1) {
        updatedProfiles[existingIndex] = profilToSave;
        print(
            'Bestehendes Profil in lokaler Liste aktualisiert: ${profilToSave.id}');
      } else {
        updatedProfiles.add(profilToSave);
        print('Neues Profil zur lokalen Liste hinzugefügt: ${profilToSave.id}');
      }

      // Lokale Liste aktualisieren und UI benachrichtigen
      _progressionsProfile = updatedProfiles;

      // UI-Zustand zurücksetzen
      _bearbeitetesProfil = null;
      uiProvider.hideProfileEditor();

      // Sofortige UI-Benachrichtigung vor Speicherung
      notifyListeners();
      print('UI mit lokalen Änderungen aktualisiert');

      // Dann in Firebase speichern
      bool saved = await saveProfiles();
      if (!saved) {
        print('Fehler beim Speichern des Profils in Firebase');
      } else {
        print('Profil erfolgreich in Firebase gespeichert');
      }

      // Profile erneut aus Firebase laden
      await loadSavedProfiles();
      print('Profile nach dem Speichern aus Firebase neu geladen');

      // Nochmal benachrichtigen, falls Firebase-Daten anders sein sollten
      notifyListeners();
      print('UI nach Firebase-Synchronisierung erneut aktualisiert');
    } catch (e) {
      print('Fehler beim Speichern des Profils: $e');
    }
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

  // VERBESSERTE METHODE: Methode zum Löschen eines Profils mit verbesserten Benachrichtigungen
  Future<void> deleteProfile(String profileId) async {
    try {
      // Standard-Profile können nicht gelöscht werden
      if (profileId == 'double-progression' ||
          profileId == 'linear-periodization' ||
          profileId == 'rir-based' ||
          profileId == 'set-consistency') {
        print('Standard-Profile können nicht gelöscht werden');
        return;
      }

      final profilIndex =
          _progressionsProfile.indexWhere((p) => p.id == profileId);
      if (profilIndex == -1) {
        print('Profil mit ID $profileId nicht gefunden');
        return;
      }

      print('Starte Löschung des Profils: $profileId');

      // UI sofort aktualisieren, bevor Firebase-Operationen beginnen
      List<ProgressionProfileModel> updatedProfiles =
          List.from(_progressionsProfile);
      updatedProfiles.removeAt(profilIndex);
      _progressionsProfile = updatedProfiles;

      // UI benachrichtigen
      notifyListeners();
      print('Profil aus lokaler Liste entfernt und UI benachrichtigt');

      // VERBESSERT: Zuerst alle Übungen aktualisieren, die dieses Profil verwenden
      print('Aktualisiere Übungen, die Profil $profileId verwenden...');
      final success = await _trainingPlanService
          .updateExercisesAfterProfileDeletion(profileId);

      if (!success) {
        print(
            'Fehler beim Aktualisieren der Übungen. Vorgang wird trotzdem fortgesetzt.');
      }

      // Änderungen in Firebase speichern
      bool saved = await saveProfiles();
      if (!saved) {
        print('Fehler beim Speichern der Änderungen in Firebase');
      } else {
        print('Änderungen erfolgreich in Firebase gespeichert');
      }

      // Profile neu laden
      await loadSavedProfiles();
      print('Profile nach dem Löschen neu geladen');

      // Zusätzliche Benachrichtigung nach dem Neuladen
      notifyListeners();
      print('Profil erfolgreich gelöscht und UI final aktualisiert');
    } catch (e) {
      print('Fehler beim Löschen des Profils: $e');

      // Bei Fehler Profile neu laden, um konsistenten Zustand sicherzustellen
      await loadSavedProfiles();
      notifyListeners();
    }
  }
}
