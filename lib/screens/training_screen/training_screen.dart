// lib/screens/training_screen/training_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/training_plan_screen/training_plan_model.dart';
import '../../providers/shared/navigation_provider.dart';
import '../../providers/training_plans_screen/training_plans_screen_provider.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';
import '../../providers/training_session_screen/training_session_provider.dart';
import '../../services/training/session_recovery_service.dart';
import '../create_training_plan_screen/create_training_plan_screen.dart';
import '../create_training_plan_screen/training_day_editor_screen.dart';
import '../training_session_screen/training_session_screen.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Clean, focused color system
  static const Color _midnight = Color(0xFF000000);
  static const Color _charcoal = Color(0xFF1C1C1E);
  static const Color _graphite = Color(0xFF2C2C2E);
  static const Color _steel = Color(0xFF48484A);
  static const Color _mercury = Color(0xFF8E8E93);
  static const Color _silver = Color(0xFFAEAEB2);
  static const Color _snow = Color(0xFFFFFFFF);
  
  // Single orange accent
  static const Color _emberCore = Color(0xFFFF4500);

  bool _sessionRecoveryChecked = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();
    
    // Session-Recovery Check nach dem ersten Frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForSessionRecovery();
    });
  }

  Future<void> _checkForSessionRecovery() async {
    if (_sessionRecoveryChecked) return;
    _sessionRecoveryChecked = true;
    
    final trainingProvider = Provider.of<TrainingSessionProvider>(context, listen: false);
    await SessionRecoveryService.checkAndRecoverSession(context, trainingProvider);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plansProvider = Provider.of<TrainingPlansProvider>(context);
    final activePlan = plansProvider.activePlan;
    final isLoading = plansProvider.isLoading;

    return Scaffold(
      backgroundColor: _midnight,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: isLoading
            ? _buildLoadingView()
            : activePlan != null
                ? _buildActivePlanView(context, activePlan, plansProvider)
                : _buildEmptyStateView(context),
      ),
    );
  }

  Widget _buildActivePlanView(BuildContext context,
      TrainingPlanModel activePlan, TrainingPlansProvider plansProvider) {
    final currentWeekIndex = plansProvider.currentWeekIndex;

    return Column(
      children: [
        // Clean top header with essential info only
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clean header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activePlan.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: _snow,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 14, color: _silver),
                            const SizedBox(width: 6),
                            Text(
                              '${activePlan.days.length} Trainingstage',
                              style: TextStyle(
                                fontSize: 14,
                                color: _silver,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action buttons row
                  Row(
                    children: [
                      // Edit button
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _navigateToEditPlan(context, activePlan),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _charcoal.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _steel.withOpacity(0.3)),
                              ),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: _silver,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _emberCore.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _emberCore.withOpacity(0.3)),
                        ),
                        child: Text(
                          'AKTIV',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _emberCore,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Week selector if periodized
              if (activePlan.isPeriodized) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _charcoal.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _graphite.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Woche ${currentWeekIndex + 1} von ${activePlan.numberOfWeeks}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _silver,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(activePlan.numberOfWeeks, (weekIndex) {
                            final isActive = weekIndex == currentWeekIndex;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  plansProvider.setCurrentWeekIndex(weekIndex);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isActive ? _emberCore : _graphite.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${weekIndex + 1}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isActive ? _snow : _silver,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Main training days list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
            itemCount: activePlan.days.length,
            itemBuilder: (context, index) {
              final day = activePlan.days[index];
              final exerciseCount = day.exercises.length;
              final totalSets = _getTrainingDaySets(activePlan, index, currentWeekIndex);
              final isEmpty = exerciseCount == 0;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isEmpty ? null : () => _startTraining(context, activePlan, index, currentWeekIndex),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isEmpty ? _charcoal.withOpacity(0.4) : _charcoal.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isEmpty ? _steel.withOpacity(0.2) : _steel.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Day number
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isEmpty ? _steel.withOpacity(0.3) : _emberCore.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isEmpty ? _steel.withOpacity(0.4) : _emberCore.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isEmpty ? _mercury : _emberCore,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  day.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: isEmpty ? _mercury : _snow,
                                  ),
                                ),
                                
                                const SizedBox(height: 6),
                                
                                if (!isEmpty) ...[
                                  Text(
                                    '$exerciseCount Übungen • $totalSets Sätze',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _silver,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    'Keine Übungen',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _mercury.withOpacity(0.8),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          // Action
                          if (!isEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _emberCore,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'STARTEN',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _snow,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _emberCore.withOpacity(0.15),
              border: Border.all(color: _emberCore.withOpacity(0.4), width: 2),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              size: 30,
              color: _emberCore,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Lade Trainingspläne...',
            style: TextStyle(
              fontSize: 16,
              color: _silver,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 40,
            height: 2,
            child: LinearProgressIndicator(
              backgroundColor: _charcoal,
              valueColor: const AlwaysStoppedAnimation<Color>(_emberCore),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _emberCore.withOpacity(0.1),
                border: Border.all(color: _emberCore.withOpacity(0.3), width: 2),
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                size: 60,
                color: _emberCore,
              ),
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'Bereit für dein\nerstes Training?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: _snow,
                letterSpacing: -0.5,
                height: 1.2,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Erstelle deinen ersten Trainingsplan\nund beginne deine Fitness-Journey.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: _silver,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 48),
            
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CreateTrainingPlanScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _emberCore,
                  foregroundColor: _snow,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Plan erstellen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  final navigationProvider =
                      Provider.of<NavigationProvider>(context, listen: false);
                  navigationProvider.setCurrentIndex(2);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _emberCore,
                  side: BorderSide(color: _emberCore.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Bestehende Pläne',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditPlan(BuildContext context, TrainingPlanModel plan) {
    final createProvider =
        Provider.of<CreateTrainingPlanProvider>(context, listen: false);
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

  void _startTraining(BuildContext context, TrainingPlanModel plan, int dayIndex, int weekIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return ChangeNotifierProvider(
            create: (context) => TrainingSessionProvider(),
            child: TrainingSessionScreen(
              trainingPlan: plan,
              dayIndex: dayIndex,
              weekIndex: weekIndex,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Nur Background-Schutz, kein Layout-breaking Container
          return ColoredBox(
            color: const Color(0xFF000000), // Prevent white edges
            child: FadeTransition(
              opacity: Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  int _getTrainingDaySets(TrainingPlanModel activePlan, int dayIndex, int currentWeekIndex) {
    final day = activePlan.days[dayIndex];
    int totalSets = 0;

    if (activePlan.isPeriodized && activePlan.periodization != null) {
      for (var exercise in day.exercises) {
        final config = activePlan.getExerciseMicrocycle(
            exercise.id, dayIndex, currentWeekIndex);
        if (config != null) {
          totalSets += config.numberOfSets;
        } else {
          totalSets += exercise.numberOfSets;
        }
      }
    } else {
      for (var exercise in day.exercises) {
        totalSets += exercise.numberOfSets;
      }
    }
    return totalSets;
  }
}