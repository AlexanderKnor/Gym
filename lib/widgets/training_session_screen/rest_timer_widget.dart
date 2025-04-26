// lib/widgets/training_session_screen/rest_timer_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/training_session_screen/training_session_provider.dart';

class RestTimerWidget extends StatelessWidget {
  const RestTimerWidget({Key? key}) : super(key: key);

  // Timer-Zeit formatieren (MM:SS)
  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<TrainingSessionProvider>(context);
    final exercise = sessionProvider.currentExercise;
    final restTimeRemaining = sessionProvider.restTimeRemaining;

    if (exercise == null) {
      return const SizedBox.shrink();
    }

    // Restzeit für Animation berechnen
    final totalRestTime = exercise.restPeriodSeconds;
    final progress = restTimeRemaining / totalRestTime;

    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: restTimeRemaining <= 3 ? Colors.red[300]! : Colors.blue[300]!,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Timer-Kreis mit Animation
            SizedBox(
              width: 70,
              height: 70,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Kreisförmiger Fortschrittsbalken
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      restTimeRemaining <= 3
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                  // Zeit-Anzeige
                  Text(
                    _formatTime(restTimeRemaining),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Mittelsektion mit Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        color: Colors.blue[700],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Erholungspause',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nächster Satz: Satz ${sessionProvider.activeSetIndex + 1} von ${sessionProvider.currentExerciseSets.length}',
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Pause/Play Button
            IconButton(
              onPressed: () => sessionProvider.toggleRestTimer(),
              icon: Icon(
                sessionProvider.isPaused ? Icons.play_arrow : Icons.pause,
              ),
              tooltip: sessionProvider.isPaused ? 'Fortsetzen' : 'Pausieren',
              color: Theme.of(context).primaryColor,
            ),

            // Skip Button
            IconButton(
              onPressed: () => sessionProvider.skipRestTimer(),
              icon: const Icon(Icons.skip_next),
              tooltip: 'Pause überspringen',
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}
