// lib/screens/create_training_plan_screen/create_training_plan_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';
import '../../widgets/create_training_plan_screen/create_training_plan_form_widget.dart';

class CreateTrainingPlanScreen extends StatelessWidget {
  const CreateTrainingPlanScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Provider in der main.dart erstellen und hier nur referenzieren
    final createProvider =
        Provider.of<CreateTrainingPlanProvider>(context, listen: false);

    // Zurücksetzen für einen sauberen Start
    createProvider.reset();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Neuen Trainingsplan erstellen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const SafeArea(
        child: CreateTrainingPlanFormWidget(),
      ),
    );
  }
}
