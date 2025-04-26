// lib/widgets/training_session_screen/training_completion_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/training_session_screen/training_session_provider.dart';
import '../../providers/shared/navigation_provider.dart';
import '../../screens/main_screen.dart';

class TrainingCompletionWidget extends StatefulWidget {
  const TrainingCompletionWidget({Key? key}) : super(key: key);

  @override
  State<TrainingCompletionWidget> createState() =>
      _TrainingCompletionWidgetState();
}

class _TrainingCompletionWidgetState extends State<TrainingCompletionWidget> {
  bool _isSaving = false;
  bool _hasAskedForChanges = false;
  bool _saveCompleted = false;

  @override
  void initState() {
    super.initState();

    // Verzögerung, damit die UI zuerst rendern kann
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveTrainingAndCheckForChanges();
    });
  }

  // Separate das Speichern und Überprüfen auf Änderungen
  Future<void> _saveTrainingAndCheckForChanges() async {
    if (!mounted) return;

    final sessionProvider =
        Provider.of<TrainingSessionProvider>(context, listen: false);

    // Zuerst das Training speichern
    await sessionProvider.completeTraining();

    if (mounted) {
      setState(() {
        _saveCompleted = true;
      });

      // Dann prüfen, ob es Änderungen am Trainingsplan gab
      if (sessionProvider.hasModifiedExercises && !_hasAskedForChanges) {
        _showSaveChangesDialog(sessionProvider);
        setState(() {
          _hasAskedForChanges = true;
        });
      }
    }
  }

  // Dialog zum Speichern der Änderungen
  void _showSaveChangesDialog(TrainingSessionProvider sessionProvider) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Dialog kann nicht durch Klicken außerhalb geschlossen werden
      builder: (context) => AlertDialog(
        title: const Text('Änderungen speichern?'),
        content: const Text(
            'Du hast Änderungen an Übungen vorgenommen (Satzanzahl, Steigerung, Pause). '
            'Möchtest du diese Änderungen in deinem Trainingsplan speichern?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Verwerfen'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveChangesToTrainingPlan(sessionProvider);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  // Speichert die Änderungen im Trainingsplan
  Future<void> _saveChangesToTrainingPlan(
      TrainingSessionProvider sessionProvider) async {
    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final success = await sessionProvider.saveModificationsToTrainingPlan();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Änderungen wurden im Trainingsplan gespeichert'
                : 'Fehler beim Speichern der Änderungen'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        setState(() {
          _isSaving = false;
        });
      }
    } catch (e) {
      print('Fehler beim Speichern der Änderungen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ein Fehler ist aufgetreten'),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          _isSaving = false;
        });
      }
    }
  }

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

    // Wenn das Speichern noch nicht abgeschlossen ist
    if (!_saveCompleted) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Training wird gespeichert...'),
            ],
          ),
        ),
      );
    }

    // Wenn gerade Änderungen gespeichert werden
    if (_isSaving) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Änderungen werden gespeichert...'),
            ],
          ),
        ),
      );
    }

    // Statistiken berechnen
    final totalExercises = trainingDay.exercises.length;
    int totalSets = 0;
    for (final exercise in trainingDay.exercises) {
      totalSets += exercise.numberOfSets;
    }

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

                // NEU: Button zum Speichern der Änderungen, falls es Änderungen gibt und noch nicht gefragt wurde
                if (sessionProvider.hasModifiedExercises &&
                    !_hasAskedForChanges) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showSaveChangesDialog(sessionProvider);
                        setState(() {
                          _hasAskedForChanges = true;
                        });
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Änderungen an Übungen speichern'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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
