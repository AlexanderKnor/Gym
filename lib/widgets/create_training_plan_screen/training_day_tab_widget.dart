// lib/widgets/create_training_plan_screen/training_day_tab_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../models/training_plan_screen/exercise_model.dart';
import '../../widgets/create_training_plan_screen/exercise_form_widget.dart';
import '../../widgets/create_training_plan_screen/microcycle_exercise_form_widget.dart';

class TrainingDayTabWidget extends StatelessWidget {
  final int dayIndex;

  const TrainingDayTabWidget({
    Key? key,
    required this.dayIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final createProvider = Provider.of<CreateTrainingPlanProvider>(context);
    final progressionProvider =
        Provider.of<ProgressionManagerProvider>(context);
    final plan = createProvider.draftPlan;
    final isPeriodized = plan?.isPeriodized ?? false;
    final activeWeekIndex = createProvider.activeWeekIndex;

    if (plan == null || dayIndex >= plan.days.length) {
      return const Center(
        child: Text("Ungültiger Tag oder kein Plan verfügbar"),
      );
    }

    final day = plan.days[dayIndex];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Tagname
          Text(
            day.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // NEU: Wochenauswahl für periodisierte Pläne
          if (isPeriodized) ...[
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.purple[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Mikrozyklus ${activeWeekIndex + 1} von ${plan.numberOfWeeks}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Wähle die Woche, deren Konfiguration du bearbeiten möchtest:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: plan.numberOfWeeks,
                        itemBuilder: (context, weekIndex) {
                          final isActive = weekIndex == activeWeekIndex;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ElevatedButton(
                              onPressed: () =>
                                  createProvider.setActiveWeekIndex(weekIndex),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isActive
                                    ? Colors.purple[600]
                                    : Colors.grey[200],
                                foregroundColor:
                                    isActive ? Colors.white : Colors.grey[800],
                                elevation: isActive ? 2 : 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text('Woche ${weekIndex + 1}'),
                            ),
                          );
                        },
                      ),
                    ),
                    if (activeWeekIndex > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _showCopyWeekDialog(
                                    context, createProvider, activeWeekIndex);
                              },
                              icon: const Icon(Icons.copy),
                              label: const Text('Woche kopieren...'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.purple[700],
                                side: BorderSide(color: Colors.purple[200]!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Liste der Übungen
          Expanded(
            child: day.exercises.isEmpty
                ? _buildEmptyState(context)
                : _buildExerciseList(context, day.exercises, createProvider,
                    progressionProvider, isPeriodized, activeWeekIndex),
          ),

          // Übung hinzufügen Button
          ElevatedButton.icon(
            onPressed: () => _showAddExerciseDialog(
                context, isPeriodized, createProvider, progressionProvider),
            icon: const Icon(Icons.add),
            label: const Text('Übung hinzufügen'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog zum Kopieren einer Woche anzeigen
  void _showCopyWeekDialog(BuildContext context,
      CreateTrainingPlanProvider provider, int currentWeekIndex) {
    final availableWeeks = List<int>.generate(provider.numberOfWeeks, (i) => i)
      ..remove(currentWeekIndex);

    if (availableWeeks.isEmpty) return;

    int? selectedSourceWeek;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Woche kopieren'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Wähle die Quell-Woche, deren Konfiguration du in die aktuelle Woche kopieren möchtest:'),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedSourceWeek,
                hint: const Text('Quell-Woche auswählen'),
                items: availableWeeks
                    .map((weekIndex) => DropdownMenuItem<int>(
                          value: weekIndex,
                          child: Text('Woche ${weekIndex + 1}'),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSourceWeek = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: selectedSourceWeek == null
                  ? null
                  : () {
                      // Kopiere die Einstellungen
                      provider.copyMicrocycleSettings(
                          selectedSourceWeek!, currentWeekIndex);
                      Navigator.pop(context);

                      // Erfolgs-Snackbar anzeigen
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Einstellungen aus Woche ${selectedSourceWeek! + 1} wurden kopiert'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
              child: const Text('Kopieren'),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Übungen vorhanden',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Füge deine erste Übung hinzu',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddExerciseDialog(
              context,
              Provider.of<CreateTrainingPlanProvider>(context, listen: false)
                  .isPeriodized,
              Provider.of<CreateTrainingPlanProvider>(context, listen: false),
              Provider.of<ProgressionManagerProvider>(context, listen: false),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Übung hinzufügen'),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(
    BuildContext context,
    List<ExerciseModel> exercises,
    CreateTrainingPlanProvider createProvider,
    ProgressionManagerProvider progressionProvider,
    bool isPeriodized,
    int activeWeekIndex,
  ) {
    return ListView.builder(
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        // Wenn periodisiert, dann zeige die Übung mit den Werten für die aktuelle Woche
        final ExerciseModel exercise = isPeriodized
            ? createProvider.getExerciseForCurrentWeek(index)
            : exercises[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              ListTile(
                title: Text(exercise.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${exercise.primaryMuscleGroup}${exercise.secondaryMuscleGroup.isNotEmpty ? ' / ${exercise.secondaryMuscleGroup}' : ''}',
                    ),
                    // Anzeigen von Sätzen, Wiederholungsbereich und RIR-Bereich
                    Text(
                      '${exercise.numberOfSets} ${exercise.numberOfSets == 1 ? "Satz" : "Sätze"} • ${exercise.repRangeMin}-${exercise.repRangeMax} Wdh • ${exercise.rirRangeMin}-${exercise.rirRangeMax} RIR • ${exercise.restPeriodSeconds}s Pause',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditExerciseDialog(
                        context,
                        index,
                        exercise,
                        isPeriodized,
                        activeWeekIndex,
                        createProvider,
                        progressionProvider,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _confirmDeleteExercise(
                          context, index, createProvider),
                      color: Colors.red,
                    ),
                  ],
                ),
              ),

              // Zeige Progressionsprofil-Info an, wenn gesetzt
              if (exercise.progressionProfileId != null &&
                  progressionProvider.progressionsProfile
                      .any((p) => p.id == exercise.progressionProfileId)) ...[
                Divider(color: Colors.grey[200]),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up,
                          color: Colors.purple[700], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Progressionsprofil: ',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              TextSpan(
                                text: progressionProvider.progressionsProfile
                                    .firstWhere((p) =>
                                        p.id == exercise.progressionProfileId)
                                    .name,
                              ),
                              if (isPeriodized)
                                TextSpan(
                                  text: ' (Woche ${activeWeekIndex + 1})',
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.purple[700]),
                                ),
                            ],
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showAddExerciseDialog(
    BuildContext context,
    bool isPeriodized,
    CreateTrainingPlanProvider createProvider,
    ProgressionManagerProvider progressionProvider,
  ) {
    if (isPeriodized) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: MicrocycleExerciseFormWidget(
            weekIndex: createProvider.activeWeekIndex,
            weekCount: createProvider.numberOfWeeks,
            onSave: (exercise) {
              createProvider.addExercise(exercise);
              Navigator.pop(context);
            },
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: ExerciseFormWidget(
            onSave: (exercise) {
              createProvider.addExercise(exercise);
              Navigator.pop(context);
            },
          ),
        ),
      );
    }
  }

  void _showEditExerciseDialog(
    BuildContext context,
    int index,
    ExerciseModel exercise,
    bool isPeriodized,
    int activeWeekIndex,
    CreateTrainingPlanProvider createProvider,
    ProgressionManagerProvider progressionProvider,
  ) {
    if (isPeriodized) {
      // Bei periodisierten Plänen zeigen wir das Formular für Mikrozyklen an
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: MicrocycleExerciseFormWidget(
            initialExercise: exercise,
            weekIndex: activeWeekIndex,
            weekCount: createProvider.numberOfWeeks,
            onSave: (updatedExercise) {
              // Alle Werte für die aktuelle Woche aktualisieren
              createProvider.updateMicrocycle(
                index,
                activeWeekIndex,
                updatedExercise.numberOfSets,
                updatedExercise.repRangeMin,
                updatedExercise.repRangeMax,
                updatedExercise.rirRangeMin,
                updatedExercise.rirRangeMax,
                updatedExercise.progressionProfileId,
              );
              Navigator.pop(context);
            },
          ),
        ),
      );
    } else {
      // Bei normalen Plänen zeigen wir das normale Formular an
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: ExerciseFormWidget(
            initialExercise: exercise,
            onSave: (updatedExercise) {
              createProvider.updateExercise(index, updatedExercise);
              Navigator.pop(context);
            },
          ),
        ),
      );
    }
  }

  void _confirmDeleteExercise(BuildContext context, int index,
      CreateTrainingPlanProvider createProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Übung löschen'),
        content: const Text('Möchtest du diese Übung wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              createProvider.removeExercise(index);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
