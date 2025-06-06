// lib/widgets/shared/standard_increment_wheel_widget.dart
import 'package:flutter/material.dart';
import '../shared/number_wheel_input_widget.dart';

class StandardIncrementWheelWidget extends StatelessWidget {
  final double value;
  final Function(double) onChanged;
  final bool isEnabled;

  const StandardIncrementWheelWidget({
    Key? key,
    required this.value,
    required this.onChanged,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NumberWheelPickerWidget(
      value: value,
      onChanged: onChanged,
      step: 0.25, // Standardsteigerung in 0.25kg Schritten
      min: 0.25, // Minimum Steigerung 0.5kg
      max: 10.0, // Maximum Steigerung 10kg
      suffix: 'kg',
      label: 'Standardsteigerung',
      isEnabled: isEnabled,
      decimalPlaces: 2, // Zwei Dezimalstelle für Gewicht (z.B. 2.25 kg)
      useIntValue: false,
      allowCustomValues: true, // Erlaubt benutzerdefinierte Werte
    );
  }
}
