import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/friend_profile_screen/friend_profile_provider.dart';
import '../../models/training_plan_screen/training_plan_model.dart';

class FriendTrainingPlansWidget extends StatelessWidget {
  const FriendTrainingPlansWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FriendProfileProvider>(context);
    final trainingPlans = provider.trainingPlans;

    if (trainingPlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Trainingspläne verfügbar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dein Freund hat noch keine Trainingspläne erstellt',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trainingspläne',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: trainingPlans.length,
              itemBuilder: (context, index) {
                final plan = trainingPlans[index];
                return _buildTrainingPlanCard(context, plan, plan.isActive);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingPlanCard(
      BuildContext context, TrainingPlanModel plan, bool isActive) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      color: isActive ? Colors.blue[50] : null,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.blue : Colors.grey[300],
          child: Icon(
            Icons.fitness_center,
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                plan.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.blue[800] : null,
                ),
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'AKTIV',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(
            '${plan.days.length} Trainingstage • ${_getTotalExercises(plan)} Übungen',
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () => _showTrainingPlanDetails(context, plan),
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? Colors.blue : Colors.grey[200],
            foregroundColor: isActive ? Colors.white : Colors.black87,
          ),
          child: const Text('Details'),
        ),
        onTap: () => _showTrainingPlanDetails(context, plan),
      ),
    );
  }

  int _getTotalExercises(TrainingPlanModel plan) {
    int total = 0;
    for (var day in plan.days) {
      total += day.exercises.length;
    }
    return total;
  }

  void _showTrainingPlanDetails(BuildContext context, TrainingPlanModel plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (plan.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'AKTIV',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Trainingstage und Übungen anzeigen
                  for (int i = 0; i < plan.days.length; i++) ...[
                    _buildDayDetails(plan.days[i], i),
                    if (i < plan.days.length - 1) const Divider(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayDetails(day, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.blue[200],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                day.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Übungen des Tages
          for (int i = 0; i < day.exercises.length; i++)
            Padding(
              padding: const EdgeInsets.only(left: 36, bottom: 8),
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              day.exercises[i].name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${day.exercises[i].numberOfSets}×',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (day.exercises[i].primaryMuscleGroup.isNotEmpty ||
                          day.exercises[i].secondaryMuscleGroup.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _getMuscleGroups(day.exercises[i]),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${day.exercises[i].restPeriodSeconds}s Pause',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.trending_up,
                              size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '+${day.exercises[i].standardIncrease}kg',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getMuscleGroups(exercise) {
    List<String> groups = [];
    if (exercise.primaryMuscleGroup.isNotEmpty) {
      groups.add(exercise.primaryMuscleGroup);
    }
    if (exercise.secondaryMuscleGroup.isNotEmpty) {
      groups.add(exercise.secondaryMuscleGroup);
    }
    return groups.join(' • ');
  }
}
