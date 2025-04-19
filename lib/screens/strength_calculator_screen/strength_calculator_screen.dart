// lib/screens/strength_calculator_screen/strength_calculator_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/strength_calculator_screen/strength_calculator_form_widget.dart';

class StrengthCalculatorScreen extends StatelessWidget {
  // Callback-Funktion, die aufgerufen wird, wenn die Werte angewendet werden sollen
  final Function(double, int, int) onApplyValues;

  const StrengthCalculatorScreen({
    Key? key,
    required this.onApplyValues,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kraftrechner'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Erklärungstext
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 1,
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'So funktioniert der Kraftrechner',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1. Gib ein Gewicht ein, mit dem du eine Übung bis zum Muskelversagen ausführen kannst',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '2. Gib die Anzahl der Wiederholungen ein, die du mit diesem Gewicht schaffst',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '3. Gib deine Zielwiederholungen und Ziel-RIR (Reps in Reserve) ein',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '4. Der Rechner bestimmt das optimale Arbeitsgewicht für deine Zielwerte',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Rechner-Formular
              StrengthCalculatorFormWidget(
                onApplyValues: onApplyValues,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
