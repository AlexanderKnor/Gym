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

  // Clean color system matching other screens
  static const Color _midnight = Color(0xFF000000);
  static const Color _charcoal = Color(0xFF1C1C1E);
  static const Color _graphite = Color(0xFF2C2C2E);
  static const Color _steel = Color(0xFF48484A);
  static const Color _mercury = Color(0xFF8E8E93);
  static const Color _silver = Color(0xFFAEAEB2);
  static const Color _snow = Color(0xFFFFFFFF);
  static const Color _emberCore = Color(0xFFFF4500);

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
          backgroundColor: NumberWheelPickerWidget._charcoal,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: NumberWheelPickerWidget._steel.withOpacity(0.3),
              width: 1,
            ),
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
                        color: NumberWheelPickerWidget._emberCore.withOpacity(0.1),
                        border: Border.all(
                          color: NumberWheelPickerWidget._emberCore.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: NumberWheelPickerWidget._emberCore,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${widget.label} eingeben',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: NumberWheelPickerWidget._snow,
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: NumberWheelPickerWidget._snow,
                  ),
                  decoration: InputDecoration(
                    suffixText: widget.suffix,
                    suffixStyle: TextStyle(
                      color: NumberWheelPickerWidget._silver,
                      fontWeight: FontWeight.w500,
                    ),
                    filled: true,
                    fillColor: NumberWheelPickerWidget._graphite.withOpacity(0.6),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: NumberWheelPickerWidget._steel.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: NumberWheelPickerWidget._steel.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: NumberWheelPickerWidget._emberCore,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.red[400]!,
                        width: 1.5,
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
                      child: Container(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NumberWheelPickerWidget._graphite,
                            foregroundColor: NumberWheelPickerWidget._silver,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: NumberWheelPickerWidget._steel.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            'Abbrechen',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Confirm button
                    Expanded(
                      child: Container(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () =>
                              _applyEditedValue(dialogContext, controller.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NumberWheelPickerWidget._emberCore,
                            foregroundColor: NumberWheelPickerWidget._snow,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Bestätigen',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
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

  // Adaptive Schriftgröße basierend auf der Textlänge
  double _getAdaptiveFontSize(String text, bool isSelected) {
    final baseSize = isSelected ? 20.0 : 16.0;
    
    // Für längere Zahlen (z.B. dreistellig mit Dezimalstellen) Schriftgröße reduzieren
    if (text.length >= 6) {
      return baseSize * 0.85; // 15% Reduktion für sehr lange Zahlen
    } else if (text.length >= 5) {
      return baseSize * 0.92; // 8% Reduktion für lange Zahlen
    }
    
    return baseSize;
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
        // Clean label with recommendation badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: NumberWheelPickerWidget._silver,
                letterSpacing: 0.5,
              ),
            ),

            // Clean recommendation badge
            if (widget.isEnabled && widget.recommendationValue != null)
              GestureDetector(
                onTap: () =>
                    _handleRecommendationValue(widget.recommendationValue!),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: NumberWheelPickerWidget._emberCore.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: NumberWheelPickerWidget._emberCore.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_upward_rounded,
                        size: 10,
                        color: NumberWheelPickerWidget._emberCore,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        widget.recommendationValue!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: NumberWheelPickerWidget._emberCore,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 4),

        // Modern elevated container with subtle depth
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isEnabled
                  ? [
                      NumberWheelPickerWidget._charcoal.withOpacity(0.95),
                      NumberWheelPickerWidget._midnight.withOpacity(0.8),
                    ]
                  : widget.isCompleted
                      ? [
                          Colors.green.withOpacity(0.08),
                          Colors.green.withOpacity(0.03),
                        ]
                      : [
                          NumberWheelPickerWidget._charcoal.withOpacity(0.7),
                          NumberWheelPickerWidget._midnight.withOpacity(0.5),
                        ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isEnabled
                  ? NumberWheelPickerWidget._steel.withOpacity(0.4)
                  : widget.isCompleted
                      ? Colors.green.withOpacity(0.3)
                      : NumberWheelPickerWidget._steel.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: widget.isEnabled
                ? [
                    BoxShadow(
                      color: NumberWheelPickerWidget._midnight.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: NumberWheelPickerWidget._emberCore.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: SizedBox(
            height: 140,
            child: _buildOptimizedWheelPicker(),
          ),
        ),
      ],
    );
  }

  Widget _buildOptimizedWheelPicker() {
    return Stack(
      children: [
        // Wheel Picker - wichtig: Hier kein ClipRect oder ClipRRect verwenden!
        // Das erlaubt, dass Elemente "über" und "unter" dem zentralen Element sichtbar sind
        Positioned.fill(
          child: ListWheelScrollView.useDelegate(
            controller: _scrollController,
            physics: widget.isEnabled
                ? const FixedExtentScrollPhysics(
                    parent: BouncingScrollPhysics(), // Natürliche Bounce-Physik
                  )
                : const NeverScrollableScrollPhysics(),
            itemExtent: 50, // Mehr Platz für dreistellige Zahlen
            perspective: 0.002, // Sehr minimal für fast flaches Design
            diameterRatio: 4.0, // Maximaler Radius für natürliche Darstellung
            overAndUnderCenterOpacity: 0.3, // Starker Kontrast zur ausgewählten Zahl
            squeeze: 0.8, // Kompaktere Darstellung für mehr sichtbare Items
            onSelectedItemChanged: (index) {
              if (widget.isEnabled) {
                HapticFeedback.lightImpact(); // Enhanced haptic feedback
                setState(() {
                  _selectedIndex = index;
                });
                // Apply value
                widget.onChanged(_displayValues[index]);

                // Check if it's a custom or standard value
                _isCustomValue = false;
                for (int i = 0; i < _displayValues.length; i++) {
                  if (i == index) continue; // Skip current value
                  if (((_displayValues[index] - _displayValues[i]) %
                              widget.step)
                          .abs() <
                      0.001) {
                    // It's a standard value (on grid)
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

                // No highlighting of recommended values in the wheel itself

                return GestureDetector(
                  onTap: () {
                    // Direktes Klicken auf eine Zahl scrollt dorthin
                    if (widget.isEnabled && index != _selectedIndex) {
                      _scrollController.animateToItem(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      );
                      HapticFeedback.selectionClick();
                    } else if (widget.isEnabled && index == _selectedIndex) {
                      // Doppelklick auf ausgewählte Zahl öffnet Editor
                      _showEditValueDialog(context);
                    }
                  },
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: isSelected
                          ? BoxDecoration(
                              gradient: widget.isEnabled
                                  ? LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        NumberWheelPickerWidget._steel.withOpacity(0.6),
                                        NumberWheelPickerWidget._steel.withOpacity(0.3),
                                      ],
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(10),
                              border: widget.isEnabled
                                  ? Border.all(
                                      color: NumberWheelPickerWidget._emberCore.withOpacity(0.7),
                                      width: 1.5,
                                    )
                                  : null,
                              boxShadow: widget.isEnabled
                                  ? [
                                      BoxShadow(
                                        color: NumberWheelPickerWidget._emberCore.withOpacity(0.15),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                      BoxShadow(
                                        color: NumberWheelPickerWidget._midnight.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            )
                          : widget.isEnabled
                              ? BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.transparent,
                                )
                              : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              _formatValue(value),
                              style: TextStyle(
                              fontSize: _getAdaptiveFontSize(_formatValue(value), isSelected),
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? widget.isEnabled
                                      ? NumberWheelPickerWidget._snow
                                      : widget.isCompleted
                                          ? Colors.green
                                          : NumberWheelPickerWidget._silver
                                  : NumberWheelPickerWidget._silver.withOpacity(0.8),
                              letterSpacing: isSelected ? -0.5 : -0.2,
                              height: 1.0, // Compact line height
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.suffix.isNotEmpty)
                            Text(
                              ' ${widget.suffix}',
                              style: TextStyle(
                                fontSize: isSelected ? 14 : 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? NumberWheelPickerWidget._silver
                                    : NumberWheelPickerWidget._silver.withOpacity(0.6),
                                letterSpacing: -0.2,
                                height: 1.0,
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

        // Modern selection guides with gradient effect
        if (widget.isEnabled)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  height: 54,
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        NumberWheelPickerWidget._emberCore.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: NumberWheelPickerWidget._emberCore.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        
        // Subtle center focus indicator
        if (widget.isEnabled)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        NumberWheelPickerWidget._emberCore.withOpacity(0.6),
                        NumberWheelPickerWidget._emberCore.withOpacity(0.2),
                        Colors.transparent,
                      ],
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
