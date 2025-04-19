// lib/widgets/training_session_screen/rest_timer_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/training_session_screen/training_session_provider.dart';
import '../../services/training_session_screen/training_timer_service.dart';

class RestTimerWidget extends StatefulWidget {
  const RestTimerWidget({Key? key}) : super(key: key);

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TrainingTimerService _timerService = TrainingTimerService();
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();

    // Animationscontroller für den Countdown-Kreis
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // Timer-Service initialisieren
    _initializeTimer();
  }

  void _initializeTimer() {
    final sessionProvider =
        Provider.of<TrainingSessionProvider>(context, listen: false);
    final exercise = sessionProvider.currentExercise;

    if (exercise != null) {
      final restPeriod = exercise.restPeriodSeconds;

      // Callbacks für den Timer definieren
      _timerService.onTick = (seconds) {
        setState(() {
          // Animation aktualisieren
          final progress = seconds / restPeriod;
          _animationController.value = progress;
        });
      };

      _timerService.onComplete = () {
        // Timer ist abgelaufen, zurück zum Training
        sessionProvider.skipRestTimer();
      };

      // Timer starten
      _timerService.startTimer(restPeriod);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<TrainingSessionProvider>(context);
    final exercise = sessionProvider.currentExercise;
    final restTimeRemaining = sessionProvider.restTimeRemaining;

    if (exercise == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Restzeit für Animation updaten
    final totalRestTime = exercise.restPeriodSeconds;
    final progress = restTimeRemaining / totalRestTime;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Übungsname
            Text(
              'Pause nach:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              exercise.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // Timer-Anzeige
            Stack(
              alignment: Alignment.center,
              children: [
                // Kreisförmiger Fortschrittsbalken
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      restTimeRemaining <= 3
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                ),

                // Zeit-Anzeige
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      TrainingTimerService.formatTime(restTimeRemaining),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Sekunden',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pause/Fortsetzen-Button
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isPaused = !_isPaused;
                      _timerService.togglePause();
                    });
                  },
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                  label: Text(_isPaused ? 'Fortsetzen' : 'Pause'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(120, 48),
                  ),
                ),
                const SizedBox(width: 16),

                // Überspringen-Button
                ElevatedButton.icon(
                  onPressed: () {
                    sessionProvider.skipRestTimer();
                  },
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Überspringen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(120, 48),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nächster Satz Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Text(
                    'Nächster Satz:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${sessionProvider.activeSetIndex + 1}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Satz ${sessionProvider.activeSetIndex + 1} von ${sessionProvider.currentExerciseSets.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
}
