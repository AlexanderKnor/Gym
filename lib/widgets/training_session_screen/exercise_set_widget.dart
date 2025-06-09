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

  // PROVER sophisticated color system
  static const Color _void = Color(0xFF000000);
  static const Color _cosmos = Color(0xFF050507);
  static const Color _nebula = Color(0xFF0F0F12);
  static const Color _stellar = Color(0xFF18181C);
  static const Color _lunar = Color(0xFF242429);
  static const Color _asteroid = Color(0xFF35353C);
  static const Color _comet = Color(0xFF65656F);
  static const Color _stardust = Color(0xFFA5A5B0);
  static const Color _nova = Color(0xFFF5F5F7);

  // Prover signature gradient
  static const Color _proverCore = Color(0xFFFF4500);
  static const Color _proverGlow = Color(0xFFFF6B3D);
  static const Color _proverFlare = Color(0xFFFFA500);

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

    // Sophisticated shadows based on state
    final List<BoxShadow> cardShadows = isActive
        ? [
            BoxShadow(
              color: _proverCore.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: _void.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
        : isCompleted
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: _void.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: _void.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive
              ? [
                  _stellar.withOpacity(0.9),
                  _nebula.withOpacity(0.7),
                ]
              : isCompleted
                  ? [
                      _stellar.withOpacity(0.6),
                      _nebula.withOpacity(0.4),
                    ]
                  : [
                      _stellar.withOpacity(0.4),
                      _nebula.withOpacity(0.3),
                    ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? _proverCore.withOpacity(0.8)
              : isCompleted
                  ? Colors.green.withOpacity(0.6)
                  : _lunar.withOpacity(0.4),
          width: isActive ? 2.5 : 1.5,
        ),
        boxShadow: cardShadows,
      ),
      child: Column(
        children: [
          // Elegant header with sophisticated design
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isActive
                    ? [_proverCore, _proverGlow]
                    : isCompleted
                        ? [
                            Colors.green.withOpacity(0.15),
                            Colors.green.withOpacity(0.08)
                          ]
                        : [
                            _asteroid.withOpacity(0.4),
                            _asteroid.withOpacity(0.2)
                          ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isActive ? 17.5 : 18.5),
                topRight: Radius.circular(isActive ? 17.5 : 18.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? _proverCore.withOpacity(0.3)
                      : isCompleted
                          ? Colors.green.withOpacity(0.2)
                          : _void.withOpacity(0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              children: [
                  // Elegant set number badge with sophisticated styling
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isActive
                            ? [_nova, _stardust.withOpacity(0.9)]
                            : isCompleted
                                ? [Colors.green, Colors.green.shade700]
                                : [
                                    _lunar.withOpacity(0.8),
                                    _stellar.withOpacity(0.6),
                                  ],
                      ),
                      border: Border.all(
                        color: isActive
                            ? _proverCore.withOpacity(0.3)
                            : isCompleted
                                ? Colors.green.withOpacity(0.4)
                                : _stardust.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isActive
                              ? _proverCore.withOpacity(0.4)
                              : isCompleted
                                  ? Colors.green.withOpacity(0.3)
                                  : _void.withOpacity(0.2),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${set.id}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isActive 
                              ? _stellar
                              : isCompleted 
                                  ? _nova
                                  : _nova,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Elegant status text with sophisticated typography
                  Text(
                    isActive
                        ? 'AKTUELLER SATZ'
                        : isCompleted
                            ? 'ABGESCHLOSSEN'
                            : 'SATZ ${set.id}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: isActive
                          ? _nova
                          : isCompleted
                              ? Colors.green[200]
                              : _stardust,
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

          // Interactive input widgets for active state with enhanced spacing
          if (isActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
            // Sophisticated compact display for non-active sets
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
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

          // Sophisticated 1RM footer with elegant design
          if (einRM != null || (isActive && empfohlener1RM != null))
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _stellar.withOpacity(0.3),
                    _nebula.withOpacity(0.5),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(isActive ? 17.5 : 18.5),
                  bottomRight: Radius.circular(isActive ? 17.5 : 18.5),
                ),
                border: Border(
                  top: BorderSide(
                    color: _lunar.withOpacity(0.4),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Enhanced 1RM display
                  Text(
                    '1RM: ${einRM != null ? einRM.toStringAsFixed(1) : "—"} kg',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _stardust,
                      letterSpacing: 0.5,
                    ),
                  ),

                  // Sophisticated recommended 1RM badge
                  if (isActive && empfohlener1RM != null)
                    Container(
                      margin: const EdgeInsets.only(left: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_proverCore, _proverGlow],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: _proverCore.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${empfohlener1RM.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _nova,
                          letterSpacing: 0.3,
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

  // Sophisticated separator with elegant gradients
  Widget _buildMinimalSeparator({required bool isCompleted}) {
    return Container(
      height: 40,
      width: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            isCompleted
                ? Colors.green.withOpacity(0.6)
                : _lunar.withOpacity(0.6),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  // Sophisticated value display with enhanced typography
  Widget _buildMinimalValueDisplay({
    required BuildContext context,
    required String label,
    required String value,
    required String unit,
    required bool isCompleted,
    required int flex,
  }) {
    final Color valueColor =
        isCompleted ? Colors.green[300]! : _nova;
    final Color labelColor =
        isCompleted ? Colors.green[400]! : _stardust;
    final Color unitColor =
        isCompleted ? Colors.green[500]! : _comet;

    return Expanded(
      flex: flex,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Enhanced label with sophisticated typography
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: labelColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          // Enhanced value display with unit
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: unitColor,
                      letterSpacing: -0.2,
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
