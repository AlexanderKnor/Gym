// lib/widgets/training_screen/active_plan_card_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/training_plan_screen/training_plan_model.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';
import '../../providers/training_plans_screen/training_plans_screen_provider.dart';
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
    final plansProvider = Provider.of<TrainingPlansProvider>(context);
    final isPeriodized = plan.isPeriodized;
    final currentWeekIndex = plansProvider.currentWeekIndex;

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
                // Bearbeiten-Button
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => _navigateToEditPlan(context),
                  tooltip: 'Trainingsplan bearbeiten',
                ),
              ],
            ),
          ),

          // NEU: Mikrozyklus-Wähler für periodisierte Pläne
          if (isPeriodized) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: Colors.purple[700], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Mesozyklus: Woche ${currentWeekIndex + 1} von ${plan.numberOfWeeks}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: plan.numberOfWeeks,
                      itemBuilder: (context, weekIndex) {
                        final isActive = weekIndex == currentWeekIndex;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text('Woche ${weekIndex + 1}'),
                            selected: isActive,
                            selectedColor: Colors.purple[400],
                            backgroundColor: Colors.grey[200],
                            labelStyle: TextStyle(
                              color: isActive ? Colors.white : Colors.black87,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                plansProvider.setCurrentWeekIndex(weekIndex);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],

          // Liste der Trainingstage
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: plan.days.length,
            itemBuilder: (context, index) {
              final day = plan.days[index];

              // Berechne die angepassten Übungen und Sätze für den aktuellen Mikrozyklus
              int totalExercises = day.exercises.length;
              int totalSets = 0;

              if (isPeriodized && plan.periodization != null) {
                for (var exercise in day.exercises) {
                  // Prüfe, ob es eine spezifische Konfiguration für diese Übung in dieser Woche gibt
                  final config = plan.getExerciseMicrocycle(
                      exercise.id, index, currentWeekIndex);
                  if (config != null) {
                    totalSets += config.numberOfSets;
                  } else {
                    totalSets += exercise.numberOfSets;
                  }
                }
              } else {
                // Bei nicht-periodisierten Plänen einfach die Standard-Satzanzahl verwenden
                for (var exercise in day.exercises) {
                  totalSets += exercise.numberOfSets;
                }
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
                    '${totalExercises} ${totalExercises == 1 ? "Übung" : "Übungen"} • $totalSets ${totalSets == 1 ? "Satz" : "Sätze"}'),
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

  // Methode zum Starten des Trainings - mit Unterstützung für Mikrozyklen
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

    // Den Index des aktuellen Mikrozyklus abrufen, falls periodisiert
    final plansProvider =
        Provider.of<TrainingPlansProvider>(context, listen: false);
    final currentWeekIndex =
        plan.isPeriodized ? plansProvider.currentWeekIndex : 0;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          // Immer einen neuen Provider erstellen, um Zustandsprobleme zu vermeiden
          return ChangeNotifierProvider(
            create: (context) => TrainingSessionProvider(),
            child: TrainingSessionScreen(
              trainingPlan: plan,
              dayIndex: dayIndex,
              weekIndex: currentWeekIndex, // Übergebe den aktuellen Mikrozyklus
            ),
          );
        },
      ),
    );
  }
}
