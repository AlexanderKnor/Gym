import '../../models/progression_manager_screen/training_set_model.dart';
import '../../models/progression_manager_screen/progression_profile_model.dart';
import '../../models/progression_manager_screen/progression_rule_model.dart';
import 'one_rm_calculator_service.dart';
import 'rule_evaluator_service.dart';

class ProgressionCalculatorService {
  static bool regelVerwendetVorherige(ProgressionRuleModel rule) {
    try {
      if (rule.type == 'condition') {
        for (var condition in rule.conditions) {
          if (condition.left['value'].toString().contains('previous') ||
              (condition.right['type'] == 'variable' &&
                  condition.right['value'].toString().contains('previous'))) {
            return true;
          }
        }

        for (var action in rule.children) {
          if (action.type == 'assignment') {
            bool usesPrevoius = _checkValueNodeForPrevious(action.value);
            if (usesPrevoius) return true;
          }
        }
      } else if (rule.type == 'assignment' && rule.children.isNotEmpty) {
        for (var action in rule.children) {
          bool usesPrevoius = _checkValueNodeForPrevious(action.value);
          if (usesPrevoius) return true;
        }
      }

      return false;
    } catch (error) {
      print('Fehler beim Prüfen auf Vorherige Variablen: $error');
      return false;
    }
  }

  static bool _checkValueNodeForPrevious(Map<String, dynamic> node) {
    if (node['type'] == 'variable') {
      return node['value'].toString().contains('previous');
    } else if (node['type'] == 'operation') {
      return _checkValueNodeForPrevious(node['left']) ||
          _checkValueNodeForPrevious(node['right']);
    }

    return false;
  }

  static Map<String, dynamic> berechneProgression(TrainingSetModel satz,
      ProgressionProfileModel profil, List<TrainingSetModel> alleSaetze) {
    try {
      if (satz.kg <= 0 || satz.wiederholungen <= 0) {
        return {
          'kg': satz.kg,
          'wiederholungen': satz.wiederholungen,
          'rir': satz.rir,
          'neuer1RM': 0.0,
        };
      }

      final config = profil.config;
      final rules = profil.rules;

      final vorherigenSatzIndex = satz.id - 1;
      TrainingSetModel? vorherigenSatz;
      if (vorherigenSatzIndex >= 1) {
        vorherigenSatz = alleSaetze.firstWhere(
            (s) => s.id == vorherigenSatzIndex,
            orElse: () =>
                TrainingSetModel(id: 0, kg: 0, wiederholungen: 0, rir: 0));
      }
      final istErsterSatz = satz.id == 1;

      final letzter1RM = OneRMCalculatorService.calculate1RM(
          satz.kg, satz.wiederholungen, satz.rir);

      final vorheriger1RM = vorherigenSatz != null
          ? OneRMCalculatorService.calculate1RM(vorherigenSatz.kg,
              vorherigenSatz.wiederholungen, vorherigenSatz.rir)
          : 0.0;

      // Für Demo-Zwecke: Wenn keine historischen Daten vorhanden sind, verwende realistische Mock-Daten
      final mockHistoricalKg = satz.kg > 0 ? satz.kg - 2.5 : 75.0;
      final mockHistoricalReps = satz.wiederholungen > 0 ? satz.wiederholungen : 8;
      final mockHistoricalRir = satz.rir > 0 ? satz.rir : 2;
      
      final variables = <String, dynamic>{
        'lastKg': satz.kg > 0 ? satz.kg : mockHistoricalKg,
        'lastReps': satz.wiederholungen > 0 ? satz.wiederholungen : mockHistoricalReps,
        'lastRIR': satz.rir >= 0 ? satz.rir : mockHistoricalRir,
        'last1RM': letzter1RM > 0 ? letzter1RM : OneRMCalculatorService.calculate1RM(mockHistoricalKg, mockHistoricalReps, mockHistoricalRir),
        'previousKg': vorherigenSatz?.kg ?? mockHistoricalKg,
        'previousReps': vorherigenSatz?.wiederholungen ?? mockHistoricalReps,
        'previousRIR': vorherigenSatz?.rir ?? mockHistoricalRir,
        'previous1RM': vorheriger1RM > 0 ? vorheriger1RM : OneRMCalculatorService.calculate1RM(mockHistoricalKg, mockHistoricalReps, mockHistoricalRir),
        'targetRepsMin': config['targetRepsMin'] ?? 8,
        'targetRepsMax': config['targetRepsMax'] ?? 10,
        'targetRIRMin': config['targetRIRMin'] ?? 1,
        'targetRIRMax': config['targetRIRMax'] ?? 2,
        'increment': config['increment'] ?? 2.5,
      };

      double neueKg = satz.kg;
      int neueWiederholungen = satz.wiederholungen;
      int neuerRir = satz.rir;

      bool ruleApplied = false;

      print(
          'Starte Regelauswertung für Satz ${satz.id} mit Werten: ${satz.kg}kg, ${satz.wiederholungen} Wdh, ${satz.rir} RIR');

      for (int i = 0; i < rules.length; i++) {
        final rule = rules[i];

        print('Prüfe Regel ${i + 1}: ${rule.type}');

        if (ruleApplied) {
          print('Regel übersprungen - bereits eine Regel angewendet');
          continue;
        }

        if (istErsterSatz && regelVerwendetVorherige(rule)) {
          print('Regel übersprungen - erster Satz verwendet vorherige Werte');
          continue;
        }

        if (rule.type == 'condition') {
          final conditionResult = RuleEvaluatorService.evaluateConditions(
              rule.conditions, variables, rule.logicalOperator);

          print('Bedingungsergebnis: $conditionResult');

          if (conditionResult && rule.children.isNotEmpty) {
            // Aktionen auswerten und Werte berechnen
            print('Regel hat zutreffende Bedingungen, wende Aktionen an:');

            for (var action in rule.children) {
              if (action.type == 'assignment') {
                // Den Wert mit Zugriff auf alle Aktionen berechnen für dynamische 1RM-Berechnung
                final wert = RuleEvaluatorService.evaluateValue(
                    action.value, variables,
                    ruleActions: rule.children);

                print('Aktion für ${action.target}: ${wert}');

                if (action.target == 'kg')
                  neueKg = wert.toDouble();
                else if (action.target == 'reps')
                  neueWiederholungen = wert.toInt();
                else if (action.target == 'rir') neuerRir = wert.toInt();
              }
            }

            ruleApplied = true;
            print('Regel angewendet!');
          }
        } else if (rule.type == 'assignment' && rule.children.isNotEmpty) {
          print('Direkte Zuweisung, wende Aktionen an:');

          for (var action in rule.children) {
            if (action.type == 'assignment') {
              // Den Wert mit Zugriff auf alle Aktionen berechnen
              final wert = RuleEvaluatorService.evaluateValue(
                  action.value, variables,
                  ruleActions: rule.children);

              print('Aktion für ${action.target}: ${wert}');

              if (action.target == 'kg')
                neueKg = wert.toDouble();
              else if (action.target == 'reps')
                neueWiederholungen = wert.toInt();
              else if (action.target == 'rir') neuerRir = wert.toInt();
            }
          }

          ruleApplied = true;
          print('Regel angewendet!');
        }
      }

      final neuer1RM = OneRMCalculatorService.calculate1RM(
          neueKg, neueWiederholungen, neuerRir);

      print(
          'Berechnungsergebnis: ${neueKg}kg, ${neueWiederholungen} Wdh, ${neuerRir} RIR, 1RM: ${neuer1RM}kg');

      return {
        'kg': neueKg,
        'wiederholungen': neueWiederholungen,
        'rir': neuerRir,
        'neuer1RM': neuer1RM,
      };
    } catch (error) {
      print('Fehler bei der Progressionsberechnung: $error');
      return {
        'kg': satz.kg,
        'wiederholungen': satz.wiederholungen,
        'rir': satz.rir,
        'neuer1RM': 0.0,
      };
    }
  }
}
