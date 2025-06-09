// lib/widgets/training_session_screen/training_completion_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../providers/training_session_screen/training_session_provider.dart';
import '../../providers/shared/navigation_provider.dart';
import '../../screens/main_screen.dart';

class TrainingCompletionWidget extends StatefulWidget {
  const TrainingCompletionWidget({Key? key}) : super(key: key);

  @override
  State<TrainingCompletionWidget> createState() =>
      _TrainingCompletionWidgetState();
}

class _TrainingCompletionWidgetState extends State<TrainingCompletionWidget>
    with TickerProviderStateMixin {
  // Unified color system matching training session
  static const Color _midnight = Color(0xFF000000);
  static const Color _charcoal = Color(0xFF1C1C1E);
  static const Color _graphite = Color(0xFF2C2C2E);
  static const Color _steel = Color(0xFF48484A);
  static const Color _mercury = Color(0xFF8E8E93);
  static const Color _silver = Color(0xFFAEAEB2);
  static const Color _snow = Color(0xFFFFFFFF);
  static const Color _emberCore = Color(0xFFFF4500);

  bool _isSaving = false;
  bool _hasAskedForChanges = false;
  bool _hasAskedForAddedExercises = false;
  bool _hasAskedForDeletedExercises = false;
  bool _saveCompleted = false;

  // Enhanced animation system
  late AnimationController _masterController;
  late AnimationController _successPulseController;
  late AnimationController _statsController;
  late AnimationController _actionsController;
  
  // Entrance animations
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideUpAnimation;
  late Animation<double> _scaleAnimation;
  
  // Success indicator animations
  late Animation<double> _successScaleAnimation;
  late Animation<double> _successPulseAnimation;
  late Animation<double> _successRotationAnimation;
  
  // Stats reveal animations
  late Animation<double> _statsSlideAnimation;
  late Animation<double> _statsFadeAnimation;
  
  // Action buttons animations
  late Animation<double> _actionsSlideAnimation;
  late Animation<double> _actionsFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Immediate dark UI
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: _midnight,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: _midnight,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    _initializeAnimations();
    _startAnimationSequence();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveTrainingAndCheckForChanges();
    });
  }

  void _initializeAnimations() {
    // Master controller for overall entrance
    _masterController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Success pulse controller
    _successPulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Stats controller
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Actions controller
    _actionsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Define entrance animations
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideUpAnimation = Tween<double>(
      begin: 80.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));

    // Success indicator animations
    _successScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.3, 0.8, curve: Curves.elasticOut),
    ));

    _successPulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _successPulseController,
      curve: Curves.easeInOut,
    ));

    _successRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.4, 0.9, curve: Curves.easeOutBack),
    ));

    // Stats animations
    _statsSlideAnimation = Tween<double>(
      begin: 40.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _statsController,
      curve: Curves.easeOutCubic,
    ));

    _statsFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statsController,
      curve: Curves.easeOut,
    ));

    // Actions animations
    _actionsSlideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _actionsController,
      curve: Curves.easeOutCubic,
    ));

    _actionsFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _actionsController,
      curve: Curves.easeOut,
    ));
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _masterController.forward();
      
      // Start continuous pulse for success indicator
      _successPulseController.repeat(reverse: true);
      
      // Stagger additional animations
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) _statsController.forward();
      
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _actionsController.forward();
    }
  }

  @override
  void dispose() {
    _masterController.dispose();
    _successPulseController.dispose();
    _statsController.dispose();
    _actionsController.dispose();
    super.dispose();
  }

  Future<void> _saveTrainingAndCheckForChanges() async {
    if (!mounted) return;

    final sessionProvider =
        Provider.of<TrainingSessionProvider>(context, listen: false);

    // Save the training first
    await sessionProvider.completeTraining();

    if (mounted) {
      setState(() {
        _saveCompleted = true;
      });

      // Wait for initial animations to complete before showing dialogs
      await Future.delayed(const Duration(milliseconds: 1800));
      
      if (!mounted) return;

      // Check for changes sequentially with proper UX flow
      await _checkForChangesSequentially(sessionProvider);
    }
  }

  Future<void> _checkForChangesSequentially(TrainingSessionProvider sessionProvider) async {
    // Check for added exercises first
    if (sessionProvider.hasAddedExercises && !_hasAskedForAddedExercises) {
      await _showSaveAddedExercisesDialog(sessionProvider);
      setState(() {
        _hasAskedForAddedExercises = true;
      });
      if (!mounted) return;
    }

    // Then check for deleted exercises
    if (sessionProvider.hasDeletedExercises && !_hasAskedForDeletedExercises) {
      await _showSaveDeletedExercisesDialog(sessionProvider);
      setState(() {
        _hasAskedForDeletedExercises = true;
      });
      if (!mounted) return;
    }

    // Finally check for modified exercises
    if (sessionProvider.hasModifiedExercises && !_hasAskedForChanges) {
      await _showSaveChangesDialog(sessionProvider);
      setState(() {
        _hasAskedForChanges = true;
      });
    }
  }

  Future<void> _showSaveChangesDialog(TrainingSessionProvider sessionProvider) async {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: _midnight.withOpacity(0.95),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _charcoal,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _steel.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _midnight.withOpacity(0.6),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon and title
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _emberCore.withOpacity(0.15),
                  border: Border.all(
                    color: _emberCore.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.save_rounded,
                  size: 32,
                  color: _emberCore,
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Änderungen speichern?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _snow,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Du hast Änderungen an Übungen vorgenommen. Möchtest du diese in deinem Trainingsplan speichern?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _silver,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _graphite,
                          foregroundColor: _silver,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: _steel.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Verwerfen',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          await _saveChangesToTrainingPlanWithFeedback(sessionProvider);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _emberCore,
                          foregroundColor: _snow,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Speichern',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NEU: Dialog zur Speicherung hinzugefügter Übungen anzeigen
  Future<void> _showSaveAddedExercisesDialog(TrainingSessionProvider sessionProvider) async {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: _midnight.withOpacity(0.95),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _charcoal,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _steel.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _midnight.withOpacity(0.6),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon and title
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _emberCore.withOpacity(0.15),
                  border: Border.all(
                    color: _emberCore.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.add_circle_outline_rounded,
                  size: 32,
                  color: _emberCore,
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Neue Übungen speichern?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _snow,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Du hast neue Übungen hinzugefügt. Möchtest du diese dauerhaft in deinem Trainingsplan speichern?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _silver,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _graphite,
                          foregroundColor: _silver,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: _steel.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Verwerfen',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          await _saveAddedExercisesToTrainingPlanWithFeedback(sessionProvider);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _emberCore,
                          foregroundColor: _snow,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Speichern',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NEU: Dialog zum Speichern gelöschter Übungen
  Future<void> _showSaveDeletedExercisesDialog(
      TrainingSessionProvider sessionProvider) async {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: _midnight.withOpacity(0.95),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _charcoal,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _steel.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _midnight.withOpacity(0.6),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon and title
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.15),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 32,
                  color: Colors.red[400],
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Gelöschte Übungen speichern?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _snow,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Du hast Übungen gelöscht. Möchtest du diese Änderungen dauerhaft in deinem Trainingsplan speichern?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _silver,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _graphite,
                          foregroundColor: _silver,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: _steel.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Verwerfen',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          await _saveDeletedExercisesToTrainingPlanWithFeedback(sessionProvider);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: _snow,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Speichern',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced feedback methods with proper UX
  Future<void> _saveChangesToTrainingPlanWithFeedback(TrainingSessionProvider sessionProvider) async {
    try {
      final success = await sessionProvider.saveModificationsToTrainingPlan();
      if (mounted) {
        _showInlineSuccessMessage(success ? 'Änderungen gespeichert' : 'Fehler beim Speichern');
      }
    } catch (e) {
      if (mounted) {
        _showInlineSuccessMessage('Fehler beim Speichern');
      }
    }
  }

  Future<void> _saveAddedExercisesToTrainingPlanWithFeedback(TrainingSessionProvider sessionProvider) async {
    try {
      final success = await sessionProvider.saveAddedExercisesToTrainingPlan();
      if (mounted) {
        _showInlineSuccessMessage(success ? 'Neue Übungen gespeichert' : 'Fehler beim Speichern');
      }
    } catch (e) {
      if (mounted) {
        _showInlineSuccessMessage('Fehler beim Speichern');
      }
    }
  }

  Future<void> _saveDeletedExercisesToTrainingPlanWithFeedback(TrainingSessionProvider sessionProvider) async {
    try {
      final success = await sessionProvider.saveDeletedExercisesToTrainingPlan();
      if (mounted) {
        _showInlineSuccessMessage(success ? 'Änderungen gespeichert' : 'Fehler beim Speichern');
      }
    } catch (e) {
      if (mounted) {
        _showInlineSuccessMessage('Fehler beim Speichern');
      }
    }
  }

  void _showInlineSuccessMessage(String message) {
    // Show elegant inline success message that matches the design
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 60,
        left: 24,
        right: 24,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: _charcoal,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _emberCore.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _midnight.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _emberCore.withOpacity(0.15),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: _emberCore,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _snow,
                          decoration: TextDecoration.none,
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
    
    overlay.insert(overlayEntry);
    
    // Remove after delay
    Future.delayed(const Duration(milliseconds: 2000), () {
      overlayEntry.remove();
    });
  }




  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<TrainingSessionProvider>(context);
    final trainingPlan = sessionProvider.trainingPlan;
    final trainingDay = sessionProvider.trainingDay;

    if (trainingPlan == null || trainingDay == null) {
      return _buildLoadingState('Training laden...');
    }

    if (!_saveCompleted) {
      return _buildLoadingState('Training speichern...');
    }

    if (_isSaving) {
      return _buildLoadingState('Änderungen speichern...');
    }

    // Calculate training stats
    final totalExercises = trainingDay.exercises.length;
    int totalSets = 0;
    for (final exercise in trainingDay.exercises) {
      totalSets += exercise.numberOfSets;
    }

    return Container(
      color: _midnight,
      child: Scaffold(
        backgroundColor: _midnight,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: AnimatedBuilder(
          animation: _masterController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideUpAnimation.value),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeInAnimation.value,
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Main content - scrollable
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              child: Column(
                                children: [
                                  const SizedBox(height: 40),
                                  
                                  // Sophisticated success indicator
                                  _buildSuccessIndicator(),
                                  
                                  const SizedBox(height: 48),
                                  
                                  // Elegant completion message
                                  _buildCompletionMessage(),
                                  
                                  const SizedBox(height: 56),
                                  
                                  // Animated training stats
                                  _buildTrainingStats(trainingPlan, trainingDay, totalExercises, totalSets),
                                  
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Fixed bottom button
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: _buildActionButtons(sessionProvider),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(String message) {
    return Container(
      color: _midnight,
      child: Material(
        color: _midnight,
        child: Scaffold(
          backgroundColor: _midnight,
          extendBodyBehindAppBar: true,
          extendBody: true,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            color: _midnight,
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1000),
                      tween: Tween(begin: 0.9, end: 1.0),
                      onEnd: () {
                        if (mounted) setState(() {});
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
                            child: const Icon(
                              Icons.fitness_center_rounded,
                              size: 28,
                              color: _emberCore,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: _snow,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
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

  Widget _buildSuccessIndicator() {
    return AnimatedBuilder(
      animation: Listenable.merge([_successPulseController, _masterController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _successScaleAnimation.value * _successPulseAnimation.value,
          child: Transform.rotate(
            angle: _successRotationAnimation.value * 2 * math.pi,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _emberCore.withOpacity(0.15),
                    _emberCore.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _emberCore.withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _charcoal,
                  border: Border.all(
                    color: _emberCore.withOpacity(0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _midnight.withOpacity(0.8),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    size: 60,
                    color: _emberCore,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletionMessage() {
    return Column(
      children: [
        const Text(
          'TRAINING\nERFOLGREICH',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _snow,
            letterSpacing: 1.2,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                _emberCore.withOpacity(0.8),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Dein Training wurde abgeschlossen',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _silver,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTrainingStats(dynamic trainingPlan, dynamic trainingDay, int totalExercises, int totalSets) {
    return AnimatedBuilder(
      animation: _statsController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _statsSlideAnimation.value),
          child: Opacity(
            opacity: _statsFadeAnimation.value,
            child: Column(
              children: [
                // Clean stats grid with duration
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        Icons.fitness_center_rounded,
                        totalExercises.toString(),
                        'Übungen',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        Icons.repeat_rounded,
                        totalSets.toString(),
                        'Sätze',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        Icons.timer_rounded,
                        _getFormattedDuration(),
                        'Dauer',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getFormattedDuration() {
    final sessionProvider = Provider.of<TrainingSessionProvider>(context, listen: false);
    final session = sessionProvider.currentSession;
    
    if (session == null) return '0min';
    
    // Calculate duration from session start to now
    final startTime = session.date;
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    
    final totalMinutes = duration.inMinutes;
    
    if (totalMinutes < 60) {
      return '${totalMinutes}min';
    } else {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}m';
      }
    }
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Column(
      children: [
        // Floating icon with subtle glow
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _emberCore.withOpacity(0.08),
                _emberCore.withOpacity(0.03),
                Colors.transparent,
              ],
              stops: const [0.3, 0.7, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: _emberCore.withOpacity(0.12),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              size: 28,
              color: _emberCore.withOpacity(0.9),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Large value display
        Text(
          value,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: _snow,
            letterSpacing: -1.0,
            height: 1.0,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Clean label
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _silver,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(dynamic sessionProvider) {
    return AnimatedBuilder(
      animation: _actionsController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _actionsSlideAnimation.value),
          child: Opacity(
            opacity: _actionsFadeAnimation.value,
            child: Column(
              children: [
                // Primary return button only
                _buildActionButton(
                  'ZUM STARTBILDSCHIRM',
                  Icons.home_rounded,
                  () {
                    HapticFeedback.mediumImpact();
                    _returnToHomeScreen(context);
                  },
                  isPrimary: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed, {bool isPrimary = false, bool isSecondary = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: isPrimary ? 20 : 18),
        label: Text(
          text,
          style: TextStyle(
            fontSize: isPrimary ? 15 : 14,
            fontWeight: FontWeight.w700,
            letterSpacing: isPrimary ? 0.8 : 0.3,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary 
              ? _emberCore 
              : isSecondary 
                  ? _charcoal.withOpacity(0.8)
                  : _graphite,
          foregroundColor: isPrimary ? _snow : _snow,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isPrimary 
                  ? _emberCore.withOpacity(0.6)
                  : _steel.withOpacity(0.3),
              width: isPrimary ? 2 : 1,
            ),
          ),
        ),
      ),
    );
  }


  void _returnToHomeScreen(BuildContext context) {
    // Update navigation index and return to main screen
    final navigationProvider =
        Provider.of<NavigationProvider>(context, listen: false);
    navigationProvider.setCurrentIndex(0);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false,
    );
  }
}
