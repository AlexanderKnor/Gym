// lib/widgets/training_session_screen/exercise_tab_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/training_session_screen/training_session_provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../models/training_plan_screen/exercise_model.dart';
import '../../models/progression_manager_screen/training_set_model.dart';
import '../../models/progression_manager_screen/progression_profile_model.dart';
import 'exercise_set_widget.dart';
import '../../screens/strength_calculator_screen/strength_calculator_screen.dart';

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
    if (widget.exerciseIndex < sessionProvider.exercises.length) {
      final exercise = sessionProvider.exercises[widget.exerciseIndex];

      // Speichere die ProfilID für diese Übung
      if (exercise.progressionProfileId != null &&
          exercise.progressionProfileId!.isNotEmpty) {
        setState(() {
          _exerciseProfileId = exercise.progressionProfileId;
        });

        // Bei Initialisierung die Progression für den aktiven Satz berechnen
        if (widget.exerciseIndex == sessionProvider.currentExerciseIndex) {
          final activeSetId =
              sessionProvider.getActiveSetIdForCurrentExercise();

          // Einmalig berechnen, wenn ein Profil gesetzt ist
          if (_exerciseProfileId != null) {
            sessionProvider.calculateProgressionForSet(widget.exerciseIndex,
                activeSetId, _exerciseProfileId!, progressionProvider);
          }
        }
      }
    }
  }

  // Methode zum Ändern des Progressionsprofils
  void _changeProgressionProfile(String newProfileId) {
    if (_exerciseProfileId == newProfileId) return;

    final sessionProvider =
        Provider.of<TrainingSessionProvider>(context, listen: false);
    final progressionProvider =
        Provider.of<ProgressionManagerProvider>(context, listen: false);

    // Profil im Provider aktualisieren
    sessionProvider.updateExerciseProgressionProfile(
        widget.exerciseIndex, newProfileId);

    // Lokalen State aktualisieren
    setState(() {
      _exerciseProfileId = newProfileId;
    });

    // Wenn diese Übung aktiv ist, die Empfehlung neu berechnen
    if (widget.exerciseIndex == sessionProvider.currentExerciseIndex) {
      final activeSetId = sessionProvider.getActiveSetIdForCurrentExercise();
      sessionProvider.calculateProgressionForSet(
          widget.exerciseIndex, activeSetId, newProfileId, progressionProvider);
    }
  }

  // Öffnet den Kraftrechner und wendet die berechneten Werte auf den aktuellen Satz an
  void _openStrengthCalculator(BuildContext context) {
    final sessionProvider =
        Provider.of<TrainingSessionProvider>(context, listen: false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StrengthCalculatorScreen(
          onApplyValues: (calculatedWeight, targetReps, targetRIR) {
            // Hole die aktive Satz-ID
            final activeSetId =
                sessionProvider.getActiveSetIdForCurrentExercise();

            // Wende die berechneten Werte auf den aktuellen Satz an
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Erforderlich für AutomaticKeepAliveClientMixin

    final sessionProvider = Provider.of<TrainingSessionProvider>(context);
    final progressionProvider =
        Provider.of<ProgressionManagerProvider>(context);

    // Prüfe, ob dieser Tab aktiv ist
    final bool isActiveExercise =
        widget.exerciseIndex == sessionProvider.currentExerciseIndex;

    // Die aktuelle Übung aus dem Provider abrufen
    if (widget.exerciseIndex >= sessionProvider.exercises.length) {
      return const Center(
        child: Text('Übung nicht gefunden'),
      );
    }

    final exercise = sessionProvider.exercises[widget.exerciseIndex];
    final bool isExerciseCompleted =
        sessionProvider.isCurrentExerciseCompleted && isActiveExercise;

    // Prüfen, ob alle Sätze abgeschlossen sind, um "Übung abschließen" Button anzuzeigen
    final bool allSetsCompleted = isActiveExercise &&
        sessionProvider.areAllSetsCompletedForCurrentExercise();

    // Prüfen, ob weitere Übungen vorhanden sind
    final bool hasMoreExercises =
        sessionProvider.hasMoreExercisesAfterCurrent();

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
          _buildExerciseHeader(exercise, progressionProvider),
          const SizedBox(height: 16),

          // Satz-Liste - Immer anzeigen, unabhängig vom Übungsstatus
          Expanded(
            child: _buildSetsList(
                sessionProvider, progressionProvider, isActiveExercise),
          ),

          // Action-Buttons anzeigen
          const SizedBox(height: 16),

          // Wenn alle Sätze abgeschlossen sind, zeige den "Übung abschließen" Button
          if (allSetsCompleted) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  sessionProvider.completeCurrentExercise();
                },
                icon: const Icon(Icons.done_all),
                label: Text(hasMoreExercises
                    ? 'Übung abschließen und zur nächsten Übung'
                    : 'Training abschließen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Button zum Reaktivieren des letzten Satzes, wenn mind. ein Satz abgeschlossen ist
          if (isActiveExercise &&
              _hasCompletedSets(sessionProvider.currentExerciseSets)) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  sessionProvider
                      .reactivateLastCompletedSet(widget.exerciseIndex);
                },
                icon: const Icon(Icons.replay),
                label: const Text('Letzten Satz reaktivieren'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Normale Action-Buttons für aktuelle Sätze
          _buildActionButtons(sessionProvider, progressionProvider),
        ],
      ),
    );
  }

  // Prüft, ob es abgeschlossene Sätze für die aktuelle Übung gibt
  bool _hasCompletedSets(List<TrainingSetModel> sets) {
    for (final set in sets) {
      if (set.abgeschlossen) {
        return true;
      }
    }
    return false;
  }

  // Header mit Übungsinformationen
  Widget _buildExerciseHeader(
      ExerciseModel exercise, ProgressionManagerProvider progressionProvider) {
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

            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // Dropdown zur Auswahl des Progressionsprofils
            Row(
              children: [
                Icon(Icons.trending_up, size: 16, color: Colors.purple[700]),
                const SizedBox(width: 8),
                const Text(
                  'Progressionsprofil:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildProfileDropdown(progressionProvider),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Dropdown zur Auswahl des Progressionsprofils
  Widget _buildProfileDropdown(ProgressionManagerProvider progressionProvider) {
    final profiles = progressionProvider.progressionsProfile;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.purple[300]!),
        color: Colors.purple[50],
      ),
      child: DropdownButton<String>(
        value: _exerciseProfileId,
        isExpanded: true,
        underline:
            const SizedBox(), // Entfernt die standardmäßige Unterstreichung
        hint: const Text('Profil wählen'),
        icon: Icon(Icons.arrow_drop_down, color: Colors.purple[700]),
        style: TextStyle(
          color: Colors.purple[800],
          fontWeight: FontWeight.bold,
        ),
        items: profiles.map((profile) {
          return DropdownMenuItem<String>(
            value: profile.id,
            child: Text(
              profile.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _exerciseProfileId == profile.id
                    ? Colors.purple[800]
                    : Colors.black87,
                fontWeight: _exerciseProfileId == profile.id
                    ? FontWeight.bold
                    : FontWeight.normal,
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

    // Prüfe, ob alle Sätze abgeschlossen sind
    final allSetsCompleted =
        sessionProvider.areAllSetsCompletedForCurrentExercise();

    return ListView.builder(
      itemCount: sets.length,
      itemBuilder: (context, index) {
        final set = sets[index];

        // Ein Satz kann nur aktiv sein, wenn nicht alle Sätze abgeschlossen sind
        final isActiveSet =
            isActiveExercise && set.id == activeSetId && !allSetsCompleted;

        // Prüfe, ob die Empfehlung angezeigt werden soll
        final showRecommendation = isActiveSet &&
            _exerciseProfileId != null &&
            sessionProvider.shouldShowRecommendation(
                widget.exerciseIndex, set.id);

        return ExerciseSetWidget(
          set: set,
          isActive: isActiveSet,
          isCompleted: set.abgeschlossen,
          onValueChanged: (field, value) {
            // Nur Werte aktualisieren, wenn der Satz aktiv und nicht alle Sätze abgeschlossen sind
            if (isActiveSet && !allSetsCompleted) {
              sessionProvider.updateSet(set.id, field, value);
            }
          },
          // Empfehlungswerte direkt aus dem Set verwenden
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

    return Column(
      children: [
        // Kraftrechner-Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _openStrengthCalculator(context),
            icon: const Icon(Icons.calculate),
            label: const Text('Kraftrechner öffnen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Bestehende Buttons in einer Reihe
        Row(
          children: [
            // Empfehlung übernehmen Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: recommendation != null
                    ? () {
                        sessionProvider.applyProgressionRecommendation(
                          activeSetId,
                          recommendation['kg'] as double?,
                          recommendation['wiederholungen'] as int?,
                          recommendation['rir'] as int?,
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
        ),
      ],
    );
  }
}
