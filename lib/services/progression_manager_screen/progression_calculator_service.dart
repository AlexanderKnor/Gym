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

      final variables = <String, dynamic>{
        'lastKg': satz.kg,
        'lastReps': satz.wiederholungen,
        'lastRIR': satz.rir,
        'last1RM': letzter1RM,
        'previousKg': vorherigenSatz?.kg ?? 0,
        'previousReps': vorherigenSatz?.wiederholungen ?? 0,
        'previousRIR': vorherigenSatz?.rir ?? 0,
        'previous1RM': vorheriger1RM,
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

      for (int i = 0; i < rules.length; i++) {
        final rule = rules[i];

        if (ruleApplied) continue;

        if (istErsterSatz && regelVerwendetVorherige(rule)) continue;

        if (rule.type == 'condition') {
          final conditionResult = RuleEvaluatorService.evaluateConditions(
              rule.conditions, variables, rule.logicalOperator);

          if (conditionResult && rule.children.isNotEmpty) {
            for (var action in rule.children) {
              if (action.type == 'assignment') {
                final wert =
                    RuleEvaluatorService.evaluateValue(action.value, variables);

                if (action.target == 'kg')
                  neueKg = wert.toDouble();
                else if (action.target == 'reps')
                  neueWiederholungen = wert.toInt();
                else if (action.target == 'rir') neuerRir = wert.toInt();
              }
            }

            ruleApplied = true;
          }
        } else if (rule.type == 'assignment' && rule.children.isNotEmpty) {
          for (var action in rule.children) {
            if (action.type == 'assignment') {
              final wert =
                  RuleEvaluatorService.evaluateValue(action.value, variables);

              if (action.target == 'kg')
                neueKg = wert.toDouble();
              else if (action.target == 'reps')
                neueWiederholungen = wert.toInt();
              else if (action.target == 'rir') neuerRir = wert.toInt();
            }
          }

          ruleApplied = true;
        }
      }

      final neuer1RM = OneRMCalculatorService.calculate1RM(
          neueKg, neueWiederholungen, neuerRir);

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
