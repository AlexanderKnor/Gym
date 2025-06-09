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
  final VoidCallback? onReactivate;

  // Clean color system matching other screens
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
    this.onReactivate,
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

    // Modern shadows matching wheel design
    final List<BoxShadow>? cardShadows = isActive
        ? [
            BoxShadow(
              color: _midnight.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: _emberCore.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
        : isCompleted
            ? [
                BoxShadow(
                  color: _midnight.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive
              ? [
                  _charcoal.withOpacity(0.95),
                  _midnight.withOpacity(0.85),
                ]
              : isCompleted
                  ? [
                      _midnight.withOpacity(0.85),
                      _midnight.withOpacity(0.7),
                    ]
                  : [
                      _midnight.withOpacity(0.7),
                      _midnight.withOpacity(0.5),
                    ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? _emberCore.withOpacity(0.5)
              : isCompleted
                  ? Colors.green.withOpacity(0.4)
                  : _steel.withOpacity(0.3),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: cardShadows,
      ),
      child: Column(
        children: [
          // Modern elevated header matching wheel design
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isActive
                    ? [
                        _steel.withOpacity(0.4),
                        _steel.withOpacity(0.2),
                      ]
                    : isCompleted
                        ? [
                            Colors.green.withOpacity(0.08),
                            Colors.green.withOpacity(0.03),
                          ]
                        : [
                            _charcoal.withOpacity(0.4),
                            _charcoal.withOpacity(0.2),
                          ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isActive ? 14.5 : 15),
                topRight: Radius.circular(isActive ? 14.5 : 15),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isActive
                      ? _emberCore.withOpacity(0.3)
                      : isCompleted
                          ? Colors.green.withOpacity(0.2)
                          : _steel.withOpacity(0.15),
                  width: isActive ? 1.5 : 1,
                ),
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: _emberCore.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                  // Modern elevated badge matching wheel design
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isActive
                          ? LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                _emberCore.withOpacity(0.2),
                                _emberCore.withOpacity(0.1),
                              ],
                            )
                          : isCompleted
                              ? LinearGradient(
                                  colors: [
                                    Colors.green.withOpacity(0.2),
                                    Colors.green.withOpacity(0.1),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    _steel.withOpacity(0.4),
                                    _steel.withOpacity(0.2),
                                  ],
                                ),
                      border: Border.all(
                        color: isActive
                            ? _emberCore.withOpacity(0.6)
                            : isCompleted
                                ? Colors.green.withOpacity(0.5)
                                : _steel.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isActive
                              ? _emberCore.withOpacity(0.15)
                              : isCompleted
                                  ? Colors.green.withOpacity(0.1)
                                  : _midnight.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${set.id}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isActive 
                              ? _emberCore
                              : isCompleted 
                                  ? Colors.green
                                  : _snow,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Clean status text
                  Text(
                    isActive
                        ? 'Aktueller Satz'
                        : isCompleted
                            ? 'Abgeschlossen'
                            : 'Satz ${set.id}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? _snow
                          : isCompleted
                              ? Colors.green
                              : _silver,
                    ),
                  ),

                  const Spacer(),

                  // Status-Icon und Reaktivieren-Button
                  if (isCompleted && onReactivate != null) ...[                    
                    // Reaktivieren-Button nur für den letzten abgeschlossenen Satz
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onReactivate,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.replay_rounded,
                                color: Colors.green[700],
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Reaktivieren',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]
                  else if (isCompleted)
                    // Normaler Haken für abgeschlossene Sätze ohne Reaktivieren-Option
                    Icon(
                      Icons.check_rounded,
                      color: Colors.green[700],
                      size: 20,
                    )
                  else if (isActive)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _emberCore,
                      ),
                    ),
              ],
            ),
          ),

          // Interactive input widgets for active state
          if (isActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weight spinner with enhanced design
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
                  const SizedBox(width: 14),

                  // Repetitions spinner with enhanced design
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
                  const SizedBox(width: 14),

                  // RIR spinner with enhanced design
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
            // Clean compact display for non-active sets
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Weight display
                  _buildMinimalValueDisplay(
                    context: context,
                    label: 'GEWICHT',
                    value: '${set.kg}',
                    unit: 'kg',
                    isCompleted: isCompleted,
                    flex: 3,
                  ),

                  // Elegant vertical separator
                  _buildMinimalSeparator(isCompleted: isCompleted),

                  // Repetitions display
                  _buildMinimalValueDisplay(
                    context: context,
                    label: 'WDH',
                    value: '${set.wiederholungen}',
                    unit: '',
                    isCompleted: isCompleted,
                    flex: 2,
                  ),

                  // Elegant vertical separator
                  _buildMinimalSeparator(isCompleted: isCompleted),

                  // RIR display
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

          // Modern elevated footer matching wheel design
          if (einRM != null || (isActive && empfohlener1RM != null))
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _charcoal.withOpacity(0.3),
                    _charcoal.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(isActive ? 14.5 : 15),
                  bottomRight: Radius.circular(isActive ? 14.5 : 15),
                ),
                border: Border(
                  top: BorderSide(
                    color: _steel.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _midnight.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Clean 1RM display
                  Text(
                    '1RM: ${einRM != null ? einRM.toStringAsFixed(1) : "—"} kg',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _silver,
                    ),
                  ),

                  // Clean recommended 1RM badge
                  if (isActive && empfohlener1RM != null)
                    Container(
                      margin: const EdgeInsets.only(left: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _emberCore.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _emberCore.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${empfohlener1RM.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _emberCore,
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

  // Clean separator
  Widget _buildMinimalSeparator({required bool isCompleted}) {
    return Container(
      height: 32,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withOpacity(0.3)
            : _steel.withOpacity(0.3),
        borderRadius: BorderRadius.circular(0.5),
      ),
    );
  }

  // Clean value display
  Widget _buildMinimalValueDisplay({
    required BuildContext context,
    required String label,
    required String value,
    required String unit,
    required bool isCompleted,
    required int flex,
  }) {
    final Color valueColor =
        isCompleted ? Colors.green : _snow;
    final Color labelColor =
        isCompleted ? Colors.green.withOpacity(0.8) : _silver;
    final Color unitColor =
        isCompleted ? Colors.green.withOpacity(0.7) : _mercury;

    return Expanded(
      flex: flex,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Clean label
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: labelColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Clean value display with unit
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                    letterSpacing: -0.3,
                    height: 1.0,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: unitColor,
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
