import 'package:flutter/foundation.dart';
import '../../models/progression_manager_screen/progression_rule_model.dart';
import '../../models/progression_manager_screen/progression_condition_model.dart';
import '../../models/progression_manager_screen/progression_action_model.dart';
import '../../models/progression_manager_screen/progression_variable_model.dart';
import '../../models/progression_manager_screen/progression_operator_model.dart';
import '../../models/progression_manager_screen/progression_profile_model.dart';
import 'progression_ui_provider.dart';
import 'progression_training_provider.dart';

/// Provider für Progressionsregeln
/// Verantwortlich für Bearbeitung und Verwaltung von Regeln
class ProgressionRuleProvider with ChangeNotifier {
  // ===== STATE DECLARATIONS =====

  // Regeleditor-Zustand
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
    'source': 'last', // 'last' oder 'previous'
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

  // ===== GETTERS =====

  ProgressionRuleModel? get bearbeiteteRegel => _bearbeiteteRegel;
  String get regelTyp => _regelTyp;
  List<ProgressionConditionModel> get regelBedingungen => _regelBedingungen;
  Map<String, dynamic> get kgAktion => _kgAktion;
  Map<String, dynamic> get repsAktion => _repsAktion;
  Map<String, dynamic> get rirAktion => _rirAktion;
  String? get draggedRuleId => _draggedRuleId;
  String? get dragOverRuleId => _dragOverRuleId;
  ProgressionRuleModel get neueRegel => _neueRegel;
  List<ProgressionVariableModel> get verfuegbareVariablen =>
      _verfuegbareVariablen;
  List<ProgressionOperatorModel> get verfuegbareOperatoren =>
      _verfuegbareOperatoren;

  // ===== METHODEN =====

  // Setter für die Regeltyp-Eigenschaft
  void setRegelTyp(String typ) {
    _regelTyp = typ;
    notifyListeners();
  }

  void openRuleEditor(
      ProgressionRuleModel? regel, ProgressionUIProvider uiProvider) {
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
        'source': 'last',
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

    uiProvider.showRuleEditor();
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
        'source':
            kgAction.value['source'] ?? 'last', // Neue Option für die Quelle
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
        'source': 'last',
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
        'source': 'last',
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

  void closeRuleEditor(ProgressionUIProvider uiProvider) {
    uiProvider.hideRuleEditor();
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
              int.tryParse(wert.toString()) ?? 0;
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
      case 'source':
        updatedAktion['source'] = wert;
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

  // GEÄNDERTE METHODE: saveRule mit async/await und expliziter Firebase-Aktualisierung
  Future<void> saveRule(
      String profileId,
      List<ProgressionProfileModel> progressionsProfile,
      Future<bool> Function()
          saveProfiles, // Funktion zum Speichern der Profile
      ProgressionTrainingProvider trainingProvider,
      ProgressionProfileModel? aktuellesProfil,
      ProgressionUIProvider uiProvider) async {
    try {
      print('Starte Speichern der Regel für Profil: $profileId');
      final profilIndex =
          progressionsProfile.indexWhere((p) => p.id == profileId);
      if (profilIndex == -1) {
        print('Profil mit ID $profileId nicht gefunden');
        return;
      }

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
              'source': _kgAktion['source'] ?? 'last', // Neue Option hinzufügen
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

        final updatedRules = progressionsProfile[profilIndex].rules.map((rule) {
          if (rule.id == updatedRegel.id) {
            return updatedRegel;
          }
          return rule;
        }).toList();

        final updatedProfil =
            progressionsProfile[profilIndex].copyWith(rules: updatedRules);
        progressionsProfile[profilIndex] = updatedProfil;

        print('Bestehende Regel (${updatedRegel.id}) aktualisiert');
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
            progressionsProfile[profilIndex].rules)
          ..add(neueRegel);

        final updatedProfil =
            progressionsProfile[profilIndex].copyWith(rules: updatedRules);
        progressionsProfile[profilIndex] = updatedProfil;

        print('Neue Regel (${neueRegel.id}) erstellt');
      }

      // Regel-Änderungen explizit in Firestore speichern
      bool saved = await saveProfiles();
      if (saved) {
        print('Regel erfolgreich in Firebase gespeichert');
      } else {
        print('Fehler beim Speichern der Regel in Firebase');
      }

      // Für aktiven Satz Empfehlung zurücksetzen
      trainingProvider.berechneEmpfehlungFuerAktivenSatz(
          aktuellesProfil: aktuellesProfil);

      uiProvider.hideRuleEditor();
      _bearbeiteteRegel = null;
      notifyListeners();
    } catch (e) {
      print('Fehler beim Speichern der Regel: $e');
    }
  }

  // GEÄNDERTE METHODE: deleteRule mit async/await und expliziter Firebase-Aktualisierung
  Future<void> deleteRule(
      String ruleId,
      String profileId,
      List<ProgressionProfileModel> progressionsProfile,
      Future<bool> Function()
          saveProfiles, // Funktion zum Speichern der Profile
      ProgressionTrainingProvider trainingProvider,
      ProgressionProfileModel? aktuellesProfil) async {
    try {
      print('Starte Löschen der Regel: $ruleId aus Profil: $profileId');
      final profilIndex =
          progressionsProfile.indexWhere((p) => p.id == profileId);
      if (profilIndex == -1) {
        print('Profil mit ID $profileId nicht gefunden');
        return;
      }

      final updatedRules = progressionsProfile[profilIndex]
          .rules
          .where((rule) => rule.id != ruleId)
          .toList();

      final updatedProfil =
          progressionsProfile[profilIndex].copyWith(rules: updatedRules);
      progressionsProfile[profilIndex] = updatedProfil;

      // Regel-Änderungen explizit in Firestore speichern
      bool saved = await saveProfiles();
      if (saved) {
        print('Regel $ruleId erfolgreich aus Firebase gelöscht');
      } else {
        print('Fehler beim Löschen der Regel $ruleId aus Firebase');
      }

      // Für aktiven Satz Empfehlung zurücksetzen
      trainingProvider.berechneEmpfehlungFuerAktivenSatz(
          aktuellesProfil: aktuellesProfil);

      notifyListeners();
    } catch (e) {
      print('Fehler beim Löschen der Regel: $e');
    }
  }

  // ===== DRAG & DROP METHODEN =====

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

  // GEÄNDERTE METHODE: handleDrop mit async/await und expliziter Firebase-Aktualisierung
  Future<void> handleDrop(
      String targetRuleId,
      String profileId,
      List<ProgressionProfileModel> progressionsProfile,
      Future<bool> Function()
          saveProfiles, // Funktion zum Speichern der Profile
      ProgressionTrainingProvider trainingProvider,
      ProgressionProfileModel? aktuellesProfil) async {
    try {
      if (_draggedRuleId == targetRuleId) {
        _draggedRuleId = null;
        _dragOverRuleId = null;
        notifyListeners();
        return;
      }

      print(
          'Verschiebe Regel $_draggedRuleId nach $targetRuleId in Profil $profileId');
      final profilIndex =
          progressionsProfile.indexWhere((p) => p.id == profileId);
      if (profilIndex == -1) {
        print('Profil mit ID $profileId nicht gefunden');
        _draggedRuleId = null;
        _dragOverRuleId = null;
        notifyListeners();
        return;
      }

      final rules = List<ProgressionRuleModel>.from(
          progressionsProfile[profilIndex].rules);

      final draggedRuleIndex =
          rules.indexWhere((rule) => rule.id == _draggedRuleId);
      final targetRuleIndex =
          rules.indexWhere((rule) => rule.id == targetRuleId);

      if (draggedRuleIndex != -1 && targetRuleIndex != -1) {
        final draggedRule = rules.removeAt(draggedRuleIndex);
        rules.insert(targetRuleIndex, draggedRule);

        final updatedProfil =
            progressionsProfile[profilIndex].copyWith(rules: rules);
        progressionsProfile[profilIndex] = updatedProfil;

        // Regel-Reihenfolge-Änderungen explizit in Firestore speichern
        bool saved = await saveProfiles();
        if (saved) {
          print('Regelreihenfolge erfolgreich in Firebase aktualisiert');
        } else {
          print('Fehler beim Aktualisieren der Regelreihenfolge in Firebase');
        }

        // Für aktiven Satz Empfehlung zurücksetzen
        trainingProvider.berechneEmpfehlungFuerAktivenSatz(
            aktuellesProfil: aktuellesProfil);
      }

      _draggedRuleId = null;
      _dragOverRuleId = null;
      notifyListeners();
    } catch (e) {
      print('Fehler beim Verschieben der Regel: $e');
      _draggedRuleId = null;
      _dragOverRuleId = null;
      notifyListeners();
    }
  }

  // ===== HELFER-METHODEN =====

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
        final source = node['source'] ?? 'last';
        final sourceText =
            source == 'previous' ? 'vorherigen Satz' : 'aktuellen Satz';
        return '1RM vom $sourceText +${node['percentage']}% (nach Epley-Formel)';
      default:
        return 'Unbekannter Wert';
    }
  }
}
