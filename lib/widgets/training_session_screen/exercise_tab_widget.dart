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

class ExerciseTabWidget extends StatefulWidget {
  final int exerciseIndex;
  final bool showDetails;

  const ExerciseTabWidget({
    Key? key,
    required this.exerciseIndex,
    this.showDetails = false,
  }) : super(key: key);

  @override
  State<ExerciseTabWidget> createState() => _ExerciseTabWidgetState();
}

class _ExerciseTabWidgetState extends State<ExerciseTabWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? _exerciseProfileId;
  final TextEditingController _standardIncreaseController =
      TextEditingController();
  final TextEditingController _restTimeController = TextEditingController();
  bool _showAdvancedOptions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProgressionManager();
    });
  }

  @override
  void dispose() {
    _standardIncreaseController.dispose();
    _restTimeController.dispose();
    super.dispose();
  }

  void _initializeProgressionManager() {
    final sessionProvider =
        Provider.of<TrainingSessionProvider>(context, listen: false);
    final progressionProvider =
        Provider.of<ProgressionManagerProvider>(context, listen: false);

    if (widget.exerciseIndex < sessionProvider.exercises.length) {
      final exercise = sessionProvider.exercises[widget.exerciseIndex];

      _standardIncreaseController.text = exercise.standardIncrease.toString();
      _restTimeController.text = exercise.restPeriodSeconds.toString();

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

  void _updateLocalControllersIfNeeded() {
    final sessionProvider =
        Provider.of<TrainingSessionProvider>(context, listen: false);
    if (widget.exerciseIndex < sessionProvider.exercises.length) {
      final exercise = sessionProvider.exercises[widget.exerciseIndex];

      if (_standardIncreaseController.text !=
          exercise.standardIncrease.toString()) {
        _standardIncreaseController.text = exercise.standardIncrease.toString();
      }

      if (_restTimeController.text != exercise.restPeriodSeconds.toString()) {
        _restTimeController.text = exercise.restPeriodSeconds.toString();
      }
    }
  }

  void _changeProgressionProfile(String newProfileId) {
    if (_exerciseProfileId == newProfileId) return;

    final sessionProvider =
        Provider.of<TrainingSessionProvider>(context, listen: false);
    final progressionProvider =
        Provider.of<ProgressionManagerProvider>(context, listen: false);

    sessionProvider.updateExerciseProgressionProfile(
        widget.exerciseIndex, newProfileId);

    HapticFeedback.selectionClick();

    setState(() {
      _exerciseProfileId = newProfileId;
    });

    if (widget.exerciseIndex == sessionProvider.currentExerciseIndex) {
      final activeSetId = sessionProvider.getActiveSetIdForCurrentExercise();
      sessionProvider.calculateProgressionForSet(
          widget.exerciseIndex, activeSetId, newProfileId, progressionProvider);
    }
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

  void _showEditExerciseConfigDialog(
      BuildContext context, String field, String title, String currentValue) {
    final TextEditingController controller =
        TextEditingController(text: currentValue);
    final sessionProvider =
        Provider.of<TrainingSessionProvider>(context, listen: false);

    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                keyboardType: TextInputType.numberWithOptions(
                    decimal: field == 'standardIncrease'),
                autofocus: true,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: field == 'standardIncrease'
                      ? 'Wert in kg'
                      : 'Wert in Sekunden',
                  hintText:
                      field == 'standardIncrease' ? 'z.B. 2.5' : 'z.B. 60',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: Colors.black, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Abbrechen',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          final value = controller.text;
                          if (value.isNotEmpty) {
                            sessionProvider.updateExerciseConfig(
                                widget.exerciseIndex, field, value);
                            if (field == 'standardIncrease') {
                              setState(() {
                                _standardIncreaseController.text = value;
                              });
                            } else if (field == 'restPeriodSeconds') {
                              setState(() {
                                _restTimeController.text = value;
                              });
                            }
                            HapticFeedback.mediumImpact();
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Speichern',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
    ).then((_) {
      controller.dispose();
    });
  }

  void _toggleAdvancedOptions() {
    setState(() {
      _showAdvancedOptions = !_showAdvancedOptions;
      HapticFeedback.selectionClick();
    });
  }

  void _showActionsMenu(
      BuildContext context, TrainingSessionProvider sessionProvider) {
    HapticFeedback.mediumImpact();

    final bool allSetsCompleted =
        sessionProvider.areAllSetsCompletedForCurrentExercise();
    final hasCompletedSets =
        _hasCompletedSets(sessionProvider.currentExerciseSets);

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

                // Satz reaktivieren - wird angezeigt, wenn es abgeschlossene Sätze gibt
                if (hasCompletedSets)
                  _buildActionButton(
                    icon: Icons.replay_rounded,
                    label: 'Letzten Satz reaktivieren',
                    onTap: () {
                      sessionProvider
                          .reactivateLastCompletedSet(widget.exerciseIndex);
                      Navigator.pop(context);
                    },
                  ),

                // Add set
                _buildActionButton(
                  icon: Icons.add_circle_outline,
                  label: 'Satz hinzufügen',
                  onTap: () {
                    sessionProvider.addSetToCurrentExercise();
                    Navigator.pop(context);
                  },
                ),

                // Remove set
                _buildActionButton(
                  icon: Icons.remove_circle_outline,
                  label: 'Satz entfernen',
                  onTap: () {
                    sessionProvider.removeSetFromCurrentExercise();
                    Navigator.pop(context);
                  },
                ),

                // Kraftrechner - nur anzeigen, wenn nicht alle Sätze abgeschlossen sind
                if (!allSetsCompleted)
                  _buildActionButton(
                    icon: Icons.calculate_outlined,
                    label: 'Kraftrechner öffnen',
                    onTap: () {
                      Navigator.pop(context);
                      _openStrengthCalculator(context);
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

    _updateLocalControllersIfNeeded();

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
            _buildExerciseInfoCard(exercise, progressionProvider),

          // Action Bar - always accessible, even when details are hidden
          if (isActiveExercise) // Entfernt die Bedingung "!allSetsCompleted"
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Quick action buttons
                  Row(
                    children: [
                      // Kraftrechner button - nur anzeigen, wenn nicht alle Sätze abgeschlossen sind
                      if (!allSetsCompleted)
                        _buildQuickActionButton(
                          icon: Icons.calculate_outlined,
                          label: 'Kraftrechner',
                          onPressed: () => _openStrengthCalculator(context),
                        ),

                      // Empfehlungen - nur anzeigen, wenn Empfehlungen verfügbar sind und nicht alle Sätze abgeschlossen sind
                      if (_exerciseProfileId != null && !allSetsCompleted) ...[
                        const SizedBox(width: 16),
                        _buildQuickActionButton(
                          icon: Icons.auto_fix_high,
                          label: 'Empfehlung',
                          onPressed: () {
                            final activeSetId = sessionProvider
                                .getActiveSetIdForCurrentExercise();
                            final activeSet =
                                sessionProvider.currentExerciseSets.firstWhere(
                              (s) => s.id == activeSetId,
                              orElse: () => TrainingSetModel(
                                  id: 0, kg: 0, wiederholungen: 0, rir: 0),
                            );

                            if (activeSet.empfehlungBerechnet) {
                              HapticFeedback.mediumImpact();
                              sessionProvider.applyProgressionRecommendation(
                                activeSetId,
                                activeSet.empfKg,
                                activeSet.empfWiederholungen,
                                activeSet.empfRir,
                              );
                            }
                          },
                          isDisabled: !_hasRecommendation(
                              sessionProvider,
                              sessionProvider
                                  .getActiveSetIdForCurrentExercise()),
                        ),
                      ],
                    ],
                  ),

                  // Options button
                  GestureDetector(
                    onTap: () => _showActionsMenu(context, sessionProvider),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.more_horiz,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Optionen',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildExerciseInfoCard(
      ExerciseModel exercise, ProgressionManagerProvider progressionProvider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Muscle groups as chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildMuscleGroupChip(exercise.primaryMuscleGroup),
                      if (exercise.secondaryMuscleGroup.isNotEmpty)
                        _buildMuscleGroupChip(exercise.secondaryMuscleGroup,
                            isSecondary: true),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Exercise details in a row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildExerciseDetailItem(
                        context: context,
                        icon: Icons.fitness_center,
                        label: 'Steigerung',
                        value: '${exercise.standardIncrease} kg',
                        onTap: () => _showEditExerciseConfigDialog(
                          context,
                          'standardIncrease',
                          'Standardsteigerung',
                          exercise.standardIncrease.toString(),
                        ),
                      ),
                      _buildExerciseDetailItem(
                        context: context,
                        icon: Icons.timer_outlined,
                        label: 'Satzpause',
                        value: '${exercise.restPeriodSeconds} s',
                        onTap: () => _showEditExerciseConfigDialog(
                          context,
                          'restPeriodSeconds',
                          'Satzpause',
                          exercise.restPeriodSeconds.toString(),
                        ),
                      ),
                      _buildExerciseDetailItem(
                        context: context,
                        icon: Icons.repeat,
                        label: 'Sätze',
                        value: '${exercise.numberOfSets}',
                        onTap: null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Progression profile dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Progressionsprofil',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                          color: Colors.grey[50],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _exerciseProfileId,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.black,
                            ),
                            hint: Text(
                              'Profil wählen',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 15,
                              ),
                            ),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            dropdownColor: Colors.white,
                            items: progressionProvider.progressionsProfile
                                .map((profile) {
                              return DropdownMenuItem<String>(
                                value: profile.id,
                                child: Text(
                                  profile.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: _exerciseProfileId == profile.id
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (profileId) {
                              if (profileId != null) {
                                _changeProgressionProfile(profileId);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleGroupChip(String label, {bool isSecondary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isSecondary ? Colors.purple[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isSecondary ? Colors.purple[700] : Colors.blue[700],
        ),
      ),
    );
  }

  Widget _buildExerciseDetailItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onTap != null ? Colors.grey[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: onTap != null ? Border.all(color: Colors.grey[200]!) : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: Colors.grey[800],
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit,
                    size: 12,
                    color: Colors.blue[600],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
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

  bool _hasCompletedSets(List<TrainingSetModel> sets) {
    for (final set in sets) {
      if (set.abgeschlossen) {
        return true;
      }
    }
    return false;
  }
}
