// lib/screens/training_session_screen/training_session_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/training_plan_screen/training_plan_model.dart';
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
  bool _startupComplete = false; // Flag für abgeschlossene Initialisierung
  bool _isLoading = true; // Neuer Flag für den Ladezustand
  int _lastKnownExerciseIndex = 0; // Zum Tracking des Übungswechsels

  @override
  void initState() {
    super.initState();
    // TabController wird später initialisiert, da wir die Anzahl der Tabs
    // erst nach dem Laden der Session kennen

    // Initialisiere die Session mit Verzögerung, um sicherzustellen, dass alle Provider bereit sind
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSessionWithDelay();
    });
  }

  // Methode, die die Initialisierung mit Verzögerung durchführt
  Future<void> _initializeSessionWithDelay() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      setState(() {
        _isLoading = true;
      });

      final sessionProvider =
          Provider.of<TrainingSessionProvider>(context, listen: false);

      // Starte die Trainingssession
      await sessionProvider.startTrainingSession(
          widget.trainingPlan, widget.dayIndex);

      // Jetzt können wir den TabController initialisieren
      if (mounted) {
        _initializeTabController();
      }

      // Markiere den Startup als abgeschlossen
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

          // Listener für Tab-Änderungen
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
    super.dispose();
  }

  // Hilfsmethode, um den Tab zur aktuellen Übung zu synchronisieren
  void _syncTabWithCurrentExercise(TrainingSessionProvider sessionProvider) {
    if (_tabController == null) return;

    // Überprüfen ob der TabController initialisiert ist und der Index gültig ist
    if (sessionProvider.currentExerciseIndex < _tabController!.length) {
      // Wechsle immer zum Tab der aktuellen Übung
      if (_tabController!.index != sessionProvider.currentExerciseIndex) {
        // Animierte Navigation zum Tab
        _tabController!.animateTo(sessionProvider.currentExerciseIndex);
        _lastKnownExerciseIndex = sessionProvider.currentExerciseIndex;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Überprüfen, ob noch geladen wird
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Training wird vorbereitet...')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Training wird vorbereitet...'),
            ],
          ),
        ),
      );
    }

    // Überprüfen, ob der Startup abgeschlossen ist
    if (!_startupComplete) {
      return Scaffold(
        appBar: AppBar(title: const Text('Training wird vorbereitet...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Consumer direkt verwenden, ohne MultiProvider
    return Consumer<TrainingSessionProvider>(
      builder: (context, sessionProvider, child) {
        // Prüfe, ob das Training abgeschlossen ist
        if (sessionProvider.isTrainingCompleted) {
          return const TrainingCompletionWidget();
        }

        // Prüfe, ob die Daten geladen wurden
        if (!_initialized || sessionProvider.exercises.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Training wird geladen...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Wichtig: Synchronisiere den TabController mit dem aktuellen Übungsindex
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _syncTabWithCurrentExercise(sessionProvider);
        });

        return Scaffold(
          appBar: AppBar(
            title: Text('Training: ${sessionProvider.trainingDay?.name ?? ""}'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _showExitConfirmation(context),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: sessionProvider.exercises.asMap().entries.map((entry) {
                final index = entry.key;
                final exercise = entry.value;
                final isCompleted = sessionProvider.isExerciseCompleted(index);

                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status-Icon (abgeschlossen, aktiv, ausstehend)
                      Icon(
                        isCompleted
                            ? Icons.check_circle
                            : index == sessionProvider.currentExerciseIndex
                                ? Icons.play_circle_fill
                                : Icons.circle_outlined,
                        size: 16,
                        color: isCompleted
                            ? Colors.green
                            : index == sessionProvider.currentExerciseIndex
                                ? Colors.blue
                                : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      // Übungsname
                      Text(exercise.name),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          body: Column(
            children: [
              // Timer-Widget, wenn in Erholungspause
              if (sessionProvider.isResting)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RestTimerWidget(),
                ),

              // Haupt-Übungsbereich
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics:
                      const NeverScrollableScrollPhysics(), // Verhindert Wischen zwischen Tabs
                  children: List.generate(
                    sessionProvider.exercises.length,
                    (index) => ExerciseTabWidget(exerciseIndex: index),
                  ),
                ),
              ),
            ],
          ),
          // Fortschrittsanzeige am unteren Rand
          bottomNavigationBar: LinearProgressIndicator(
            value: sessionProvider.trainingProgress,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor:
                AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        );
      },
    );
  }

  // Dialog zur Bestätigung des Trainingsabbruchs
  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Training beenden?'),
        content: const Text(
            'Möchtest du das Training wirklich beenden? Dein Fortschritt wird gespeichert.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Speichere das Training vor dem Beenden
                final sessionProvider = Provider.of<TrainingSessionProvider>(
                    context,
                    listen: false);

                // Training als abgeschlossen markieren, auch wenn es nicht vollständig ist
                sessionProvider.completeTraining();
              } catch (e) {
                print('Fehler beim Beenden des Trainings: $e');
              }

              Navigator.of(context).pop(); // Dialog schließen
              Navigator.of(context).pop(); // Zum vorherigen Screen zurückkehren
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Training beenden'),
          ),
        ],
      ),
    );
  }
}
