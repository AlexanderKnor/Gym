// lib/widgets/training_screen/active_plan_card_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/training_plan_screen/training_plan_model.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';
import '../../providers/training_session_screen/training_session_provider.dart';
import '../../screens/create_training_plan_screen/training_day_editor_screen.dart';
import '../../screens/training_session_screen/training_session_screen.dart';

class ActivePlanCardWidget extends StatelessWidget {
  final TrainingPlanModel plan;

  const ActivePlanCardWidget({
    Key? key,
    required this.plan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Plannamen
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    plan.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Bearbeiten-Button hinzugefügt
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => _navigateToEditPlan(context),
                  tooltip: 'Trainingsplan bearbeiten',
                ),
              ],
            ),
          ),

          // Liste der Trainingstage
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: plan.days.length,
            itemBuilder: (context, index) {
              final day = plan.days[index];

              // Zähle die Gesamtzahl der Sätze für diesen Tag
              int totalSets = 0;
              for (var exercise in day.exercises) {
                totalSets += exercise.numberOfSets;
              }

              return ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue[100],
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ),
                title: Text(day.name),
                // Zeige die Anzahl der Übungen und die Gesamtzahl der Sätze an
                subtitle: Text(
                    '${day.exercises.length} ${day.exercises.length == 1 ? "Übung" : "Übungen"} • $totalSets ${totalSets == 1 ? "Satz" : "Sätze"}'),
                trailing: ElevatedButton(
                  onPressed: day.exercises.isEmpty
                      ? null // Deaktivieren, wenn keine Übungen vorhanden sind
                      : () => _startTraining(context, index),
                  child: const Text('Start'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Methode zum Navigieren zum Editor-Screen
  void _navigateToEditPlan(BuildContext context) {
    final createProvider =
        Provider.of<CreateTrainingPlanProvider>(context, listen: false);

    // Plan in den Provider laden und direkt zum Editor navigieren
    createProvider.skipToEditor(plan);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: createProvider,
          child: const TrainingDayEditorScreen(),
        ),
      ),
    );
  }

  // Methode zum Starten des Trainings - GEÄNDERT
  void _startTraining(BuildContext context, int dayIndex) {
    // Prüfen, ob der Tag Übungen enthält
    if (plan.days[dayIndex].exercises.isEmpty) {
      // Falls keine Übungen vorhanden sind, Meldung anzeigen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keine Übungen für diesen Tag definiert.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // GEÄNDERT: Immer einen NEUEN Provider erstellen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          // Immer einen neuen Provider erstellen, um Zustandsprobleme zu vermeiden
          return ChangeNotifierProvider(
            create: (context) => TrainingSessionProvider(),
            child: TrainingSessionScreen(
              trainingPlan: plan,
              dayIndex: dayIndex,
            ),
          );
        },
      ),
    );
  }
}
