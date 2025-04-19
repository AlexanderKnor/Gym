// lib/widgets/training_session_screen/exercise_set_widget.dart
import 'package:flutter/material.dart';
import '../../models/progression_manager_screen/training_set_model.dart';
import '../../services/progression_manager_screen/one_rm_calculator_service.dart';

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
    // Berechne 1RM für aktuelle Werte
    final einRM = set.kg > 0 && set.wiederholungen > 0
        ? OneRMCalculatorService.calculate1RM(
            set.kg, set.wiederholungen, set.rir)
        : 0.0;

    // Berechne empfohlenen 1RM
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

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      color: isActive
          ? Colors.blue[50]
          : isCompleted
              ? Colors.green[50]
              : Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Satz-Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.blue
                            : isCompleted
                                ? Colors.green
                                : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${set.id}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isActive
                          ? 'Aktueller Satz'
                          : isCompleted
                              ? 'Satz abgeschlossen'
                              : 'Satz ${set.id}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? Colors.blue
                            : isCompleted
                                ? Colors.green[700]
                                : Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                // Status-Icon
                if (isCompleted)
                  Icon(Icons.check_circle, color: Colors.green[700])
                else if (isActive)
                  Icon(Icons.play_arrow, color: Colors.blue[700])
                else
                  Icon(Icons.circle_outlined, color: Colors.grey[700]),
              ],
            ),
            const SizedBox(height: 12),

            // Eingabefelder oder Werte, je nach Status
            Row(
              children: [
                // Gewicht
                Expanded(
                  child: _buildInputField(
                    context,
                    'Gewicht',
                    set.kg.toString(),
                    'kg',
                    isActive,
                    (value) => onValueChanged('kg', value),
                    recommendation != null
                        ? recommendation!['kg']?.toString()
                        : null,
                    'kg',
                  ),
                ),
                const SizedBox(width: 8),

                // Wiederholungen
                Expanded(
                  child: _buildInputField(
                    context,
                    'Wdh.',
                    set.wiederholungen.toString(),
                    '',
                    isActive,
                    (value) => onValueChanged('wiederholungen', value),
                    recommendation != null
                        ? recommendation!['wiederholungen']?.toString()
                        : null,
                    'wdh',
                  ),
                ),
                const SizedBox(width: 8),

                // RIR
                Expanded(
                  child: _buildInputField(
                    context,
                    'RIR',
                    set.rir.toString(),
                    '',
                    isActive,
                    (value) => onValueChanged('rir', value),
                    recommendation != null
                        ? recommendation!['rir']?.toString()
                        : null,
                    'rir',
                  ),
                ),
                const SizedBox(width: 8),

                // 1RM als Read-Only Feld
                Expanded(
                  child: _build1RMField(
                    context,
                    einRM,
                    empfohlener1RM,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context,
    String label,
    String value,
    String suffix,
    bool isEnabled,
    Function(String) onChanged,
    String? recommendationValue,
    String fieldType,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: value),
          keyboardType:
              TextInputType.numberWithOptions(decimal: fieldType == 'kg'),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            suffixText: suffix,
            isDense: true,
            enabled: isEnabled,
          ),
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isEnabled ? Colors.black : Colors.grey[600],
          ),
        ),
        if (isActive && recommendationValue != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.arrow_upward,
                size: 12,
                color: Colors.purple[700],
              ),
              const SizedBox(width: 2),
              Text(
                suffix.isNotEmpty
                    ? '$recommendationValue $suffix'
                    : recommendationValue,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _build1RMField(
    BuildContext context,
    double currentRM,
    double? suggestedRM,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1RM',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[100],
          ),
          width: double.infinity,
          child: Text(
            currentRM > 0 ? '${currentRM.toStringAsFixed(1)} kg' : '-',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        // Empfehlungs-1RM anzeigen
        if (isActive && suggestedRM != null && suggestedRM > 0) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.arrow_upward,
                size: 12,
                color: Colors.purple[700],
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  '${suggestedRM.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
