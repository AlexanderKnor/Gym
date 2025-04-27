// lib/screens/training_session_screen/training_session_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/training_plan_screen/training_plan_model.dart';
import '../../models/progression_manager_screen/training_set_model.dart';
import '../../providers/training_session_screen/training_session_provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../widgets/training_session_screen/exercise_tab_widget.dart';
import '../../widgets/training_session_screen/rest_timer_widget.dart';
import '../../widgets/training_session_screen/training_completion_widget.dart';

class TrainingSessionScreen extends StatefulWidget {
  final TrainingPlanModel trainingPlan;
  final int dayIndex;

  const TrainingSessionScreen({
    Key? key,
    required this.trainingPlan,
    required this.dayIndex,
  }) : super(key: key);

  @override
  State<TrainingSessionScreen> createState() => _TrainingSessionScreenState();
}

class _TrainingSessionScreenState extends State<TrainingSessionScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _initialized = false;
  bool _startupComplete = false;
  bool _isLoading = true;
  int _lastKnownExerciseIndex = 0;
  bool _showExerciseDetails = true; // Standardmäßig auf true setzen
  bool _isNavigatingExercises = false;

  @override
  void initState() {
    super.initState();

    // Set system UI overlay style to match the aesthetic
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSessionWithDelay();
    });
  }

  Future<void> _initializeSessionWithDelay() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      setState(() {
        _isLoading = true;
      });

      final sessionProvider =
          Provider.of<TrainingSessionProvider>(context, listen: false);

      await sessionProvider.startTrainingSession(
          widget.trainingPlan, widget.dayIndex);

      if (mounted) {
        _initializeTabController();
      }

      if (mounted) {
        setState(() {
          _startupComplete = true;
          _isLoading = false;
          _lastKnownExerciseIndex = sessionProvider.currentExerciseIndex;
        });
      }
    } catch (e) {
      print('Fehler bei der Initialisierung der Trainingssession: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _initializeTabController() {
    try {
      final sessionProvider =
          Provider.of<TrainingSessionProvider>(context, listen: false);
      final exerciseCount = sessionProvider.exercises.length;

      if (exerciseCount > 0) {
        setState(() {
          _tabController = TabController(
            length: exerciseCount,
            vsync: this,
          );

          _tabController!.addListener(() {
            if (!_tabController!.indexIsChanging) {
              sessionProvider.selectExercise(_tabController!.index);
            }
          });

          _initialized = true;
        });
      }
    } catch (e) {
      print('Fehler bei der Initialisierung des TabControllers: $e');
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();

    // Reset system UI to default when leaving
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
    );

    super.dispose();
  }

  void _syncTabWithCurrentExercise(TrainingSessionProvider sessionProvider) {
    if (_tabController == null) return;

    if (sessionProvider.currentExerciseIndex < _tabController!.length) {
      if (_tabController!.index != sessionProvider.currentExerciseIndex) {
        _tabController!.animateTo(sessionProvider.currentExerciseIndex);
        _lastKnownExerciseIndex = sessionProvider.currentExerciseIndex;
      }
    }
  }

  void _toggleExerciseDetails() {
    setState(() {
      _showExerciseDetails = !_showExerciseDetails;

      // Provide haptic feedback for the toggle
      HapticFeedback.lightImpact();
    });
  }

  void _toggleExerciseNavigation() {
    setState(() {
      _isNavigatingExercises = !_isNavigatingExercises;

      // Provide haptic feedback for the toggle
      HapticFeedback.mediumImpact();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[800]!),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Dein Training wird vorbereitet',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_startupComplete) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[800]!),
          ),
        ),
      );
    }

    return Consumer<TrainingSessionProvider>(
      builder: (context, sessionProvider, child) {
        if (sessionProvider.isTrainingCompleted) {
          return const TrainingCompletionWidget();
        }

        if (!_initialized || sessionProvider.exercises.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[800]!),
              ),
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _syncTabWithCurrentExercise(sessionProvider);
        });

        final bool allSetsCompleted =
            sessionProvider.areAllSetsCompletedForCurrentExercise();
        final bool hasMoreExercises =
            sessionProvider.hasMoreExercisesAfterCurrent();
        final exercise =
            sessionProvider.exercises[sessionProvider.currentExerciseIndex];

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(
                kToolbarHeight + 40), // Erhöhte Höhe für die Tabs
            child: ClipRRect(
              child: BackdropFilter(
                filter: _isNavigatingExercises
                    ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
                    : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  color: _isNavigatingExercises
                      ? Colors.white.withOpacity(0.8)
                      : Colors.white,
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                      // SizedBox mit fester Höhe für stabiles Layout
                      height: kToolbarHeight + 40,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Main App Bar
                          Container(
                            height: kToolbarHeight,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              children: [
                                // Close button
                                IconButton(
                                  icon: const Icon(Icons.close, size: 22),
                                  onPressed: () =>
                                      _showExitConfirmation(context),
                                  splashRadius: 20,
                                ),

                                // Title
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      sessionProvider.trainingDay?.name ?? "",
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                ),

                                // Info-Button wurde entfernt
                                const SizedBox(width: 48), // Platzhalter
                              ],
                            ),
                          ),

                          // Exercise navigation indicator
                          GestureDetector(
                            onTap: _toggleExerciseNavigation,
                            child: Container(
                              height: 40,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _isNavigatingExercises
                                      ? Colors.grey[100]
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      exercise.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[900],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _isNavigatingExercises
                                          ? Icons.arrow_drop_up
                                          : Icons.arrow_drop_down,
                                      color: Colors.grey[700],
                                    ),
                                  ],
                                ),
                              ),
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
          body: Stack(
            children: [
              // Main content
              Column(
                children: [
                  // Rest timer if active
                  if (sessionProvider.isResting)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 16.0),
                      child: RestTimerWidget(),
                    ),

                  // Exercise content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(
                        sessionProvider.exercises.length,
                        (index) => ExerciseTabWidget(
                          exerciseIndex: index,
                          showDetails: _showExerciseDetails,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Exercise navigation overlay
              if (_isNavigatingExercises)
                _buildExerciseNavigationOverlay(sessionProvider),
            ],
          ),
          bottomNavigationBar: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: _isNavigatingExercises ? 0 : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress indicator
                LinearProgressIndicator(
                  value: sessionProvider.trainingProgress,
                  minHeight: 2,
                  backgroundColor: Colors.grey[200],
                  color: Colors.black,
                ),

                // Action button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: allSetsCompleted
                            ? () {
                                HapticFeedback.mediumImpact();
                                sessionProvider.completeCurrentExercise();
                              }
                            : () {
                                HapticFeedback.mediumImpact();
                                sessionProvider.completeCurrentSet();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          allSetsCompleted
                              ? (hasMoreExercises
                                  ? 'Nächste Übung'
                                  : 'Training abschließen')
                              : 'Satz abschließen',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExerciseNavigationOverlay(
      TrainingSessionProvider sessionProvider) {
    return GestureDetector(
      onTap: _toggleExerciseNavigation,
      child: Container(
        color: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.white.withOpacity(0.85),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 70),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Navigation title
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      'Wechsle zu',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  // Exercise list
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: sessionProvider.exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = sessionProvider.exercises[index];
                        final isCurrentExercise =
                            index == sessionProvider.currentExerciseIndex;
                        final isCompleted =
                            sessionProvider.isExerciseCompleted(index);

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _tabController?.animateTo(index);
                            sessionProvider.selectExercise(index);

                            // Close navigation with slight delay
                            Future.delayed(const Duration(milliseconds: 200),
                                _toggleExerciseNavigation);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: isCurrentExercise
                                  ? Colors.grey[100]
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isCurrentExercise
                                    ? Colors.black
                                    : Colors.grey[200]!,
                                width: isCurrentExercise ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Status icon
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCompleted
                                        ? Colors.green[100]
                                        : isCurrentExercise
                                            ? Colors.black
                                            : Colors.grey[200],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isCompleted
                                          ? Icons.check
                                          : isCurrentExercise
                                              ? Icons.play_arrow
                                              : Icons.fitness_center,
                                      size: 18,
                                      color: isCompleted
                                          ? Colors.green[700]
                                          : isCurrentExercise
                                              ? Colors.white
                                              : Colors.grey[500],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Exercise details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exercise.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isCurrentExercise
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: isCurrentExercise
                                              ? Colors.black
                                              : Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${exercise.primaryMuscleGroup}${exercise.secondaryMuscleGroup.isNotEmpty ? ' • ${exercise.secondaryMuscleGroup}' : ''}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Status text
                                if (isCompleted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Abgeschlossen',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  )
                                else if (isCurrentExercise)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Aktuell',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Close button
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: TextButton(
                      onPressed: _toggleExerciseNavigation,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Schließen',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showActionsMenu(
      BuildContext context, TrainingSessionProvider sessionProvider) {
    HapticFeedback.mediumImpact();

    final bool hasCompletedSets =
        _hasCompletedSets(sessionProvider.currentExerciseSets);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
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
                const Text(
                  'Übungsoptionen',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Übungsdetails-Bereich
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 8),
                        child: Text(
                          "Übungsinformationen",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      // Übungsdetails anzeigen/ausblenden
                      _buildActionButton(
                        icon: _showExerciseDetails
                            ? Icons.visibility_off
                            : Icons.visibility,
                        label: _showExerciseDetails
                            ? 'Übungsdetails ausblenden'
                            : 'Übungsdetails anzeigen',
                        onTap: () {
                          _toggleExerciseDetails();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),

                // Satz-Optionen
                Container(
                  margin: const EdgeInsets.only(bottom: 12, top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 8),
                        child: Text(
                          "Satz-Optionen",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      // Satz reaktivieren - wird angezeigt, wenn es abgeschlossene Sätze gibt
                      if (hasCompletedSets)
                        _buildActionButton(
                          icon: Icons.replay_rounded,
                          label: 'Letzten Satz reaktivieren',
                          onTap: () {
                            sessionProvider.reactivateLastCompletedSet(
                                sessionProvider.currentExerciseIndex);
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
                    ],
                  ),
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

  bool _hasCompletedSets(List<TrainingSetModel> sets) {
    for (final set in sets) {
      if (set.abgeschlossen) {
        return true;
      }
    }
    return false;
  }

  void _showExitConfirmation(BuildContext context) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
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
                const Text(
                  'Training beenden?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Dein Fortschritt wird gespeichert, aber das Training wird als nicht abgeschlossen markiert.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final sessionProvider =
                            Provider.of<TrainingSessionProvider>(context,
                                listen: false);
                        sessionProvider.completeTraining();
                      } catch (e) {
                        print('Fehler beim Beenden des Trainings: $e');
                      }
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red[700],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Training beenden',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Weiter trainieren',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
