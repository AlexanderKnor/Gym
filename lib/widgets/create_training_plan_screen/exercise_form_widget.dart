// lib/widgets/create_training_plan_screen/exercise_form_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/training_plan_screen/exercise_model.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';

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
  String? _selectedProfileId; // Für die Profilauswahl

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

    // Profil-ID initialisieren
    _selectedProfileId = widget.initialExercise?.progressionProfileId;
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
    // ProgressionManagerProvider für die verfügbaren Profile
    final progressionProvider =
        Provider.of<ProgressionManagerProvider>(context);
    final progressionProfiles = progressionProvider.progressionsProfile;

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
              const SizedBox(height: 16),

              // NEUER ABSCHNITT: Progressionsprofil-Auswahl
              const Text(
                'Progressionsprofil (optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Wähle ein Progressionsprofil für automatische Empfehlungen',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              // Dropdown für die Profil-Auswahl
              DropdownButtonFormField<String?>(
                value: _selectedProfileId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                hint: const Text('Kein Profil (Standard)'),
                items: [
                  // "Kein Profil" Option
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Kein Profil (Standard)'),
                  ),
                  // Alle verfügbaren Profile
                  ...progressionProfiles
                      .map((profile) => DropdownMenuItem<String?>(
                            value: profile.id,
                            child: Text(profile.name),
                          )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedProfileId = value;
                  });
                },
              ),

              // Zeige Details zum ausgewählten Profil an
              if (_selectedProfileId != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.purple[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: Colors.purple[700]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              progressionProfiles
                                  .firstWhere((p) => p.id == _selectedProfileId)
                                  .name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progressionProfiles
                            .firstWhere((p) => p.id == _selectedProfileId)
                            .description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

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
        progressionProfileId:
            _selectedProfileId, // Das ausgewählte Profil speichern
      );

      widget.onSave(exercise);
    }
  }
}
