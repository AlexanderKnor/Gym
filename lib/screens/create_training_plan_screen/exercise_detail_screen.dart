// lib/screens/create_training_plan_screen/exercise_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../models/exercise_database/predefined_exercise_model.dart';
import '../../models/exercise_database/exercise_detail_model.dart';
import '../../services/exercise_database/exercise_detail_service.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final PredefinedExercise exercise;
  final Function(PredefinedExercise) onSelectExercise;

  const ExerciseDetailScreen({
    Key? key,
    required this.exercise,
    required this.onSelectExercise,
  }) : super(key: key);

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen>
    with TickerProviderStateMixin {
  // Services
  final ExerciseDetailService _detailService = ExerciseDetailService();
  
  // Exercise details
  late ExerciseDetailModel _exerciseDetails;
  
  // Animation controllers
  late AnimationController _entranceController;
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatingAnimation;
  
  // Tab selection
  int _selectedTab = 0;
  
  // Cosmic Color System - matching app theme
  static const Color _void = Color(0xFF000000);
  static const Color _cosmos = Color(0xFF050507);
  static const Color _nebula = Color(0xFF0F0F12);
  static const Color _stellar = Color(0xFF18181C);
  static const Color _lunar = Color(0xFF242429);
  static const Color _asteroid = Color(0xFF35353C);
  static const Color _comet = Color(0xFF65656F);
  static const Color _stardust = Color(0xFFA5A5B0);
  static const Color _nova = Color(0xFFF5F5F7);
  
  // Prover signature colors
  static const Color _proverCore = Color(0xFFFF4500);
  static const Color _proverGlow = Color(0xFFFF6B3D);
  static const Color _proverFlare = Color(0xFFFFA500);

  @override
  void initState() {
    super.initState();
    
    // Set immersive system UI
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: _void,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    
    // Load exercise details
    _loadExerciseDetails();
    
    // Initialize animations
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
    ));
    
    _floatingAnimation = Tween<double>(
      begin: -8.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    _entranceController.forward();
  }
  
  void _loadExerciseDetails() {
    try {
      // Nutze die Details direkt aus der PredefinedExercise (aus JSON)
      _exerciseDetails = _detailService.getExerciseDetails(widget.exercise) ??
          ExerciseDetailModel(
            exerciseId: widget.exercise.name.toLowerCase().replaceAll(' ', '_'),
            exerciseName: widget.exercise.name,
            primaryMuscleGroup: widget.exercise.primaryMuscleGroup,
            secondaryMuscleGroups: widget.exercise.secondaryMuscleGroups,
            primaryMuscleIds: [],
            secondaryMuscleIds: [],
            useBackView: false,
            affectedJoints: [],
            movementPattern: 'Standard',
            movementDescription: 'Standardübung',
            rangeOfMotion: 3,
            stability: 3,
            jointStress: 3,
            systemicStress: 3,
          );
    } catch (e) {
      // Fallback to minimal details
      _exerciseDetails = ExerciseDetailModel(
        exerciseId: widget.exercise.name.toLowerCase().replaceAll(' ', '_'),
        exerciseName: widget.exercise.name,
        primaryMuscleGroup: widget.exercise.primaryMuscleGroup,
        secondaryMuscleGroups: widget.exercise.secondaryMuscleGroups,
        primaryMuscleIds: [],
        secondaryMuscleIds: [],
        useBackView: false,
        affectedJoints: [],
        movementPattern: 'Standard',
        movementDescription: 'Standardübung',
        rangeOfMotion: 3,
        stability: 3,
        jointStress: 3,
        systemicStress: 3,
      );
    }
  }
  
  @override
  void dispose() {
    _entranceController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _void,
      body: Stack(
        children: [
          // Cosmic background
          _buildCosmicBackground(),
          
          // Main content
          SafeArea(
            bottom: false,
            child: AnimatedBuilder(
              animation: _entranceController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Column(
                        children: [
                          // Minimal header
                          _buildMinimalHeader(),
                          
                          // Hero section
                          _buildHeroSection(),
                          
                          // Tab selector
                          _buildTabSelector(),
                          
                          // Content
                          Expanded(
                            child: _buildTabContent(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Floating action button
          _buildFloatingAction(),
        ],
      ),
    );
  }
  
  Widget _buildCosmicBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.7, -0.6),
          radius: 1.2,
          colors: [
            _nebula.withOpacity(0.3),
            _cosmos,
            _void,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
  
  Widget _buildMinimalHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          // Back button with glass effect
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _stellar.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _lunar.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _stardust,
                  size: 18,
                ),
              ),
            ),
          ),
          
          const Spacer(),
          
          // Equipment badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _stellar.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _lunar.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              widget.exercise.equipment,
              style: TextStyle(
                color: _stardust,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        children: [
          // Exercise name
          Text(
            widget.exercise.name,
            style: const TextStyle(
              color: _nova,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Movement pattern chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _proverCore.withOpacity(0.15),
                  _proverGlow.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _proverCore.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sync_alt_rounded,
                  color: _proverCore,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _exerciseDetails.movementPattern,
                  style: TextStyle(
                    color: _proverCore,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabSelector() {
    final tabs = ['Anatomie', 'Metriken', 'Details'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _stellar.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _lunar.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final isSelected = _selectedTab == index;
          
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTab = index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _lunar.withOpacity(0.5) : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? _nova : _stardust,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: isSelected ? 0.5 : 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildTabContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: IndexedStack(
        key: ValueKey(_selectedTab),
        index: _selectedTab,
        children: [
          _buildAnatomyTab(),
          _buildMetricsTab(),
          _buildDetailsTab(),
        ],
      ),
    );
  }
  
  Widget _buildAnatomyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        children: [
          // Anatomy visualization placeholder
          AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatingAnimation.value),
                child: Container(
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _stellar.withOpacity(0.3),
                        _nebula.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _lunar.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Stack(
                        children: [
                          // Muscle visualization
                          Center(
                            child: Icon(
                              Icons.accessibility_new_rounded,
                              size: 120,
                              color: _proverCore.withOpacity(0.2),
                            ),
                          ),
                          
                          // View indicator
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _void.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _exerciseDetails.useBackView ? 'Rücken' : 'Front',
                                style: TextStyle(
                                  color: _stardust,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Muscle groups
          _buildGlassCard(
            title: 'Muskelgruppen',
            icon: Icons.fitness_center_rounded,
            child: Column(
              children: [
                _buildMuscleItem(
                  'Primär',
                  _exerciseDetails.primaryMuscleGroup,
                  _proverCore,
                  true,
                ),
                if (_exerciseDetails.secondaryMuscleGroups.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ..._exerciseDetails.secondaryMuscleGroups.map((muscle) =>
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildMuscleItem(
                        'Sekundär',
                        muscle,
                        _stardust,
                        false,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        children: [
          _buildMetricCard(
            'Range of Motion',
            _exerciseDetails.rangeOfMotion,
            _proverCore,
            Icons.open_in_full_rounded,
            'Bewegungsumfang der Übung',
          ),
          const SizedBox(height: 16),
          _buildMetricCard(
            'Stabilität',
            _exerciseDetails.stability,
            Colors.cyan,
            Icons.balance_rounded,
            'Stabilisierungsanforderung',
          ),
          const SizedBox(height: 16),
          _buildMetricCard(
            'Gelenkbelastung',
            _exerciseDetails.jointStress,
            Colors.amber,
            Icons.warning_amber_rounded,
            'Belastung der Gelenke',
          ),
          const SizedBox(height: 16),
          _buildMetricCard(
            'Systemische Belastung',
            _exerciseDetails.systemicStress,
            Colors.deepPurple,
            Icons.bolt_rounded,
            'Gesamtbelastung des Körpers',
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        children: [
          // Movement description
          _buildGlassCard(
            title: 'Bewegung',
            icon: Icons.timeline_rounded,
            child: Text(
              _exerciseDetails.movementDescription,
              style: TextStyle(
                color: _stardust,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Affected joints
          if (_exerciseDetails.affectedJoints.isNotEmpty)
            _buildGlassCard(
              title: 'Belastete Gelenke',
              icon: Icons.hub_rounded,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _exerciseDetails.affectedJoints.map((joint) =>
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _stellar.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _lunar.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      joint,
                      style: TextStyle(
                        color: _stardust,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ).toList(),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Tips if available
          if (_exerciseDetails.tips != null)
            _buildGlassCard(
              title: 'Tipps',
              icon: Icons.lightbulb_outline_rounded,
              gradient: true,
              child: Column(
                children: _exerciseDetails.tips!.map((tip) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: _proverCore,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tip,
                            style: TextStyle(
                              color: _stardust,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).toList(),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildGlassCard({
    required String title,
    required IconData icon,
    required Widget child,
    bool gradient = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient 
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _proverCore.withOpacity(0.08),
                _stellar.withOpacity(0.3),
              ],
            )
          : null,
        color: gradient ? null : _stellar.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gradient 
            ? _proverCore.withOpacity(0.2)
            : _lunar.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: gradient ? _proverCore : _stardust,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: gradient ? _proverCore : _stardust,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMuscleItem(String type, String muscle, Color color, bool isPrimary) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type.toUpperCase(),
                style: TextStyle(
                  color: _comet,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                muscle,
                style: TextStyle(
                  color: _nova,
                  fontSize: 15,
                  fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMetricCard(
    String label,
    int value,
    Color color,
    IconData icon,
    String description,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _stellar.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _lunar.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: _nova,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            description,
                            style: TextStyle(
                              color: _comet,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Value display
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            color.withOpacity(0.2),
                            color.withOpacity(0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          value.toString(),
                          style: TextStyle(
                            color: color,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Visual rating bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value / 5,
                    minHeight: 6,
                    backgroundColor: _lunar.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFloatingAction() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _void.withOpacity(0),
              _void.withOpacity(0.8),
              _void,
            ],
            stops: const [0, 0.3, 1],
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onSelectExercise(widget.exercise);
            },
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_proverCore, _proverGlow],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _proverCore.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: _nova,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ÜBUNG HINZUFÜGEN',
                      style: const TextStyle(
                        color: _nova,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
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
}