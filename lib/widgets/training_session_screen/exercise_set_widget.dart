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

  // Clean color system matching training screen
  static const Color _midnight = Color(0xFF000000);
  static const Color _charcoal = Color(0xFF1C1C1E);
  static const Color _graphite = Color(0xFF2C2C2E);
  static const Color _steel = Color(0xFF48484A);
  static const Color _mercury = Color(0xFF8E8E93);
  static const Color _silver = Color(0xFFAEAEB2);
  static const Color _snow = Color(0xFFFFFFFF);
  static const Color _emberCore = Color(0xFFFF4500);

  const ExerciseSetWidget({
    Key? key,
    required this.set,
    required this.isActive,
    required this.isCompleted,
    required this.onValueChanged,
    this.recommendation,
  }) : super(key: key);

  // Prüft, ob Empfehlungen angezeigt werden sollen
  bool shouldShowRecommendation() {
    if (recommendation == null) return false;

    // Keine Empfehlung anzeigen, wenn alle empfohlenen Werte 0 oder null sind
    if ((recommendation!['kg'] == null || recommendation!['kg'] == 0) &&
        (recommendation!['wiederholungen'] == null ||
            recommendation!['wiederholungen'] == 0) &&
        (recommendation!['rir'] == null || recommendation!['rir'] == 0)) {
      return false;
    }

    // Keine Empfehlung anzeigen, wenn alle Werte exakt der Empfehlung entsprechen
    if (set.kg == recommendation!['kg'] &&
        set.wiederholungen == recommendation!['wiederholungen'] &&
        set.rir == recommendation!['rir']) {
      return false;
    }

    return true;
  }

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

    // Schatten definieren basierend auf dem Status
    final List<BoxShadow> cardShadows = isActive
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              offset: const Offset(0, 1),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ]
        : isCompleted
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.08),
                  offset: const Offset(0, 1),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  offset: const Offset(0, 1),
                  blurRadius: 3,
                  spreadRadius: 0,
                ),
              ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _charcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? _emberCore
              : isCompleted
                  ? Colors.green
                  : _steel.withOpacity(0.4),
          width: isActive ? 2 : 1,
        ),
        boxShadow: cardShadows,
      ),
      child: Column(
        children: [
          // Header mit Set-Nummer und Status
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isActive
                      ? [_emberCore, _emberCore.withOpacity(0.8)]
                      : isCompleted
                          ? [
                              Colors.green.withOpacity(0.2),
                              Colors.green.withOpacity(0.1)
                            ]
                          : [
                              _steel.withOpacity(0.3),
                              _steel.withOpacity(0.1)
                            ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isActive
                        ? Colors.black.withOpacity(0.1)
                        : Colors.transparent,
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Set-Nummer mit verbessertem Design
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? Colors.white
                          : isCompleted
                              ? Colors.green
                              : _graphite, // Dunkler Hintergrund für starken Kontrast
                      border: isActive || isCompleted 
                          ? null 
                          : Border.all(
                              color: _silver.withOpacity(0.3),
                              width: 1,
                            ), // Subtiler Border für ausstehende Sätze
                      boxShadow: [
                        BoxShadow(
                          color: (isActive
                                  ? Colors.black
                                  : isCompleted
                                      ? Colors.green
                                      : _graphite)!
                              .withOpacity(0.2),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${set.id}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isActive 
                              ? Colors.black 
                              : isCompleted 
                                  ? Colors.white
                                  : _snow, // Weißer Text für bessere Lesbarkeit auf dunklem Hintergrund
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Status-Text mit verbesserter Typografie
                  Text(
                    isActive
                        ? 'Aktueller Satz'
                        : isCompleted
                            ? 'Abgeschlossen'
                            : 'Satz ${set.id}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: isActive
                          ? Colors.white
                          : isCompleted
                              ? Colors.green[700]
                              : Colors.grey[700],
                    ),
                  ),

                  const Spacer(),

                  // Status-Icon: Nur Haken für abgeschlossene Sätze
                  if (isCompleted)
                    Icon(
                      Icons.check_rounded,
                      color: Colors.green[700],
                      size: 20,
                    )
                  else if (isActive)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Widget für Werte - unterschiedliches Layout je nach Zustand
          if (isActive)
            // Spinner-Widgets für Werte im aktiven Zustand
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
                      recommendationValue: recommendation != null &&
                              isActive &&
                              shouldShowRecommendation()
                          ? recommendation!['kg']?.toString()
                          : null,
                      onRecommendationApplied: (value) {
                        double? parsedValue = double.tryParse(value);
                        if (parsedValue != null) {
                          HapticFeedback.mediumImpact();
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
                      recommendationValue: recommendation != null &&
                              isActive &&
                              shouldShowRecommendation()
                          ? recommendation!['wiederholungen']?.toString()
                          : null,
                      onRecommendationApplied: (value) {
                        int? parsedValue = int.tryParse(value);
                        if (parsedValue != null) {
                          HapticFeedback.mediumImpact();
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
                      recommendationValue: recommendation != null &&
                              isActive &&
                              shouldShowRecommendation()
                          ? recommendation!['rir']?.toString()
                          : null,
                      onRecommendationApplied: (value) {
                        int? parsedValue = int.tryParse(value);
                        if (parsedValue != null) {
                          HapticFeedback.mediumImpact();
                          onValueChanged('rir', parsedValue);
                        }
                      },
                    ),
                  ),
                ],
              ),
            )
          else
            // Elegante kompakte Darstellung für nicht-aktive Sätze
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gewicht
                  _buildMinimalValueDisplay(
                    context: context,
                    label: 'Gewicht',
                    value: '${set.kg}',
                    unit: 'kg',
                    isCompleted: isCompleted,
                    flex: 3,
                  ),

                  // Vertikaler Trenner
                  _buildMinimalSeparator(isCompleted: isCompleted),

                  // Wiederholungen
                  _buildMinimalValueDisplay(
                    context: context,
                    label: 'Wdh',
                    value: '${set.wiederholungen}',
                    unit: '',
                    isCompleted: isCompleted,
                    flex: 2,
                  ),

                  // Vertikaler Trenner
                  _buildMinimalSeparator(isCompleted: isCompleted),

                  // RIR
                  _buildMinimalValueDisplay(
                    context: context,
                    label: 'RIR',
                    value: '${set.rir}',
                    unit: '',
                    isCompleted: isCompleted,
                    flex: 2,
                  ),
                ],
              ),
            ),

          // 1RM Info als elegante Fußzeile
          if (einRM != null || (isActive && empfohlener1RM != null))
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: _graphite.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
                border: Border(
                  top: BorderSide(
                    color: _steel.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 1RM mit besserem Styling
                  Text(
                    '1RM: ${einRM != null ? einRM.toStringAsFixed(1) : "—"} kg',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _silver,
                      letterSpacing: -0.3,
                    ),
                  ),

                  // Empfohlene 1RM mit verbessertem Design
                  if (isActive && empfohlener1RM != null)
                    Container(
                      margin: const EdgeInsets.only(left: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${empfohlener1RM.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Minimalistischer Trenner
  Widget _buildMinimalSeparator({required bool isCompleted}) {
    return Container(
      height: 36,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[200]!.withOpacity(0.0),
            isCompleted
                ? Colors.green[200]!.withOpacity(0.7)
                : _steel.withOpacity(0.4), // Bessere Sichtbarkeit auf dunklem Hintergrund
            Colors.grey[200]!.withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  // Hilfsmethode für die minimalistische Werteanzeige ohne Icons
  Widget _buildMinimalValueDisplay({
    required BuildContext context,
    required String label,
    required String value,
    required String unit,
    required bool isCompleted,
    required int flex,
  }) {
    final Color valueColor =
        isCompleted ? Colors.green[700]! : _silver; // Ausgegrauter Text für ausstehende Sätze  
    final Color labelColor =
        isCompleted ? Colors.green[600]! : _mercury; // Noch subtilere Labels

    return Expanded(
      flex: flex,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: labelColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),

          // Wert mit Einheit
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                    letterSpacing: -0.5,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isCompleted ? Colors.green[600] : Colors.grey[600],
                      letterSpacing: -0.3,
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
