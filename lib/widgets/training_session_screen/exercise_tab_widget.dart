// lib/widgets/training_session_screen/exercise_tab_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/training_session_screen/training_session_provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../models/training_plan_screen/exercise_model.dart';
import '../../models/progression_manager_screen/training_set_model.dart';
import 'exercise_set_widget.dart';

class ExerciseTabWidget extends StatefulWidget {
  final int exerciseIndex;

  const ExerciseTabWidget({
    Key? key,
    required this.exerciseIndex,
  }) : super(key: key);

  @override
  State<ExerciseTabWidget> createState() => _ExerciseTabWidgetState();
}

class _ExerciseTabWidgetState extends State<ExerciseTabWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive =>
      true; // Behält den Tab-Status bei, wenn er nicht sichtbar ist

  // Speichert das Profil für die aktuelle Übung
  String? _exerciseProfileId;

  @override
  void initState() {
    super.initState();

    // Initialisiere den Progression Manager für diese Übung
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProgressionManager();
    });
  }

  void _initializeProgressionManager() {
    final sessionProvider =
        Provider.of<TrainingSessionProvider>(context, listen: false);
    final progressionProvider =
        Provider.of<ProgressionManagerProvider>(context, listen: false);

    // Aktuelle Übung abrufen
    final exercise = sessionProvider.exercises[widget.exerciseIndex];

    // Speichere die ProfilID für diese Übung
    if (exercise.progressionProfileId != null &&
        exercise.progressionProfileId!.isNotEmpty) {
      setState(() {
        _exerciseProfileId = exercise.progressionProfileId;
      });

      // Bei Initialisierung die Progression für den aktiven Satz berechnen
      if (widget.exerciseIndex == sessionProvider.currentExerciseIndex) {
        final activeSetId = sessionProvider.getActiveSetIdForCurrentExercise();

        // Einmalig berechnen, wenn ein Profil gesetzt ist
        if (_exerciseProfileId != null) {
          sessionProvider.calculateProgressionForSet(widget.exerciseIndex,
              activeSetId, _exerciseProfileId!, progressionProvider);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Erforderlich für AutomaticKeepAliveClientMixin

    final sessionProvider = Provider.of<TrainingSessionProvider>(context);
    final progressionProvider =
        Provider.of<ProgressionManagerProvider>(context, listen: false);

    // Prüfe, ob dieser Tab aktiv ist
    final bool isActiveExercise =
        widget.exerciseIndex == sessionProvider.currentExerciseIndex;

    // Die aktuelle Übung aus dem Provider abrufen
    final exercise = sessionProvider.exercises[widget.exerciseIndex];
    final bool isExerciseCompleted =
        sessionProvider.isCurrentExerciseCompleted && isActiveExercise;

    // Wenn sich der aktive Satz ändert und ein Profil existiert, berechne die Empfehlung
    if (isActiveExercise && _exerciseProfileId != null) {
      final activeSetId = sessionProvider.getActiveSetIdForCurrentExercise();
      // Wir verzögern den Aufruf, damit er nach dem Rendering ausgeführt wird
      Future.microtask(() {
        sessionProvider.calculateProgressionForSet(widget.exerciseIndex,
            activeSetId, _exerciseProfileId!, progressionProvider);
      });
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Übungs-Header mit Informationen zur Übung
          _buildExerciseHeader(exercise),
          const SizedBox(height: 16),

          // Information-Banner, wenn die Übung abgeschlossen ist
          if (isExerciseCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Übung abgeschlossen! Weiter zur nächsten Übung...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),

          if (isExerciseCompleted) const SizedBox(height: 16),

          // Satz-Liste
          if (!isExerciseCompleted)
            Expanded(
              child: _buildSetsList(
                  sessionProvider, progressionProvider, isActiveExercise),
            ),

          // Action-Buttons nur anzeigen, wenn dieser Tab aktiv ist
          if (isActiveExercise && !isExerciseCompleted) ...[
            const SizedBox(height: 16),
            _buildActionButtons(sessionProvider, progressionProvider),
          ],
        ],
      ),
    );
  }

  // Header mit Übungsinformationen
  Widget _buildExerciseHeader(ExerciseModel exercise) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Übungsname
            Text(
              exercise.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Muskelgruppen
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    exercise.primaryMuscleGroup,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
                if (exercise.secondaryMuscleGroup.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      exercise.secondaryMuscleGroup,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[800],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Weitere Übungsdetails
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem(
                  Icons.fitness_center,
                  'Steigerung',
                  '${exercise.standardIncrease} kg',
                ),
                _buildDetailItem(
                  Icons.timer,
                  'Satzpause',
                  '${exercise.restPeriodSeconds} sek',
                ),
                _buildDetailItem(
                  Icons.repeat,
                  'Sätze',
                  '${exercise.numberOfSets}',
                ),
              ],
            ),

            // Anzeige des aktiven Profils, wenn vorhanden
            if (_exerciseProfileId != null) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.trending_up, size: 16, color: Colors.purple[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Progressionsprofil: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  Consumer<ProgressionManagerProvider>(
                    builder: (context, provider, _) {
                      final profil = provider.progressionsProfile.firstWhere(
                        (p) => p.id == _exerciseProfileId,
                        orElse: () => provider.progressionsProfile.first,
                      );
                      return Text(
                        profil.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[800],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Hilfsmethode für die Detailansicht
  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Satz-Liste mit allen Sätzen der Übung
  Widget _buildSetsList(TrainingSessionProvider sessionProvider,
      ProgressionManagerProvider progressionProvider, bool isActiveExercise) {
    final sets = sessionProvider.currentExerciseSets;
    final activeSetId = sessionProvider.getActiveSetIdForCurrentExercise();

    return ListView.builder(
      itemCount: sets.length,
      itemBuilder: (context, index) {
        final set = sets[index];
        final isActiveSet = isActiveExercise && set.id == activeSetId;

        // GEÄNDERT: Prüfe, ob die Empfehlung angezeigt werden soll
        final showRecommendation = isActiveSet &&
            _exerciseProfileId != null &&
            sessionProvider.shouldShowRecommendation(
                widget.exerciseIndex, set.id);

        return ExerciseSetWidget(
          set: set,
          isActive: isActiveSet,
          isCompleted: set.abgeschlossen,
          onValueChanged: (field, value) {
            sessionProvider.updateSet(set.id, field, value);
          },
          // GEÄNDERT: Empfehlungswerte direkt aus dem Set verwenden
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

  // Action-Buttons für die aktuelle Übung
  Widget _buildActionButtons(TrainingSessionProvider sessionProvider,
      ProgressionManagerProvider progressionProvider) {
    final activeSetId = sessionProvider.getActiveSetIdForCurrentExercise();
    final activeSet = sessionProvider.currentExerciseSets.firstWhere(
      (s) => s.id == activeSetId,
      orElse: () => sessionProvider.currentExerciseSets.first,
    );

    // Prüfe, ob die Empfehlung angezeigt werden soll
    final showRecommendation = _exerciseProfileId != null &&
        sessionProvider.shouldShowRecommendation(
            widget.exerciseIndex, activeSetId);

    // Empfehlungsdaten direkt aus dem Set verwenden
    final recommendation = showRecommendation && activeSet.empfehlungBerechnet
        ? {
            'kg': activeSet.empfKg,
            'wiederholungen': activeSet.empfWiederholungen,
            'rir': activeSet.empfRir,
          }
        : null;

    return Row(
      children: [
        // Empfehlung übernehmen Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: recommendation != null
                ? () {
                    sessionProvider.applyProgressionRecommendation(
                      activeSetId,
                      recommendation['kg']
                          as double?, // Typumwandlung hinzugefügt
                      recommendation['wiederholungen']
                          as int?, // Typumwandlung hinzugefügt
                      recommendation['rir']
                          as int?, // Typumwandlung hinzugefügt
                    );
                  }
                : null,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Empfehlung übernehmen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Satz abschließen Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              sessionProvider.completeCurrentSet();
            },
            icon: const Icon(Icons.check),
            label: const Text('Satz abschließen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
