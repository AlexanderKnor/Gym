// lib/widgets/create_training_plan_screen/exercise_form_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/training_plan_screen/exercise_model.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';

class ExerciseFormWidget extends StatefulWidget {
  final ExerciseModel? initialExercise;
  final Function(ExerciseModel) onSave;
  final Function()? onFormLoaded; // Neuer Callback für den Ladezustand

  const ExerciseFormWidget({
    Key? key,
    this.initialExercise,
    required this.onSave,
    this.onFormLoaded, // Neuer optionaler Parameter
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
  late TextEditingController _numberOfSetsController;
  late TextEditingController _repRangeMinController;
  late TextEditingController _repRangeMaxController;
  late TextEditingController _rirRangeMinController;
  late TextEditingController _rirRangeMaxController;
  String? _selectedProfileId;
  bool _isLoading = true;
  // Eigenen Provider erstellen, um Zustandsprobleme zu vermeiden
  late ProgressionManagerProvider _progressionProvider;

  @override
  void initState() {
    super.initState();

    // Controller initialisieren
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
    _numberOfSetsController = TextEditingController(
      text: widget.initialExercise?.numberOfSets.toString() ?? '3',
    );
    _repRangeMinController = TextEditingController(
      text: widget.initialExercise?.repRangeMin.toString() ?? '8',
    );
    _repRangeMaxController = TextEditingController(
      text: widget.initialExercise?.repRangeMax.toString() ?? '12',
    );
    _rirRangeMinController = TextEditingController(
      text: widget.initialExercise?.rirRangeMin.toString() ?? '1',
    );
    _rirRangeMaxController = TextEditingController(
      text: widget.initialExercise?.rirRangeMax.toString() ?? '3',
    );

    // WICHTIG: Profil-ID temporär speichern
    final tempProfileId = widget.initialExercise?.progressionProfileId;

    // Eigenen Provider erstellen
    _progressionProvider = ProgressionManagerProvider();

    // Profile später laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfilesAndVerifySelection(tempProfileId);
    });
  }

  // Methode zum Laden der Profile und Überprüfen der Auswahl
  Future<void> _loadProfilesAndVerifySelection(String? tempProfileId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Warten auf das Laden der Profile vom Provider
      await _progressionProvider.refreshProfiles();

      // Nach dem Laden der Profile überprüfen, ob das Profil existiert
      if (tempProfileId != null) {
        final profileExists = _progressionProvider.progressionsProfile
            .any((profile) => profile.id == tempProfileId);

        // Nur wenn das Profil existiert, es setzen
        _selectedProfileId = profileExists ? tempProfileId : null;

        // Debug-Ausgabe
        print('Profil überprüft: ID=$tempProfileId, existiert=$profileExists');
        print(
            'Verfügbare Profile: ${_progressionProvider.progressionsProfile.map((p) => "${p.id}: ${p.name}").join(', ')}');
      }
    } catch (e) {
      print('Fehler beim Laden der Profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // NEU: Signalisieren, dass das Formular geladen ist
        if (widget.onFormLoaded != null) {
          widget.onFormLoaded!();
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _primaryMuscleController.dispose();
    _secondaryMuscleController.dispose();
    _standardIncreaseController.dispose();
    _restPeriodController.dispose();
    _numberOfSetsController.dispose();
    _repRangeMinController.dispose();
    _repRangeMaxController.dispose();
    _rirRangeMinController.dispose();
    _rirRangeMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Verwende den lokalen Provider statt des geerbten
    final progressionProfiles = _progressionProvider.progressionsProfile;

    // Zeige Ladeindikator während Profile geladen werden
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Profile werden geladen...'),
          ],
        ),
      );
    }

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

              // Anzahl der Sätze
              TextFormField(
                controller: _numberOfSetsController,
                decoration: const InputDecoration(
                  labelText: 'Anzahl Sätze',
                  border: OutlineInputBorder(),
                  hintText: 'z.B. 3, 4, 5',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte gib die Anzahl der Sätze ein';
                  }
                  final sets = int.tryParse(value);
                  if (sets == null || sets < 1) {
                    return 'Bitte gib eine gültige Zahl ein (mindestens 1)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // NEU: Wiederholungsbereich
              const Text(
                'Wiederholungsbereich',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Min. Wiederholungen
                  Expanded(
                    child: TextFormField(
                      controller: _repRangeMinController,
                      decoration: const InputDecoration(
                        labelText: 'Min. Wiederholungen',
                        border: OutlineInputBorder(),
                        hintText: 'z.B. 8',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Erforderlich';
                        }
                        final reps = int.tryParse(value);
                        if (reps == null || reps < 1) {
                          return 'Min. 1';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Max. Wiederholungen
                  Expanded(
                    child: TextFormField(
                      controller: _repRangeMaxController,
                      decoration: const InputDecoration(
                        labelText: 'Max. Wiederholungen',
                        border: OutlineInputBorder(),
                        hintText: 'z.B. 12',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Erforderlich';
                        }
                        final reps = int.tryParse(value);
                        if (reps == null || reps < 1) {
                          return 'Min. 1';
                        }

                        // Prüfen, ob Max größer oder gleich Min ist
                        final minReps =
                            int.tryParse(_repRangeMinController.text) ?? 0;
                        if (reps < minReps) {
                          return 'Muss ≥ Min. sein';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // NEU: RIR-Bereich
              const Text(
                'RIR-Bereich (Reps in Reserve)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Min. RIR
                  Expanded(
                    child: TextFormField(
                      controller: _rirRangeMinController,
                      decoration: const InputDecoration(
                        labelText: 'Min. RIR',
                        border: OutlineInputBorder(),
                        hintText: 'z.B. 1',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Erforderlich';
                        }
                        final rir = int.tryParse(value);
                        if (rir == null || rir < 0) {
                          return 'Min. 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Max. RIR
                  Expanded(
                    child: TextFormField(
                      controller: _rirRangeMaxController,
                      decoration: const InputDecoration(
                        labelText: 'Max. RIR',
                        border: OutlineInputBorder(),
                        hintText: 'z.B. 3',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Erforderlich';
                        }
                        final rir = int.tryParse(value);
                        if (rir == null || rir < 0) {
                          return 'Min. 0';
                        }

                        // Prüfen, ob Max größer oder gleich Min ist
                        final minRir =
                            int.tryParse(_rirRangeMinController.text) ?? 0;
                        if (rir < minRir) {
                          return 'Muss ≥ Min. sein';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
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

              // Progressionsprofil-Auswahl
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
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  hintText: 'Kein Profil (Standard)',
                  helperText: '${progressionProfiles.length} Profile verfügbar',
                ),
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

              // Profildetails
              if (_selectedProfileId != null) ...[
                const SizedBox(height: 8),
                ...progressionProfiles
                    .where((p) => p.id == _selectedProfileId)
                    .map((selectedProfile) => Container(
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
                                      selectedProfile.name,
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
                                selectedProfile.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.purple[600],
                                ),
                              ),
                            ],
                          ),
                        )),
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
        numberOfSets: int.tryParse(_numberOfSetsController.text) ?? 3,
        repRangeMin: int.tryParse(_repRangeMinController.text) ?? 8,
        repRangeMax: int.tryParse(_repRangeMaxController.text) ?? 12,
        rirRangeMin: int.tryParse(_rirRangeMinController.text) ?? 1,
        rirRangeMax: int.tryParse(_rirRangeMaxController.text) ?? 3,
        progressionProfileId: _selectedProfileId,
      );

      widget.onSave(exercise);
    }
  }
}
