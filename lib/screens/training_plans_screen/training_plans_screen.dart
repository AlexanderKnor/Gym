import 'package:flutter/material.dart';

class TrainingPlansScreen extends StatelessWidget {
  const TrainingPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            'Trainingspläne Screen',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
