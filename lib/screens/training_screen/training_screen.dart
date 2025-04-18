// lib/screens/training_screen/training_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/shared/navigation_provider.dart'; // Hinzugefügt
import '../../providers/training_plans_screen/training_plans_screen_provider.dart';
import '../../widgets/training_screen/active_plan_card_widget.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final plansProvider = Provider.of<TrainingPlansProvider>(context);
    final activePlan = plansProvider.activePlan;

    return Scaffold(
      body: SafeArea(
        child: activePlan != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seitentitel
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Dein aktiver Trainingsplan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),

                  // Aktive Plan-Karte
                  ActivePlanCardWidget(plan: activePlan),

                  // Schnellstatistiken
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(context, 'Tage',
                                activePlan.days.length.toString()),
                            _buildStatItem(
                              context,
                              'Übungen',
                              _getTotalExercises(activePlan).toString(),
                            ),
                            _buildStatItem(context, 'Status', 'Aktiv'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : _buildNoActivePlanState(context),
      ),
    );
  }

  Widget _buildNoActivePlanState(BuildContext context) {
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
            'Kein aktiver Trainingsplan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Erstelle einen neuen Trainingsplan oder aktiviere einen bestehenden',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigiere zum Trainingsplan-Screen
              final navigationProvider =
                  Provider.of<NavigationProvider>(context, listen: false);
              navigationProvider.setCurrentIndex(2); // Zum Trainingspläne-Tab
            },
            icon: const Icon(Icons.calendar_today),
            label: const Text('Zu deinen Trainingsplänen'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  int _getTotalExercises(dynamic plan) {
    return plan.days.fold(0, (sum, day) => sum + day.exercises.length);
  }
}
