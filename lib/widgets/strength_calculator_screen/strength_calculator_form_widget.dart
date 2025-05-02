// lib/widgets/strength_calculator_screen/strength_calculator_form_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/strength_calculator_screen/strength_calculator_model.dart';
import '../../services/progression_manager_screen/one_rm_calculator_service.dart';
import '../shared/weight_wheel_input_widget.dart';
import '../shared/repetition_wheel_input_widget.dart';
import '../shared/rir_wheel_input_widget.dart';

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
  // Modell für die Berechnungen
  late StrengthCalculatorModel _calculatorModel;

  // Werte für die Eingabefelder
  double _testWeight = 0.0;
  int _testReps = 0;
  int _targetReps = 10;
  int _targetRIR = 2;

  // Zeigt an, ob eine Berechnung durchgeführt wurde
  bool _hasCalculated = false;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();

    // Modell mit Standardwerten initialisieren
    _calculatorModel = StrengthCalculatorModel(
        testWeight: _testWeight,
        testReps: _testReps,
        targetReps: _targetReps,
        targetRIR: _targetRIR);
  }

  // Aktualisiert das Modell mit den neuen Werten
  void _updateModelValues() {
    setState(() {
      _calculatorModel = _calculatorModel.copyWith(
        testWeight: _testWeight,
        testReps: _testReps,
        targetReps: _targetReps,
        targetRIR: _targetRIR,
      );

      // Bei Änderungen müssen die Berechnungen zurückgesetzt werden
      if (_hasCalculated) {
        _calculatorModel.resetCalculations();
        _hasCalculated = false;
      }
    });
  }

  // Führt die Berechnung durch
  void _calculateWorkingWeight() async {
    // Validierung
    if (_testWeight <= 0 ||
        _testReps <= 0 ||
        _targetReps <= 0 ||
        _targetRIR < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bitte gib gültige Werte ein.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    // Zeige Lade-Animation
    setState(() {
      _isCalculating = true;
    });

    // Künstliche Verzögerung für bessere UX
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
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
        _isCalculating = false;
      });
    }
  }

  // Wendet die berechneten Werte auf den aktuellen Satz an
  void _applyToCurrentSet() {
    if (_hasCalculated && _calculatorModel.calculatedWorkingWeight != null) {
      // Provide haptic feedback
      HapticFeedback.mediumImpact();

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Test-Werte Eingabebereich
        _buildSectionLabel('Testgewicht & Wiederholungen'),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gib das Gewicht und die Wiederholungen ein, die du bis zum Muskelversagen schaffst',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Testgewicht mit Wheel
                    Expanded(
                      flex: 3,
                      child: WeightSpinnerWidget(
                        value: _testWeight,
                        onChanged: (value) {
                          setState(() {
                            _testWeight = value;
                            _updateModelValues();
                          });
                        },
                        isEnabled: true,
                        isCompleted: false,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Wiederholungen mit Wheel
                    Expanded(
                      flex: 2,
                      child: RepetitionSpinnerWidget(
                        value: _testReps,
                        onChanged: (value) {
                          setState(() {
                            _testReps = value;
                            _updateModelValues();
                          });
                        },
                        isEnabled: true,
                        isCompleted: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Zielwerte Eingabebereich
        _buildSectionLabel('Zielwerte'),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gib die gewünschten Zielwerte für dein Training ein',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Zielwiederholungen mit Wheel
                    Expanded(
                      flex: 2,
                      child: RepetitionSpinnerWidget(
                        value: _targetReps,
                        onChanged: (value) {
                          setState(() {
                            _targetReps = value;
                            _updateModelValues();
                          });
                        },
                        isEnabled: true,
                        isCompleted: false,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Ziel-RIR mit Wheel
                    Expanded(
                      flex: 2,
                      child: RirSpinnerWidget(
                        value: _targetRIR,
                        onChanged: (value) {
                          setState(() {
                            _targetRIR = value;
                            _updateModelValues();
                          });
                        },
                        isEnabled: true,
                        isCompleted: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Berechnen-Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isCalculating ? null : _calculateWorkingWeight,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[600],
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isCalculating
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.grey[200]!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Berechnung läuft...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Berechnen',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
          ),
        ),

        // Ergebnisbereich (nur anzeigen, wenn Berechnung durchgeführt wurde)
        if (_hasCalculated && _calculatorModel.calculatedWorkingWeight != null)
          Column(
            children: [
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.green[300]!,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green[100],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Berechnungsergebnis',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // 1RM Ergebnis
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dein geschätztes 1RM:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            '${_calculatorModel.calculatedOneRM!.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Arbeitsgewicht Ergebnis
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Arbeitsgewicht für ${_calculatorModel.targetReps} Wdh. mit RIR ${_calculatorModel.targetRIR}:',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
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

                      const SizedBox(height: 24),

                      // Übernehmen-Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _applyToCurrentSet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Auf aktuellen Satz anwenden',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}
