// lib/widgets/training_session_screen/repetition_spinner_widget.dart
import 'package:flutter/material.dart';
import '../shared/number_wheel_input_widget.dart';

class RepetitionSpinnerWidget extends StatelessWidget {
  final int value;
  final Function(int) onChanged;
  final bool isEnabled;
  final bool isCompleted;
  final String? recommendationValue;
  final Function(String)? onRecommendationApplied;

  const RepetitionSpinnerWidget({
    Key? key,
    required this.value,
    required this.onChanged,
    this.isEnabled = true,
    this.isCompleted = false,
    this.recommendationValue,
    this.onRecommendationApplied,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NumberWheelPickerWidget(
      value: value.toDouble(),
      onChanged: (newValue) => onChanged(newValue.toInt()),
      step: 1.0, // Wiederholungen immer um 1 erhöhen/verringern
      min: 0.0, // Minimum Wiederholungen 0
      max: 100.0, // Maximum Wiederholungen 100
      label: 'Wdh',
      isEnabled: isEnabled,
      isCompleted: isCompleted,
      recommendationValue: recommendationValue,
      onRecommendationApplied: onRecommendationApplied,
      decimalPlaces: 0, // Keine Dezimalstellen für Wiederholungen
      useIntValue: true, // Nur ganzzahlige Werte anzeigen
      allowCustomValues:
          false, // Bei Wiederholungen sind keine Zwischenwerte sinnvoll
    );
  }
}
