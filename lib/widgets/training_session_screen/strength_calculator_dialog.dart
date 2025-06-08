// lib/widgets/training_session_screen/strength_calculator_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../models/strength_calculator_screen/strength_calculator_model.dart';
import '../../services/progression_manager_screen/one_rm_calculator_service.dart';
import '../shared/weight_wheel_input_widget.dart';
import '../shared/repetition_wheel_input_widget.dart';
import '../shared/rir_wheel_input_widget.dart';

class StrengthCalculatorDialog extends StatefulWidget {
  final Function(double, int, int) onApplyValues;

  const StrengthCalculatorDialog({
    Key? key,
    required this.onApplyValues,
  }) : super(key: key);

  @override
  State<StrengthCalculatorDialog> createState() => _StrengthCalculatorDialogState();
}

class _StrengthCalculatorDialogState extends State<StrengthCalculatorDialog>
    with TickerProviderStateMixin {
  // Clean color system matching training session
  static const Color _midnight = Color(0xFF000000);
  static const Color _charcoal = Color(0xFF1C1C1E);
  static const Color _graphite = Color(0xFF2C2C2E);
  static const Color _steel = Color(0xFF48484A);
  static const Color _mercury = Color(0xFF8E8E93);
  static const Color _silver = Color(0xFFAEAEB2);
  static const Color _snow = Color(0xFFFFFFFF);
  static const Color _emberCore = Color(0xFFFF4500);

  // Modell für die Berechnungen
  late StrengthCalculatorModel _calculatorModel;

  // Werte für die Eingabefelder
  double _testWeight = 0.0;
  int _testReps = 0;
  int _targetReps = 10;
  int _targetRIR = 2;

  // Zeigt an, ob eine Berechnung durchgeführt wurde
  bool _hasCalculated = false;
  bool _isCalculating = false;
  
  // Für Fehlermeldungen
  String? _errorMessage;
  
  // Animation Controller
  late AnimationController _resultAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  // ScrollController für Auto-Scroll
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Modell mit Standardwerten initialisieren
    _calculatorModel = StrengthCalculatorModel(
        testWeight: _testWeight,
        testReps: _testReps,
        targetReps: _targetReps,
        targetRIR: _targetRIR);
        
    // Animation Controller initialisieren
    _resultAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _resultAnimationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<double>(
      begin: 15.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _resultAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.97,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _resultAnimationController,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
    ));
  }
  
  @override
  void dispose() {
    _resultAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Aktualisiert das Modell mit den neuen Werten
  void _updateModelValues() {
    setState(() {
      _calculatorModel = _calculatorModel.copyWith(
        testWeight: _testWeight,
        testReps: _testReps,
        targetReps: _targetReps,
        targetRIR: _targetRIR,
      );

      // Bei Änderungen müssen die Berechnungen zurückgesetzt werden
      if (_hasCalculated) {
        _calculatorModel.resetCalculations();
        _hasCalculated = false;
        _resultAnimationController.reset();
      }
      
      // Fehlermeldung zurücksetzen
      _errorMessage = null;
    });
  }

  // Führt die Berechnung durch
  void _calculateWorkingWeight() async {
    // Validierung
    if (_testWeight <= 0 ||
        _testReps <= 0 ||
        _targetReps <= 0 ||
        _targetRIR < 0) {
      setState(() {
        _errorMessage = 'Bitte gib gültige Werte ein.';
      });
      return;
    }

    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    // Zeige Lade-Animation
    setState(() {
      _isCalculating = true;
      _errorMessage = null;
    });

    // Künstliche Verzögerung für bessere UX
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        // 1RM berechnen (mit RIR = 0, da wir bis zum Muskelversagen gehen)
        _calculatorModel.calculatedOneRM = OneRMCalculatorService.calculate1RM(
          _calculatorModel.testWeight,
          _calculatorModel.testReps,
          0, // RIR = 0 für Test bis zum Muskelversagen
        );

        // Arbeitsgewicht basierend auf 1RM und Zielwerten berechnen
        if (_calculatorModel.calculatedOneRM! > 0) {
          _calculatorModel.calculatedWorkingWeight =
              OneRMCalculatorService.calculateWeightFromTargetRM(
            _calculatorModel.calculatedOneRM!,
            _calculatorModel.targetReps,
            _calculatorModel.targetRIR,
          );
        }

        _hasCalculated = true;
        _isCalculating = false;
        
        // Direkt die Animation starten
        _resultAnimationController.forward();
      });
    }
  }

  // Wendet die berechneten Werte auf den aktuellen Satz an
  void _applyToCurrentSet() {
    if (_hasCalculated && _calculatorModel.calculatedWorkingWeight != null) {
      // Provide haptic feedback
      HapticFeedback.mediumImpact();

      widget.onApplyValues(
        _calculatorModel.calculatedWorkingWeight!,
        _calculatorModel.targetReps,
        _calculatorModel.targetRIR,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Stack(
          children: [
            // Haupt-Container
            Container(
              decoration: BoxDecoration(
                color: _charcoal,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _steel.withOpacity(0.3)),
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Kompakter Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _graphite.withOpacity(0.8),
                            _charcoal.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _emberCore.withOpacity(0.15),
                              border: Border.all(color: _emberCore.withOpacity(0.4)),
                            ),
                            child: const Icon(
                              Icons.calculate_outlined,
                              size: 16,
                              color: _emberCore,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Kraftrechner',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: _snow,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: _silver,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fehlermeldung wenn vorhanden
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_rounded,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.red[300],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          // Test-Werte Eingabebereich
                          _buildSectionLabel('Testgewicht & Wiederholungen'),
                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _graphite.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _steel.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                // Testgewicht
                                Expanded(
                                  flex: 3,
                                  child: WeightSpinnerWidget(
                                    value: _testWeight,
                                    onChanged: (value) {
                                      setState(() {
                                        _testWeight = value;
                                      });
                                      _updateModelValues();
                                    },
                                    isEnabled: true,
                                    isCompleted: false,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Test-Wiederholungen
                                Expanded(
                                  flex: 2,
                                  child: RepetitionSpinnerWidget(
                                    value: _testReps,
                                    onChanged: (value) {
                                      setState(() {
                                        _testReps = value;
                                      });
                                      _updateModelValues();
                                    },
                                    isEnabled: true,
                                    isCompleted: false,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Ziel-Werte Eingabebereich
                          _buildSectionLabel('Zielwerte'),
                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _graphite.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _steel.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                // Ziel-Wiederholungen
                                Expanded(
                                  flex: 2,
                                  child: RepetitionSpinnerWidget(
                                    value: _targetReps,
                                    onChanged: (value) {
                                      setState(() {
                                        _targetReps = value;
                                      });
                                      _updateModelValues();
                                    },
                                    isEnabled: true,
                                    isCompleted: false,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Ziel-RIR
                                Expanded(
                                  flex: 2,
                                  child: RirSpinnerWidget(
                                    value: _targetRIR,
                                    onChanged: (value) {
                                      setState(() {
                                        _targetRIR = value;
                                      });
                                      _updateModelValues();
                                    },
                                    isEnabled: true,
                                    isCompleted: false,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Berechnen Button
                          SizedBox(
                            width: double.infinity,
                            height: 52, // Erhöht für bessere Text-Darstellung
                            child: ElevatedButton(
                              onPressed: _isCalculating ? null : _calculateWorkingWeight,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _emberCore,
                                foregroundColor: _snow,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12), // Mehr Padding
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isCalculating
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            color: _snow,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Berechne...',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'BERECHNEN',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),

                          // Platzhalter für Ergebnisse (werden als Overlay angezeigt)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Ergebnis-Overlay
            if (_hasCalculated)
              _buildResultOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _emberCore,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _emberCore.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _emberCore.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Berechnete Werte'),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _buildResultItem(
                  'Geschätztes 1RM',
                  '${_calculatorModel.calculatedOneRM?.toStringAsFixed(1) ?? '0'} kg',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultItem(
                  'Arbeitsgewicht',
                  '${_calculatorModel.calculatedWorkingWeight?.toStringAsFixed(1) ?? '0'} kg',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Übernehmen Button
          SizedBox(
            width: double.infinity,
            height: 52, // Erhöht für bessere Text-Darstellung
            child: ElevatedButton(
              onPressed: _applyToCurrentSet,
              style: ElevatedButton.styleFrom(
                backgroundColor: _emberCore.withOpacity(0.15),
                foregroundColor: _emberCore,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12), // Mehr Padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: _emberCore.withOpacity(0.3)),
                ),
              ),
              child: const Text(
                'WERTE ÜBERNEHMEN',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _charcoal.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _steel.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _silver,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _snow,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultOverlay() {
    return AnimatedBuilder(
      animation: _resultAnimationController,
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            ignoring: _fadeAnimation.value < 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: _midnight.withOpacity(0.95 * _fadeAnimation.value),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      constraints: const BoxConstraints(maxWidth: 340),
                      decoration: BoxDecoration(
                        color: _charcoal,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _emberCore.withOpacity(0.6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _midnight.withOpacity(0.6),
                            blurRadius: 24,
                            spreadRadius: 0,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Close Button - oben rechts
                          Padding(
                            padding: const EdgeInsets.only(top: 16, right: 16),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _hasCalculated = false;
                                      _resultAnimationController.reverse();
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 20,
                                      color: _silver,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Content - alles zentriert
                          Padding(
                            padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
                            child: Column(
                              children: [
                                // Title - zentriert
                                const Text(
                                  'Empfohlenes Arbeitsgewicht',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: _snow,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Main Weight Display - zentriert
                                TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 800),
                                  tween: Tween(
                                    begin: 0.0, 
                                    end: _calculatorModel.calculatedWorkingWeight ?? 0.0
                                  ),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          value.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 64,
                                            fontWeight: FontWeight.w800,
                                            color: _emberCore,
                                            letterSpacing: -3,
                                            height: 0.85,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'kg',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w600,
                                            color: _snow,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Target info - zentriert
                                Text(
                                  '${_calculatorModel.targetReps} Wiederholungen · RIR ${_calculatorModel.targetRIR}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _silver,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                
                                const SizedBox(height: 32),
                                
                                // Divider
                                Container(
                                  width: 120,
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        _steel.withOpacity(0.4),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // 1RM Info - zentriert
                                Column(
                                  children: [
                                    Text(
                                      'Geschätztes 1RM',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _silver,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_calculatorModel.calculatedOneRM?.toStringAsFixed(1) ?? '0'} kg',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: _snow,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 32),
                                
                                // Action Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _applyToCurrentSet,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _emberCore,
                                      foregroundColor: _snow,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      'Übernehmen',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}