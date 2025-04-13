import '../../models/progression_manager_screen/progression_condition_model.dart';
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
      Map<String, dynamic> valueNode, Map<String, dynamic> variables) {
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
        final lastKg = variables['lastKg'] ?? 0.0;
        final lastReps = variables['lastReps'] ?? 0;
        final lastRIR = variables['lastRIR'] ?? 0;

        final currentRM = OneRMCalculatorService.calculate1RM(
            lastKg.toDouble(), lastReps, lastRIR);

        final targetReps = variables['targetRepsMin'] ?? 8;
        final targetRIR = variables['targetRIRMax'] ?? 2;

        return OneRMCalculatorService.calculateWeightFromTargetRM(
            currentRM, targetReps, targetRIR, valueNode['percentage'] ?? 2.5);
      }

      return 0;
    } catch (error) {
      print('Fehler bei der Auswertung eines Wertes: $error');
      return 0;
    }
  }
}
