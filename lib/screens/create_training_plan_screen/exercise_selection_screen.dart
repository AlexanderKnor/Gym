// lib/screens/create_training_plan_screen/exercise_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/training_plan_screen/exercise_model.dart';
import '../../providers/training_session_screen/training_session_provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';

class ExerciseSelectionScreen extends StatefulWidget {
  final ExerciseModel? initialExercise;

  const ExerciseSelectionScreen({
    Key? key,
    this.initialExercise,
  }) : super(key: key);

  @override
  State<ExerciseSelectionScreen> createState() => _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _primaryMuscleController;
  late TextEditingController _secondaryMuscleController;
  
  late int _numberOfSets;
  late int _repRangeMin;
  late int _repRangeMax;
  late int _rirRangeMin;
  late int _rirRangeMax;
  late double _standardIncrease;
  late int _restPeriodSeconds;
  
  String? _selectedProfileId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController(
      text: widget.initialExercise?.name ?? '',
    );
    _primaryMuscleController = TextEditingController(
      text: widget.initialExercise?.primaryMuscleGroup ?? '',
    );
    _secondaryMuscleController = TextEditingController(
      text: widget.initialExercise?.secondaryMuscleGroup ?? '',
    );
    
    _numberOfSets = widget.initialExercise?.numberOfSets ?? 3;
    _repRangeMin = widget.initialExercise?.repRangeMin ?? 8;
    _repRangeMax = widget.initialExercise?.repRangeMax ?? 12;
    _rirRangeMin = widget.initialExercise?.rirRangeMin ?? 1;
    _rirRangeMax = widget.initialExercise?.rirRangeMax ?? 3;
    _standardIncrease = widget.initialExercise?.standardIncrease ?? 2.5;
    _restPeriodSeconds = widget.initialExercise?.restPeriodSeconds ?? 90;
    _selectedProfileId = widget.initialExercise?.progressionProfileId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _primaryMuscleController.dispose();
    _secondaryMuscleController.dispose();
    super.dispose();
  }

  void _saveExercise() {
    if (_formKey.currentState!.validate() && !_isSaving) {
      setState(() {
        _isSaving = true;
      });

      final exercise = ExerciseModel(
        id: widget.initialExercise?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        primaryMuscleGroup: _primaryMuscleController.text,
        secondaryMuscleGroup: _secondaryMuscleController.text,
        numberOfSets: _numberOfSets,
        repRangeMin: _repRangeMin,
        repRangeMax: _repRangeMax,
        rirRangeMin: _rirRangeMin,
        rirRangeMax: _rirRangeMax,
        standardIncrease: _standardIncrease,
        restPeriodSeconds: _restPeriodSeconds,
        progressionProfileId: _selectedProfileId,
      );

      // Check if we're in training plan creation context or training session context
      try {
        final createProvider = Provider.of<CreateTrainingPlanProvider>(context, listen: false);
        createProvider.addExercise(exercise);
      } catch (e) {
        // If CreateTrainingPlanProvider is not available, fall back to training session logic
        final sessionProvider = Provider.of<TrainingSessionProvider>(context, listen: false);
        sessionProvider.addNewExerciseToSession(exercise);
      }
      
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressionProvider = Provider.of<ProgressionManagerProvider>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Midnight
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF000000),
                const Color(0xFF000000).withOpacity(0.95),
                const Color(0xFF000000).withOpacity(0.8),
                const Color(0xFF000000).withOpacity(0.4),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 0.6, 0.85, 1.0],
            ),
          ),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF48484A).withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Color(0xFFFFFFFF),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          widget.initialExercise != null ? 'Übung bearbeiten' : 'Neue Übung',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: Color(0xFFFFFFFF),
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF4500),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF4500),
                          Color(0xFFFF6B3D),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4500).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _saveExercise,
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            'SPEICHERN',
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
            bottom: 32,
          ),
          children: [
            // Übungsname
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF48484A).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Übungsname',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF4500),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'z.B. Bankdrücken',
                        hintStyle: const TextStyle(
                          color: Color(0xFF8E8E93),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte geben Sie einen Übungsnamen ein';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Muskelgruppen
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF48484A).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Muskelgruppen',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF4500),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _primaryMuscleController,
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Primäre Muskelgruppe',
                        labelStyle: const TextStyle(
                          color: Color(0xFFAEAEB2),
                        ),
                        hintText: 'z.B. Brust',
                        hintStyle: const TextStyle(
                          color: Color(0xFF8E8E93),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte geben Sie eine primäre Muskelgruppe ein';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _secondaryMuscleController,
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Sekundäre Muskelgruppe (optional)',
                        labelStyle: const TextStyle(
                          color: Color(0xFFAEAEB2),
                        ),
                        hintText: 'z.B. Trizeps',
                        hintStyle: const TextStyle(
                          color: Color(0xFF8E8E93),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Trainingsparameter
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF48484A).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.fitness_center,
                          size: 18,
                          color: Color(0xFFFF4500),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Trainingsparameter',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF4500),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Sätze
                    _buildParameterRow(
                      'Sätze',
                      Container(
                        width: 120,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: IconButton(
                                icon: const Icon(Icons.remove, size: 16),
                                onPressed: _numberOfSets > 1
                                    ? () {
                                        setState(() {
                                          _numberOfSets--;
                                        });
                                        HapticFeedback.lightImpact();
                                      }
                                    : null,
                                padding: EdgeInsets.zero,
                                color: const Color(0xFFFF4500),
                                disabledColor: const Color(0xFF8E8E93),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  '$_numberOfSets',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFFFFFF),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: IconButton(
                                icon: const Icon(Icons.add, size: 16),
                                onPressed: _numberOfSets < 10
                                    ? () {
                                        setState(() {
                                          _numberOfSets++;
                                        });
                                        HapticFeedback.lightImpact();
                                      }
                                    : null,
                                padding: EdgeInsets.zero,
                                color: const Color(0xFFFF4500),
                                disabledColor: const Color(0xFF8E8E93),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Wiederholungen
                    _buildParameterRow(
                      'Wiederholungen',
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Min Reps
                            Container(
                              width: 60,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: InkWell(
                                onTap: () => _showNumberPicker(
                                  context,
                                  'Min. Wiederholungen',
                                  _repRangeMin,
                                  1,
                                  30,
                                  (value) {
                                    setState(() {
                                      _repRangeMin = value;
                                      if (_repRangeMax < _repRangeMin) {
                                        _repRangeMax = _repRangeMin;
                                      }
                                    });
                                  },
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Center(
                                  child: Text(
                                    '$_repRangeMin',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFFFFFF),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '-',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFFAEAEB2),
                                ),
                              ),
                            ),
                            // Max Reps
                            Container(
                              width: 60,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: InkWell(
                                onTap: () => _showNumberPicker(
                                  context,
                                  'Max. Wiederholungen',
                                  _repRangeMax,
                                  _repRangeMin,
                                  30,
                                  (value) {
                                    setState(() {
                                      _repRangeMax = value;
                                    });
                                  },
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Center(
                                  child: Text(
                                    '$_repRangeMax',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFFFFFF),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // RIR
                    _buildParameterRow(
                      'RIR (Reps in Reserve)',
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Min RIR
                            Container(
                              width: 60,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: InkWell(
                                onTap: () => _showNumberPicker(
                                  context,
                                  'Min. RIR',
                                  _rirRangeMin,
                                  0,
                                  10,
                                  (value) {
                                    setState(() {
                                      _rirRangeMin = value;
                                      if (_rirRangeMax < _rirRangeMin) {
                                        _rirRangeMax = _rirRangeMin;
                                      }
                                    });
                                  },
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Center(
                                  child: Text(
                                    '$_rirRangeMin',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFFFFFF),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '-',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFFAEAEB2),
                                ),
                              ),
                            ),
                            // Max RIR
                            Container(
                              width: 60,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: InkWell(
                                onTap: () => _showNumberPicker(
                                  context,
                                  'Max. RIR',
                                  _rirRangeMax,
                                  _rirRangeMin,
                                  10,
                                  (value) {
                                    setState(() {
                                      _rirRangeMax = value;
                                    });
                                  },
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Center(
                                  child: Text(
                                    '$_rirRangeMax',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFFFFFF),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Weitere Einstellungen
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF48484A).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weitere Einstellungen',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF4500),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Standard-Erhöhung
                    _buildParameterRow(
                      'Standard-Erhöhung (kg)',
                      Container(
                        width: 100,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: () => _showIncrementPicker(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Center(
                            child: Text(
                              _standardIncrease.toStringAsFixed(_standardIncrease == _standardIncrease.roundToDouble() ? 0 : 1) + ' kg',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Pausenzeit
                    _buildParameterRow(
                      'Pausenzeit',
                      Container(
                        width: 100,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: () => _showRestPeriodPicker(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Center(
                            child: Text(
                              _formatRestPeriod(_restPeriodSeconds),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Progressionsprofil
            if (progressionProvider.progressionsProfile.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF48484A).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.trending_up_rounded,
                            size: 18,
                            color: Color(0xFFFF4500),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Progressionsprofil (optional)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF4500),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedProfileId,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          hint: const Text(
                            'Kein Profil ausgewählt',
                            style: TextStyle(
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 16,
                          ),
                          dropdownColor: const Color(0xFF1C1C1E),
                          icon: const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: Color(0xFFFF4500),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                'Kein Profil',
                                style: TextStyle(
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ),
                            ...progressionProvider.progressionsProfile.map((profile) {
                              return DropdownMenuItem<String>(
                                value: profile.id,
                                child: Text(
                                  profile.name,
                                  style: const TextStyle(
                                    color: Color(0xFFFFFFFF),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedProfileId = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterRow(String label, Widget control) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFFAEAEB2),
          ),
        ),
        control,
      ],
    );
  }

  void _showNumberPicker(
    BuildContext context,
    String title,
    int currentValue,
    int min,
    int max,
    Function(int) onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        int tempValue = currentValue;
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 300,
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF48484A),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListWheelScrollView(
                      itemExtent: 50,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(
                        initialItem: currentValue - min,
                      ),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          tempValue = min + index;
                        });
                      },
                      children: List.generate(
                        max - min + 1,
                        (index) {
                          final value = min + index;
                          final isSelected = value == tempValue;
                          return Center(
                            child: Text(
                              '$value',
                              style: TextStyle(
                                fontSize: isSelected ? 24 : 18,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected
                                    ? const Color(0xFFFF4500)
                                    : const Color(0xFFAEAEB2),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        onSelected(tempValue);
                        Navigator.pop(context);
                        HapticFeedback.lightImpact();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4500),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Auswählen',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showIncrementPicker(BuildContext context) {
    final increments = [0.25, 0.5, 1.0, 1.25, 2.0, 2.5, 5.0, 7.5, 10.0];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        double tempValue = _standardIncrease;
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 350,
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF48484A),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Standard-Erhöhung',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListWheelScrollView(
                      itemExtent: 50,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(
                        initialItem: increments.indexOf(_standardIncrease),
                      ),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          tempValue = increments[index];
                        });
                      },
                      children: increments.map((increment) {
                        final isSelected = increment == tempValue;
                        return Center(
                          child: Text(
                            '${increment.toStringAsFixed(increment == increment.roundToDouble() ? 0 : 2)} kg',
                            style: TextStyle(
                              fontSize: isSelected ? 24 : 18,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? const Color(0xFFFF4500)
                                  : const Color(0xFFAEAEB2),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        this.setState(() {
                          _standardIncrease = tempValue;
                        });
                        Navigator.pop(context);
                        HapticFeedback.lightImpact();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4500),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Auswählen',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRestPeriodPicker(BuildContext context) {
    final restPeriods = [30, 45, 60, 90, 120, 150, 180, 240, 300];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        int tempValue = _restPeriodSeconds;
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 350,
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF48484A),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Pausenzeit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListWheelScrollView(
                      itemExtent: 50,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(
                        initialItem: restPeriods.indexOf(_restPeriodSeconds),
                      ),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          tempValue = restPeriods[index];
                        });
                      },
                      children: restPeriods.map((period) {
                        final isSelected = period == tempValue;
                        return Center(
                          child: Text(
                            _formatRestPeriod(period),
                            style: TextStyle(
                              fontSize: isSelected ? 24 : 18,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? const Color(0xFFFF4500)
                                  : const Color(0xFFAEAEB2),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        this.setState(() {
                          _restPeriodSeconds = tempValue;
                        });
                        Navigator.pop(context);
                        HapticFeedback.lightImpact();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4500),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Auswählen',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatRestPeriod(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (remainingSeconds == 0) {
        return '${minutes}min';
      } else {
        return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}min';
      }
    }
  }
}