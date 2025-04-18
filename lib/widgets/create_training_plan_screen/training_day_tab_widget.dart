// lib/widgets/create_training_plan_screen/training_day_tab_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';
import '../../models/training_plan_screen/exercise_model.dart';
import 'exercise_form_widget.dart';

class TrainingDayTabWidget extends StatelessWidget {
  final int dayIndex;

  const TrainingDayTabWidget({
    Key? key,
    required this.dayIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CreateTrainingPlanProvider>(context);
    final day = provider.draftPlan!.days[dayIndex];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            day.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${day.exercises.length} ${day.exercises.length == 1 ? "Übung" : "Übungen"}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Übungsliste
          Expanded(
            child: day.exercises.isEmpty
                ? _buildEmptyState(context)
                : _buildExercisesList(context, day.exercises),
          ),

          // Übung hinzufügen Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _showAddExerciseDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Übung hinzufügen'),
              ),
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
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Übungen',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Füge Übungen hinzu, um deinen Trainingstag zu gestalten',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _showAddExerciseDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Erste Übung hinzufügen'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList(
      BuildContext context, List<ExerciseModel> exercises) {
    return ListView.builder(
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              exercise.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Primär: ${exercise.primaryMuscleGroup}'),
                if (exercise.secondaryMuscleGroup.isNotEmpty)
                  Text('Sekundär: ${exercise.secondaryMuscleGroup}'),
                Text('Steigerung: ${exercise.standardIncrease} kg'),
              ],
            ),
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
                ),
              ],
            ),
            isThreeLine: true,
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
            // Übung hinzufügen
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
            // Übung aktualisieren
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
