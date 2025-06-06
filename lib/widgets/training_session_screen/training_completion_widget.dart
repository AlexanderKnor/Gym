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

class _TrainingCompletionWidgetState extends State<TrainingCompletionWidget>
    with SingleTickerProviderStateMixin {
  // Clean color system matching training screen
  static const Color _midnight = Color(0xFF000000);
  static const Color _charcoal = Color(0xFF1C1C1E);
  static const Color _graphite = Color(0xFF2C2C2E);
  static const Color _steel = Color(0xFF48484A);
  static const Color _mercury = Color(0xFF8E8E93);
  static const Color _silver = Color(0xFFAEAEB2);
  static const Color _snow = Color(0xFFFFFFFF);
  static const Color _emberCore = Color(0xFFFF4500);

  bool _isSaving = false;
  bool _hasAskedForChanges = false;
  bool _hasAskedForAddedExercises = false; // NEU: Für hinzugefügte Übungen
  bool _hasAskedForDeletedExercises = false; // NEU: Für gelöschte Übungen
  bool _saveCompleted = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Configure animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    // Start animations after short delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _animationController.forward();
      }
    });

    // Initialize training completion process
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveTrainingAndCheckForChanges();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveTrainingAndCheckForChanges() async {
    if (!mounted) return;

    final sessionProvider =
        Provider.of<TrainingSessionProvider>(context, listen: false);

    // First save the training
    await sessionProvider.completeTraining();

    if (mounted) {
      setState(() {
        _saveCompleted = true;
      });

      // NEU: Prüfe zuerst, ob neue Übungen hinzugefügt wurden
      if (sessionProvider.hasAddedExercises && !_hasAskedForAddedExercises) {
        _showSaveAddedExercisesDialog(sessionProvider);
        setState(() {
          _hasAskedForAddedExercises = true;
        });
        return; // Weitere Dialoge erst nach diesem Dialog anzeigen
      }

      // NEU: Prüfe dann, ob Übungen gelöscht wurden
      if (sessionProvider.hasDeletedExercises &&
          !_hasAskedForDeletedExercises) {
        _showSaveDeletedExercisesDialog(sessionProvider);
        setState(() {
          _hasAskedForDeletedExercises = true;
        });
        return; // Weitere Dialoge erst nach diesem Dialog anzeigen
      }

      // Check if there were modifications to the training plan
      if (sessionProvider.hasModifiedExercises && !_hasAskedForChanges) {
        _showSaveChangesDialog(sessionProvider);
        setState(() {
          _hasAskedForChanges = true;
        });
      }
    }
  }

  void _showSaveChangesDialog(TrainingSessionProvider sessionProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.save_outlined, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('Änderungen speichern?'),
          ],
        ),
        content: const Text(
            'Du hast Änderungen an Übungen vorgenommen (Satzanzahl, Steigerung, Pause). '
            'Möchtest du diese Änderungen in deinem Trainingsplan speichern?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  // NEU: Dialog zur Speicherung hinzugefügter Übungen anzeigen
  void _showSaveAddedExercisesDialog(TrainingSessionProvider sessionProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add_circle_outline, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Text('Neue Übungen speichern?'),
          ],
        ),
        content: const Text(
            'Du hast während des Trainings neue Übungen hinzugefügt. '
            'Möchtest du diese Übungen dauerhaft in deinem Trainingsplan speichern?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              // Nach dem Schließen des Dialogs prüfen, ob es Änderungen gab
              _continueWithNextDialogs(sessionProvider);
            },
            child: const Text('Verwerfen'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveAddedExercisesToTrainingPlan(sessionProvider);

              // Nach dem Speichern prüfen, ob es weitere Dialoge gibt
              _continueWithNextDialogs(sessionProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  // NEU: Dialog zum Speichern gelöschter Übungen
  void _showSaveDeletedExercisesDialog(
      TrainingSessionProvider sessionProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Gelöschte Übungen speichern?'),
          ],
        ),
        content: const Text('Du hast während des Trainings Übungen gelöscht. '
            'Möchtest du diese Änderungen dauerhaft in deinem Trainingsplan speichern?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              // Nach dem Schließen des Dialogs prüfen, ob es Änderungen gab
              _continueWithNextDialogs(sessionProvider);
            },
            child: const Text('Verwerfen'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveDeletedExercisesToTrainingPlan(sessionProvider);

              // Nach dem Speichern prüfen, ob es weitere Dialoge gibt
              _continueWithNextDialogs(sessionProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  // NEU: Hilfsmethode, um mit den nächsten Dialogen fortzufahren
  void _continueWithNextDialogs(TrainingSessionProvider sessionProvider) {
    if (mounted) {
      // Prüfen, ob gelöschte Übungen vorhanden sind
      if (sessionProvider.hasDeletedExercises &&
          !_hasAskedForDeletedExercises) {
        _showSaveDeletedExercisesDialog(sessionProvider);
        setState(() {
          _hasAskedForDeletedExercises = true;
        });
      }
      // Prüfen, ob Änderungen vorhanden sind
      else if (sessionProvider.hasModifiedExercises && !_hasAskedForChanges) {
        _showSaveChangesDialog(sessionProvider);
        setState(() {
          _hasAskedForChanges = true;
        });
      }
    }
  }

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
            backgroundColor: success ? Colors.green[600] : Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
          SnackBar(
            content: const Text('Ein Fehler ist aufgetreten'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // NEU: Methode zum Speichern hinzugefügter Übungen
  Future<void> _saveAddedExercisesToTrainingPlan(
      TrainingSessionProvider sessionProvider) async {
    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final success = await sessionProvider.saveAddedExercisesToTrainingPlan();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Neue Übungen wurden im Trainingsplan gespeichert'
                : 'Fehler beim Speichern der neuen Übungen'),
            backgroundColor: success ? Colors.green[600] : Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        setState(() {
          _isSaving = false;
        });
      }
    } catch (e) {
      print('Fehler beim Speichern der hinzugefügten Übungen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ein Fehler ist aufgetreten'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // NEU: Methode zum Speichern gelöschter Übungen
  Future<void> _saveDeletedExercisesToTrainingPlan(
      TrainingSessionProvider sessionProvider) async {
    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final success =
          await sessionProvider.saveDeletedExercisesToTrainingPlan();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Gelöschte Übungen wurden im Trainingsplan gespeichert'
                : 'Fehler beim Speichern der gelöschten Übungen'),
            backgroundColor: success ? Colors.green[600] : Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        setState(() {
          _isSaving = false;
        });
      }
    } catch (e) {
      print('Fehler beim Speichern der gelöschten Übungen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ein Fehler ist aufgetreten'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
      return Scaffold(
        appBar: AppBar(
          title: const Text('Training'),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If still saving
    if (!_saveCompleted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Training wird gespeichert'),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Training wird gespeichert...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // If saving modifications
    if (_isSaving) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Änderungen werden gespeichert'),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Änderungen werden gespeichert...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate stats
    final totalExercises = trainingDay.exercises.length;
    int totalSets = 0;
    for (final exercise in trainingDay.exercises) {
      totalSets += exercise.numberOfSets;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training abgeschlossen'),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Success animation
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 80,
                      color: Colors.green[600],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Title and subtitle
                const Text(
                  'Herzlichen Glückwunsch!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Du hast dein Training erfolgreich abgeschlossen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 32),

                // Training summary card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.fitness_center,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Trainingsübersicht',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 32),

                        // Plan and Day info
                        _buildInfoRow(
                          context,
                          Icons.assignment_outlined,
                          'Trainingsplan:',
                          trainingPlan.name,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          Icons.event_outlined,
                          'Trainingstag:',
                          trainingDay.name,
                        ),

                        const SizedBox(height: 24),

                        // Statistics cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                Icons.fitness_center,
                                'Übungen',
                                totalExercises.toString(),
                                Colors.indigo,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                Icons.replay,
                                'Sätze',
                                totalSets.toString(),
                                Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Motivation card
                Card(
                  elevation: 2,
                  color: Colors.amber[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Großartige Arbeit! Regelmäßiges Training ist der Schlüssel zum Erfolg.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.amber[900],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // NEU: Button zum Speichern hinzugefügter Übungen, wenn benötigt
                if (sessionProvider.hasAddedExercises &&
                    !_hasAskedForAddedExercises)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showSaveAddedExercisesDialog(sessionProvider);
                        setState(() {
                          _hasAskedForAddedExercises = true;
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text(
                        'Neue Übungen im Trainingsplan speichern',
                        style: TextStyle(fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),

                // Save changes button if needed
                if (sessionProvider.hasModifiedExercises &&
                    !_hasAskedForChanges)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showSaveChangesDialog(sessionProvider);
                        setState(() {
                          _hasAskedForChanges = true;
                        });
                      },
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'Änderungen im Trainingsplan speichern',
                        style: TextStyle(fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),

                // Return to home button
                ElevatedButton.icon(
                  onPressed: () => _returnToHomeScreen(context),
                  icon: const Icon(Icons.home),
                  label: const Text(
                    'Zum Startbildschirm',
                    style: TextStyle(fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    MaterialColor color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(icon, color: color[700], size: 20),
          ),
          const SizedBox(width: 12),
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
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _returnToHomeScreen(BuildContext context) {
    // Update navigation index and return to main screen
    final navigationProvider =
        Provider.of<NavigationProvider>(context, listen: false);
    navigationProvider.setCurrentIndex(0);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false,
    );
  }
}
