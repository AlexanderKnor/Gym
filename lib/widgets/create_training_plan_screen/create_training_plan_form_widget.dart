import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';

class CreateTrainingPlanFormWidget extends StatelessWidget {
  const CreateTrainingPlanFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider als Zustandsmanagement für dieses Widget
    final createTrainingPlanProvider =
        Provider.of<CreateTrainingPlanProvider>(context);

    // Platzhalter für das Formular zur Erstellung eines Trainingsplans
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          'Hier wird später ein Formular für die Erstellung eines Trainingsplans angezeigt',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
