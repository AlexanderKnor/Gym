// lib/widgets/training_session_screen/weight_spinner_widget.dart
import 'package:flutter/material.dart';
import '../shared/number_wheel_input_widget.dart';

class WeightSpinnerWidget extends StatelessWidget {
  final double value;
  final Function(double) onChanged;
  final bool isEnabled;
  final bool isCompleted;
  final String? recommendationValue;
  final Function(String)? onRecommendationApplied;

  const WeightSpinnerWidget({
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
      value: value,
      onChanged: onChanged,
      step: 0.5, // Gewicht in 0.5kg Schritten für den Spinner
      min: 0.0, // Minimum Gewicht 0kg
      max: 500.0, // Maximum Gewicht 500kg
      suffix: 'kg',
      label: 'Gewicht',
      isEnabled: isEnabled,
      isCompleted: isCompleted,
      recommendationValue: recommendationValue,
      onRecommendationApplied: onRecommendationApplied,
      decimalPlaces: 1, // Eine Dezimalstelle für Gewicht (z.B. 72.5 kg)
      useIntValue: false,
      allowCustomValues: true, // Erlaubt benutzerdefinierte Werte wie 14.2kg
    );
  }
}
