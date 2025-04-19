// lib/widgets/strength_calculator_screen/strength_calculator_form_widget.dart
import 'package:flutter/material.dart';
import '../../models/strength_calculator_screen/strength_calculator_model.dart';
import '../../services/progression_manager_screen/one_rm_calculator_service.dart';

class StrengthCalculatorFormWidget extends StatefulWidget {
  final Function(double, int, int) onApplyValues;

  const StrengthCalculatorFormWidget({
    Key? key,
    required this.onApplyValues,
  }) : super(key: key);

  @override
  _StrengthCalculatorFormWidgetState createState() =>
      _StrengthCalculatorFormWidgetState();
}

class _StrengthCalculatorFormWidgetState
    extends State<StrengthCalculatorFormWidget> {
  final _formKey = GlobalKey<FormState>();

  // Controller für die Textfelder
  final _testWeightController = TextEditingController();
  final _testRepsController = TextEditingController();
  final _targetRepsController = TextEditingController();
  final _targetRIRController = TextEditingController();

  // Modell für die Berechnungen
  late StrengthCalculatorModel _calculatorModel;

  // Zeigt an, ob eine Berechnung durchgeführt wurde
  bool _hasCalculated = false;

  @override
  void initState() {
    super.initState();

    // Modell mit Standardwerten initialisieren
    _calculatorModel = StrengthCalculatorModel();

    // Controller mit Standardwerten initialisieren
    _testWeightController.text = '';
    _testRepsController.text = '';
    _targetRepsController.text = _calculatorModel.targetReps.toString();
    _targetRIRController.text = _calculatorModel.targetRIR.toString();

    // Listener hinzufügen, um das Modell zu aktualisieren
    _testWeightController.addListener(_updateModelFromControllers);
    _testRepsController.addListener(_updateModelFromControllers);
    _targetRepsController.addListener(_updateModelFromControllers);
    _targetRIRController.addListener(_updateModelFromControllers);
  }

  @override
  void dispose() {
    // Controller freigeben
    _testWeightController.dispose();
    _testRepsController.dispose();
    _targetRepsController.dispose();
    _targetRIRController.dispose();
    super.dispose();
  }

  // Aktualisiert das Modell mit den Werten aus den Controllern
  void _updateModelFromControllers() {
    setState(() {
      _calculatorModel = _calculatorModel.copyWith(
        testWeight: double.tryParse(_testWeightController.text) ?? 0.0,
        testReps: int.tryParse(_testRepsController.text) ?? 0,
        targetReps: int.tryParse(_targetRepsController.text) ?? 10,
        targetRIR: int.tryParse(_targetRIRController.text) ?? 2,
      );

      // Bei Änderungen müssen die Berechnungen zurückgesetzt werden
      if (_hasCalculated) {
        _calculatorModel.resetCalculations();
        _hasCalculated = false;
      }
    });
  }

  // Führt die Berechnung durch
  void _calculateWorkingWeight() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        // 1RM berechnen (mit RIR = 0, da wir bis zum Muskelversagen gehen)
        _calculatorModel.calculatedOneRM = OneRMCalculatorService.calculate1RM(
          _calculatorModel.testWeight,
          _calculatorModel.testReps,
          0, // RIR = 0 für Test bis zum Muskelversagen
        );

        // Arbeitsgewicht basierend auf 1RM und Zielwerten berechnen
        if (_calculatorModel.calculatedOneRM! > 0) {
          _calculatorModel.calculatedWorkingWeight =
              OneRMCalculatorService.calculateWeightFromTargetRM(
            _calculatorModel.calculatedOneRM!,
            _calculatorModel.targetReps,
            _calculatorModel.targetRIR,
          );
        }

        _hasCalculated = true;
      });
    }
  }

  // Wendet die berechneten Werte auf den aktuellen Satz an
  void _applyToCurrentSet() {
    if (_hasCalculated && _calculatorModel.calculatedWorkingWeight != null) {
      widget.onApplyValues(
        _calculatorModel.calculatedWorkingWeight!,
        _calculatorModel.targetReps,
        _calculatorModel.targetRIR,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Eingabebereich
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Testgewicht und Wiederholungen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Gib das Gewicht und die Wiederholungen ein, die du bis zum Muskelversagen schaffst',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Testgewicht
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _testWeightController,
                            decoration: const InputDecoration(
                              labelText: 'Testgewicht',
                              suffixText: 'kg',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Bitte gib ein Gewicht ein';
                              }
                              final weight = double.tryParse(value);
                              if (weight == null || weight <= 0) {
                                return 'Bitte gib ein gültiges Gewicht ein';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _testRepsController,
                            decoration: const InputDecoration(
                              labelText: 'Wiederholungen',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Bitte gib Wiederholungen ein';
                              }
                              final reps = int.tryParse(value);
                              if (reps == null || reps <= 0) {
                                return 'Bitte gib gültige Wiederholungen ein';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Zielwerte
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Zielwerte',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Gib die gewünschten Zielwerte für dein Training ein',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Zielwiederholungen und Ziel-RIR
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _targetRepsController,
                            decoration: const InputDecoration(
                              labelText: 'Ziel Wiederholungen',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Bitte gib Wiederholungen ein';
                              }
                              final reps = int.tryParse(value);
                              if (reps == null || reps <= 0) {
                                return 'Bitte gib gültige Wiederholungen ein';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _targetRIRController,
                            decoration: const InputDecoration(
                              labelText: 'Ziel RIR',
                              border: OutlineInputBorder(),
                              helperText: 'Reps in Reserve',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Bitte gib RIR ein';
                              }
                              final rir = int.tryParse(value);
                              if (rir == null || rir < 0) {
                                return 'Bitte gib gültigen RIR ein';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Berechnen-Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _calculateWorkingWeight,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Berechnen'),
              ),
            ),

            const SizedBox(height: 24),

            // Ergebnisbereich (nur anzeigen, wenn Berechnung durchgeführt wurde)
            if (_hasCalculated &&
                _calculatorModel.calculatedWorkingWeight != null)
              Card(
                elevation: 2,
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Berechnungsergebnis',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 1RM Ergebnis
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Dein geschätztes 1RM:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_calculatorModel.calculatedOneRM!.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Arbeitsgewicht Ergebnis
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Arbeitsgewicht für ${_calculatorModel.targetReps} Wdh. mit RIR ${_calculatorModel.targetRIR}:',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_calculatorModel.calculatedWorkingWeight!.toStringAsFixed(1)} kg',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Übernehmen-Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _applyToCurrentSet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text('Auf aktuellen Satz anwenden'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
