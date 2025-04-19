// lib/models/strength_calculator_screen/strength_calculator_model.dart
class StrengthCalculatorModel {
  // Eingabewerte
  double testWeight;
  int testReps;
  int targetReps;
  int targetRIR;

  // Berechnete Werte
  double? calculatedOneRM;
  double? calculatedWorkingWeight;

  StrengthCalculatorModel({
    this.testWeight = 0.0,
    this.testReps = 0,
    this.targetReps = 10,
    this.targetRIR = 2,
    this.calculatedOneRM,
    this.calculatedWorkingWeight,
  });

  // Methode zum Kopieren mit geänderten Werten
  StrengthCalculatorModel copyWith({
    double? testWeight,
    int? testReps,
    int? targetReps,
    int? targetRIR,
    double? calculatedOneRM,
    double? calculatedWorkingWeight,
  }) {
    return StrengthCalculatorModel(
      testWeight: testWeight ?? this.testWeight,
      testReps: testReps ?? this.testReps,
      targetReps: targetReps ?? this.targetReps,
      targetRIR: targetRIR ?? this.targetRIR,
      calculatedOneRM: calculatedOneRM ?? this.calculatedOneRM,
      calculatedWorkingWeight:
          calculatedWorkingWeight ?? this.calculatedWorkingWeight,
    );
  }

  // Hilfsmethode zum Zurücksetzen der Berechnungsergebnisse
  void resetCalculations() {
    calculatedOneRM = null;
    calculatedWorkingWeight = null;
  }
}
