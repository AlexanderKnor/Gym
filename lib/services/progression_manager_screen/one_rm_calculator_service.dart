class OneRMCalculatorService {
  static double calculate1RM(double weight, int repetitions, int rir) {
    if (weight <= 0 || repetitions <= 0) return 0;

    final gesamtWiederholungen = repetitions + rir;
    final einRM = weight * (1 + 0.0333 * gesamtWiederholungen);

    return (einRM * 10).round() / 10;
  }

  static double calculateWeightFromTargetRM(
      double targetRM, int repetitions, int rir,
      [double prozent = 0]) {
    if (repetitions <= 0 || targetRM <= 0) return 0;

    final adjustedRM = targetRM * (1 + prozent / 100);
    final weight = adjustedRM / (1 + 0.0333 * (repetitions + rir));

    return (weight * 2).round() / 2;
  }
}
