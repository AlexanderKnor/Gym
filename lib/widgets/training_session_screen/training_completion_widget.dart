// lib/widgets/training_session_screen/training_completion_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/training_session_screen/training_session_provider.dart';
import '../../providers/shared/navigation_provider.dart';
import '../../screens/main_screen.dart';

class TrainingCompletionWidget extends StatelessWidget {
  const TrainingCompletionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<TrainingSessionProvider>(context);
    final trainingPlan = sessionProvider.trainingPlan;
    final trainingDay = sessionProvider.trainingDay;

    if (trainingPlan == null || trainingDay == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Statistiken berechnen
    final totalExercises = trainingDay.exercises.length;
    int totalSets = 0;
    for (final exercise in trainingDay.exercises) {
      totalSets += exercise.numberOfSets;
    }

    // GEÄNDERT: Sicherstellen, dass wir nur einmal speichern
    // Verzögerung, damit die UI zuerst rendern kann
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Sicherstellen, dass wir nicht während eines Build-Vorgangs den State ändern
      Future.microtask(() {
        sessionProvider.completeTraining();
      });
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Erfolgssymbol
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 24),

                // Titel
                const Text(
                  'Training abgeschlossen!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Untertitel
                Text(
                  'Du hast dein Training erfolgreich beendet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Trainingsübersicht
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trainingsübersicht',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Plan und Tag
                      _buildInfoRow('Trainingsplan:', trainingPlan.name),
                      const SizedBox(height: 8),
                      _buildInfoRow('Trainingstag:', trainingDay.name),
                      const SizedBox(height: 16),

                      // Statistiken
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              Icons.fitness_center,
                              'Übungen',
                              '$totalExercises',
                              Colors.purple[700]!,
                              Colors.purple[100]!,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              Icons.repeat,
                              'Sätze',
                              '$totalSets',
                              Colors.green[700]!,
                              Colors.green[100]!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Motivationstext
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events,
                          color: Colors.amber[700], size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Großartige Arbeit! Regelmäßiges Training ist der Schlüssel zum Erfolg.',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.amber[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Zurück-Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _returnToHomeScreen(context),
                    icon: const Icon(Icons.home),
                    label: const Text('Zum Startbildschirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String label,
    String value,
    Color iconColor,
    Color backgroundColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _returnToHomeScreen(BuildContext context) {
    // Navigation zum Home-Screen (Index 0)
    final navigationProvider =
        Provider.of<NavigationProvider>(context, listen: false);
    navigationProvider.setCurrentIndex(0);

    // Navigiere zurück zur MainScreen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false, // Entferne alle vorherigen Routen
    );
  }
}
