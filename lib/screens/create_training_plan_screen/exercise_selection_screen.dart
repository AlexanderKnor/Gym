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
        // Check if widget is still mounted before navigating
        if (!mounted) return;
        
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
        // Check if widget is still mounted before navigating
        if (!mounted) return;
        
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

class _ExerciseConfigurationScreenState extends State<ExerciseConfigurationScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _heroController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _heroScaleAnimation;
  
  // Sophisticated color system - matching modern screens
  static const Color _void = Color(0xFF000000);
  static const Color _cosmos = Color(0xFF050507);
  static const Color _nebula = Color(0xFF0F0F12);
  static const Color _stellar = Color(0xFF18181C);
  static const Color _lunar = Color(0xFF242429);
  static const Color _asteroid = Color(0xFF35353C);
  static const Color _comet = Color(0xFF65656F);
  static const Color _stardust = Color(0xFFA5A5B0);
  static const Color _nova = Color(0xFFF5F5F7);

  // Prover signature gradient
  static const Color _proverCore = Color(0xFFFF4500);
  static const Color _proverGlow = Color(0xFFFF6B3D);
  static const Color _proverFlare = Color(0xFFFFA500);
  
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
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _heroController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    );

    _heroScaleAnimation = CurvedAnimation(
      parent: _heroController,
      curve: const Cubic(0.175, 0.885, 0.32, 1.275),
    );

    _fadeController.forward();
    _heroController.forward();
    
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
    _fadeController.dispose();
    _heroController.dispose();
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
      backgroundColor: _void,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            bottom: false,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Space for fixed header
                  SliverToBoxAdapter(
                    child: SizedBox(height: 60),
                  ),
                  
                  // Exercise header - elegant and minimal
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.exercise.name,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: _nova,
                                letterSpacing: -1,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _stellar.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _lunar.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    widget.exercise.primaryMuscleGroup,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _stardust,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                                if (widget.exercise.secondaryMuscleGroup.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '+ ${widget.exercise.secondaryMuscleGroup}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _comet,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Configuration sections
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildModernSection(
                          'TRAININGSPARAMETER',
                          Icons.tune_rounded,
                          [
                            _buildModernParameterCard(
                              'Sätze',
                              Icons.repeat_rounded,
                              _buildSetSelector(),
                            ),
                            _buildModernParameterCard(
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
                            _buildModernParameterCard(
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
                        
                        const SizedBox(height: 32),
                        
                        _buildModernSection(
                          'WEITERE EINSTELLUNGEN',
                          Icons.settings_rounded,
                          [
                            _buildModernParameterCard(
                              'Standard-Erhöhung',
                              Icons.trending_up_rounded,
                              _buildIncrementSelector(),
                            ),
                            _buildModernParameterCard(
                              'Pausenzeit',
                              Icons.timer_outlined,
                              _buildRestPeriodSelector(),
                            ),
                          ],
                        ),
                        
                        if (progressionProvider.progressionsProfile.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          _buildModernSection(
                            'PROGRESSIONSPROFIL',
                            Icons.analytics_outlined,
                            [_buildProgressionProfileSelector(progressionProvider)],
                            optional: true,
                          ),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Fixed header with logo and actions
          SafeArea(
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _void,
                    _void.withOpacity(0.95),
                    _void.withOpacity(0.8),
                    _void.withOpacity(0),
                  ],
                  stops: const [0.0, 0.6, 0.8, 1.0],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _stellar.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _lunar.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: _nova,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'KONFIGURATION',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _nova,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  _isSaving
                    ? Container(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _proverCore,
                        ),
                      )
                    : GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _saveExercise();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_proverCore, _proverGlow],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: _proverCore.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'FERTIG',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _nova,
                              letterSpacing: 1,
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
    );
  }

  Widget _buildModernSection(
    String title,
    IconData icon,
    List<Widget> children, {
    bool optional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: _proverCore,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _proverCore,
                  letterSpacing: 1.2,
                  ),
                ),
                if (optional) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _comet.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _comet.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'OPTIONAL',
                      style: TextStyle(
                        fontSize: 9,
                        color: _comet,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ...children.map((child) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: child,
        )),
        ],
      );
  }

  Widget _buildModernParameterCard(String label, IconData icon, Widget control) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _stellar.withOpacity(0.6),
            _nebula.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _lunar.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: _void.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _stellar.withOpacity(0.8),
                    _stellar.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _lunar.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 20,
                  color: _stardust,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _nova,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: control,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetSelector() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _stellar.withOpacity(0.8),
            _stellar.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _lunar.withOpacity(0.5),
          width: 1,
        ),
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
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
                child: Container(
                  height: 50,
                  child: Center(
                    child: Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 22,
                      color: _numberOfSets > 1
                          ? _proverCore
                          : _comet.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 26,
            color: _lunar.withOpacity(0.5),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                '$_numberOfSets',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _nova,
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 26,
            color: _lunar.withOpacity(0.5),
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
                  topRight: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                child: Container(
                  height: 50,
                  child: Center(
                    child: Icon(
                      Icons.add_circle_outline_rounded,
                      size: 22,
                      color: _numberOfSets < 10
                          ? _proverCore
                          : _comet.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
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
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _stellar.withOpacity(0.8),
            _stellar.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _lunar.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showModernNumberPicker(
                  context,
                  'MINIMUM',
                  minValue,
                  minLimit,
                  maxValue,
                  onMinChanged,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
                child: Container(
                  height: 50,
                  child: Center(
                    child: Text(
                      '$minValue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _nova,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 32,
            child: Center(
              child: Container(
                width: 20,
                height: 2,
                decoration: BoxDecoration(
                  color: _comet,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showModernNumberPicker(
                  context,
                  'MAXIMUM',
                  maxValue,
                  minValue,
                  maxLimit,
                  onMaxChanged,
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                child: Container(
                  height: 50,
                  child: Center(
                    child: Text(
                      '$maxValue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _nova,
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
  }

  Widget _buildIncrementSelector() {
    return GestureDetector(
      onTap: () => _showIncrementPicker(context),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _stellar.withOpacity(0.8),
              _stellar.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _lunar.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            '${_standardIncrease.toStringAsFixed(_standardIncrease == _standardIncrease.roundToDouble() ? 0 : 1)} kg',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _nova,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestPeriodSelector() {
    return GestureDetector(
      onTap: () => _showRestPeriodPicker(context),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _stellar.withOpacity(0.8),
              _stellar.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _lunar.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            _formatRestPeriod(_restPeriodSeconds),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _nova,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressionProfileSelector(ProgressionManagerProvider provider) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _stellar.withOpacity(0.8),
            _stellar.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _lunar.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedProfileId,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        hint: Text(
          'Kein Profil ausgewählt',
          style: TextStyle(
            color: _comet,
            fontSize: 16,
          ),
        ),
        style: TextStyle(
          color: _nova,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        dropdownColor: _stellar,
        icon: Icon(
          Icons.expand_more_rounded,
          color: _proverCore,
          size: 24,
        ),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text(
              'Kein Profil',
              style: TextStyle(color: _comet),
            ),
          ),
          ...provider.progressionsProfile.map((profile) {
            return DropdownMenuItem<String>(
              value: profile.id,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _proverCore,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    profile.name,
                    style: TextStyle(
                      color: _nova,
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
    );
  }

  void _showModernNumberPicker(
    BuildContext context,
    String title,
    int currentValue,
    int min,
    int max,
    Function(int) onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        int tempValue = currentValue;
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_stellar, _nebula],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(
                  color: _lunar.withOpacity(0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(20),
              height: 400,
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _lunar,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_proverCore, _proverGlow],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: _nova,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: _nova,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, size: 22, color: _stardust),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListWheelScrollView(
                      itemExtent: 60,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(
                        initialItem: currentValue - min,
                      ),
                      onSelectedItemChanged: (index) {
                        HapticFeedback.selectionClick();
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
                                fontSize: isSelected ? 32 : 22,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                color: isSelected ? _proverCore : _stardust,
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
                      gradient: LinearGradient(
                        colors: [_proverCore, _proverGlow],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _proverCore.withOpacity(0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          onSelected(tempValue);
                          Navigator.pop(context);
                          HapticFeedback.lightImpact();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'AUSWÄHLEN',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _nova,
                                letterSpacing: 1.5,
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        double tempValue = _standardIncrease;
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_stellar, _nebula],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(
                  color: _lunar.withOpacity(0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(20),
              height: 400,
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _lunar,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_proverCore, _proverGlow],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.trending_up_rounded,
                          color: _nova,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'STANDARD-ERHÖHUNG',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: _nova,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, size: 22, color: _stardust),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListWheelScrollView(
                      itemExtent: 60,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(
                        initialItem: increments.indexOf(_standardIncrease),
                      ),
                      onSelectedItemChanged: (index) {
                        HapticFeedback.selectionClick();
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
                              fontSize: isSelected ? 32 : 22,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              color: isSelected ? _proverCore : _stardust,
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
                      gradient: LinearGradient(
                        colors: [_proverCore, _proverGlow],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _proverCore.withOpacity(0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
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
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'AUSWÄHLEN',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _nova,
                                letterSpacing: 1.5,
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        int tempValue = _restPeriodSeconds;
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_stellar, _nebula],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(
                  color: _lunar.withOpacity(0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(20),
              height: 400,
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _lunar,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_proverCore, _proverGlow],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.timer_outlined,
                          color: _nova,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'PAUSENZEIT',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: _nova,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, size: 22, color: _stardust),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListWheelScrollView(
                      itemExtent: 60,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(
                        initialItem: restPeriods.indexOf(_restPeriodSeconds),
                      ),
                      onSelectedItemChanged: (index) {
                        HapticFeedback.selectionClick();
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
                              fontSize: isSelected ? 32 : 22,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              color: isSelected ? _proverCore : _stardust,
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
                      gradient: LinearGradient(
                        colors: [_proverCore, _proverGlow],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _proverCore.withOpacity(0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
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
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'AUSWÄHLEN',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _nova,
                                letterSpacing: 1.5,
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