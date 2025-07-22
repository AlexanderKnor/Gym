// lib/widgets/training_session_screen/exercise_tab_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';

import '../../providers/training_session_screen/training_session_provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../models/training_plan_screen/exercise_model.dart';
import '../../models/progression_manager_screen/training_set_model.dart';
import 'exercise_set_widget.dart';
import 'strength_calculator_dialog.dart';
import '../../widgets/shared/standard_increment_wheel_widget.dart';
import '../../widgets/shared/rest_period_wheel_widget.dart';
import '../../screens/create_training_plan_screen/exercise_selection_screen.dart';

class ExerciseTabWidget extends StatefulWidget {
  final int exerciseIndex;
  final bool showDetails;
  final Function?
      onExerciseRemoved; // NEU: Callback für TabController-Aktualisierung

  const ExerciseTabWidget({
    Key? key,
    required this.exerciseIndex,
    this.showDetails = false,
    this.onExerciseRemoved, // NEU: Parameter hinzugefügt
  }) : super(key: key);

  @override
  State<ExerciseTabWidget> createState() => _ExerciseTabWidgetState();
}

class _ExerciseTabWidgetState extends State<ExerciseTabWidget>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  String? _exerciseProfileId;
  bool _showStandardIncrementWheel = false;
  bool _showRestPeriodWheel = false;
  bool _isProcessingDeletion = false; // NEU: Flag für Löschvorgang
  
  // Auto-Scroll Controller für Sätze
  final ScrollController _setsScrollController = ScrollController();
  final GlobalKey _setListKey = GlobalKey();
  final GlobalKey _actionBarKey = GlobalKey(); // Referenz für Action-Button Position
  
  // Animation Controller für smooth scrolling
  late AnimationController _scrollAnimationController;
  late Animation<double> _scrollAnimation;
  
  // State tracking für intelligent auto-scroll triggering
  int? _lastActiveSetId;
  bool _hasScrolledToActiveSet = false;
  int? _lastExerciseIndex;
  
  // Keys für jeden Satz für präzise Positionsberechnung
  final Map<int, GlobalKey> _setKeys = {};

  // Clean color system matching training screen
  static const Color _midnight = Color(0xFF000000);
  static const Color _charcoal = Color(0xFF1C1C1E);
  static const Color _graphite = Color(0xFF2C2C2E);
  static const Color _steel = Color(0xFF48484A);
  static const Color _mercury = Color(0xFF8E8E93);
  static const Color _silver = Color(0xFFAEAEB2);
  static const Color _snow = Color(0xFFFFFFFF);
  static const Color _emberCore = Color(0xFFFF4500);

  @override
  void initState() {
    super.initState();
    
    // Initialisiere Animation Controller für smooth scrolling
    _scrollAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scrollAnimation = CurvedAnimation(
      parent: _scrollAnimationController,
      curve: Curves.easeOutCubic,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialisierung nach dem ersten Frame
      _initializeProgressionManager();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeProgressionManager();
  }

  void _initializeProgressionManager() {
    final sessionProvider =
        Provider.of<TrainingSessionProvider>(context, listen: false);
    final progressionProvider =
        Provider.of<ProgressionManagerProvider>(context, listen: false);

    if (widget.exerciseIndex < sessionProvider.exercises.length) {
      // WICHTIG: Verwende die angepasste Übung für den aktuellen Mikrozyklus
      final exercise =
          sessionProvider.getExerciseForMicrocycle(widget.exerciseIndex);

      if (exercise.progressionProfileId != null &&
          exercise.progressionProfileId!.isNotEmpty) {
        setState(() {
          _exerciseProfileId = exercise.progressionProfileId;
        });

        if (widget.exerciseIndex == sessionProvider.currentExerciseIndex) {
          final activeSetId =
              sessionProvider.getActiveSetIdForCurrentExercise();

          if (_exerciseProfileId != null) {
            // Berechnung nach dem Frame-Build zur Vermeidung von Build-Phase-Konflikten
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                sessionProvider.calculateProgressionForSet(widget.exerciseIndex,
                    activeSetId, _exerciseProfileId!, progressionProvider);
              }
            });
          }
        }
      }
    }
  }

  void _navigateToExerciseSelection(BuildContext context, ExerciseModel exercise) {
    final sessionProvider =
        Provider.of<TrainingSessionProvider>(context, listen: false);
    final progressionProvider =
        Provider.of<ProgressionManagerProvider>(context, listen: false);
    final adaptedExercise =
        sessionProvider.getExerciseForMicrocycle(widget.exerciseIndex);

    // Store original values for change detection
    final String? originalProfileId = adaptedExercise.progressionProfileId;
    final int originalRepRangeMin = adaptedExercise.repRangeMin;
    final int originalRepRangeMax = adaptedExercise.repRangeMax;
    final int originalRirRangeMin = adaptedExercise.rirRangeMin;
    final int originalRirRangeMax = adaptedExercise.rirRangeMax;

    // Navigate directly to ExerciseConfigurationScreen to avoid the intermediate loading screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseConfigurationScreen(
          exercise: adaptedExercise,
          isNewExercise: false,
          onExerciseSaved: (updatedExercise) async {
            // Update the exercise in the session
            await sessionProvider.updateExerciseFullDetails(widget.exerciseIndex, updatedExercise);
            
            // Check if relevant settings changed
            bool settingsChanged = originalProfileId != updatedExercise.progressionProfileId ||
                originalRepRangeMin != updatedExercise.repRangeMin ||
                originalRepRangeMax != updatedExercise.repRangeMax ||
                originalRirRangeMin != updatedExercise.rirRangeMin ||
                originalRirRangeMax != updatedExercise.rirRangeMax;

            // Update UI immediately
            if (settingsChanged) {
              setState(() {
                _exerciseProfileId = updatedExercise.progressionProfileId;
              });

              // Recalculate progression if needed
              if (widget.exerciseIndex == sessionProvider.currentExerciseIndex &&
                  updatedExercise.progressionProfileId != null) {
                
                final activeSetId = sessionProvider.getActiveSetIdForCurrentExercise();
                
                sessionProvider.resetProgressionRecommendations(widget.exerciseIndex, activeSetId);
                
                sessionProvider.calculateProgressionForSet(
                  widget.exerciseIndex,
                  activeSetId,
                  updatedExercise.progressionProfileId!,
                  progressionProvider,
                );
              }
            }
          },
        ),
      ),
    );
  }


  void _openStrengthCalculator(BuildContext context) {
    HapticFeedback.mediumImpact();

    final sessionProvider =
        Provider.of<TrainingSessionProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StrengthCalculatorDialog(
        onApplyValues: (calculatedWeight, targetReps, targetRIR) {
          final activeSetId =
              sessionProvider.getActiveSetIdForCurrentExercise();
          sessionProvider.applyCustomValues(
            widget.exerciseIndex,
            activeSetId,
            calculatedWeight,
            targetReps,
            targetRIR,
          );
        },
      ),
    );
  }

  void _showActionsMenu(
      BuildContext context, TrainingSessionProvider sessionProvider) {
    // Prüfen, ob es abgeschlossene Sätze gibt
    final hasCompletedSets =
        _hasCompletedSets(sessionProvider.currentExerciseSets);

    // Wenn keine abgeschlossenen Sätze vorhanden sind, keinen Dialog zeigen
    // und stattdessen eine Benachrichtigung anzeigen
    if (!hasCompletedSets) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Keine abgeschlossenen Sätze vorhanden'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Haptisches Feedback
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
        decoration: BoxDecoration(
          color: _charcoal,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: _steel.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Satz-Optionen',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _snow,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Satz reaktivieren - wird immer angezeigt, da wir bereits geprüft haben, dass es abgeschlossene Sätze gibt
                _buildActionButton(
                  icon: Icons.replay_rounded,
                  label: 'Letzten Satz reaktivieren',
                  onTap: () {
                    sessionProvider
                        .reactivateLastCompletedSet(widget.exerciseIndex);
                    Navigator.pop(context);
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          color: _graphite.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _steel.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _emberCore.withOpacity(0.15),
                border: Border.all(
                  color: _emberCore.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: _emberCore,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _snow,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Verbessertes Auto-Scroll mit präziser Positionierung unter Action Bar
  Future<void> _scrollToActiveSet(int activeSetIndex, int totalSets) async {
    if (!_setsScrollController.hasClients || !mounted) return;
    
    // Wartezeit für vollständigen Widget-Build nach UI-Updates
    await Future.delayed(const Duration(milliseconds: 150));
    
    if (!_setsScrollController.hasClients || !mounted) return;
    
    try {
      // Berechne die ideale Position direkt unter der Action Bar
      final actionBarRenderBox = _actionBarKey.currentContext?.findRenderObject() as RenderBox?;
      final listRenderBox = _setListKey.currentContext?.findRenderObject() as RenderBox?;
      
      if (actionBarRenderBox != null && listRenderBox != null) {
        // Berechne exakte Positionen
        final actionBarGlobalPosition = actionBarRenderBox.localToGlobal(Offset.zero);
        final listGlobalPosition = listRenderBox.localToGlobal(Offset.zero);
        
        // Action Bar Bottom + kleiner Gap = ideale Position für aktiven Satz
        final actionBarBottom = actionBarGlobalPosition.dy + actionBarRenderBox.size.height;
        const double idealGap = 8.0; // Kleiner Gap unter Action Bar
        final double idealActiveSetPosition = actionBarBottom + idealGap;
        
        // Verwende Widget-Key für präzise Positionierung
        final targetKey = _setKeys[activeSetIndex];
        if (targetKey?.currentContext != null) {
          final setRenderBox = targetKey!.currentContext!.findRenderObject() as RenderBox?;
          if (setRenderBox != null) {
            final currentSetPosition = setRenderBox.localToGlobal(Offset.zero);
            
            // Berechne benötigten Scroll-Offset
            final double scrollAdjustment = currentSetPosition.dy - idealActiveSetPosition;
            final double targetScrollOffset = _setsScrollController.offset + scrollAdjustment;
            
            // Begrenze auf gültige Scroll-Grenzen
            final double maxScrollExtent = _setsScrollController.position.maxScrollExtent;
            final double minScrollExtent = _setsScrollController.position.minScrollExtent;
            final double finalOffset = targetScrollOffset.clamp(minScrollExtent, maxScrollExtent);
            
            // Smooth Animation zur idealen Position
            await _setsScrollController.animateTo(
              finalOffset,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
            );
            
            // Haptisches Feedback
            if (mounted && activeSetIndex > 0) {
              HapticFeedback.lightImpact();
            }
            return;
          }
        }
      }
      
      // Fallback: Verbesserte Schätzung basierend auf neuen Card-Höhen
      const double estimatedSetHeight = 118.0; // Angepasst für neue Card-Größen
      const double actionBarHeight = 42.0; // Action Bar Höhe
      const double actionBarPadding = 20.0; // Top + Bottom Padding
      const double idealGap = 8.0;
      
      // Berechne Ziel-Offset für ideale Positionierung
      final double setPosition = activeSetIndex * estimatedSetHeight;
      final double actionBarSpace = actionBarHeight + actionBarPadding + idealGap;
      final double targetOffset = setPosition - actionBarSpace;
      
      final double maxScrollExtent = _setsScrollController.position.maxScrollExtent;
      final double minScrollExtent = _setsScrollController.position.minScrollExtent;
      final double finalOffset = targetOffset.clamp(minScrollExtent, maxScrollExtent);
      
      await _setsScrollController.animateTo(
        finalOffset,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
      
      // Haptisches Feedback
      if (mounted && activeSetIndex > 0) {
        HapticFeedback.lightImpact();
      }
      
    } catch (e) {
      print('Auto-scroll error: $e');
      // Fallback: Einfacher Scroll zum Index
      if (mounted && _setsScrollController.hasClients) {
        try {
          const double fallbackSetHeight = 118.0;
          final double fallbackOffset = activeSetIndex * fallbackSetHeight;
          final double maxScrollExtent = _setsScrollController.position.maxScrollExtent;
          final double finalOffset = fallbackOffset.clamp(0.0, maxScrollExtent);
          
          _setsScrollController.jumpTo(finalOffset);
        } catch (fallbackError) {
          print('Fallback scroll error: $fallbackError');
        }
      }
    }
  }
  
  // ENTFERNT: Komplexe Berechnungen nicht mehr n\u00f6tig
  /*
  double? _calculatePreciseScrollOffset(int activeSetIndex) {
    try {
      // Action Bar Position ermitteln
      final actionBarRenderBox = _actionBarKey.currentContext?.findRenderObject() as RenderBox?;
      if (actionBarRenderBox == null) return null;
      
      // Action Bar Position relativ zum ListView
      final listRenderBox = _setListKey.currentContext?.findRenderObject() as RenderBox?;
      if (listRenderBox == null) return null;
      
      // Berechne die relative Position zwischen Action Bar und ListView
      final actionBarPosition = actionBarRenderBox.localToGlobal(Offset.zero);
      final listPosition = listRenderBox.localToGlobal(Offset.zero);
      final actionBarBottom = actionBarPosition.dy + actionBarRenderBox.size.height;
      
      // Wenn ein spezifischer Satz-Key verfügbar ist, verwende die echte Position
      final setKey = _setKeys[activeSetIndex];
      if (setKey?.currentContext != null) {
        final setRenderBox = setKey!.currentContext!.findRenderObject() as RenderBox?;
        if (setRenderBox != null) {
          final setPosition = setRenderBox.localToGlobal(Offset.zero);
          
          // Gewünschte Position: Satz direkt unter Action Bar mit optimiertem Gap
          const double desiredGap = 8.0; // Kleinerer Gap für direktere Positionierung
          final double targetSetY = actionBarBottom + desiredGap;
          
          // Berechne erforderlichen Scroll-Offset
          final double currentSetY = setPosition.dy;
          final double scrollAdjustment = currentSetY - targetSetY;
          final double currentScrollOffset = _setsScrollController.offset;
          
          return currentScrollOffset + scrollAdjustment;
        }
      }
      
      // Fallback: Verwende approximierte Position
      const double desiredGap = 8.0;
      const double averageSetHeight = 104.0; // Gemessene Durchschnittshöhe
      const double listTopPadding = 4.0;
      
      final double targetSetY = actionBarBottom + desiredGap;
      final double listTop = listPosition.dy;
      final double setEstimatedY = listTop + listTopPadding + (activeSetIndex * averageSetHeight);
      
      final double scrollAdjustment = setEstimatedY - targetSetY;
      return _setsScrollController.offset + scrollAdjustment;
      
    } catch (e) {
      print('Error calculating precise scroll offset: $e');
      return null; // Fallback bei Fehlern
    }
  }
  
  // Fallback-Berechnung falls keine genaue Position ermittelt werden kann
  double _calculateFallbackScrollOffset(int activeSetIndex) {
    // Approximierte Werte basierend auf typischer UI-Struktur
    const double actionBarHeight = 34.0; // Neue reduzierte Höhe
    const double actionBarPadding = 12.0 + 8.0; // top + bottom padding mit neuen Werten
    const double exerciseDetailsHeight = 0.0; // Nur wenn showDetails true ist
    const double setHeight = 108.0;
    const double listTopPadding = 4.0;
    
    // Berechne Position wo der aktive Satz beginnen soll
    final double actionBarTotalHeight = actionBarHeight + actionBarPadding;
    final double targetSetPosition = actionBarTotalHeight + exerciseDetailsHeight + 8.0;
    
    // Berechne erforderlichen Scroll-Offset
    final double setActualPosition = listTopPadding + (activeSetIndex * setHeight);
    return setActualPosition - targetSetPosition;
  }
  */

  @override
  void dispose() {
    _setsScrollController.dispose();
    _scrollAnimationController.dispose();
    _setKeys.clear(); // Cleanup für bessere Memory-Performance
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final sessionProvider = Provider.of<TrainingSessionProvider>(context);
    final progressionProvider =
        Provider.of<ProgressionManagerProvider>(context);

    final bool isActiveExercise =
        widget.exerciseIndex == sessionProvider.currentExerciseIndex;

    if (widget.exerciseIndex >= sessionProvider.exercises.length) {
      return const Center(child: Text('Übung nicht gefunden'));
    }

    // KORRIGIERT: Verwende die für den aktuellen Mikrozyklus angepasste Übung
    final exercise =
        sessionProvider.getExerciseForMicrocycle(widget.exerciseIndex);
    final bool allSetsCompleted = isActiveExercise &&
        sessionProvider.areAllSetsCompletedForCurrentExercise();


    return Container(
      color: _midnight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Action Bar - immer sichtbar im Apple-Stil
          if (isActiveExercise)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                key: _actionBarKey, // GlobalKey für Positionsreferenz
                height: 42, // Erhöht für bessere Button-Darstellung
                decoration: BoxDecoration(
                  color: _charcoal.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _steel.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    // Kraftrechner button - kompakter Stil
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: allSetsCompleted
                              ? null
                              : () => _openStrengthCalculator(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Opacity(
                            opacity: allSetsCompleted ? 0.5 : 1.0,
                            child: Container(
                              height: 42,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calculate_outlined,
                                    size: 16,
                                    color: allSetsCompleted ? _mercury : _snow,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Rechner',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: allSetsCompleted ? _mercury : _snow,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Trennlinie
                    Container(
                      width: 1,
                      height: 24,
                      color: _steel.withOpacity(0.3),
                    ),

                    // Progress-Button - immer anzeigen, aber bei Bedarf ausgegraut
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // Progress Button immer enabled, interne Validierung
                            if (!_hasRecommendation(
                                sessionProvider,
                                sessionProvider.getActiveSetIdForCurrentExercise())) {
                              return; // Ignoriere Klick ohne visuelles Feedback
                            }
                                  final activeSetId = sessionProvider
                                      .getActiveSetIdForCurrentExercise();
                                  final activeSet = sessionProvider
                                      .currentExerciseSets
                                      .firstWhere(
                                    (s) => s.id == activeSetId,
                                    orElse: () => TrainingSetModel(
                                        id: 0,
                                        kg: 0,
                                        wiederholungen: 0,
                                        rir: 0),
                                  );

                                  if (activeSet.empfehlungBerechnet) {
                                    HapticFeedback.mediumImpact();
                                    sessionProvider
                                        .applyProgressionRecommendation(
                                      activeSetId,
                                      activeSet.empfKg,
                                      activeSet.empfWiederholungen,
                                      activeSet.empfRir,
                                    );
                                  }
                                },
                          borderRadius: BorderRadius.circular(12),
                          child: Opacity(
                            opacity: 1.0, // Immer volle Opacity
                            child: Container(
                              height: 42,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bolt,
                                    size: 16,
                                    color: _emberCore, // Immer orange
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Progress',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _snow, // Immer weiß
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Trennlinie - immer anzeigen
                    Container(
                      width: 1,
                      height: 24,
                      color: _steel.withOpacity(0.3),
                    ),

                    // Übungseinstellungen-Button (verschoben vom unteren Bereich)
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _navigateToExerciseSelection(context, exercise),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 38,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.tune,
                                  size: 16,
                                  color: _snow,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Bearbeiten',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _snow,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Sets list - main focus
          Expanded(
            child: _buildSetsList(
                sessionProvider, progressionProvider, isActiveExercise),
          ),
        ],
      ),
    );
  }

  // Neuer Button zum Öffnen des Übungseditors
  Widget _buildExerciseDetailsButton(
      BuildContext context, ExerciseModel exercise) {
    final sessionProvider =
        Provider.of<TrainingSessionProvider>(context, listen: false);

    // KORRIGIERT: Verwende die für den aktuellen Mikrozyklus angepasste Übung
    final adaptedExercise =
        sessionProvider.getExerciseForMicrocycle(widget.exerciseIndex);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: InkWell(
        onTap: () => _navigateToExerciseSelection(context, adaptedExercise),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _charcoal.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _steel.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.tune,
                size: 18,
                color: _silver,
              ),
              const SizedBox(width: 8),
              Text(
                'Übungseinstellungen bearbeiten',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _snow,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetsList(TrainingSessionProvider sessionProvider,
      ProgressionManagerProvider progressionProvider, bool isActiveExercise) {
    final sets = sessionProvider.currentExerciseSets;
    final activeSetId = sessionProvider.getActiveSetIdForCurrentExercise();
    final allSetsCompleted =
        sessionProvider.areAllSetsCompletedForCurrentExercise();

    if (sets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Sätze verfügbar',
              style: TextStyle(
                fontSize: 17,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                sessionProvider.addSetToCurrentExercise();
                HapticFeedback.mediumImpact();
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Satz hinzufügen'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Auto-Scroll Logic: Intelligente Fokussierung basierend auf Zustandsänderungen
    final activeSetIndex = activeSetId - 1; // setId is 1-based, index is 0-based
    
    // Check if exercise changed (neue Übung ausgewählt)
    final bool exerciseChanged = _lastExerciseIndex != widget.exerciseIndex;
    
    // Check if the active set has changed for this exercise
    final bool activeSetChanged = _lastActiveSetId != activeSetId;
    
    if (isActiveExercise && _setsScrollController.hasClients) {
      
      if (exerciseChanged) {
        // Neue Übung: Scroll sanft zum ersten Satz (oder aktiven Satz)
        _lastExerciseIndex = widget.exerciseIndex;
        _lastActiveSetId = activeSetId;
        _hasScrolledToActiveSet = false;
        
        // Erweiterte Verzögerung für perfekten UI-Aufbau bei Übungswechsel
        Future.delayed(const Duration(milliseconds: 250), () {
          if (!_hasScrolledToActiveSet && mounted) {
            _hasScrolledToActiveSet = true;
            // Bei Übungswechsel zum aktiven/ersten Satz scrollen
            final scrollToIndex = activeSetIndex >= 0 ? activeSetIndex : 0;
            _scrollToActiveSet(scrollToIndex, sets.length);
          }
        });
        
      } else if (activeSetChanged && activeSetIndex >= 0 && activeSetIndex < sets.length) {
        // Satz-Wechsel innerhalb derselben Übung: Focus auf neuen aktiven Satz
        _lastActiveSetId = activeSetId;
        _hasScrolledToActiveSet = false;
        
        // Optimierter Trigger bei Satz-Completion mit minimaler Verzögerung
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!_hasScrolledToActiveSet && mounted) {
            _hasScrolledToActiveSet = true;
            _scrollToActiveSet(activeSetIndex, sets.length);
          }
        });
      }
    }

    return ListView.builder(
      key: _setListKey,
      controller: _setsScrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: sets.length,
      itemBuilder: (context, index) {
        final set = sets[index];
        final isActiveSet =
            isActiveExercise && set.id == activeSetId && !allSetsCompleted;
        final showRecommendation = isActiveSet &&
            _exerciseProfileId != null &&
            sessionProvider.shouldShowRecommendation(
                widget.exerciseIndex, set.id);

        // Stelle sicher, dass jeder Satz einen eindeutigen Key hat
        if (!_setKeys.containsKey(index)) {
          _setKeys[index] = GlobalKey();
        }
        
        return Container(
          key: _setKeys[index],
          child: ExerciseSetWidget(
            set: set,
            isActive: isActiveSet,
            isCompleted: set.abgeschlossen,
            onValueChanged: (field, value) {
              if (isActiveSet && !allSetsCompleted) {
                sessionProvider.updateSet(set.id, field, value);
              }
            },
            recommendation: showRecommendation
                ? {
                    'kg': set.empfKg,
                    'wiederholungen': set.empfWiederholungen,
                    'rir': set.empfRir,
                  }
                : null,
            onReactivate: set.abgeschlossen && isActiveExercise && 
                set.id == _getLastCompletedSetId(sets)
                ? () {
                    HapticFeedback.mediumImpact();
                    sessionProvider.reactivateLastCompletedSet(
                        sessionProvider.currentExerciseIndex);
                  }
                : null,
          ),
        );
      },
    );
  }

  bool _hasRecommendation(
      TrainingSessionProvider sessionProvider, int activeSetId) {
    if (_exerciseProfileId == null) return false;

    try {
      final activeSet = sessionProvider.currentExerciseSets.firstWhere(
        (s) => s.id == activeSetId,
      );
      return activeSet.empfehlungBerechnet;
    } catch (e) {
      return false;
    }
  }

  bool _hasCompletedSets(List<TrainingSetModel> sets) {
    for (final set in sets) {
      if (set.abgeschlossen) {
        return true;
      }
    }
    return false;
  }
  
  // Neue Funktion: Findet die ID des letzten abgeschlossenen Satzes
  int? _getLastCompletedSetId(List<TrainingSetModel> sets) {
    // Durchlaufe die Sätze in umgekehrter Reihenfolge
    for (int i = sets.length - 1; i >= 0; i--) {
      if (sets[i].abgeschlossen) {
        return sets[i].id;
      }
    }
    return null;
  }
}
