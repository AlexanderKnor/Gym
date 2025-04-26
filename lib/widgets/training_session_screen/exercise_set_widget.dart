// lib/widgets/training_session_screen/exercise_set_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/progression_manager_screen/training_set_model.dart';
import '../../services/progression_manager_screen/one_rm_calculator_service.dart';
import '../shared/weight_wheel_input_widget.dart';
import '../shared/repetition_wheel_input_widget.dart';
import '../shared/rir_wheel_input_widget.dart';

class ExerciseSetWidget extends StatelessWidget {
  final TrainingSetModel set;
  final bool isActive;
  final bool isCompleted;
  final Function(String, dynamic) onValueChanged;
  final Map<String, dynamic>? recommendation;

  const ExerciseSetWidget({
    Key? key,
    required this.set,
    required this.isActive,
    required this.isCompleted,
    required this.onValueChanged,
    this.recommendation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1RM Calculations
    final einRM = set.kg > 0 && set.wiederholungen > 0
        ? OneRMCalculatorService.calculate1RM(
            set.kg, set.wiederholungen, set.rir)
        : null;

    double? empfohlener1RM;
    if (recommendation != null) {
      final empfKg = recommendation!['kg'] as double?;
      final empfWdh = recommendation!['wiederholungen'] as int?;
      final empfRir = recommendation!['rir'] as int?;

      if (empfKg != null && empfWdh != null && empfRir != null) {
        empfohlener1RM =
            OneRMCalculatorService.calculate1RM(empfKg, empfWdh, empfRir);
      }
    }

    // Kompaktere Karte mit eleganter Gestaltung
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? Colors.black
              : isCompleted
                  ? Colors.green[300]!
                  : Colors.grey[200]!,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Header mit Set-Nummer und Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.black
                  : isCompleted
                      ? Colors.green[50]
                      : Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                // Set-Nummer
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? Colors.white
                        : isCompleted
                            ? Colors.green
                            : Colors.grey[400],
                  ),
                  child: Center(
                    child: Text(
                      '${set.id}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Status-Text
                Text(
                  isActive
                      ? 'Aktueller Satz'
                      : isCompleted
                          ? 'Abgeschlossen'
                          : 'Satz ${set.id}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                    color: isActive
                        ? Colors.white
                        : isCompleted
                            ? Colors.green[700]
                            : Colors.grey[700],
                  ),
                ),

                const Spacer(),

                // Status-Icon
                if (isCompleted)
                  Icon(
                    Icons.check,
                    color: Colors.green[700],
                    size: 18,
                  )
                else if (isActive)
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 18,
                  ),
              ],
            ),
          ),

          // Spinner-Widgets für Werte
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gewicht-Spinner
                Expanded(
                  flex: 3,
                  child: WeightSpinnerWidget(
                    value: set.kg,
                    onChanged: (value) => onValueChanged('kg', value),
                    isEnabled: isActive && !isCompleted,
                    isCompleted: isCompleted,
                    recommendationValue: recommendation != null
                        ? recommendation!['kg']?.toString()
                        : null,
                    onRecommendationApplied: (value) {
                      // Hier ist die kritische Stelle: Wir müssen sicherstellen, dass der exakte Wert übergeben wird
                      double? parsedValue = double.tryParse(value);
                      if (parsedValue != null) {
                        // Direkt den exakten Wert setzen, ohne Rundung
                        onValueChanged('kg', parsedValue);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // Wiederholungen-Spinner
                Expanded(
                  flex: 2,
                  child: RepetitionSpinnerWidget(
                    value: set.wiederholungen,
                    onChanged: (value) =>
                        onValueChanged('wiederholungen', value),
                    isEnabled: isActive && !isCompleted,
                    isCompleted: isCompleted,
                    recommendationValue: recommendation != null
                        ? recommendation!['wiederholungen']?.toString()
                        : null,
                    onRecommendationApplied: (value) {
                      int? parsedValue = int.tryParse(value);
                      if (parsedValue != null) {
                        onValueChanged('wiederholungen', parsedValue);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // RIR-Spinner
                Expanded(
                  flex: 2,
                  child: RirSpinnerWidget(
                    value: set.rir,
                    onChanged: (value) => onValueChanged('rir', value),
                    isEnabled: isActive && !isCompleted,
                    isCompleted: isCompleted,
                    recommendationValue: recommendation != null
                        ? recommendation!['rir']?.toString()
                        : null,
                    onRecommendationApplied: (value) {
                      int? parsedValue = int.tryParse(value);
                      if (parsedValue != null) {
                        onValueChanged('rir', parsedValue);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // 1RM Info als optionales Element
          if (einRM != null || (isActive && empfohlener1RM != null))
            Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Aktuelle 1RM
                  Text(
                    '1RM: ${einRM != null ? einRM.toStringAsFixed(1) : "—"} kg',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),

                  // Empfohlene 1RM, falls verfügbar
                  if (isActive && empfohlener1RM != null)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            size: 10,
                            color: Colors.purple[700],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${empfohlener1RM.toStringAsFixed(1)} kg',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
