// lib/screens/training_screen/training_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../models/training_plan_screen/training_plan_model.dart';
import '../../providers/shared/navigation_provider.dart';
import '../../providers/training_plans_screen/training_plans_screen_provider.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';
import '../../providers/training_session_screen/training_session_provider.dart';
import '../../services/training/session_recovery_service.dart';
import '../create_training_plan_screen/create_plan_wizard_screen.dart';
import '../create_training_plan_screen/training_day_editor_screen.dart';
import '../training_session_screen/training_session_screen.dart';
import '../../utils/smooth_page_route.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _heroController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _heroScaleAnimation;
  late Animation<double> _pulseAnimation;

  // Sophisticated color system
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

  bool _sessionRecoveryChecked = false;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

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

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    );

    _heroScaleAnimation = CurvedAnimation(
      parent: _heroController,
      curve: const Cubic(0.175, 0.885, 0.32, 1.275),
    );

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeInOutCubic),
    );

    _fadeController.forward();
    _heroController.forward();

    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForSessionRecovery();
    });
  }

  Future<void> _checkForSessionRecovery() async {
    if (_sessionRecoveryChecked) return;
    _sessionRecoveryChecked = true;

    final trainingProvider =
        Provider.of<TrainingSessionProvider>(context, listen: false);
    await SessionRecoveryService.checkAndRecoverSession(
        context, trainingProvider);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _heroController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plansProvider = Provider.of<TrainingPlansProvider>(context);
    final activePlan = plansProvider.activePlan;
    final isLoading = plansProvider.isLoading;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _void,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            bottom: false,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: isLoading
                  ? _buildLoadingView()
                  : activePlan != null
                      ? _buildActivePlanView(context, activePlan, plansProvider)
                      : _buildEmptyStateView(context),
            ),
          ),
          // Fixed header with logo
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _proverCore.withOpacity(0.4),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'PROVER',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _nova,
                        letterSpacing: 1.5,
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

  Widget _buildActivePlanView(BuildContext context,
      TrainingPlanModel activePlan, TrainingPlansProvider plansProvider) {
    final currentWeekIndex = plansProvider.currentWeekIndex;
    final size = MediaQuery.of(context).size;

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Compact header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Space for fixed header
                const SizedBox(height: 60),

                // Plan info - full width card matching training days
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _stellar.withOpacity(0.5),
                        _nebula.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _lunar.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Main content
                      Column(
                        children: [
                          // Active plan label
                          Center(
                            child: Text(
                              'AKTIVER PLAN',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _proverCore,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Plan name
                          Center(
                            child: Text(
                              activePlan.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: _nova,
                                letterSpacing: -0.5,
                                height: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // Gym name (if available)
                          if (activePlan.gym != null && activePlan.gym!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.fitness_center,
                                    size: 14,
                                    color: _comet,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    activePlan.gym!.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _comet,
                                      letterSpacing: 0.5,
                                      height: 1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                      // Options button positioned top right
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _showPlanOptions(context, activePlan);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.more_horiz,
                              color: _stardust,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Week selector for periodized plans
        if (activePlan.isPeriodized) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MIKROZYKLUS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _comet,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: activePlan.numberOfWeeks,
                      itemBuilder: (context, weekIndex) {
                        final isActive = weekIndex == currentWeekIndex;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            plansProvider.setCurrentWeekIndex(weekIndex);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isActive
                                    ? [
                                        _stellar.withOpacity(0.9),
                                        _stellar.withOpacity(0.6),
                                      ]
                                    : [
                                        _stellar.withOpacity(0.5),
                                        _stellar.withOpacity(0.3),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isActive
                                    ? _lunar.withOpacity(0.6)
                                    : _lunar.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      _void.withOpacity(isActive ? 0.4 : 0.2),
                                  blurRadius: isActive ? 12 : 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${weekIndex + 1}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isActive ? _nova : _stardust,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Training days with stagger animation
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final day = activePlan.days[index];
                final exerciseCount = day.exercises.length;
                final totalSets =
                    _getTrainingDaySets(activePlan, index, currentWeekIndex);
                final isEmpty = exerciseCount == 0;

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 600 + (index * 100)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isEmpty
                                  ? [
                                      _stellar.withOpacity(0.3),
                                      _nebula.withOpacity(0.2),
                                    ]
                                  : [
                                      _stellar.withOpacity(0.6),
                                      _nebula.withOpacity(0.4),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isEmpty
                                  ? _lunar.withOpacity(0.2)
                                  : _lunar.withOpacity(0.4),
                            ),
                            boxShadow: isEmpty
                                ? null
                                : [
                                    BoxShadow(
                                      color: _void.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                // Day number with orange accent for active cards
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: isEmpty
                                          ? [
                                              _lunar.withOpacity(0.4),
                                              _lunar.withOpacity(0.2),
                                            ]
                                          : [
                                              _stellar.withOpacity(0.8),
                                              _stellar.withOpacity(0.4),
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isEmpty
                                          ? _asteroid.withOpacity(0.3)
                                          : _proverCore.withOpacity(0.6),
                                      width: isEmpty ? 1 : 2,
                                    ),
                                    boxShadow: isEmpty
                                        ? [
                                            BoxShadow(
                                              color: _void.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: _void.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                            BoxShadow(
                                              color:
                                                  _proverCore.withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 0),
                                            ),
                                          ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: isEmpty ? _comet : _stardust,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        day.name.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: isEmpty ? _comet : _nova,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      if (!isEmpty) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            _buildMetric(
                                                exerciseCount.toString(),
                                                'Übungen'),
                                            const SizedBox(width: 16),
                                            _buildMetric(
                                                totalSets.toString(), 'Sätze'),
                                          ],
                                        ),
                                      ] else ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Keine Übungen definiert',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _comet.withOpacity(0.7),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Start button
                                if (!isEmpty) ...[
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () => _startTraining(context,
                                        activePlan, index, currentWeekIndex),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
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
                                        'START',
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              childCount: activePlan.days.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(String value, String label) {
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _stardust,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _comet,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _nova,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _comet,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalStat(String value, String label) {
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _nova,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _stardust.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  int _getTotalExercises(TrainingPlanModel plan) {
    int total = 0;
    for (var day in plan.days) {
      total += day.exercises.length;
    }
    return total;
  }

  int _getTotalSetsPerWeek(TrainingPlanModel plan, int weekIndex) {
    int total = 0;
    for (int dayIndex = 0; dayIndex < plan.days.length; dayIndex++) {
      total += _getTrainingDaySets(plan, dayIndex, weekIndex);
    }
    return total;
  }

  void _showPlanOptions(BuildContext context, TrainingPlanModel plan) {
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
              colors: [_stellar, _nebula],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: _lunar.withOpacity(0.3),
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
                          colors: [_proverCore, _proverGlow],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        color: _nova,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Trainingsplan Optionen',
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

                // Option: Trainingsplan bearbeiten
                _buildPlanOptionButton(
                  icon: Icons.edit_outlined,
                  label: 'Trainingsplan bearbeiten',
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateToEditPlan(context, plan);
                  },
                  isPrimary: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(colors: [_proverCore, _proverGlow])
            : LinearGradient(
                colors: [_lunar.withOpacity(0.3), _lunar.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrimary
              ? _proverCore.withOpacity(0.5)
              : _lunar.withOpacity(0.4),
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
                  color: isPrimary ? _nova : _stardust,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                    color: isPrimary ? _nova : _stardust,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const SizedBox.shrink();
  }

  Widget _buildEmptyStateView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with animation
            ScaleTransition(
              scale: _heroScaleAnimation,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow effect
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _proverCore.withOpacity(0.15),
                          _proverCore.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                  // Main logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_stellar, _nebula],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: _proverCore.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_proverCore, _proverGlow],
                        ).createShader(bounds),
                        child: Text(
                          'P',
                          style: TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.w800,
                            color: _nova,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Title
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_nova, _stardust],
              ).createShader(bounds),
              child: const Text(
                'PROVER',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: _nova,
                  letterSpacing: 6,
                ),
              ),
            ),

            const SizedBox(height: 50),

            Text(
              'Elite Performance Training',
              style: TextStyle(
                fontSize: 16,
                color: _comet,
                fontWeight: FontWeight.w400,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 64),

            // CTA Button
            Container(
              width: double.infinity,
              height: 60,
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
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      SmoothPageRoute(
                        builder: (context) => const CreatePlanWizardScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Text(
                      'TRAINING BEGINNEN',
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

            const SizedBox(height: 20),

            // Secondary action
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                final navigationProvider =
                    Provider.of<NavigationProvider>(context, listen: false);
                navigationProvider.setCurrentIndex(2);
              },
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'VORHANDENE PLÄNE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _comet,
                  letterSpacing: 1.5,
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

  void _startTraining(BuildContext context, TrainingPlanModel plan,
      int dayIndex, int weekIndex) {
    // Haptic feedback for better UX
    HapticFeedback.lightImpact();

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
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Smooth fade transition without flicker
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: Container(
              color: _void,
              child: child,
            ),
          );
        },
      ),
    );
  }

  int _getTrainingDaySets(
      TrainingPlanModel activePlan, int dayIndex, int currentWeekIndex) {
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
