// lib/widgets/progression_manager_screen/components/set_card_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../../models/progression_manager_screen/training_set_model.dart';
import '../../../services/progression_manager_screen/one_rm_calculator_service.dart';
import '../../shared/weight_wheel_input_widget.dart';
import '../../shared/repetition_wheel_input_widget.dart';
import '../../shared/rir_wheel_input_widget.dart';

class SetCardWidget extends StatelessWidget {
  final TrainingSetModel satz;

  // Clean color system matching training screen
  static const Color _midnight = Color(0xFF000000);
  static const Color _charcoal = Color(0xFF1C1C1E);
  static const Color _graphite = Color(0xFF2C2C2E);
  static const Color _steel = Color(0xFF48484A);
  static const Color _mercury = Color(0xFF8E8E93);
  static const Color _silver = Color(0xFFAEAEB2);
  static const Color _snow = Color(0xFFFFFFFF);
  static const Color _emberCore = Color(0xFFFF4500);

  const SetCardWidget({
    Key? key,
    required this.satz,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);
    final istAktiv =
        satz.id == provider.aktiverSatz && !provider.trainingAbgeschlossen;
    final istAbgeschlossen = satz.abgeschlossen;

    // Berechne 1RM für aktuelle Werte
    final einRM = satz.kg > 0 && satz.wiederholungen > 0
        ? OneRMCalculatorService.calculate1RM(
            satz.kg, satz.wiederholungen, satz.rir)
        : 0.0;

    // Berechne 1RM für empfohlene Werte
    double? empfohlener1RM;
    if (istAktiv &&
        satz.empfehlungBerechnet &&
        satz.empfKg != null &&
        satz.empfWiederholungen != null &&
        satz.empfRir != null) {
      empfohlener1RM = OneRMCalculatorService.calculate1RM(
          satz.empfKg!, satz.empfWiederholungen!, satz.empfRir!);
    }

    // Prüfe, ob die Empfehlung angezeigt werden soll
    final sollEmpfehlungAnzeigen = provider.sollEmpfehlungAnzeigen(satz.id);

    // Schatten definieren basierend auf dem Status
    final List<BoxShadow> cardShadows = istAktiv
        ? [
            BoxShadow(
              color: _emberCore.withOpacity(0.2),
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ]
        : istAbgeschlossen
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.15),
                  offset: const Offset(0, 1),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ]
            : [];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: istAktiv
            ? _charcoal.withOpacity(0.95)
            : istAbgeschlossen
                ? _charcoal.withOpacity(0.85)
                : _charcoal.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: istAktiv
              ? _emberCore
              : istAbgeschlossen
                  ? Colors.green.withOpacity(0.6)
                  : _steel.withOpacity(0.3),
          width: istAktiv ? 2 : 1,
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
                color: istAktiv
                    ? _emberCore.withOpacity(0.15)
                    : istAbgeschlossen
                        ? Colors.green.withOpacity(0.1)
                        : _graphite.withOpacity(0.5),
                border: Border(
                  bottom: BorderSide(
                    color: istAktiv
                        ? _emberCore.withOpacity(0.3)
                        : istAbgeschlossen
                            ? Colors.green.withOpacity(0.2)
                            : _steel.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Set-Nummer mit verbessertem Design
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: istAktiv
                          ? _emberCore.withOpacity(0.15)
                          : istAbgeschlossen
                              ? Colors.green.withOpacity(0.15)
                              : _steel.withOpacity(0.3),
                      border: Border.all(
                        color: istAktiv
                            ? _emberCore
                            : istAbgeschlossen
                                ? Colors.green
                                : _steel.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${satz.id}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: istAktiv 
                              ? _emberCore 
                              : istAbgeschlossen
                                  ? Colors.green
                                  : _mercury,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Status-Text mit verbesserter Typografie
                  Text(
                    istAktiv
                        ? 'Aktueller Satz'
                        : istAbgeschlossen
                            ? 'Abgeschlossen'
                            : 'Satz ${satz.id}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: istAktiv
                          ? _snow
                          : istAbgeschlossen
                              ? Colors.green
                              : _silver,
                    ),
                  ),

                  const Spacer(),

                  // Status-Icon: Nur Haken für abgeschlossene Sätze
                  if (istAbgeschlossen)
                    Icon(
                      Icons.check_rounded,
                      color: Colors.green,
                      size: 20,
                    )
                  else if (istAktiv)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _emberCore,
                        boxShadow: [
                          BoxShadow(
                            color: _emberCore.withOpacity(0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Widget für Werte - unterschiedliches Layout je nach Zustand
          if (istAktiv)
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
                      value: satz.kg,
                      onChanged: (value) =>
                          provider.handleChange(satz.id, 'kg', value),
                      isEnabled: istAktiv && !istAbgeschlossen,
                      isCompleted: istAbgeschlossen,
                      recommendationValue:
                          sollEmpfehlungAnzeigen && satz.empfKg != null
                              ? satz.empfKg!.toString()
                              : null,
                      onRecommendationApplied: (value) {
                        double? parsedValue = double.tryParse(value);
                        if (parsedValue != null) {
                          HapticFeedback.mediumImpact();
                          provider.handleChange(satz.id, 'kg', parsedValue);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Wiederholungen-Spinner
                  Expanded(
                    flex: 2,
                    child: RepetitionSpinnerWidget(
                      value: satz.wiederholungen,
                      onChanged: (value) => provider.handleChange(
                          satz.id, 'wiederholungen', value),
                      isEnabled: istAktiv && !istAbgeschlossen,
                      isCompleted: istAbgeschlossen,
                      recommendationValue: sollEmpfehlungAnzeigen &&
                              satz.empfWiederholungen != null
                          ? satz.empfWiederholungen!.toString()
                          : null,
                      onRecommendationApplied: (value) {
                        int? parsedValue = int.tryParse(value);
                        if (parsedValue != null) {
                          HapticFeedback.mediumImpact();
                          provider.handleChange(
                              satz.id, 'wiederholungen', parsedValue);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

                  // RIR-Spinner
                  Expanded(
                    flex: 2,
                    child: RirSpinnerWidget(
                      value: satz.rir,
                      onChanged: (value) =>
                          provider.handleChange(satz.id, 'rir', value),
                      isEnabled: istAktiv && !istAbgeschlossen,
                      isCompleted: istAbgeschlossen,
                      recommendationValue:
                          sollEmpfehlungAnzeigen && satz.empfRir != null
                              ? satz.empfRir!.toString()
                              : null,
                      onRecommendationApplied: (value) {
                        int? parsedValue = int.tryParse(value);
                        if (parsedValue != null) {
                          HapticFeedback.mediumImpact();
                          provider.handleChange(satz.id, 'rir', parsedValue);
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
                    value: '${satz.kg}',
                    unit: 'kg',
                    isCompleted: istAbgeschlossen,
                    flex: 3,
                  ),

                  // Vertikaler Trenner
                  _buildMinimalSeparator(isCompleted: istAbgeschlossen),

                  // Wiederholungen
                  _buildMinimalValueDisplay(
                    context: context,
                    label: 'Wdh',
                    value: '${satz.wiederholungen}',
                    unit: '',
                    isCompleted: istAbgeschlossen,
                    flex: 2,
                  ),

                  // Vertikaler Trenner
                  _buildMinimalSeparator(isCompleted: istAbgeschlossen),

                  // RIR
                  _buildMinimalValueDisplay(
                    context: context,
                    label: 'RIR',
                    value: '${satz.rir}',
                    unit: '',
                    isCompleted: istAbgeschlossen,
                    flex: 2,
                  ),
                ],
              ),
            ),

          // 1RM Info als elegante Fußzeile
          if (einRM > 0 || (istAktiv && empfohlener1RM != null))
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
                    color: _steel.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 1RM mit besserem Styling
                  Text(
                    '1RM: ${einRM.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _mercury,
                      letterSpacing: -0.3,
                    ),
                  ),

                  // Empfohlene 1RM mit verbessertem Design
                  if (istAktiv &&
                      empfohlener1RM != null &&
                      sollEmpfehlungAnzeigen)
                    Container(
                      margin: const EdgeInsets.only(left: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _emberCore.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _emberCore.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${empfohlener1RM.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _emberCore,
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
            _steel.withOpacity(0.0),
            isCompleted
                ? Colors.green.withOpacity(0.3)
                : _steel.withOpacity(0.3),
            _steel.withOpacity(0.0),
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
        isCompleted ? Colors.green : _snow;
    final Color labelColor =
        isCompleted ? Colors.green.withOpacity(0.8) : _mercury;

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
                      color: isCompleted ? Colors.green.withOpacity(0.8) : _mercury,
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
