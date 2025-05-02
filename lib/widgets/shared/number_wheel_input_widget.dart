// lib/widgets/shared/number_wheel_picker_widget.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumberWheelPickerWidget extends StatefulWidget {
  final double value;
  final Function(double) onChanged;
  final double step;
  final double min;
  final double max;
  final String suffix;
  final String label;
  final bool isEnabled;
  final bool isCompleted;
  final String? recommendationValue;
  final Function(String)? onRecommendationApplied;
  final int decimalPlaces;
  final bool useIntValue; // Wenn true, werden nur ganzzahlige Werte angezeigt
  final bool allowCustomValues; // Wenn true, werden beliebige Werte akzeptiert

  const NumberWheelPickerWidget({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.step,
    required this.min,
    required this.max,
    required this.label,
    this.suffix = '',
    this.isEnabled = true,
    this.isCompleted = false,
    this.recommendationValue,
    this.onRecommendationApplied,
    this.decimalPlaces = 1,
    this.useIntValue = false,
    this.allowCustomValues =
        true, // Standardmäßig erlauben wir benutzerdefinierte Werte
  }) : super(key: key);

  @override
  State<NumberWheelPickerWidget> createState() =>
      _NumberWheelPickerWidgetState();
}

class _NumberWheelPickerWidgetState extends State<NumberWheelPickerWidget> {
  late FixedExtentScrollController _scrollController;
  late int _selectedIndex;
  late List<double>
      _displayValues; // Die im Spinner angezeigten Werte (inkl. benutzerdefinierter Wert)
  bool _isCustomValue = false; // Flag für benutzerdefinierten Wert

  // Neue Variable, um den letzten empfohlenen Wert zu speichern
  double? _lastRecommendedValue;

  @override
  void initState() {
    super.initState();
    _generateDisplayValues();
    _initScrollController();
  }

  // Generiert die Werte für das Spinner-Rad, inkl. des aktuellen Werts, falls dieser kein Standardwert ist
  void _generateDisplayValues() {
    _displayValues = [];

    // Standardwerte nach Step-Größe generieren
    for (double value = widget.min; value <= widget.max; value += widget.step) {
      _displayValues.add(value);
    }

    // Prüfen, ob der aktuelle Wert ein benutzerdefinierter Wert ist
    if (widget.allowCustomValues) {
      bool isOnStandardValue = false;
      double tolerance = 0.001; // Toleranz für Floating-Point-Vergleiche

      for (double standardValue in _displayValues) {
        if ((widget.value - standardValue).abs() < tolerance) {
          isOnStandardValue = true;
          break;
        }
      }

      // Wenn nicht auf Standardwert, dann als benutzerdefinierten Wert einfügen
      if (!isOnStandardValue &&
          widget.value >= widget.min &&
          widget.value <= widget.max) {
        _isCustomValue = true;

        // An der richtigen Position einfügen (sortiert)
        int insertIndex = 0;
        while (insertIndex < _displayValues.length &&
            _displayValues[insertIndex] < widget.value) {
          insertIndex++;
        }

        _displayValues.insert(insertIndex, widget.value);
      } else {
        _isCustomValue = false;
      }
    }

    // WICHTIG: Wenn ein empfohlener Wert gespeichert ist, diesen immer einschließen
    if (_lastRecommendedValue != null) {
      bool recommendedValueExists = false;
      double tolerance = 0.001;

      for (double value in _displayValues) {
        if ((_lastRecommendedValue! - value).abs() < tolerance) {
          recommendedValueExists = true;
          break;
        }
      }

      if (!recommendedValueExists) {
        // Empfohlenen Wert an der richtigen Position einfügen (sortiert)
        int insertIndex = 0;
        while (insertIndex < _displayValues.length &&
            _displayValues[insertIndex] < _lastRecommendedValue!) {
          insertIndex++;
        }

        _displayValues.insert(insertIndex, _lastRecommendedValue!);
      }
    }
  }

  void _initScrollController() {
    // Finde den Index des aktuellen Werts im Spinner
    _selectedIndex = _findValueIndex(widget.value);
    _scrollController =
        FixedExtentScrollController(initialItem: _selectedIndex);
  }

  // Findet den Index des Werts in der Liste oder den nächstgelegenen Wert
  int _findValueIndex(double value) {
    double tolerance = 0.001; // Toleranz für Floating-Point-Vergleiche

    // Exakten Index suchen
    for (int i = 0; i < _displayValues.length; i++) {
      if ((value - _displayValues[i]).abs() < tolerance) {
        return i;
      }
    }

    // Wenn nicht gefunden (sollte nicht passieren, da wir den Wert eingefügt haben)
    // den nächstgelegenen Wert zurückgeben
    int closestIndex = 0;
    double minDiff = double.infinity;

    for (int i = 0; i < _displayValues.length; i++) {
      double diff = (value - _displayValues[i]).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  @override
  void didUpdateWidget(NumberWheelPickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.min != widget.min ||
        oldWidget.max != widget.max ||
        oldWidget.step != widget.step ||
        oldWidget.value != widget.value) {
      // Bei Änderung der Parameter oder des Werts die Anzeige-Werte neu generieren
      _generateDisplayValues();
      _updateValueOnWheel();
    }
  }

  void _updateValueOnWheel() {
    // Aktualisiere die Position im Spinner
    int newIndex = _findValueIndex(widget.value);
    if (newIndex != _selectedIndex) {
      _selectedIndex = newIndex;

      // Versuche, den ScrollController zu aktualisieren, wenn er existiert
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpToItem(
              _selectedIndex); // WICHTIG: jumpToItem statt animateToItem verwenden
        }
      });
    }
  }

  // Verarbeitet einen Empfehlungswert und behandelt ihn als benutzerdefinierten Wert
  void _handleRecommendationValue(String recommendationText) {
    if (widget.onRecommendationApplied != null) {
      // Parsen des empfohlenen Werts
      double? recommendedValue = double.tryParse(recommendationText);
      if (recommendedValue != null) {
        // Empfohlenen Wert für spätere Verwendung speichern
        _lastRecommendedValue = recommendedValue;

        // Zuerst die Liste neu generieren, um den empfohlenen Wert einzufügen
        setState(() {
          _generateDisplayValues();
        });

        // Parent-Callback ausführen, damit der Wert auch dort aktualisiert wird
        widget.onRecommendationApplied!(recommendationText);

        // Aktualisiere die angezeigte Position sofort ohne Animation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _selectedIndex = _findValueIndex(recommendedValue);
            if (_scrollController.hasClients) {
              _scrollController.jumpToItem(_selectedIndex);
            }
          });
        });

        // Vibrations-Feedback
        HapticFeedback.selectionClick();
      }
    }
  }

  // Öffnet einen Dialog zur manuellen Eingabe des Wertes
  void _showEditValueDialog(BuildContext context) {
    if (!widget.isEnabled) return;

    HapticFeedback.mediumImpact();

    final TextEditingController controller = TextEditingController(
        text: widget.useIntValue
            ? widget.value.toInt().toString()
            : widget.value.toStringAsFixed(widget.decimalPlaces));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog Header
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${widget.label} eingeben',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Input Field
                TextField(
                  controller: controller,
                  keyboardType: widget.useIntValue
                      ? TextInputType.number
                      : const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    suffixText: widget.suffix,
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.red[400]!,
                        width: 1,
                      ),
                    ),
                  ),
                  onSubmitted: (_) =>
                      _applyEditedValue(dialogContext, controller.text),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[800],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Abbrechen',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Confirm button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            _applyEditedValue(dialogContext, controller.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Bestätigen',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Verarbeitet den eingegebenen Wert und schließt den Dialog
  void _applyEditedValue(BuildContext dialogContext, String text) {
    double? newValue = double.tryParse(text.replaceAll(',', '.'));
    if (newValue != null) {
      // Nur Min/Max-Grenzen anwenden, keine Schrittrundung für manuelle Eingaben
      newValue = newValue.clamp(widget.min, widget.max);

      // Als benutzerdefinierten Wert merken
      _lastRecommendedValue = newValue;

      // Dialog schließen
      Navigator.pop(dialogContext);

      // Wert anwenden, wenn er sich geändert hat
      if (newValue != widget.value) {
        // Werte neu generieren für die Anzeige
        setState(() {
          _generateDisplayValues();
        });

        // Parent-Widget informieren
        widget.onChanged(newValue);

        // Aktualisiere die Position sofort
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _selectedIndex = _findValueIndex(newValue!);
            if (_scrollController.hasClients) {
              _scrollController.jumpToItem(_selectedIndex);
            }
          });
        });

        // Haptic feedback
        HapticFeedback.selectionClick();
      }
    } else {
      // Bei ungültiger Eingabe eine kleine Benachrichtigung anzeigen
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: const Text('Bitte gib einen gültigen Wert ein'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatValue(double value) {
    if (widget.useIntValue) {
      return value.toInt().toString();
    } else {
      // Bei benutzerdefinierten Werten alle Dezimalstellen anzeigen, sonst nur die angegebene Anzahl
      if (_isCustomValue && !widget.useIntValue && value == widget.value) {
        // Für den benutzerdefinierten Wert alle notwendigen Dezimalstellen anzeigen
        String formatted = value.toString();
        // Entferne .0 am Ende, wenn es keine echte Dezimalstelle ist
        if (formatted.endsWith('.0')) {
          formatted = formatted.substring(0, formatted.length - 2);
        }
        return formatted;
      } else {
        return value.toStringAsFixed(widget.decimalPlaces);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label mit Recommendation-Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),

            // Empfehlungs-Badge im modernen schwarzen Design
            if (widget.isEnabled && widget.recommendationValue != null)
              GestureDetector(
                onTap: () =>
                    _handleRecommendationValue(widget.recommendationValue!),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_upward_rounded,
                        size: 8,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        widget.recommendationValue!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 4),

        // Input container
        Container(
          height: 120, // Höher machen, damit mehr Elemente sichtbar sind
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isEnabled
                  ? Colors.grey[300]!
                  : widget.isCompleted
                      ? Colors.green[200]!
                      : Colors.grey[200]!,
            ),
            color: widget.isEnabled
                ? Colors.white
                : widget.isCompleted
                    ? Colors.green[50]
                    : Colors.grey[50],
            boxShadow: widget.isEnabled
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: _buildWheelPicker(),
        ),
      ],
    );
  }

  Widget _buildWheelPicker() {
    return Stack(
      children: [
        // Wheel Picker - wichtig: Hier kein ClipRect oder ClipRRect verwenden!
        // Das erlaubt, dass Elemente "über" und "unter" dem zentralen Element sichtbar sind
        Positioned.fill(
          child: ListWheelScrollView.useDelegate(
            controller: _scrollController,
            physics: widget.isEnabled
                ? const FixedExtentScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            itemExtent: 38, // Etwas kleiner für mehr sichtbare Elemente
            perspective: 0.005, // Weniger Perspektive für klarere Darstellung
            diameterRatio: 2.3, // Größerer Radius für weniger starke Krümmung
            overAndUnderCenterOpacity:
                0.8, // Transparenz für oberen und unteren Wert
            onSelectedItemChanged: (index) {
              if (widget.isEnabled) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedIndex = index;
                });
                // Wert anwenden
                widget.onChanged(_displayValues[index]);

                // Prüfen ob es ein benutzerdefinierter oder Standardwert ist
                _isCustomValue = false;
                for (int i = 0; i < _displayValues.length; i++) {
                  if (i == index) continue; // Aktueller Wert überspringen
                  if (((_displayValues[index] - _displayValues[i]) %
                              widget.step)
                          .abs() <
                      0.001) {
                    // Es ist ein Standardwert (auf dem Raster)
                    _isCustomValue = false;
                    break;
                  }
                  _isCustomValue = true;
                }
              }
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                if (index < 0 || index >= _displayValues.length) {
                  return null;
                }

                final value = _displayValues[index];
                final isSelected = index == _selectedIndex;

                return GestureDetector(
                  onTap: () => _showEditValueDialog(context),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: isSelected
                          ? BoxDecoration(
                              color: widget.isEnabled
                                  ? Colors.grey[100]
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: widget.isEnabled
                                  ? Border.all(color: Colors.grey[300]!)
                                  : null,
                            )
                          : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatValue(value),
                            style: TextStyle(
                              fontSize: isSelected ? 18 : 16,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? widget.isEnabled
                                      ? Colors.black
                                      : widget.isCompleted
                                          ? Colors.green[700]
                                          : Colors.grey[600]
                                  : Colors.grey[600],
                            ),
                          ),
                          if (widget.suffix.isNotEmpty)
                            Text(
                              ' ${widget.suffix}',
                              style: TextStyle(
                                fontSize: isSelected ? 14 : 12,
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: _displayValues.length,
            ),
          ),
        ),

        // Center selection indicator - durchsichtige Linien für natürlichere Darstellung
        if (widget.isEnabled)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border(
                      top:
                          BorderSide(color: Colors.grey[300]!.withOpacity(0.7)),
                      bottom:
                          BorderSide(color: Colors.grey[300]!.withOpacity(0.7)),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
