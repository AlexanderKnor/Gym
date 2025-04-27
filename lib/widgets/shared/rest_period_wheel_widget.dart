// lib/widgets/shared/rest_period_wheel_widget.dart
import 'package:flutter/material.dart';
import '../shared/number_wheel_input_widget.dart';

class RestPeriodWheelWidget extends StatelessWidget {
  final int value;
  final Function(int) onChanged;
  final bool isEnabled;

  const RestPeriodWheelWidget({
    Key? key,
    required this.value,
    required this.onChanged,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NumberWheelPickerWidget(
      value: value.toDouble(),
      onChanged: (newValue) => onChanged(newValue.toInt()),
      step: 5.0, // Pausenzeit in 5 Sekunden Schritten
      min: 15.0, // Minimum Pause 15 Sekunden
      max: 300.0, // Maximum Pause 300 Sekunden (5 Minuten)
      suffix: 's',
      label: 'Satzpause',
      isEnabled: isEnabled,
      decimalPlaces: 0, // Keine Dezimalstellen für Sekunden
      useIntValue: true, // Nur ganzzahlige Werte anzeigen
      allowCustomValues: true, // Erlaubt benutzerdefinierte Werte
    );
  }
}
