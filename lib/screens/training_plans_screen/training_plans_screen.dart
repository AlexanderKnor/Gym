import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/training_plans_screen/training_plans_screen_provider.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';
import '../../models/training_plan_screen/training_plan_model.dart';
import '../create_training_plan_screen/create_training_plan_screen.dart';
import '../create_training_plan_screen/training_day_editor_screen.dart';

class TrainingPlansScreen extends StatelessWidget {
  const TrainingPlansScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final plansProvider = Provider.of<TrainingPlansProvider>(context);
    final trainingPlans = plansProvider.trainingPlans;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deine Trainingspläne'),
        automaticallyImplyLeading: false,
      ),
      body: plansProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : trainingPlans.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trainingPlans.length,
                  itemBuilder: (context, index) {
                    return _buildTrainingPlanCard(
                      context,
                      trainingPlans[index],
                      plansProvider,
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'plans_add_plan',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateTrainingPlanScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Neuen Trainingsplan erstellen',
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Trainingspläne',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Erstelle deinen ersten Trainingsplan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateTrainingPlanScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Trainingsplan erstellen'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingPlanCard(
    BuildContext context,
    TrainingPlanModel plan,
    TrainingPlansProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: plan.isActive
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: plan.isActive
                  ? Theme.of(context).primaryColor
                  : Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  color: plan.isActive ? Colors.white : Colors.grey[800],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    plan.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: plan.isActive ? Colors.white : Colors.grey[800],
                    ),
                  ),
                ),
                if (plan.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Aktiv',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Inhalt
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Überschrift für Trainingstage
                const Text(
                  'Trainingstage:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Trainingstage als Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: plan.days.map((day) {
                    return Chip(
                      label: Text(day.name),
                      avatar: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          '${plan.days.indexOf(day) + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Statistik
                Row(
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
              ],
            ),
          ),

          // Aktionen
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Bearbeiten-Button
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _navigateToEditPlan(context, plan),
                  color: Colors.blue,
                  tooltip: 'Bearbeiten',
                ),

                // Löschen-Button
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDeletePlan(context, provider, plan),
                  color: Colors.red,
                  tooltip: 'Löschen',
                ),

                // Nur anzeigen, wenn der Plan nicht aktiv ist
                if (!plan.isActive)
                  TextButton.icon(
                    onPressed: () async {
                      await provider.activateTrainingPlan(plan.id);
                      // Entferne die SnackBar-Anzeige
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Aktivieren'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Neue Methode für die Navigation zum Editor
  void _navigateToEditPlan(BuildContext context, TrainingPlanModel plan) {
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

  void _confirmDeletePlan(
    BuildContext context,
    TrainingPlansProvider provider,
    TrainingPlanModel plan,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trainingsplan löschen'),
        content: Text(
            'Möchtest du den Trainingsplan "${plan.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.deleteTrainingPlan(plan.id);
              Navigator.pop(context);
              // SnackBar-Meldung entfernt
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

  int _getTotalExercises(TrainingPlanModel plan) {
    return plan.days.fold(0, (sum, day) => sum + day.exercises.length);
  }
}
