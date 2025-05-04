class OneRMCalculatorService {
  static double calculate1RM(double weight, int repetitions, int rir) {
    if (weight <= 0 || repetitions <= 0) return 0;

    final gesamtWiederholungen = repetitions + rir;
    final einRM = weight * (1 + 0.0333 * gesamtWiederholungen);

    return (einRM * 10).round() / 10;
  }

  static double calculateWeightFromTargetRM(
      double targetRM, int repetitions, int rir,
      [dynamic prozent = 0]) {
    try {
      // Fehlerbehandlung - Wenn ungültige Werte übergeben werden
      if (repetitions <= 0 || targetRM <= 0) {
        print(
            'Ungültige Werte für calculateWeightFromTargetRM: targetRM=$targetRM, repetitions=$repetitions, rir=$rir');
        return 0;
      }

      // Konvertierung zu double für Prozent, egal ob int oder double übergeben wird
      double prozentDouble = 0.0;
      if (prozent is int) {
        prozentDouble = prozent.toDouble();
      } else if (prozent is double) {
        prozentDouble = prozent;
      } else if (prozent is String) {
        prozentDouble = double.tryParse(prozent) ?? 0.0;
      } else {
        print('Ungültiger Prozenttyp: ${prozent?.runtimeType}');
      }

      print(
          'Prozent-Wert: $prozent (${prozent.runtimeType}), konvertiert zu $prozentDouble');

      // Prozentuale Anpassung des Ziel-1RM
      final adjustedRM = targetRM * (1 + prozentDouble / 100);
      print('Angepasster 1RM mit $prozentDouble% Steigerung: $adjustedRM kg');

      // Berechnung des Gewichts aus dem 1RM nach Epley-Formel umgekehrt
      final weight = adjustedRM / (1 + 0.0333 * (repetitions + rir));

      // Auf 0,5 kg genau runden und sicherstellen, dass kein negativer Wert zurückgegeben wird
      final roundedWeight = (weight * 2).round() / 2;
      print('Berechnetes Gewicht: $roundedWeight kg (vor Rundung: $weight kg)');

      return roundedWeight > 0 ? roundedWeight : 0;
    } catch (e) {
      print('Fehler in calculateWeightFromTargetRM: $e');
      return 0;
    }
  }
}
