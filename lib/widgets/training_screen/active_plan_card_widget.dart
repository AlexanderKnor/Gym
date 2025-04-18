// lib/widgets/training_screen/active_plan_card_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/training_plan_screen/training_plan_model.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';
import '../../screens/create_training_plan_screen/training_day_editor_screen.dart';

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
                subtitle: Text('${day.exercises.length} Übungen'),
                trailing: ElevatedButton(
                  onPressed: () {
                    // Start-Button-Funktionalität ohne Meldung
                    // Hier könnte später die eigentliche Navigation zum Training stattfinden
                  },
                  child: const Text('Start'),
                ),
              );
            },
          ),

          // Footer mit Statistiken wurde entfernt
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
}
