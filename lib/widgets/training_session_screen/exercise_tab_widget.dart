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
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? _exerciseProfileId;
  bool _showStandardIncrementWheel = false;
  bool _showRestPeriodWheel = false;
  bool _isProcessingDeletion = false; // NEU: Flag für Löschvorgang

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
            sessionProvider.calculateProgressionForSet(widget.exerciseIndex,
                activeSetId, _exerciseProfileId!, progressionProvider);
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

    // Merken wir uns das aktuelle Profil, um später zu überprüfen, ob es geändert wurde
    final String? originalProfileId = exercise.progressionProfileId;

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
              child: Stack(
                children: [
                  // Das tatsächliche Formular mit Lösch-Button
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Form Widget
                        ExerciseFormWidget(
                          initialExercise: exercise,
                          onSave: (updatedExercise) async {
                            // Übung im Provider aktualisieren
                            await sessionProvider.updateExerciseFullDetails(
                                widget.exerciseIndex, updatedExercise);

                            // Dialog schließen
                            Navigator.pop(context);

                            // Wenn das Progressionsprofil geändert wurde oder ein neues hinzugefügt wurde,
                            // Empfehlungen sofort neu berechnen
                            if (originalProfileId !=
                                updatedExercise.progressionProfileId) {
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
                                await sessionProvider
                                    .calculateProgressionForSet(
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
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

    final exercise = sessionProvider.exercises[widget.exerciseIndex];
    final bool allSetsCompleted = isActiveExercise &&
        sessionProvider.areAllSetsCompletedForCurrentExercise();

    if (isActiveExercise && _exerciseProfileId != null) {
      final activeSetId = sessionProvider.getActiveSetIdForCurrentExercise();
      Future.microtask(() {
        sessionProvider.calculateProgressionForSet(widget.exerciseIndex,
            activeSetId, _exerciseProfileId!, progressionProvider);
      });
    }

    return Container(
      color: Colors.white,
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
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
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
                                    color: Colors.grey[800],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Rechner',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
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
                      color: Colors.grey[300],
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
                                    color: Colors.grey[800],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Progress',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
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
                      color: Colors.grey[300],
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
                                    color: Colors.grey[800],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Zurück',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
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
    return InkWell(
      onTap: () => _showExerciseEditor(context, exercise),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tune,
              size: 18,
              color: Colors.grey[800],
            ),
            const SizedBox(width: 8),
            Text(
              'Übungseinstellungen bearbeiten',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
                letterSpacing: -0.3,
              ),
            ),
          ],
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

    return ListView.builder(
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

        return ExerciseSetWidget(
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
