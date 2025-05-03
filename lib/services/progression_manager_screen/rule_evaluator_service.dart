import '../../models/progression_manager_screen/progression_condition_model.dart';
import '../../models/progression_manager_screen/progression_action_model.dart';
import 'one_rm_calculator_service.dart';

class RuleEvaluatorService {
  static bool evaluateSingleCondition(
      ProgressionConditionModel condition, Map<String, dynamic> variables) {
    try {
      final leftValue = evaluateValue(condition.left, variables);
      final rightValue = evaluateValue(condition.right, variables);

      switch (condition.operator) {
        case 'eq':
          return leftValue == rightValue;
        case 'gt':
          return leftValue > rightValue;
        case 'lt':
          return leftValue < rightValue;
        case 'gte':
          return leftValue >= rightValue;
        case 'lte':
          return leftValue <= rightValue;
        default:
          return false;
      }
    } catch (error) {
      print('Fehler bei der Auswertung einer Bedingung: $error');
      return false;
    }
  }

  static bool evaluateConditions(List<ProgressionConditionModel> conditions,
      Map<String, dynamic> variables, String logicalOperator) {
    try {
      if (conditions.isEmpty) return true;
      if (conditions.length == 1)
        return evaluateSingleCondition(conditions[0], variables);

      if (logicalOperator == 'OR') {
        return conditions
            .any((condition) => evaluateSingleCondition(condition, variables));
      } else {
        return conditions.every(
            (condition) => evaluateSingleCondition(condition, variables));
      }
    } catch (error) {
      print('Fehler bei der Auswertung von Bedingungen: $error');
      return false;
    }
  }

  static dynamic evaluateValue(
      Map<String, dynamic> valueNode, Map<String, dynamic> variables,
      {List<ProgressionActionModel>? ruleActions}) {
    try {
      if (valueNode['type'] == 'variable') {
        if (variables[valueNode['value']] == null) {
          print('Variable "${valueNode['value']}" nicht gefunden');
          return 0;
        }
        return variables[valueNode['value']];
      } else if (valueNode['type'] == 'constant') {
        return valueNode['value'];
      } else if (valueNode['type'] == 'operation') {
        final leftValue = evaluateValue(valueNode['left'], variables);
        final rightValue = evaluateValue(valueNode['right'], variables);

        switch (valueNode['operator']) {
          case 'add':
            return leftValue + rightValue;
          case 'subtract':
            return leftValue - rightValue;
          case 'multiply':
            return leftValue * rightValue;
          case 'divide':
            if (rightValue == 0) {
              print('Division durch Null vermieden');
              return 0;
            }
            return leftValue / rightValue;
          default:
            return 0;
        }
      } else if (valueNode['type'] == 'oneRM') {
        // Quelle für 1RM bestimmen: 'last' (Standard) oder 'previous'
        final String source = valueNode['source'] ?? 'last';

        // Werte basierend auf der Quelle auswählen
        final double kg;
        final int reps;
        final int rir;

        if (source == 'previous') {
          // Werte vom vorherigen Satz verwenden
          kg = variables['previousKg'] ?? 0.0;
          reps = variables['previousReps'] ?? 0;
          rir = variables['previousRIR'] ?? 0;
          print(
              'Verwende 1RM vom vorherigen Satz: $kg kg, $reps reps, $rir RIR');
        } else {
          // Werte vom letzten (aktuellen) Satz verwenden
          kg = variables['lastKg'] ?? 0.0;
          reps = variables['lastReps'] ?? 0;
          rir = variables['lastRIR'] ?? 0;
          print('Verwende 1RM vom letzten Satz: $kg kg, $reps reps, $rir RIR');
        }

        // 1RM aus den ausgewählten Werten berechnen
        final currentRM =
            OneRMCalculatorService.calculate1RM(kg.toDouble(), reps, rir);

        // Dynamische Bestimmung von targetReps und targetRIR aus den anderen Actions der Regel
        int targetReps = variables['targetRepsMin'] ?? 8;
        int targetRIR = variables['targetRIRMin'] ?? 1;

        // Regel-Aktionen durchsuchen, wenn verfügbar
        if (ruleActions != null && ruleActions.isNotEmpty) {
          for (var action in ruleActions) {
            if (action.type == 'assignment') {
              // Zielwerte aus expliziten Regelaktionen holen
              if (action.target == 'reps') {
                // Die genauen Wiederholungswerte aus der Regel extrahieren
                var repsValue = evaluateValue(action.value, variables);
                if (repsValue is num) {
                  targetReps = repsValue.toInt();
                  print(
                      'Dynamische Wiederholungen für 1RM-Berechnung: $targetReps');
                }
              } else if (action.target == 'rir') {
                // Die genauen RIR-Werte aus der Regel extrahieren
                var rirValue = evaluateValue(action.value, variables);
                if (rirValue is num) {
                  targetRIR = rirValue.toInt();
                  print('Dynamischer RIR für 1RM-Berechnung: $targetRIR');
                }
              }
            }
          }
        }

        // Prozentuale Anpassung beachten
        double percentageAdjustment = valueNode['percentage'] ?? 0.0;

        // Gewicht basierend auf dem gewählten 1RM und den Zielwerten berechnen
        final calculatedWeight =
            OneRMCalculatorService.calculateWeightFromTargetRM(
                currentRM, targetReps, targetRIR, percentageAdjustment);

        print(
            '1RM-Berechnung: $currentRM 1RM mit $targetReps Wdh, $targetRIR RIR, $percentageAdjustment% = $calculatedWeight kg');

        return calculatedWeight;
      }

      return 0;
    } catch (error) {
      print('Fehler bei der Auswertung eines Wertes: $error');
      return 0;
    }
  }
}
