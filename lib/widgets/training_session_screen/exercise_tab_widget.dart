// lib/widgets/training_session_screen/exercise_tab_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/training_session_screen/training_session_provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../models/training_plan_screen/exercise_model.dart';
import '../../models/progression_manager_screen/training_set_model.dart';
import 'exercise_set_widget.dart';
import '../../screens/strength_calculator_screen/strength_calculator_screen.dart';
import '../../widgets/shared/standard_increment_wheel_widget.dart';
import '../../widgets/shared/rest_period_wheel_widget.dart';
import '../../widgets/create_training_plan_screen/exercise_form_widget.dart';

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

  void _showExerciseEditor(BuildContext context, ExerciseModel exercise) {
    final sessionProvider =
        Provider.of<TrainingSessionProvider>(context, listen: false);
    final progressionProvider =
        Provider.of<ProgressionManagerProvider>(context, listen: false);

    // KORRIGIERT: Verwende die für den aktuellen Mikrozyklus angepasste Übung
    // anstatt der Standardübung direkt zu verwenden
    final adaptedExercise =
        sessionProvider.getExerciseForMicrocycle(widget.exerciseIndex);

    // Speichere die ursprünglichen Werte zum Vergleich
    final String? originalProfileId = adaptedExercise.progressionProfileId;
    final int originalRepRangeMin = adaptedExercise.repRangeMin;
    final int originalRepRangeMax = adaptedExercise.repRangeMax;
    final int originalRirRangeMin = adaptedExercise.rirRangeMin;
    final int originalRirRangeMax = adaptedExercise.rirRangeMax;

    // Prüfen, ob mehr als eine Übung vorhanden ist
    final bool canDeleteExercise = sessionProvider.exercises.length > 1;

    // Dialog mit StatefulBuilder zeigen, um Zustand im Dialog zu verwalten
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // Lokale Variable für den Ladezustand
        bool isFormLoaded = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: _charcoal,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                children: [
                  // Das tatsächliche Formular mit Lösch-Button
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Form Widget mit der angepassten Übung
                        ExerciseFormWidget(
                          initialExercise: adaptedExercise,
                          onSave: (updatedExercise) async {
                            // Übung im Provider aktualisieren
                            await sessionProvider.updateExerciseFullDetails(
                                widget.exerciseIndex, updatedExercise);

                            // Dialog schließen
                            Navigator.pop(context);

                            // Überprüfen, ob sich relevante Einstellungen geändert haben
                            bool settingsChanged = originalProfileId !=
                                    updatedExercise.progressionProfileId ||
                                originalRepRangeMin !=
                                    updatedExercise.repRangeMin ||
                                originalRepRangeMax !=
                                    updatedExercise.repRangeMax ||
                                originalRirRangeMin !=
                                    updatedExercise.rirRangeMin ||
                                originalRirRangeMax !=
                                    updatedExercise.rirRangeMax;

                            // Wenn das Progressionsprofil geändert wurde oder ein neues hinzugefügt wurde,
                            // oder wenn sich andere relevante Einstellungen geändert haben,
                            // Empfehlungen sofort neu berechnen
                            if (settingsChanged) {
                              setState(() {
                                _exerciseProfileId =
                                    updatedExercise.progressionProfileId;
                              });

                              // Für den aktiven Satz sofort neu berechnen, falls es der aktuelle Index ist
                              if (widget.exerciseIndex ==
                                      sessionProvider.currentExerciseIndex &&
                                  updatedExercise.progressionProfileId !=
                                      null) {
                                // Aktiven Satz-ID abrufen
                                final activeSetId = sessionProvider
                                    .getActiveSetIdForCurrentExercise();

                                // Alte Empfehlungen zurücksetzen
                                sessionProvider.resetProgressionRecommendations(
                                    widget.exerciseIndex, activeSetId);

                                // Neue Empfehlungen berechnen auf Basis der historischen Daten
                                sessionProvider.calculateProgressionForSet(
                                    widget.exerciseIndex,
                                    activeSetId,
                                    updatedExercise.progressionProfileId!,
                                    progressionProvider,
                                    forceRecalculation: true);
                              }
                            }

                            // Haptic feedback für Bestätigung
                            HapticFeedback.mediumImpact();
                          },
                          // Callback für den Ladezustand
                          onFormLoaded: () {
                            // Zustand im Dialog aktualisieren, wenn das Formular geladen ist
                            setDialogState(() {
                              isFormLoaded = true;
                            });
                          },
                        ),

                        // Lösch-Button - wird nur angezeigt, wenn das Formular geladen ist
                        if (isFormLoaded && canDeleteExercise)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: ElevatedButton.icon(
                              onPressed: _isProcessingDeletion
                                  ? null // Deaktivieren während Löschvorgang läuft
                                  : () async {
                                      // NEU: Verarbeitung des Löschvorgangs
                                      setDialogState(() {
                                        _isProcessingDeletion = true;
                                      });

                                      try {
                                        // Bestätigungsdialog anzeigen
                                        bool confirmDelete =
                                            await showDialog<bool>(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder: (confirmContext) =>
                                                      AlertDialog(
                                                    title: const Text(
                                                        'Übung löschen?'),
                                                    content: const Text(
                                                        'Möchtest du diese Übung wirklich löschen? Dies kann später im Trainingsplan gespeichert werden.'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    confirmContext)
                                                                .pop(false),
                                                        child: const Text(
                                                            'Abbrechen'),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    confirmContext)
                                                                .pop(true),
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                        child: const Text(
                                                            'Löschen'),
                                                      ),
                                                    ],
                                                  ),
                                                ) ??
                                                false;

                                        // Wenn Benutzer abgebrochen hat, Dialog-Status zurücksetzen
                                        if (!confirmDelete) {
                                          setDialogState(() {
                                            _isProcessingDeletion = false;
                                          });
                                          return;
                                        }

                                        // Erst Dialog schließen
                                        Navigator.pop(context);

                                        // Kurze Verzögerung vor Löschoperation
                                        await Future.delayed(
                                            const Duration(milliseconds: 300));

                                        // Dann die Übung löschen
                                        final success = await sessionProvider
                                            .removeExerciseFromSession(
                                          widget.exerciseIndex,
                                          onTabsChanged:
                                              widget.onExerciseRemoved,
                                        );

                                        // Haptisches Feedback, wenn erfolgreich
                                        if (success && mounted) {
                                          HapticFeedback.mediumImpact();
                                        }
                                      } catch (e) {
                                        print(
                                            'Fehler beim Löschen der Übung: $e');
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Fehler beim Löschen: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }

                                        // Bei Fehler auch den Dialog-Status zurücksetzen
                                        if (mounted) {
                                          setState(() {
                                            _isProcessingDeletion = false;
                                          });
                                        }
                                      }
                                    },
                              icon: _isProcessingDeletion
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.delete_outline,
                                      color: Colors.white),
                              label: Text(_isProcessingDeletion
                                  ? 'Wird gelöscht...'
                                  : 'Übung löschen'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Overlay mit Ladeindikator, wenn das Formular noch nicht geladen ist
                  if (!isFormLoaded)
                    Container(
                      color: Colors.white,
                      width: double.infinity,
                      height: double.infinity,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Übung wird geladen...'),
                          ],
                        ),
                      ),
                    ),
                ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openStrengthCalculator(BuildContext context) {
    HapticFeedback.mediumImpact();

    final sessionProvider =
        Provider.of<TrainingSessionProvider>(context, listen: false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StrengthCalculatorScreen(
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
      builder: (context) => Container(
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
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Satz-Optionen',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
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
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: Colors.black,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ultra-sanfter Auto-Scroll mit perfekter Glätte
  Future<void> _scrollToActiveSet(int activeSetIndex, int totalSets) async {
    if (!_setsScrollController.hasClients || !mounted) return;
    
    // Erweiterte Wartezeit für vollständige Widget-Stabilisierung
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Doppelte Überprüfung der Controller-Verfügbarkeit
    if (!_setsScrollController.hasClients || !mounted) return;
    
    // Berechne die exakte Position basierend auf Action Bar
    double? targetScrollOffset = _calculatePreciseScrollOffset(activeSetIndex);
    
    if (targetScrollOffset == null) {
      // Fallback auf approximierte Berechnung
      targetScrollOffset = _calculateFallbackScrollOffset(activeSetIndex);
    }
    
    // Sichere Grenzen mit zusätzlicher Validierung
    final double maxScrollExtent = _setsScrollController.position.maxScrollExtent;
    final double minScrollExtent = _setsScrollController.position.minScrollExtent;
    final double finalOffset = targetScrollOffset.clamp(minScrollExtent, maxScrollExtent);
    
    // Präziser Performance-Check
    final double currentOffset = _setsScrollController.offset;
    const double scrollThreshold = 10.0; // Noch präziser
    
    if ((finalOffset - currentOffset).abs() < scrollThreshold) {
      return; // Bereits optimal positioniert
    }
    
    try {
      // Berechne optimale Animation-Parameter für maximale Sanftheit
      final double scrollDistance = (finalOffset - currentOffset).abs();
      
      // Frame-Rate optimierte Dauer-Berechnung für perfekte Sanftheit
      // Ziel: ~60fps mit smooth interpolation
      final double pixelsPerSecond = 120.0; // Sanfte Geschwindigkeit
      final int calculatedDuration = (scrollDistance / pixelsPerSecond * 1000).round();
      final int duration = calculatedDuration.clamp(400, 1200); // Realistische Grenzen
      
      // Experimentiere mit verschiedenen Curves für maximale Sanftheit
      Curve animationCurve;
      
      if (scrollDistance < 50) {
        // Sehr kurze Distanz: Linear für absolute Glätte
        animationCurve = Curves.linear;
      } else if (scrollDistance < 150) {
        // Mittlere Distanz: Sanfte Deceleration
        animationCurve = Curves.easeOut;
      } else {
        // Lange Distanz: Ultra-sanfte exponentielle Kurve
        animationCurve = Curves.easeOutExpo;
      }
      
      // Ultra-sanfte Animation mit perfekter Frame-Rate
      await _setsScrollController.animateTo(
        finalOffset,
        duration: Duration(milliseconds: duration),
        curve: animationCurve,
      );
      
      // Verzögerte haptische Rückmeldung für natürlicheres Gefühl
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 200));
        HapticFeedback.selectionClick();
      }
      
    } catch (e) {
      // Sanftes Fallback auch bei Fehlern
      if (mounted && _setsScrollController.hasClients) {
        try {
          await _setsScrollController.animateTo(
            finalOffset,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
          );
        } catch (_) {
          _setsScrollController.jumpTo(finalOffset);
        }
      }
    }
  }
  
  // Berechne exakte Scroll-Position basierend auf realen Widget-Positionen
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
          const double desiredGap = 16.0; // Etwas größerer Gap für bessere Optik
          final double targetSetY = actionBarBottom + desiredGap;
          
          // Berechne erforderlichen Scroll-Offset
          final double currentSetY = setPosition.dy;
          final double scrollAdjustment = currentSetY - targetSetY;
          final double currentScrollOffset = _setsScrollController.offset;
          
          return currentScrollOffset + scrollAdjustment;
        }
      }
      
      // Fallback: Verwende approximierte Position
      const double desiredGap = 16.0;
      const double averageSetHeight = 104.0; // Gemessene Durchschnittshöhe
      const double listTopPadding = 8.0;
      
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
    const double actionBarHeight = 38.0;
    const double actionBarPadding = 16.0 + 8.0; // top + bottom padding
    const double exerciseDetailsHeight = 0.0; // Nur wenn showDetails true ist
    const double setHeight = 108.0;
    const double listTopPadding = 8.0;
    
    // Berechne Position wo der aktive Satz beginnen soll
    final double actionBarTotalHeight = actionBarHeight + actionBarPadding;
    final double targetSetPosition = actionBarTotalHeight + exerciseDetailsHeight + 8.0;
    
    // Berechne erforderlichen Scroll-Offset
    final double setActualPosition = listTopPadding + (activeSetIndex * setHeight);
    return setActualPosition - targetSetPosition;
  }

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
          // Exercise details section - only show if enabled
          if (widget.showDetails)
            _buildExerciseDetailsButton(context, exercise),

          // Action Bar - immer sichtbar im Apple-Stil
          if (isActiveExercise)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Container(
                key: _actionBarKey, // GlobalKey für Positionsreferenz
                height: 38,
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
                              height: 38,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calculate_outlined,
                                    size: 18,
                                    color: allSetsCompleted ? _mercury : _snow,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Rechner',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: allSetsCompleted ? _mercury : _snow,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
                          onTap: (!_hasRecommendation(
                                      sessionProvider,
                                      sessionProvider
                                          .getActiveSetIdForCurrentExercise()) ||
                                  allSetsCompleted)
                              ? null
                              : () {
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
                            opacity: (!_hasRecommendation(
                                        sessionProvider,
                                        sessionProvider
                                            .getActiveSetIdForCurrentExercise()) ||
                                    allSetsCompleted)
                                ? 0.5
                                : 1.0,
                            child: Container(
                              height: 38,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bolt,
                                    size: 18,
                                    color: (!_hasRecommendation(sessionProvider, sessionProvider.getActiveSetIdForCurrentExercise()) || allSetsCompleted) ? _mercury : _emberCore,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Progress',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: (!_hasRecommendation(sessionProvider, sessionProvider.getActiveSetIdForCurrentExercise()) || allSetsCompleted) ? _mercury : _snow,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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

                    // Zurück-Button - immer anzeigen, aber bei Bedarf ausgegraut
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: !_hasCompletedSets(
                                  sessionProvider.currentExerciseSets)
                              ? null
                              : () =>
                                  _showActionsMenu(context, sessionProvider),
                          borderRadius: BorderRadius.circular(12),
                          child: Opacity(
                            opacity: !_hasCompletedSets(
                                    sessionProvider.currentExerciseSets)
                                ? 0.5
                                : 1.0,
                            child: Container(
                              height: 38,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.replay_rounded,
                                    size: 18,
                                    color: !_hasCompletedSets(sessionProvider.currentExerciseSets) ? _mercury : _snow,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Zurück',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: !_hasCompletedSets(sessionProvider.currentExerciseSets) ? _mercury : _snow,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
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
        onTap: () => _showExerciseEditor(context, adaptedExercise),
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
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
}
