import 'package:flutter/foundation.dart';
import '../../models/progression_manager_screen/training_set_model.dart';
import '../../models/progression_manager_screen/progression_profile_model.dart';
import '../../models/progression_manager_screen/progression_rule_model.dart';
import '../../models/progression_manager_screen/progression_condition_model.dart';
import '../../models/progression_manager_screen/progression_action_model.dart';
import '../../models/progression_manager_screen/progression_variable_model.dart';
import '../../models/progression_manager_screen/progression_operator_model.dart';
import '../../services/progression_manager_screen/one_rm_calculator_service.dart';
import '../../services/progression_manager_screen/rule_evaluator_service.dart';
import '../../services/progression_manager_screen/progression_calculator_service.dart';
import '../../services/progression_manager_screen/firestore_profile_service.dart';

class ProgressionManagerProvider extends ChangeNotifier {
  // ===== STATE DECLARATIONS =====

  // Training-Tracking States
  List<TrainingSetModel> _saetze = [
    TrainingSetModel(id: 1, kg: 80, wiederholungen: 8, rir: 2),
    TrainingSetModel(id: 2, kg: 85, wiederholungen: 6, rir: 1),
    TrainingSetModel(id: 3, kg: 87.5, wiederholungen: 5, rir: 1),
    TrainingSetModel(id: 4, kg: 75, wiederholungen: 8, rir: 3),
  ];
  int _aktiverSatz = 1;
  bool _trainingAbgeschlossen = false;

  // Progressions-Manager States
  bool _zeigePQB = false;
  String _aktivesProgressionsProfil = 'double-progression';
  Map<String, dynamic> _progressionsConfig = {
    'targetRepsMin': 8,
    'targetRepsMax': 10,
    'targetRIRMin': 1,
    'targetRIRMax': 2,
    'increment': 2.5,
  };

  // Regeleditor-Zustand
  bool _zeigeRegelEditor = false;
  ProgressionRuleModel? _bearbeiteteRegel;
  String _regelTyp = 'condition'; // 'condition' oder 'assignment'
  List<ProgressionConditionModel> _regelBedingungen = [
    ProgressionConditionModel(
      left: {'type': 'variable', 'value': 'lastReps'},
      operator: 'lt',
      right: {'type': 'constant', 'value': 10},
    ),
  ];

  // Aktionswerte für Regeleditor
  Map<String, dynamic> _kgAktion = {
    'type': 'direct',
    'variable': 'lastKg',
    'operator': 'add',
    'value': 2.5,
    'valueType': 'constant', // 'constant' oder 'config'
    'rmPercentage': 2.5,
  };

  Map<String, dynamic> _repsAktion = {
    'variable': 'lastReps',
    'operator': 'add',
    'value': 1,
  };

  Map<String, dynamic> _rirAktion = {
    'variable': 'lastRIR',
    'operator': 'none',
    'value': 0,
  };

  // Profileditor-Zustand
  bool _zeigeProfilEditor = false;
  ProgressionProfileModel? _bearbeitetesProfil;

  // Drag-and-Drop-Zustand
  String? _draggedRuleId;
  String? _dragOverRuleId;

  // Neue Regel
  ProgressionRuleModel _neueRegel = ProgressionRuleModel(
    id: 'rule_${DateTime.now().millisecondsSinceEpoch}',
    type: 'condition',
    conditions: [
      ProgressionConditionModel(
        left: {'type': 'variable', 'value': 'lastReps'},
        operator: 'lt',
        right: {'type': 'constant', 'value': 10},
      ),
    ],
    logicalOperator: 'AND',
    children: [],
  );

  // ===== CONSTANTS =====

  // Verfügbare Variablen
  final List<ProgressionVariableModel> _verfuegbareVariablen = [
    ProgressionVariableModel(
        id: 'lastKg', label: 'Letztes Gewicht', type: 'number'),
    ProgressionVariableModel(
        id: 'lastReps', label: 'Letzte Wiederholungen', type: 'number'),
    ProgressionVariableModel(
        id: 'lastRIR', label: 'Letzter RIR', type: 'number'),
    ProgressionVariableModel(
        id: 'last1RM', label: 'Letzter 1RM', type: 'number'),
    ProgressionVariableModel(
        id: 'previousKg', label: 'Vorheriges Gewicht', type: 'number'),
    ProgressionVariableModel(
        id: 'previousReps', label: 'Vorherige Wiederholungen', type: 'number'),
    ProgressionVariableModel(
        id: 'previousRIR', label: 'Vorheriger RIR', type: 'number'),
    ProgressionVariableModel(
        id: 'previous1RM', label: 'Vorheriger 1RM', type: 'number'),
    ProgressionVariableModel(
        id: 'targetRepsMin', label: 'Ziel Wdh. Min', type: 'number'),
    ProgressionVariableModel(
        id: 'targetRepsMax', label: 'Ziel Wdh. Max', type: 'number'),
    ProgressionVariableModel(
        id: 'targetRIRMin', label: 'Ziel RIR Min', type: 'number'),
    ProgressionVariableModel(
        id: 'targetRIRMax', label: 'Ziel RIR Max', type: 'number'),
    ProgressionVariableModel(
        id: 'increment', label: 'Std. Steigerung', type: 'number'),
  ];

  // Verfügbare Operatoren
  final List<ProgressionOperatorModel> _verfuegbareOperatoren = [
    ProgressionOperatorModel(id: 'eq', label: '=', type: 'comparison'),
    ProgressionOperatorModel(id: 'gt', label: '>', type: 'comparison'),
    ProgressionOperatorModel(id: 'lt', label: '<', type: 'comparison'),
    ProgressionOperatorModel(id: 'gte', label: '>=', type: 'comparison'),
    ProgressionOperatorModel(id: 'lte', label: '<=', type: 'comparison'),
    ProgressionOperatorModel(id: 'add', label: '+', type: 'math'),
    ProgressionOperatorModel(id: 'subtract', label: '-', type: 'math'),
    ProgressionOperatorModel(id: 'multiply', label: '*', type: 'math'),
  ];

  // Progressionsprofile
  List<ProgressionProfileModel> _progressionsProfile = [];

  // Firebase-Service für Profilspeicherung (NEU)
  final FirestoreProfileService _profileStorageService =
      FirestoreProfileService();

  // Konstruktor mit Initialisierung
  ProgressionManagerProvider() {
    _initializeProfiles();

    // Verzögert gespeicherte Profile laden
    Future.microtask(() async {
      await _loadSavedProfiles();

      // Für den ersten aktiven Satz die Empfehlung einmal berechnen
      berechneEmpfehlungFuerAktivenSatz();
    });
  }

  // ===== GETTERS =====

  List<TrainingSetModel> get saetze => _saetze;
  int get aktiverSatz => _aktiverSatz;
  bool get trainingAbgeschlossen => _trainingAbgeschlossen;
  bool get zeigePQB => _zeigePQB;
  String get aktivesProgressionsProfil => _aktivesProgressionsProfil;
  Map<String, dynamic> get progressionsConfig => _progressionsConfig;
  bool get zeigeRegelEditor => _zeigeRegelEditor;
  ProgressionRuleModel? get bearbeiteteRegel => _bearbeiteteRegel;
  String get regelTyp => _regelTyp;
  List<ProgressionConditionModel> get regelBedingungen => _regelBedingungen;
  Map<String, dynamic> get kgAktion => _kgAktion;
  Map<String, dynamic> get repsAktion => _repsAktion;
  Map<String, dynamic> get rirAktion => _rirAktion;
  bool get zeigeProfilEditor => _zeigeProfilEditor;
  ProgressionProfileModel? get bearbeitetesProfil => _bearbeitetesProfil;
  String? get draggedRuleId => _draggedRuleId;
  String? get dragOverRuleId => _dragOverRuleId;
  ProgressionRuleModel get neueRegel => _neueRegel;
  List<ProgressionVariableModel> get verfuegbareVariablen =>
      _verfuegbareVariablen;
  List<ProgressionOperatorModel> get verfuegbareOperatoren =>
      _verfuegbareOperatoren;
  List<ProgressionProfileModel> get progressionsProfile => _progressionsProfile;

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

  // ===== PROFIL PERSISTENZ METHODEN =====

  // Methode zum Laden gespeicherter Profile - AKTUALISIERT FÜR FIREBASE
  Future<void> _loadSavedProfiles() async {
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

  // Methode zum Speichern der Profile - AKTUALISIERT FÜR FIREBASE
  Future<void> _saveProfiles() async {
    try {
      print('Starte das Speichern von Profilen in Firestore...');
      await _profileStorageService.saveProfiles(_progressionsProfile);
      await _profileStorageService
          .saveActiveProfile(_aktivesProgressionsProfil);
      print('Profile und aktives Profil erfolgreich in Firestore gespeichert');
    } catch (e) {
      print('Fehler beim Speichern der Profile: $e');
    }
  }

  // ===== PROFILINITIALISIERUNG =====

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
    // Hier würde der bereits existierende Code für die Erstellung der Double-Progression-Regeln folgen
    // Ich belasse diesen Teil, da er unverändert bleibt
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
    // Existierender Code für die Erstellung der Linear-Periodization-Regeln
    // Bleibt unverändert
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
    // Existierender Code für die Erstellung der RIR-basierten Regeln
    // Bleibt unverändert
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
    // Existierender Code für die Erstellung der Set-Consistency-Regeln
    // Bleibt unverändert
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

  // ===== METHODEN FÜR TRAINING TRACKER =====

  void handleChange(int id, String feld, dynamic wert) {
    if (id != _aktiverSatz) return;

    final index = _saetze.indexWhere((satz) => satz.id == id);
    if (index == -1) return;

    final updatedSaetze = List<TrainingSetModel>.from(_saetze);

    switch (feld) {
      case 'kg':
        if (wert is String && wert.isEmpty) {
          // Leere Werte während der Bearbeitung zulassen
        } else {
          final neuerWert = double.tryParse(wert.toString()) ?? 0.0;
          updatedSaetze[index] = updatedSaetze[index].copyWith(kg: neuerWert);
        }
        break;
      case 'wiederholungen':
        if (wert is String && wert.isEmpty) {
          // Leere Werte während der Bearbeitung zulassen
        } else {
          final neuerWert = int.tryParse(wert.toString()) ?? 0;
          updatedSaetze[index] =
              updatedSaetze[index].copyWith(wiederholungen: neuerWert);
        }
        break;
      case 'rir':
        if (wert is String && wert.isEmpty) {
          // Leere Werte während der Bearbeitung zulassen
        } else {
          final neuerWert = int.tryParse(wert.toString()) ?? 0;
          updatedSaetze[index] = updatedSaetze[index].copyWith(rir: neuerWert);
        }
        break;
    }

    _saetze = updatedSaetze;
    notifyListeners();
  }

  void toggleProgressionManager() {
    _zeigePQB = !_zeigePQB;
    notifyListeners();
  }

  void wechsleProgressionsProfil(String profilId) {
    _aktivesProgressionsProfil = profilId;

    final profil = _progressionsProfile.firstWhere(
      (p) => p.id == profilId,
      orElse: () => _progressionsProfile.first,
    );

    _progressionsConfig = Map.from(profil.config);

    // Beim Profilwechsel für den aktiven Satz neue Empfehlung berechnen
    final aktiverSatzIndex =
        _saetze.indexWhere((satz) => satz.id == _aktiverSatz);
    if (aktiverSatzIndex != -1) {
      final updatedSaetze = List<TrainingSetModel>.from(_saetze);
      updatedSaetze[aktiverSatzIndex] =
          updatedSaetze[aktiverSatzIndex].copyWith(empfehlungBerechnet: false);
      _saetze = updatedSaetze;

      // Verzögert Empfehlung neu berechnen
      Future.microtask(() {
        berechneEmpfehlungFuerAktivenSatz();
      });
    }

    // Profil-Änderung speichern
    _saveProfiles();

    notifyListeners();
  }

  void handleConfigChange(String key, dynamic value) {
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

    // Bei Konfigurationsänderungen für den aktiven Satz Empfehlung zurücksetzen
    final aktiverSatzIndex =
        _saetze.indexWhere((satz) => satz.id == _aktiverSatz);
    if (aktiverSatzIndex != -1) {
      final updatedSaetze = List<TrainingSetModel>.from(_saetze);
      updatedSaetze[aktiverSatzIndex] =
          updatedSaetze[aktiverSatzIndex].copyWith(empfehlungBerechnet: false);
      _saetze = updatedSaetze;

      // Verzögert Empfehlung neu berechnen
      Future.microtask(() {
        berechneEmpfehlungFuerAktivenSatz();
      });
    }

    // Konfigurationsänderungen speichern
    _saveProfiles();

    notifyListeners();
  }

  double berechne1RM(double gewicht, int wiederholungen, int rir) {
    return OneRMCalculatorService.calculate1RM(gewicht, wiederholungen, rir);
  }

  Map<String, dynamic> berechneProgression(TrainingSetModel satz) {
    final profil = _progressionsProfile.firstWhere(
      (p) => p.id == _aktivesProgressionsProfil,
      orElse: () => _progressionsProfile.first,
    );

    return ProgressionCalculatorService.berechneProgression(
        satz, profil, _saetze);
  }

  // Berechnet die Empfehlung für den aktiven Satz (nur einmal)
  void berechneEmpfehlungFuerAktivenSatz({bool notify = true}) {
    final aktiverSatzIndex =
        _saetze.indexWhere((satz) => satz.id == _aktiverSatz);
    if (aktiverSatzIndex == -1) return;

    final aktiverSatz = _saetze[aktiverSatzIndex];

    // Nur berechnen, wenn noch nicht berechnet wurde
    if (!aktiverSatz.empfehlungBerechnet) {
      final empfehlung = ProgressionCalculatorService.berechneProgression(
          aktiverSatz, aktuellesProfil!, _saetze);

      final updatedSaetze = List<TrainingSetModel>.from(_saetze);
      updatedSaetze[aktiverSatzIndex] = aktiverSatz.copyWith(
        empfKg: empfehlung['kg'],
        empfWiederholungen: empfehlung['wiederholungen'],
        empfRir: empfehlung['rir'],
        empfehlungBerechnet: true,
      );

      _saetze = updatedSaetze;

      if (notify) {
        notifyListeners();
      }
    }
  }

  // Prüft, ob die Empfehlung angezeigt werden soll
  bool sollEmpfehlungAnzeigen(int satzId) {
    final satz =
        _saetze.firstWhere((s) => s.id == satzId, orElse: () => _saetze.first);

    // Keine Empfehlung anzeigen, wenn der Satz nicht aktiv ist
    if (satzId != _aktiverSatz || _trainingAbgeschlossen) return false;

    // Keine Empfehlung anzeigen, wenn noch keine berechnet wurde
    if (!satz.empfehlungBerechnet) return false;

    // Keine Empfehlung anzeigen, wenn alle Werte exakt der Empfehlung entsprechen
    if (satz.kg == satz.empfKg &&
        satz.wiederholungen == satz.empfWiederholungen &&
        satz.rir == satz.empfRir) {
      return false;
    }

    // Ansonsten Empfehlung anzeigen
    return true;
  }

  void empfehlungUebernehmen() {
    final aktiverSatzIndex =
        _saetze.indexWhere((satz) => satz.id == _aktiverSatz);
    if (aktiverSatzIndex == -1) return;

    final aktiverSatz = _saetze[aktiverSatzIndex];

    // Zuerst sicherstellen, dass eine Empfehlung berechnet wurde
    if (!aktiverSatz.empfehlungBerechnet) {
      berechneEmpfehlungFuerAktivenSatz();
      return; // Warten auf nächsten Render-Zyklus
    }

    // Dann die Empfehlung übernehmen
    final updatedSaetze = List<TrainingSetModel>.from(_saetze);
    updatedSaetze[aktiverSatzIndex] = aktiverSatz.copyWith(
      kg: aktiverSatz.empfKg ?? aktiverSatz.kg,
      wiederholungen:
          aktiverSatz.empfWiederholungen ?? aktiverSatz.wiederholungen,
      rir: aktiverSatz.empfRir ?? aktiverSatz.rir,
    );

    _saetze = updatedSaetze;
    notifyListeners();
  }

  void satzAbschliessen() {
    final aktiverSatzDaten = _saetze.firstWhere(
      (satz) => satz.id == _aktiverSatz,
      orElse: () => _saetze.first,
    );

    if (aktiverSatzDaten.kg <= 0 || aktiverSatzDaten.wiederholungen <= 0) {
      return;
    }

    _saetze = _saetze.map((satz) {
      if (satz.id == _aktiverSatz) {
        return satz.copyWith(abgeschlossen: true);
      }
      return satz;
    }).toList();

    if (_aktiverSatz < 4) {
      _aktiverSatz++;

      // Für neuen aktiven Satz nach kurzem Delay die Empfehlung berechnen
      Future.microtask(() {
        berechneEmpfehlungFuerAktivenSatz();
      });
    } else {
      _trainingAbgeschlossen = true;
    }

    notifyListeners();
  }

  void trainingZuruecksetzen() {
    // Sätze zurücksetzen und Empfehlungen löschen
    _saetze = _saetze
        .map((satz) => satz.copyWith(
              abgeschlossen: false,
              empfehlungBerechnet: false,
              empfKg: null,
              empfWiederholungen: null,
              empfRir: null,
            ))
        .toList();

    _aktiverSatz = 1;
    _trainingAbgeschlossen = false;

    // Für ersten Satz Empfehlung neu berechnen
    Future.microtask(() {
      berechneEmpfehlungFuerAktivenSatz();
    });

    notifyListeners();
  }

  // Neue Methode: Übung abschließen und zur nächsten übergehen oder dieselbe wiederholen
  void uebungAbschliessen({bool neueUebung = false}) {
    // Sätze zurücksetzen und Empfehlungen löschen
    _saetze = _saetze
        .map((satz) => satz.copyWith(
              abgeschlossen: false,
              empfehlungBerechnet: false,
              empfKg: null,
              empfWiederholungen: null,
              empfRir: null,
            ))
        .toList();

    _aktiverSatz = 1;
    _trainingAbgeschlossen = false;

    // Wenn zu neuer Übung gewechselt wird, könnte man hier theoretisch
    // zur nächsten Übung in einem Trainingsplan wechseln
    // (für zukünftige Erweiterung)

    // Für ersten Satz Empfehlung neu berechnen
    Future.microtask(() {
      berechneEmpfehlungFuerAktivenSatz();
    });

    notifyListeners();
  }

  // ===== METHODEN FÜR REGELEDITOR =====

  // Setter für die Regeltyp-Eigenschaft
  void setRegelTyp(String typ) {
    _regelTyp = typ;
    notifyListeners();
  }

  void openRuleEditor(ProgressionRuleModel? regel) {
    _bearbeiteteRegel = regel;

    if (regel == null) {
      // Standardwerte für neue Regel
      _regelTyp = 'condition'; // Standardmäßig eine bedingte Regel
      _regelBedingungen = [
        ProgressionConditionModel(
          left: {'type': 'variable', 'value': 'lastReps'},
          operator: 'lt',
          right: {'type': 'constant', 'value': 10},
        ),
      ];

      _kgAktion = {
        'type': 'direct',
        'variable': 'lastKg',
        'operator': 'add',
        'value': 2.5,
        'valueType': 'constant',
        'rmPercentage': 2.5,
      };

      _repsAktion = {
        'variable': 'lastReps',
        'operator': 'add',
        'value': 1,
      };

      _rirAktion = {
        'variable': 'lastRIR',
        'operator': 'none',
        'value': 0,
      };
    } else {
      // Regel-Typ setzen
      _regelTyp = regel.type;

      if (regel.type == 'condition') {
        // Bedingungen und Aktionen für Bedingte Regel
        _regelBedingungen = List.from(regel.conditions);

        final kgAction = regel.children.firstWhere(
          (action) => action.target == 'kg',
          orElse: () => ProgressionActionModel(
            id: 'temp_kg',
            type: 'assignment',
            target: 'kg',
            value: {'type': 'variable', 'value': 'lastKg'},
          ),
        );

        final repsAction = regel.children.firstWhere(
          (action) => action.target == 'reps',
          orElse: () => ProgressionActionModel(
            id: 'temp_reps',
            type: 'assignment',
            target: 'reps',
            value: {'type': 'variable', 'value': 'lastReps'},
          ),
        );

        final rirAction = regel.children.firstWhere(
          (action) => action.target == 'rir',
          orElse: () => ProgressionActionModel(
            id: 'temp_rir',
            type: 'assignment',
            target: 'rir',
            value: {'type': 'variable', 'value': 'lastRIR'},
          ),
        );

        _setActionValues(kgAction, repsAction, rirAction);
      } else if (regel.type == 'assignment') {
        // Standardbedingungen für die UI
        _regelBedingungen = [
          ProgressionConditionModel(
            left: {'type': 'variable', 'value': 'lastReps'},
            operator: 'lt',
            right: {'type': 'constant', 'value': 10},
          ),
        ];

        // Aktionen für direkte Zuweisung
        if (regel.children.isNotEmpty) {
          final kgAction = regel.children.firstWhere(
            (action) => action.target == 'kg',
            orElse: () => ProgressionActionModel(
              id: 'temp_kg',
              type: 'assignment',
              target: 'kg',
              value: {'type': 'variable', 'value': 'lastKg'},
            ),
          );

          final repsAction = regel.children.firstWhere(
            (action) => action.target == 'reps',
            orElse: () => ProgressionActionModel(
              id: 'temp_reps',
              type: 'assignment',
              target: 'reps',
              value: {'type': 'variable', 'value': 'lastReps'},
            ),
          );

          final rirAction = regel.children.firstWhere(
            (action) => action.target == 'rir',
            orElse: () => ProgressionActionModel(
              id: 'temp_rir',
              type: 'assignment',
              target: 'rir',
              value: {'type': 'variable', 'value': 'lastRIR'},
            ),
          );

          _setActionValues(kgAction, repsAction, rirAction);
        }
      }
    }

    _zeigeRegelEditor = true;
    notifyListeners();
  }

  // Hilfsmethode zum Setzen der Aktionswerte
  void _setActionValues(ProgressionActionModel kgAction,
      ProgressionActionModel repsAction, ProgressionActionModel rirAction) {
    if (kgAction.value['type'] == 'oneRM') {
      _kgAktion = {
        'type': 'oneRM',
        'variable': 'lastKg',
        'operator': 'none',
        'value': 0.0,
        'valueType': 'constant',
        'rmPercentage': kgAction.value['percentage'] ?? 2.5,
      };
    } else if (kgAction.value['type'] == 'operation') {
      // Prüfen, ob es sich um eine variable 'increment' handelt
      bool isConfigValue = kgAction.value['right']['type'] == 'variable' &&
          kgAction.value['right']['value'] == 'increment';

      _kgAktion = {
        'type': 'direct',
        'variable': kgAction.value['left']['value'],
        'operator': kgAction.value['operator'],
        'value': isConfigValue ? 0.0 : kgAction.value['right']['value'],
        'valueType': isConfigValue ? 'config' : 'constant',
        'rmPercentage': 2.5,
      };
    } else {
      _kgAktion = {
        'type': 'direct',
        'variable': kgAction.value['type'] == 'variable'
            ? kgAction.value['value']
            : 'constant',
        'operator': 'none',
        'value': kgAction.value['type'] == 'constant'
            ? kgAction.value['value']
            : 0.0,
        'valueType': 'constant',
        'rmPercentage': 2.5,
      };
    }

    if (repsAction.value['type'] == 'operation') {
      _repsAktion = {
        'variable': repsAction.value['left']['value'],
        'operator': repsAction.value['operator'],
        'value': repsAction.value['right']['value'],
      };
    } else {
      _repsAktion = {
        'variable': repsAction.value['type'] == 'variable'
            ? repsAction.value['value']
            : 'constant',
        'operator': 'none',
        'value': repsAction.value['type'] == 'constant'
            ? repsAction.value['value']
            : 0,
      };
    }

    if (rirAction.value['type'] == 'operation') {
      _rirAktion = {
        'variable': rirAction.value['left']['value'],
        'operator': rirAction.value['operator'],
        'value': rirAction.value['right']['value'],
      };
    } else {
      _rirAktion = {
        'variable': rirAction.value['type'] == 'variable'
            ? rirAction.value['value']
            : 'constant',
        'operator': 'none',
        'value': rirAction.value['type'] == 'constant'
            ? rirAction.value['value']
            : 0,
      };
    }
  }

  void closeRuleEditor() {
    _zeigeRegelEditor = false;
    _bearbeiteteRegel = null;
    notifyListeners();
  }

  void updateRegelBedingung(int index, String feld, dynamic wert) {
    if (index >= _regelBedingungen.length) return;

    final updatedBedingungen =
        List<ProgressionConditionModel>.from(_regelBedingungen);

    switch (feld) {
      case 'leftVariable':
        updatedBedingungen[index].left['value'] = wert;

        // Wenn die linke Variable geändert wird und der Typ der rechten Seite 'variable' ist,
        // müssen wir sicherstellen, dass die rechte Variable aktualisiert wird
        if (updatedBedingungen[index].right['type'] == 'variable') {
          // Basierend auf der neuen linken Variable einen passenden rechten Wert auswählen
          String rightVar = 'targetRepsMax';

          if (wert == 'lastKg')
            rightVar = 'previousKg';
          else if (wert == 'lastReps')
            rightVar = 'targetRepsMax';
          else if (wert == 'lastRIR')
            rightVar = 'targetRIRMin';
          else if (wert == 'last1RM')
            rightVar = 'previous1RM';
          else if (wert == 'previousKg')
            rightVar = 'lastKg';
          else if (wert == 'previousReps')
            rightVar = 'lastReps';
          else if (wert == 'previousRIR')
            rightVar = 'lastRIR';
          else if (wert == 'previous1RM')
            rightVar = 'last1RM';
          else if (wert.startsWith('target'))
            rightVar =
                wert == 'targetRepsMin' ? 'targetRepsMax' : 'targetRepsMin';

          updatedBedingungen[index].right['value'] = rightVar;
        }
        break;
      case 'operator':
        updatedBedingungen[index].operator = wert;
        break;
      case 'rightType':
        updatedBedingungen[index].right['type'] = wert;
        if (wert == 'variable') {
          final leftVar = updatedBedingungen[index].left['value'];
          String rightVar = 'targetRepsMax';

          if (leftVar == 'lastKg')
            rightVar = 'previousKg';
          else if (leftVar == 'lastReps')
            rightVar = 'targetRepsMax';
          else if (leftVar == 'lastRIR')
            rightVar = 'targetRIRMin';
          else if (leftVar == 'last1RM')
            rightVar = 'previous1RM';
          else if (leftVar == 'previousKg')
            rightVar = 'lastKg';
          else if (leftVar == 'previousReps')
            rightVar = 'lastReps';
          else if (leftVar == 'previousRIR')
            rightVar = 'lastRIR';
          else if (leftVar == 'previous1RM') rightVar = 'last1RM';

          updatedBedingungen[index].right['value'] = rightVar;
        } else {
          updatedBedingungen[index].right['value'] = 0;
        }
        break;
      case 'rightValue':
        if (updatedBedingungen[index].right['type'] == 'constant') {
          updatedBedingungen[index].right['value'] =
              double.tryParse(wert.toString()) ?? 0;
        } else {
          updatedBedingungen[index].right['value'] = wert;
        }
        break;
    }

    _regelBedingungen = updatedBedingungen;
    notifyListeners();
  }

  void addRegelBedingung() {
    _regelBedingungen.add(ProgressionConditionModel.defaultCondition());
    notifyListeners();
  }

  void removeRegelBedingung(int index) {
    if (_regelBedingungen.length <= 1) return;

    final updatedBedingungen =
        List<ProgressionConditionModel>.from(_regelBedingungen);
    updatedBedingungen.removeAt(index);
    _regelBedingungen = updatedBedingungen;
    notifyListeners();
  }

  void updateKgAktion(String feld, dynamic wert) {
    final updatedAktion = Map<String, dynamic>.from(_kgAktion);

    switch (feld) {
      case 'type':
        updatedAktion['type'] = wert;
        break;
      case 'variable':
        updatedAktion['variable'] = wert;
        break;
      case 'operator':
        updatedAktion['operator'] = wert;
        break;
      case 'value':
        updatedAktion['value'] = double.tryParse(wert.toString()) ?? 0.0;
        break;
      case 'valueType':
        updatedAktion['valueType'] = wert;
        break;
      case 'rmPercentage':
        updatedAktion['rmPercentage'] = double.tryParse(wert.toString()) ?? 2.5;
        break;
    }

    _kgAktion = updatedAktion;
    notifyListeners();
  }

  void updateRepsAktion(String feld, dynamic wert) {
    final updatedAktion = Map<String, dynamic>.from(_repsAktion);

    switch (feld) {
      case 'variable':
        updatedAktion['variable'] = wert;
        break;
      case 'operator':
        updatedAktion['operator'] = wert;
        break;
      case 'value':
        updatedAktion['value'] = int.tryParse(wert.toString()) ?? 0;
        break;
    }

    _repsAktion = updatedAktion;
    notifyListeners();
  }

  void updateRirAktion(String feld, dynamic wert) {
    final updatedAktion = Map<String, dynamic>.from(_rirAktion);

    switch (feld) {
      case 'variable':
        updatedAktion['variable'] = wert;
        break;
      case 'operator':
        updatedAktion['operator'] = wert;
        break;
      case 'value':
        updatedAktion['value'] = int.tryParse(wert.toString()) ?? 0;
        break;
    }

    _rirAktion = updatedAktion;
    notifyListeners();
  }

  void saveRule() {
    try {
      final profilIndex = _progressionsProfile
          .indexWhere((p) => p.id == _aktivesProgressionsProfil);
      if (profilIndex == -1) return;

      final aktionen = <ProgressionActionModel>[];
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // KG-Aktion erstellen
      if (_kgAktion['type'] == 'oneRM') {
        aktionen.add(
          ProgressionActionModel(
            id: 'action_kg_$timestamp',
            type: 'assignment',
            target: 'kg',
            value: {
              'type': 'oneRM',
              'percentage': _kgAktion['rmPercentage'],
            },
          ),
        );
      } else {
        if (_kgAktion['operator'] == 'none') {
          aktionen.add(
            ProgressionActionModel(
              id: 'action_kg_$timestamp',
              type: 'assignment',
              target: 'kg',
              value: _kgAktion['variable'] == 'constant'
                  ? {'type': 'constant', 'value': _kgAktion['value']}
                  : {'type': 'variable', 'value': _kgAktion['variable']},
            ),
          );
        } else {
          // Hier ist die geänderte Logik für die valueType-Unterscheidung
          aktionen.add(
            ProgressionActionModel(
              id: 'action_kg_$timestamp',
              type: 'assignment',
              target: 'kg',
              value: {
                'type': 'operation',
                'left': {'type': 'variable', 'value': _kgAktion['variable']},
                'operator': _kgAktion['operator'],
                'right': _kgAktion['valueType'] == 'config'
                    ? {'type': 'variable', 'value': 'increment'}
                    : {'type': 'constant', 'value': _kgAktion['value']},
              },
            ),
          );
        }
      }

      // Wiederholungs-Aktion erstellen
      if (_repsAktion['operator'] == 'none') {
        aktionen.add(
          ProgressionActionModel(
            id: 'action_reps_$timestamp',
            type: 'assignment',
            target: 'reps',
            value: _repsAktion['variable'] == 'constant'
                ? {'type': 'constant', 'value': _repsAktion['value']}
                : {'type': 'variable', 'value': _repsAktion['variable']},
          ),
        );
      } else {
        aktionen.add(
          ProgressionActionModel(
            id: 'action_reps_$timestamp',
            type: 'assignment',
            target: 'reps',
            value: {
              'type': 'operation',
              'left': {'type': 'variable', 'value': _repsAktion['variable']},
              'operator': _repsAktion['operator'],
              'right': {'type': 'constant', 'value': _repsAktion['value']},
            },
          ),
        );
      }

      // RIR-Aktion erstellen
      if (_rirAktion['operator'] == 'none') {
        aktionen.add(
          ProgressionActionModel(
            id: 'action_rir_$timestamp',
            type: 'assignment',
            target: 'rir',
            value: _rirAktion['variable'] == 'constant'
                ? {'type': 'constant', 'value': _rirAktion['value']}
                : {'type': 'variable', 'value': _rirAktion['variable']},
          ),
        );
      } else {
        aktionen.add(
          ProgressionActionModel(
            id: 'action_rir_$timestamp',
            type: 'assignment',
            target: 'rir',
            value: {
              'type': 'operation',
              'left': {'type': 'variable', 'value': _rirAktion['variable']},
              'operator': _rirAktion['operator'],
              'right': {'type': 'constant', 'value': _rirAktion['value']},
            },
          ),
        );
      }

      if (_bearbeiteteRegel != null) {
        // Eine bestehende Regel aktualisieren
        ProgressionRuleModel updatedRegel;

        if (_regelTyp == 'condition') {
          // Bedingte Regel aktualisieren
          updatedRegel = _bearbeiteteRegel!.copyWith(
            type: 'condition',
            conditions: _regelBedingungen,
            children: aktionen,
          );
        } else {
          // Direkte Zuweisung aktualisieren
          updatedRegel = _bearbeiteteRegel!.copyWith(
            type: 'assignment',
            conditions: [], // Keine Bedingungen bei direkter Zuweisung
            children: aktionen,
          );
        }

        final updatedRules =
            _progressionsProfile[profilIndex].rules.map((rule) {
          if (rule.id == updatedRegel.id) {
            return updatedRegel;
          }
          return rule;
        }).toList();

        final updatedProfil =
            _progressionsProfile[profilIndex].copyWith(rules: updatedRules);
        _progressionsProfile[profilIndex] = updatedProfil;
      } else {
        // Eine neue Regel erstellen
        ProgressionRuleModel neueRegel;

        if (_regelTyp == 'condition') {
          // Neue bedingte Regel
          neueRegel = ProgressionRuleModel(
            id: 'rule_$timestamp',
            type: 'condition',
            conditions: _regelBedingungen,
            logicalOperator: 'AND',
            children: aktionen,
          );
        } else {
          // Neue direkte Zuweisung
          neueRegel = ProgressionRuleModel(
            id: 'rule_$timestamp',
            type: 'assignment',
            conditions: [], // Keine Bedingungen bei direkter Zuweisung
            logicalOperator:
                'AND', // Muss gesetzt werden, wird aber nicht verwendet
            children: aktionen,
          );
        }

        final updatedRules = List<ProgressionRuleModel>.from(
            _progressionsProfile[profilIndex].rules)
          ..add(neueRegel);

        final updatedProfil =
            _progressionsProfile[profilIndex].copyWith(rules: updatedRules);
        _progressionsProfile[profilIndex] = updatedProfil;
      }

      // Regel-Änderungen speichern
      _saveProfiles();

      // Für aktiven Satz Empfehlung zurücksetzen
      final aktiverSatzIndex =
          _saetze.indexWhere((satz) => satz.id == _aktiverSatz);
      if (aktiverSatzIndex != -1) {
        final updatedSaetze = List<TrainingSetModel>.from(_saetze);
        updatedSaetze[aktiverSatzIndex] = updatedSaetze[aktiverSatzIndex]
            .copyWith(empfehlungBerechnet: false);
        _saetze = updatedSaetze;

        // Verzögert Empfehlung neu berechnen
        Future.microtask(() {
          berechneEmpfehlungFuerAktivenSatz();
        });
      }

      _zeigeRegelEditor = false;
      _bearbeiteteRegel = null;
      notifyListeners();
    } catch (e) {
      print('Fehler beim Speichern der Regel: $e');
    }
  }

  void deleteRule(String ruleId) {
    final profilIndex = _progressionsProfile
        .indexWhere((p) => p.id == _aktivesProgressionsProfil);
    if (profilIndex == -1) return;

    final updatedRules = _progressionsProfile[profilIndex]
        .rules
        .where((rule) => rule.id != ruleId)
        .toList();

    final updatedProfil =
        _progressionsProfile[profilIndex].copyWith(rules: updatedRules);
    _progressionsProfile[profilIndex] = updatedProfil;

    // Regel-Änderungen speichern
    _saveProfiles();

    // Für aktiven Satz Empfehlung zurücksetzen
    final aktiverSatzIndex =
        _saetze.indexWhere((satz) => satz.id == _aktiverSatz);
    if (aktiverSatzIndex != -1) {
      final updatedSaetze = List<TrainingSetModel>.from(_saetze);
      updatedSaetze[aktiverSatzIndex] =
          updatedSaetze[aktiverSatzIndex].copyWith(empfehlungBerechnet: false);
      _saetze = updatedSaetze;

      // Verzögert Empfehlung neu berechnen
      Future.microtask(() {
        berechneEmpfehlungFuerAktivenSatz();
      });
    }

    notifyListeners();
  }

  // ===== METHODEN FÜR DRAG-AND-DROP =====

  void handleDragStart(String ruleId) {
    _draggedRuleId = ruleId;
    notifyListeners();
  }

  void handleDragOver(String ruleId) {
    if (ruleId != _draggedRuleId) {
      _dragOverRuleId = ruleId;
      notifyListeners();
    }
  }

  void handleDragLeave() {
    _dragOverRuleId = null;
    notifyListeners();
  }

  void handleDrop(String targetRuleId) {
    if (_draggedRuleId == targetRuleId) {
      _draggedRuleId = null;
      _dragOverRuleId = null;
      notifyListeners();
      return;
    }

    final profilIndex = _progressionsProfile
        .indexWhere((p) => p.id == _aktivesProgressionsProfil);
    if (profilIndex == -1) {
      _draggedRuleId = null;
      _dragOverRuleId = null;
      notifyListeners();
      return;
    }

    final rules = List<ProgressionRuleModel>.from(
        _progressionsProfile[profilIndex].rules);

    final draggedRuleIndex =
        rules.indexWhere((rule) => rule.id == _draggedRuleId);
    final targetRuleIndex = rules.indexWhere((rule) => rule.id == targetRuleId);

    if (draggedRuleIndex != -1 && targetRuleIndex != -1) {
      final draggedRule = rules.removeAt(draggedRuleIndex);
      rules.insert(targetRuleIndex, draggedRule);

      final updatedProfil =
          _progressionsProfile[profilIndex].copyWith(rules: rules);
      _progressionsProfile[profilIndex] = updatedProfil;

      // Regel-Reihenfolge-Änderungen speichern
      _saveProfiles();

      // Für aktiven Satz Empfehlung zurücksetzen
      final aktiverSatzIndex =
          _saetze.indexWhere((satz) => satz.id == _aktiverSatz);
      if (aktiverSatzIndex != -1) {
        final updatedSaetze = List<TrainingSetModel>.from(_saetze);
        updatedSaetze[aktiverSatzIndex] = updatedSaetze[aktiverSatzIndex]
            .copyWith(empfehlungBerechnet: false);
        _saetze = updatedSaetze;

        // Verzögert Empfehlung neu berechnen
        Future.microtask(() {
          berechneEmpfehlungFuerAktivenSatz();
        });
      }
    }

    _draggedRuleId = null;
    _dragOverRuleId = null;
    notifyListeners();
  }

  // ===== METHODEN FÜR PROFILEDITOR =====

  void openProfileEditor(ProgressionProfileModel? profil) {
    if (profil != null) {
      _bearbeitetesProfil = profil.copyWith();
    } else {
      _bearbeitetesProfil = ProgressionProfileModel.empty(
          'profile_${DateTime.now().millisecondsSinceEpoch}');
    }

    _zeigeProfilEditor = true;
    notifyListeners();
  }

  void closeProfileEditor() {
    _zeigeProfilEditor = false;
    _bearbeitetesProfil = null;
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

  void saveProfile() {
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

    // Bei Profilspeicherung für aktiven Satz Empfehlung zurücksetzen
    final aktiverSatzIndex =
        _saetze.indexWhere((satz) => satz.id == _aktiverSatz);
    if (aktiverSatzIndex != -1) {
      final updatedSaetze = List<TrainingSetModel>.from(_saetze);
      updatedSaetze[aktiverSatzIndex] =
          updatedSaetze[aktiverSatzIndex].copyWith(empfehlungBerechnet: false);
      _saetze = updatedSaetze;

      // Verzögert Empfehlung neu berechnen
      Future.microtask(() {
        berechneEmpfehlungFuerAktivenSatz();
      });
    }

    // Profil-Änderungen speichern
    _saveProfiles();

    _zeigeProfilEditor = false;
    _bearbeitetesProfil = null;
    notifyListeners();
  }

  void duplicateProfile(String profilId) {
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

    openProfileEditor(copy);
  }

  // Methode zum Löschen eines Profils
  Future<void> deleteProfile(String profileId) async {
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

    // Profil aus der Liste entfernen
    _progressionsProfile.removeAt(profilIndex);

    // Wenn das aktive Profil gelöscht wurde, zum ersten Profil wechseln
    if (profileId == _aktivesProgressionsProfil) {
      _aktivesProgressionsProfil = _progressionsProfile.first.id;
      _progressionsConfig = Map.from(_progressionsProfile.first.config);
    }

    // Änderungen speichern
    await _saveProfiles();

    notifyListeners();
  }

  // Helper-Methoden
  String getVariableLabel(String variableId) {
    final variable = _verfuegbareVariablen.firstWhere(
      (v) => v.id == variableId,
      orElse: () => const ProgressionVariableModel(id: '', label: '', type: ''),
    );
    return variable.label.isNotEmpty ? variable.label : variableId;
  }

  String getOperatorLabel(String operatorId) {
    final operator = _verfuegbareOperatoren.firstWhere(
      (o) => o.id == operatorId,
      orElse: () => const ProgressionOperatorModel(id: '', label: '', type: ''),
    );
    return operator.label.isNotEmpty ? operator.label : operatorId;
  }

  String getTargetLabel(String targetId) {
    final targets = {
      'kg': 'Gewicht',
      'reps': 'Wiederholungen',
      'rir': 'RIR',
    };
    return targets[targetId] ?? targetId;
  }

  String renderValueNode(Map<String, dynamic> node) {
    if (node == null) return '';

    switch (node['type']) {
      case 'variable':
        return getVariableLabel(node['value']);
      case 'constant':
        return node['value'].toString();
      case 'operation':
        return '${renderValueNode(node['left'])} ${getOperatorLabel(node['operator'])} ${renderValueNode(node['right'])}';
      case 'oneRM':
        return '1RM +${node['percentage']}% (nach Epley-Formel)';
      default:
        return 'Unbekannter Wert';
    }
  }
}
