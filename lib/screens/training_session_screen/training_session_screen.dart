// lib/screens/training_session_screen/training_session_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';

import '../../models/training_plan_screen/training_plan_model.dart';
import '../../models/progression_manager_screen/training_set_model.dart';
import '../../providers/training_session_screen/training_session_provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../providers/shared/navigation_provider.dart';
import '../main_screen.dart';
import '../../widgets/training_session_screen/exercise_tab_widget.dart';
import '../../widgets/training_session_screen/rest_timer_widget.dart';
import '../../widgets/training_session_screen/training_completion_widget.dart';
import '../../widgets/create_training_plan_screen/exercise_form_widget.dart';

class TrainingSessionScreen extends StatefulWidget {
  final TrainingPlanModel trainingPlan;
  final int dayIndex;
  final int weekIndex; // Neuer Parameter für den Mikrozyklus
  final bool isRecoveredSession; // Neuer Parameter für wiederhergestellte Sessions

  const TrainingSessionScreen({
    Key? key,
    required this.trainingPlan,
    required this.dayIndex,
    this.weekIndex = 0, // Standard: erste Woche
    this.isRecoveredSession = false, // Standard: neue Session
  }) : super(key: key);

  @override
  State<TrainingSessionScreen> createState() => _TrainingSessionScreenState();
}

class _TrainingSessionScreenState extends State<TrainingSessionScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  bool _initialized = false;
  bool _startupComplete = false;
  bool _isLoading = true;
  int _lastKnownExerciseIndex = 0;
  bool _showExerciseDetails = true;
  bool _isNavigatingExercises = false;

  // Animation controllers for smooth exercise navigation
  late AnimationController _exerciseNavAnimationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Screen entrance animation controller for smooth transitions
  late AnimationController _screenEntranceController;
  late Animation<double> _screenOpacityAnimation;
  late Animation<double> _screenSlideAnimation;

  // Clean color system matching training screen
  static const Color _midnight = Color(0xFF000000);
  static const Color _charcoal = Color(0xFF1C1C1E);
  static const Color _graphite = Color(0xFF2C2C2E);
  static const Color _steel = Color(0xFF48484A);
  static const Color _mercury = Color(0xFF8E8E93);
  static const Color _silver = Color(0xFFAEAEB2);
  static const Color _snow = Color(0xFFFFFFFF);
  static const Color _emberCore = Color(0xFFFF4500);

  @override
  void initState() {
    super.initState();

    // IMMEDIATE dark system UI to prevent ANY white flashing
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: _midnight,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: _midnight,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    
    // Force immersive mode immediately to prevent any system UI during loading
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Initialize exercise navigation animation controller
    _exerciseNavAnimationController = AnimationController(
      duration: const Duration(milliseconds: 450), // Slightly longer for smoother feel
      vsync: this,
    );

    // Initialize screen entrance animation controller
    _screenEntranceController = AnimationController(
      duration: const Duration(milliseconds: 800), // Longer for smoother entrance
      vsync: this,
    );

    // Create slide animation (from button area downwards)
    _slideAnimation = Tween<double>(
      begin: -0.8, // Start closer to button area, not completely off-screen
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _exerciseNavAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Create fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _exerciseNavAnimationController,
      curve: Curves.easeOut,
    ));

    // Create scale animation (slight scale-up effect)
    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _exerciseNavAnimationController,
      curve: Curves.easeOutBack, // Elastic feeling
    ));

    // Create screen entrance animations
    _screenOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _screenEntranceController,
      curve: Curves.easeOut,
    ));

    _screenSlideAnimation = Tween<double>(
      begin: 20.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _screenEntranceController,
      curve: Curves.easeOutCubic,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSessionWithDelay();
    });
  }

  Future<void> _initializeSessionWithDelay() async {
    try {
      // Minimale Verzögerung für nahtlosen Übergang
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      final sessionProvider =
          Provider.of<TrainingSessionProvider>(context, listen: false);

      // Prüfe ob es eine wiederhergestellte Session ist
      if (!widget.isRecoveredSession) {
        // Normale neue Session - starte Training
        await sessionProvider.startTrainingSession(
            widget.trainingPlan, widget.dayIndex, widget.weekIndex);
      }
      // Bei wiederhergestellter Session: Provider hat bereits alle Daten geladen

      if (mounted) {
        _initializeTabController();
        
        setState(() {
          _startupComplete = true;
          _isLoading = false;
          _lastKnownExerciseIndex = sessionProvider.currentExerciseIndex;
        });
        
        // Start screen entrance animation immediately
        _screenEntranceController.forward();
      }
    } catch (e) {
      print('Fehler bei der Initialisierung der Trainingssession: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _initializeTabController() {
    try {
      final sessionProvider =
          Provider.of<TrainingSessionProvider>(context, listen: false);
      final exerciseCount = sessionProvider.exercises.length;

      if (exerciseCount > 0) {
        setState(() {
          _tabController = TabController(
            length: exerciseCount,
            vsync: this,
          );

          _tabController!.addListener(() {
            if (!_tabController!.indexIsChanging) {
              sessionProvider.selectExercise(_tabController!.index);
            }
          });

          _initialized = true;
        });
      }
    } catch (e) {
      print('Fehler bei der Initialisierung des TabControllers: $e');
    }
  }

  // Methode zum Neuerstellen des TabControllers nach dem Löschen einer Übung
  void _recreateTabController() {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    // Verzögerung hinzufügen, damit alle vorherigen Updates abgeschlossen werden
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      try {
        final sessionProvider =
            Provider.of<TrainingSessionProvider>(context, listen: false);
        final exerciseCount = sessionProvider.exercises.length;

        // Alten Controller bereinigen
        _tabController?.dispose();
        _tabController = null;

        // Neuen Controller erstellen
        if (exerciseCount > 0) {
          _tabController = TabController(
            length: exerciseCount,
            vsync: this,
          );

          _tabController!.addListener(() {
            if (!_tabController!.indexIsChanging) {
              sessionProvider.selectExercise(_tabController!.index);
            }
          });

          // Animation zum nächsten Tab
          _tabController!.animateTo(sessionProvider.currentExerciseIndex);
        }

        if (mounted) {
          setState(() {
            _initialized = true;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Fehler bei TabController-Aktualisierung: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _exerciseNavAnimationController.dispose();
    _screenEntranceController.dispose();

    // Reset system UI to default when leaving
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: _midnight,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    super.dispose();
  }

  void _syncTabWithCurrentExercise(TrainingSessionProvider sessionProvider) {
    if (_tabController == null) return;

    if (sessionProvider.currentExerciseIndex < _tabController!.length) {
      if (_tabController!.index != sessionProvider.currentExerciseIndex) {
        _tabController!.animateTo(sessionProvider.currentExerciseIndex);
        _lastKnownExerciseIndex = sessionProvider.currentExerciseIndex;
      }
    }
  }

  void _toggleExerciseDetails() {
    setState(() {
      _showExerciseDetails = !_showExerciseDetails;

      // Provide haptic feedback for the toggle
      HapticFeedback.lightImpact();
    });
  }

  void _toggleExerciseNavigation() {
    setState(() {
      _isNavigatingExercises = !_isNavigatingExercises;
    });

    // Animate based on new state
    if (_isNavigatingExercises) {
      _exerciseNavAnimationController.forward();
    } else {
      _exerciseNavAnimationController.reverse();
    }

    // Provide haptic feedback for the toggle
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    // Vollständig abgedichteter loading state gegen weiße Ränder
    if (_isLoading || !_startupComplete) {
      return Container(
        color: _midnight, // Root container for edge protection
        child: Material(
          color: _midnight,
          child: Scaffold(
            backgroundColor: _midnight,
            extendBodyBehindAppBar: true,
            extendBody: true,
            body: Container(
              width: double.infinity,
              height: double.infinity,
              color: _midnight, // Zusätzliche Absicherung
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                // Elegant pulsing icon mit reversibler Animation
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1000),
                  tween: Tween(begin: 0.9, end: 1.0),
                  onEnd: () {
                    // Kontinuierliches Pulsing durch Rebuild
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _emberCore.withOpacity(0.08),
                          border: Border.all(
                            color: _emberCore.withOpacity(0.25), 
                            width: 1
                          ),
                        ),
                        child: Icon(
                          Icons.fitness_center_rounded,
                          size: 28,
                          color: _emberCore,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Clean title text mit expliziter Textdefinition
                Text(
                  widget.isRecoveredSession 
                    ? 'Session wiederherstellen'
                    : 'Training starten',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: _snow,
                    letterSpacing: -0.3,
                    decoration: TextDecoration.none, // Explizit keine Unterstreichung
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Minimaler progress indicator
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(_emberCore.withOpacity(0.4)),
                    backgroundColor: Colors.transparent,
                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _screenEntranceController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _screenSlideAnimation.value),
          child: Opacity(
            opacity: _screenOpacityAnimation.value,
            child: Consumer<TrainingSessionProvider>(
              builder: (context, sessionProvider, child) {
        if (sessionProvider.isTrainingCompleted) {
          return const TrainingCompletionWidget();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _syncTabWithCurrentExercise(sessionProvider);
        });

        final bool allSetsCompleted =
            sessionProvider.areAllSetsCompletedForCurrentExercise();
        final bool hasMoreExercises =
            sessionProvider.hasMoreExercisesAfterCurrent();
        final exercise =
            sessionProvider.exercises[sessionProvider.currentExerciseIndex];

        // Mikrozyklus-Anzeige erstellen (falls periodisiert)
        Widget? microcycleIndicator;
        if (widget.trainingPlan.isPeriodized) {
          microcycleIndicator = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _emberCore.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _emberCore.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 12, color: _emberCore),
                const SizedBox(width: 4),
                Text(
                  'Woche ${widget.weekIndex + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _emberCore,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: _midnight,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight + 50),
            child: Container(
              color: _midnight,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Main App Bar
                    Container(
                      height: kToolbarHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          const SizedBox(width: 44), // Balance for close button

                          // Title
                          Expanded(
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    sessionProvider.trainingDay?.name ?? "",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: _snow,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  if (microcycleIndicator != null) ...[
                                    const SizedBox(width: 8),
                                    microcycleIndicator,
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Close button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showExitConfirmation(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: _snow,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Exercise navigation indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: _toggleExerciseNavigation,
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _isNavigatingExercises
                                ? _emberCore.withOpacity(0.15)
                                : _charcoal.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isNavigatingExercises
                                  ? _emberCore.withOpacity(0.6)
                                  : _steel.withOpacity(0.2),
                              width: _isNavigatingExercises ? 2 : 1,
                            ),
                            boxShadow: _isNavigatingExercises 
                                ? [
                                    BoxShadow(
                                      color: _emberCore.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              // Exercise number indicator
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _emberCore.withOpacity(0.15),
                                  border: Border.all(color: _emberCore.withOpacity(0.4)),
                                ),
                                child: Center(
                                  child: Text(
                                    '${sessionProvider.currentExerciseIndex + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _emberCore,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  exercise.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _snow,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _isNavigatingExercises
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: _silver,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              // Main content
              Column(
                children: [
                  // Rest timer with smooth transitions
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: sessionProvider.isResting ? null : 0,
                    curve: Curves.easeInOut,
                    child: sessionProvider.isResting
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 16.0),
                            child: RestTimerWidget(),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Exercise content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(
                        sessionProvider.exercises.length,
                        (index) => ExerciseTabWidget(
                          exerciseIndex: index,
                          showDetails: _showExerciseDetails,
                          onExerciseRemoved:
                              _recreateTabController, // Callback übergeben
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Animated exercise navigation overlay
              _buildAnimatedExerciseNavigationOverlay(sessionProvider),
            ],
          ),
          bottomNavigationBar: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: _isNavigatingExercises ? 0 : null,
            child: Container(
              color: _midnight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress indicator
                  LinearProgressIndicator(
                    value: sessionProvider.trainingProgress,
                    minHeight: 3,
                    backgroundColor: _charcoal,
                    color: _emberCore,
                  ),

                  // Action button
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            if (allSetsCompleted && !hasMoreExercises) {
                              sessionProvider.completeCurrentExercise();
                            } else {
                              sessionProvider.completeCurrentSet();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _emberCore,
                            foregroundColor: _snow,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            allSetsCompleted && !hasMoreExercises
                                ? 'TRAINING ABSCHLIESSEN'
                                : 'SATZ ABSCHLIESSEN',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
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
        );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedExerciseNavigationOverlay(
      TrainingSessionProvider sessionProvider) {
    return AnimatedBuilder(
      animation: _exerciseNavAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * MediaQuery.of(context).size.height),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.topCenter, // Scale from button area
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: IgnorePointer(
                ignoring: !_isNavigatingExercises,
                child: GestureDetector(
                  onTap: _toggleExerciseNavigation,
                  child: Container(
                    color: _midnight.withOpacity(0.95 * _fadeAnimation.value),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
              children: [
                // Navigation title
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: const Text(
                    'Übung wechseln',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: _snow,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                // Exercise list
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: sessionProvider.exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = sessionProvider.exercises[index];
                      final isCurrentExercise =
                          index == sessionProvider.currentExerciseIndex;
                      final isCompleted =
                          sessionProvider.isExerciseCompleted(index);

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _tabController?.animateTo(index);
                          sessionProvider.selectExercise(index);
                          Future.delayed(const Duration(milliseconds: 200),
                              _toggleExerciseNavigation);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isCurrentExercise
                                ? _charcoal.withOpacity(0.95)
                                : _charcoal.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCurrentExercise
                                  ? _emberCore
                                  : _steel.withOpacity(0.3),
                              width: isCurrentExercise ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Status icon
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCompleted
                                      ? Colors.green.withOpacity(0.15)
                                      : isCurrentExercise
                                          ? _emberCore.withOpacity(0.15)
                                          : _steel.withOpacity(0.3),
                                  border: Border.all(
                                    color: isCompleted
                                        ? Colors.green
                                        : isCurrentExercise
                                            ? _emberCore
                                            : _steel.withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    isCompleted
                                        ? Icons.check_rounded
                                        : isCurrentExercise
                                            ? Icons.trending_up_rounded
                                            : Icons.fitness_center_rounded,
                                    size: 20,
                                    color: isCompleted
                                        ? Colors.green
                                        : isCurrentExercise
                                            ? _emberCore
                                            : _mercury,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Exercise details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Exercise number badge
                                        Container(
                                          margin: const EdgeInsets.only(right: 10),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isCurrentExercise 
                                                ? _emberCore.withOpacity(0.15)
                                                : _steel.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isCurrentExercise 
                                                  ? _emberCore.withOpacity(0.4)
                                                  : _steel.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isCurrentExercise ? _emberCore : _silver,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            exercise.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: isCurrentExercise ? _snow : _silver,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 36), // Align with exercise name
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${exercise.primaryMuscleGroup}${exercise.secondaryMuscleGroup.isNotEmpty ? ' • ${exercise.secondaryMuscleGroup}' : ''}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: _mercury,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          // Status badge
                                          if (isCompleted)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                    color: Colors.green.withOpacity(0.3)),
                                              ),
                                              child: const Text(
                                                'FERTIG',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.green,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            )
                                          else if (isCurrentExercise)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _emberCore.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                    color: _emberCore.withOpacity(0.3)),
                                              ),
                                              child: const Text(
                                                'AKTIV',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: _emberCore,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Add Exercise Button
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    _toggleExerciseNavigation();
                    _showAddExerciseDialog(context, sessionProvider);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _charcoal.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _steel.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _emberCore.withOpacity(0.15),
                            border:
                                Border.all(color: _emberCore.withOpacity(0.4)),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: _emberCore,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Neue Übung hinzufügen',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _snow,
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
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // NEU: Dialog zum Hinzufügen einer Übung anzeigen
  void _showAddExerciseDialog(
      BuildContext context, TrainingSessionProvider sessionProvider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ExerciseFormWidget(
          onSave: (exercise) async {
            await sessionProvider.addNewExerciseToSession(exercise);

            // TabController aktualisieren
            if (_initialized && _tabController != null) {
              final exerciseCount = sessionProvider.exercises.length;

              // TabController neu erstellen mit neuer Anzahl an Übungen
              _tabController!.dispose();
              _tabController = TabController(
                length: exerciseCount,
                vsync: this,
              );

              // Zum neuen Tab navigieren
              _tabController!.animateTo(exerciseCount - 1);
              sessionProvider.selectExercise(exerciseCount - 1);
            }

            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showActionsMenu(
      BuildContext context, TrainingSessionProvider sessionProvider) {
    HapticFeedback.mediumImpact();

    final bool hasCompletedSets =
        _hasCompletedSets(sessionProvider.currentExerciseSets);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(
          color: _charcoal,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: _steel.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Übungsoptionen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _snow,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),

              // Übungsdetails-Bereich
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: const Text(
                        "Übungsinformationen",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _silver,
                        ),
                      ),
                    ),
                    // Übungsdetails anzeigen/ausblenden
                    _buildActionButton(
                      icon: _showExerciseDetails
                          ? Icons.visibility_off
                          : Icons.visibility,
                      label: _showExerciseDetails
                          ? 'Übungsdetails ausblenden'
                          : 'Übungsdetails anzeigen',
                      onTap: () {
                        _toggleExerciseDetails();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),

              // Satz-Optionen
              Container(
                margin: const EdgeInsets.only(bottom: 12, top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: const Text(
                        "Satz-Optionen",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _silver,
                        ),
                      ),
                    ),
                    // Satz reaktivieren - wird angezeigt, wenn es abgeschlossene Sätze gibt
                    if (hasCompletedSets)
                      _buildActionButton(
                        icon: Icons.replay_rounded,
                        label: 'Letzten Satz reaktivieren',
                        onTap: () {
                          sessionProvider.reactivateLastCompletedSet(
                              sessionProvider.currentExerciseIndex);
                          Navigator.pop(context);
                        },
                      ),

                    // Add set
                    _buildActionButton(
                      icon: Icons.add_circle_outline,
                      label: 'Satz hinzufügen',
                      onTap: () {
                        sessionProvider.addSetToCurrentExercise();
                        Navigator.pop(context);
                      },
                    ),

                    // Remove set
                    _buildActionButton(
                      icon: Icons.remove_circle_outline,
                      label: 'Satz entfernen',
                      onTap: () {
                        sessionProvider.removeSetFromCurrentExercise();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _steel.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: _emberCore,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _snow,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasCompletedSets(List<TrainingSetModel> sets) {
    for (final set in sets) {
      if (set.abgeschlossen) {
        return true;
      }
    }
    return false;
  }

  void _showExitConfirmation(BuildContext context) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_charcoal, _midnight],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: _steel.withOpacity(0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header mit Titel
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red, Colors.red.shade400],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.exit_to_app,
                        color: _snow,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Training beenden',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: _snow,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, size: 22, color: _silver),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Dein Fortschritt wird gespeichert, aber das Training wird als nicht abgeschlossen markiert.',
                  style: TextStyle(
                    fontSize: 15,
                    color: _silver,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Option: Training beenden
                _buildExitOptionButton(
                  icon: Icons.exit_to_app,
                  label: 'Training beenden',
                  onTap: () async {
                    // BUGFIX: Provider VOR Navigation speichern
                    final sessionProvider = Provider.of<TrainingSessionProvider>(context, listen: false);
                    final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
                    final navigator = Navigator.of(context);
                    
                    // Dialog schließen
                    navigator.pop();
                    
                    // BUGFIX: Navigation Tab SOFORT setzen
                    navigationProvider.setCurrentIndex(0);
                    
                    // BUGFIX: Navigation SOFORT ausführen BEVOR exitTrainingEarly
                    navigator.pushAndRemoveUntil(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return const MainScreen();
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: Tween<double>(
                              begin: 0.0,
                              end: 1.0,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            )),
                            child: child,
                          );
                        },
                      ),
                      (route) => false, // Remove all previous routes
                    );
                    
                    // Session cleanup NACH der Navigation
                    try {
                      await sessionProvider.exitTrainingEarly();
                    } catch (e) {
                      print('Fehler beim Beenden des Trainings: $e');
                      
                      // Auch bei Fehlern die Session löschen
                      try {
                        await sessionProvider.clearSavedSession();
                      } catch (clearError) {
                        print('Fehler beim Löschen der Session: $clearError');
                      }
                    }
                  },
                  isPrimary: false,
                  isDestructive: true,
                ),

                const SizedBox(height: 12),

                // Option: Weiter trainieren
                _buildExitOptionButton(
                  icon: Icons.fitness_center,
                  label: 'Weiter trainieren',
                  onTap: () => Navigator.of(context).pop(),
                  isPrimary: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExitOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(colors: [_emberCore, _emberCore.withOpacity(0.8)])
            : LinearGradient(
                colors: [_steel.withOpacity(0.3), _steel.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrimary
              ? _emberCore.withOpacity(0.5)
              : isDestructive
                  ? Colors.red.withOpacity(0.4)
                  : _steel.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isPrimary 
                      ? _snow 
                      : isDestructive 
                          ? Colors.red 
                          : _silver,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                    color: isPrimary 
                        ? _snow 
                        : isDestructive 
                            ? Colors.red 
                            : _silver,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}