// lib/widgets/create_training_plan_screen/exercise_form_widget.dart
import 'package:flutter/material.dart';
import '../../models/training_plan_screen/exercise_model.dart';

class ExerciseFormWidget extends StatefulWidget {
  final ExerciseModel? initialExercise;
  final Function(ExerciseModel) onSave;

  const ExerciseFormWidget({
    Key? key,
    this.initialExercise,
    required this.onSave,
  }) : super(key: key);

  @override
  _ExerciseFormWidgetState createState() => _ExerciseFormWidgetState();
}

class _ExerciseFormWidgetState extends State<ExerciseFormWidget> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _primaryMuscleController;
  late TextEditingController _secondaryMuscleController;
  late TextEditingController _standardIncreaseController;
  late TextEditingController _restPeriodController;

  @override
  void initState() {
    super.initState();

    // Controller mit Werten aus initialExercise initialisieren, falls vorhanden
    _nameController = TextEditingController(
      text: widget.initialExercise?.name ?? '',
    );

    _primaryMuscleController = TextEditingController(
      text: widget.initialExercise?.primaryMuscleGroup ?? '',
    );

    _secondaryMuscleController = TextEditingController(
      text: widget.initialExercise?.secondaryMuscleGroup ?? '',
    );

    _standardIncreaseController = TextEditingController(
      text: widget.initialExercise?.standardIncrease.toString() ?? '2.5',
    );

    _restPeriodController = TextEditingController(
      text: widget.initialExercise?.restPeriodSeconds.toString() ?? '90',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _primaryMuscleController.dispose();
    _secondaryMuscleController.dispose();
    _standardIncreaseController.dispose();
    _restPeriodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                widget.initialExercise != null
                    ? 'Übung bearbeiten'
                    : 'Neue Übung',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Übungsname
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Übungsname',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte gib einen Namen ein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Primäre Muskelgruppe
              TextFormField(
                controller: _primaryMuscleController,
                decoration: const InputDecoration(
                  labelText: 'Primäre Muskelgruppe',
                  border: OutlineInputBorder(),
                  hintText: 'z.B. Brust, Rücken, Beine',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte gib die primäre Muskelgruppe ein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Sekundäre Muskelgruppe
              TextFormField(
                controller: _secondaryMuscleController,
                decoration: const InputDecoration(
                  labelText: 'Sekundäre Muskelgruppe (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'z.B. Schultern, Trizeps',
                ),
              ),
              const SizedBox(height: 12),

              // Standard Gewichtssteigerung
              TextFormField(
                controller: _standardIncreaseController,
                decoration: const InputDecoration(
                  labelText: 'Standard Steigerung (kg)',
                  border: OutlineInputBorder(),
                  suffixText: 'kg',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte gib die Standard-Steigerung ein';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Bitte gib eine gültige Zahl ein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Satzpause
              TextFormField(
                controller: _restPeriodController,
                decoration: const InputDecoration(
                  labelText: 'Satzpause (Sekunden)',
                  border: OutlineInputBorder(),
                  suffixText: 'Sekunden',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte gib die Satzpause ein';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Bitte gib eine gültige Zahl ein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Abbrechen'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveExercise,
                    child: const Text('Speichern'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveExercise() {
    if (_formKey.currentState!.validate()) {
      final exerciseId = widget.initialExercise?.id ??
          'exercise_${DateTime.now().millisecondsSinceEpoch}';

      final exercise = ExerciseModel(
        id: exerciseId,
        name: _nameController.text.trim(),
        primaryMuscleGroup: _primaryMuscleController.text.trim(),
        secondaryMuscleGroup: _secondaryMuscleController.text.trim(),
        standardIncrease:
            double.tryParse(_standardIncreaseController.text) ?? 2.5,
        restPeriodSeconds: int.tryParse(_restPeriodController.text) ?? 90,
      );

      widget.onSave(exercise);
    }
  }
}
