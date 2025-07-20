import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/training_plan_screen/exercise_model.dart';
import '../../models/exercise_database/predefined_exercise_model.dart';
import '../../providers/training_session_screen/training_session_provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';
import 'exercise_database_selection_screen.dart';

class ExerciseSelectionScreen extends StatefulWidget {
  final ExerciseModel? initialExercise;
  final int? exerciseIndex;
  final Function(ExerciseModel)? onExerciseUpdated;

  const ExerciseSelectionScreen({
    Key? key,
    this.initialExercise,
    this.exerciseIndex,
    this.onExerciseUpdated,
  }) : super(key: key);

  @override
  State<ExerciseSelectionScreen> createState() => _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  @override
  void initState() {
    super.initState();
    
    // If creating new exercise, immediately redirect to database selection
    if (widget.initialExercise == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseDatabaseSelectionScreen(
              onExerciseSelected: (PredefinedExercise predefinedExercise) {
                // Create exercise model from selected predefined exercise
                final exercise = ExerciseModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: predefinedExercise.name,
                  primaryMuscleGroup: predefinedExercise.primaryMuscleGroup,
                  secondaryMuscleGroup: predefinedExercise.secondaryMuscleGroups.join(', '),
                  numberOfSets: 3,
                  repRangeMin: 8,
                  repRangeMax: 12,
                  rirRangeMin: 1,
                  rirRangeMax: 3,
                  standardIncrease: 2.5,
                  restPeriodSeconds: 90,
                  progressionProfileId: null,
                );
                
                // Navigate to configuration screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExerciseConfigurationScreen(
                      exercise: exercise,
                      isNewExercise: true,
                      onExerciseSaved: widget.onExerciseUpdated,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      });
    } else {
      // If editing existing exercise, go directly to configuration
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseConfigurationScreen(
              exercise: widget.initialExercise!,
              isNewExercise: false,
              onExerciseSaved: widget.onExerciseUpdated,
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while redirecting
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Center(
        child: CircularProgressIndicator(
          color: const Color(0xFFFF4500),
        ),
      ),
    );
  }
}

// New configuration screen for exercise parameters
class ExerciseConfigurationScreen extends StatefulWidget {
  final ExerciseModel exercise;
  final bool isNewExercise;
  final Function(ExerciseModel)? onExerciseSaved;

  const ExerciseConfigurationScreen({
    Key? key,
    required this.exercise,
    required this.isNewExercise,
    this.onExerciseSaved,
  }) : super(key: key);

  @override
  State<ExerciseConfigurationScreen> createState() => _ExerciseConfigurationScreenState();
}

class _ExerciseConfigurationScreenState extends State<ExerciseConfigurationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
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
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
    
    _numberOfSets = widget.exercise.numberOfSets;
    _repRangeMin = widget.exercise.repRangeMin;
    _repRangeMax = widget.exercise.repRangeMax;
    _rirRangeMin = widget.exercise.rirRangeMin;
    _rirRangeMax = widget.exercise.rirRangeMax;
    _standardIncrease = widget.exercise.standardIncrease;
    _restPeriodSeconds = widget.exercise.restPeriodSeconds;
    _selectedProfileId = widget.exercise.progressionProfileId;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _saveExercise() async {
    if (!_isSaving) {
      setState(() {
        _isSaving = true;
      });

      final exercise = ExerciseModel(
        id: widget.exercise.id,
        name: widget.exercise.name,
        primaryMuscleGroup: widget.exercise.primaryMuscleGroup,
        secondaryMuscleGroup: widget.exercise.secondaryMuscleGroup,
        numberOfSets: _numberOfSets,
        repRangeMin: _repRangeMin,
        repRangeMax: _repRangeMax,
        rirRangeMin: _rirRangeMin,
        rirRangeMax: _rirRangeMax,
        standardIncrease: _standardIncrease,
        restPeriodSeconds: _restPeriodSeconds,
        progressionProfileId: _selectedProfileId,
      );

      if (widget.onExerciseSaved != null) {
        widget.onExerciseSaved!(exercise);
        Navigator.of(context).pop();
        return;
      }

      try {
        final createProvider = Provider.of<CreateTrainingPlanProvider>(context, listen: false);
        if (widget.isNewExercise) {
          createProvider.addExercise(exercise);
        } else {
          final exercises = createProvider.draftPlan?.days[createProvider.selectedDayIndex].exercises ?? [];
          final exerciseIndex = exercises.indexWhere((e) => e.id == widget.exercise.id);
          if (exerciseIndex != -1) {
            createProvider.updateExercise(exerciseIndex, exercise);
          }
        }
      } catch (e) {
        final sessionProvider = Provider.of<TrainingSessionProvider>(context, listen: false);
        if (widget.isNewExercise) {
          sessionProvider.addNewExerciseToSession(exercise);
        } else {
          final exerciseIndex = sessionProvider.exercises.indexWhere((e) => e.id == widget.exercise.id);
          if (exerciseIndex != -1) {
            sessionProvider.updateExerciseFullDetails(exerciseIndex, exercise);
          }
        }
      }
      
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressionProvider = Provider.of<ProgressionManagerProvider>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
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
        title: const Text(
          'Übung konfigurieren',
          style: TextStyle(
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
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
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
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Text(
                            'FERTIG',
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ListView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
              bottom: 32,
            ),
            children: [
              // Exercise Header Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFF4500).withOpacity(0.1),
                      const Color(0xFFFF6B3D).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF4500).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF4500),
                                  Color(0xFFFF6B3D),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF4500).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.fitness_center,
                                color: Color(0xFFFFFFFF),
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.exercise.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFFFFFF),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF4500).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        widget.exercise.primaryMuscleGroup,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFFF4500),
                                        ),
                                      ),
                                    ),
                                    if (widget.exercise.secondaryMuscleGroup.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        widget.exercise.secondaryMuscleGroup,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF8E8E93),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Training Parameters Section
              _buildSection(
                title: 'Trainingsparameter',
                icon: Icons.tune_rounded,
                children: [
                  _buildParameterCard(
                    'Sätze',
                    Icons.repeat_rounded,
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _numberOfSets > 1
                                    ? () {
                                        setState(() => _numberOfSets--);
                                        HapticFeedback.lightImpact();
                                      }
                                    : null,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                                child: Container(
                                  height: 48,
                                  child: Center(
                                    child: Icon(
                                      Icons.remove_circle_outline,
                                      size: 20,
                                      color: _numberOfSets > 1
                                          ? const Color(0xFFFF4500)
                                          : const Color(0xFF8E8E93).withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: const Color(0xFF48484A),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                '$_numberOfSets',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: const Color(0xFF48484A),
                          ),
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _numberOfSets < 10
                                    ? () {
                                        setState(() => _numberOfSets++);
                                        HapticFeedback.lightImpact();
                                      }
                                    : null,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                child: Container(
                                  height: 48,
                                  child: Center(
                                    child: Icon(
                                      Icons.add_circle_outline,
                                      size: 20,
                                      color: _numberOfSets < 10
                                          ? const Color(0xFFFF4500)
                                          : const Color(0xFF8E8E93).withOpacity(0.5),
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
                  
                  _buildParameterCard(
                    'Wiederholungen',
                    Icons.tag_rounded,
                    _buildRangeSelector(
                      minValue: _repRangeMin,
                      maxValue: _repRangeMax,
                      onMinChanged: (value) => setState(() {
                        _repRangeMin = value;
                        if (_repRangeMax < value) _repRangeMax = value;
                      }),
                      onMaxChanged: (value) => setState(() => _repRangeMax = value),
                      minLimit: 1,
                      maxLimit: 30,
                    ),
                  ),
                  
                  _buildParameterCard(
                    'RIR (Reps in Reserve)',
                    Icons.battery_charging_full_rounded,
                    _buildRangeSelector(
                      minValue: _rirRangeMin,
                      maxValue: _rirRangeMax,
                      onMinChanged: (value) => setState(() {
                        _rirRangeMin = value;
                        if (_rirRangeMax < value) _rirRangeMax = value;
                      }),
                      onMaxChanged: (value) => setState(() => _rirRangeMax = value),
                      minLimit: 0,
                      maxLimit: 10,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Additional Settings Section
              _buildSection(
                title: 'Weitere Einstellungen',
                icon: Icons.settings_rounded,
                children: [
                  _buildParameterCard(
                    'Standard-Erhöhung',
                    Icons.trending_up_rounded,
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showIncrementPicker(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: Text(
                              '${_standardIncrease.toStringAsFixed(_standardIncrease == _standardIncrease.roundToDouble() ? 0 : 1)} kg',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  _buildParameterCard(
                    'Pausenzeit',
                    Icons.timer_outlined,
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showRestPeriodPicker(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: Text(
                              _formatRestPeriod(_restPeriodSeconds),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Progression Profile Section
              if (progressionProvider.progressionsProfile.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Progressionsprofil',
                  icon: Icons.analytics_outlined,
                  optional: true,
                  children: [
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
                            vertical: 12,
                          ),
                        ),
                        hint: const Text(
                          'Kein Profil ausgewählt',
                          style: TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 16,
                          ),
                        ),
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        dropdownColor: const Color(0xFF1C1C1E),
                        icon: const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: Color(0xFFFF4500),
                          size: 28,
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
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF4500),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    profile.name,
                                    style: const TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
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
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool optional = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFFFF4500),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF4500),
                    letterSpacing: -0.3,
                  ),
                ),
                if (optional) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8E8E93).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Optional',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8E8E93),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF48484A).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterCard(String label, IconData icon, Widget control) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 20,
                color: const Color(0xFFAEAEB2),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFFAEAEB2),
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 140,
            child: control,
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector({
    required int minValue,
    required int maxValue,
    required Function(int) onMinChanged,
    required Function(int) onMaxChanged,
    required int minLimit,
    required int maxLimit,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _showNumberPicker(
                context,
                'Minimum',
                minValue,
                minLimit,
                maxLimit,
                onMinChanged,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$minValue',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 20,
            child: Center(
              child: Text(
                '-',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _showNumberPicker(
                context,
                'Maximum',
                maxValue,
                minValue,
                maxLimit,
                onMaxChanged,
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$maxValue',
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
                                fontSize: isSelected ? 28 : 20,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
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
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF4500),
                          Color(0xFFFF6B3D),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          onSelected(tempValue);
                          Navigator.pop(context);
                          HapticFeedback.lightImpact();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'Auswählen',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
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
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
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
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF4500),
                          Color(0xFFFF6B3D),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          this.setState(() {
                            _standardIncrease = tempValue;
                          });
                          Navigator.pop(context);
                          HapticFeedback.lightImpact();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'Auswählen',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
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
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
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
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF4500),
                          Color(0xFFFF6B3D),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          this.setState(() {
                            _restPeriodSeconds = tempValue;
                          });
                          Navigator.pop(context);
                          HapticFeedback.lightImpact();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'Auswählen',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
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