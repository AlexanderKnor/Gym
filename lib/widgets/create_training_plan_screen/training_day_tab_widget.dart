// lib/widgets/create_training_plan_screen/training_day_tab_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';
import '../../models/training_plan_screen/exercise_model.dart';
import '../../widgets/create_training_plan_screen/exercise_form_widget.dart';

class TrainingDayTabWidget extends StatelessWidget {
  final int dayIndex;

  const TrainingDayTabWidget({
    Key? key,
    required this.dayIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final createProvider = Provider.of<CreateTrainingPlanProvider>(context);
    final plan = createProvider.draftPlan;

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

          // Liste der Übungen
          Expanded(
            child: day.exercises.isEmpty
                ? _buildEmptyState(context)
                : _buildExerciseList(context, day.exercises),
          ),

          // Übung hinzufügen Button
          ElevatedButton.icon(
            onPressed: () => _showAddExerciseDialog(context),
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
            onPressed: () => _showAddExerciseDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Übung hinzufügen'),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(
      BuildContext context, List<ExerciseModel> exercises) {
    return ListView.builder(
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(exercise.name),
            subtitle: Text(
                '${exercise.primaryMuscleGroup} / ${exercise.secondaryMuscleGroup}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      _showEditExerciseDialog(context, index, exercise),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDeleteExercise(context, index),
                  color: Colors.red,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddExerciseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ExerciseFormWidget(
          onSave: (exercise) {
            Provider.of<CreateTrainingPlanProvider>(context, listen: false)
                .addExercise(exercise);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showEditExerciseDialog(
      BuildContext context, int index, ExerciseModel exercise) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ExerciseFormWidget(
          initialExercise: exercise,
          onSave: (updatedExercise) {
            Provider.of<CreateTrainingPlanProvider>(context, listen: false)
                .updateExercise(index, updatedExercise);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _confirmDeleteExercise(BuildContext context, int index) {
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
              Provider.of<CreateTrainingPlanProvider>(context, listen: false)
                  .removeExercise(index);
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
