// lib/widgets/training_screen/active_plan_card_widget.dart
import 'package:flutter/material.dart';
import '../../models/training_plan_screen/training_plan_model.dart';

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
                    // Platzhalter für Start-Button-Funktionalität
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Training "${day.name}" gestartet'),
                      ),
                    );
                  },
                  child: const Text('Start'),
                ),
              );
            },
          ),

          // Footer mit Statistiken
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${plan.days.length} Trainingstage',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Gesamt: ${_getTotalExercises(plan)} Übungen',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalExercises(TrainingPlanModel plan) {
    return plan.days.fold(0, (sum, day) => sum + day.exercises.length);
  }
}
