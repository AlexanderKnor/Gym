import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../providers/training_plans_screen/training_plans_screen_provider.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';
import '../../models/training_plan_screen/training_plan_model.dart';
import '../create_training_plan_screen/create_plan_wizard_screen.dart';
import '../create_training_plan_screen/training_day_editor_screen.dart';
import '../../utils/smooth_page_route.dart';

class TrainingPlansScreen extends StatelessWidget {
  const TrainingPlansScreen({Key? key}) : super(key: key);

  // PROVER color system - consistent with progression manager
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

  @override
  Widget build(BuildContext context) {
    final plansProvider = Provider.of<TrainingPlansProvider>(context);
    final trainingPlans = plansProvider.trainingPlans;

    return Scaffold(
      backgroundColor: _void,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            bottom: false,
            child: plansProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : trainingPlans.isEmpty
                    ? _buildEmptyState(context)
                    : _buildTrainingPlansView(context, trainingPlans, plansProvider),
          ),
          // Fixed header with logo - consistent with other screens
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Widget _buildTrainingPlansView(BuildContext context, List<TrainingPlanModel> trainingPlans, TrainingPlansProvider plansProvider) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Content header - spacing for fixed header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 76, 24, 24), // 60px header + 16px spacing
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TRAINING',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _proverCore,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'DEINE PLÄNE',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: _nova,
                          letterSpacing: -0.5,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${trainingPlans.length} Pläne verfügbar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _stardust,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Add button - consistent with demo button style
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      SmoothPageRoute(
                        builder: (context) => const CreatePlanWizardScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _stellar.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _proverCore.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _void.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: _proverCore, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'NEU',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _proverCore,
                            letterSpacing: 1,
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

        // Training plans list with stagger animation
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final plan = trainingPlans[index];

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
                          child: TrainingPlanCard(
                            plan: plan,
                            onEdit: () => _navigateToEditPlan(context, plan),
                            onDelete: () => _confirmDeletePlan(context, plansProvider, plan),
                            onActivate: plan.isActive ? null : () {
                              HapticFeedback.lightImpact();
                              plansProvider.activateTrainingPlan(plan.id);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              childCount: trainingPlans.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Space for fixed header
            const SizedBox(height: 60),
            
            // Logo with animation
            Stack(
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

            const SizedBox(height: 48),

            // Title
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_nova, _stardust],
              ).createShader(bounds),
              child: const Text(
                'TRAINING',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: _nova,
                  letterSpacing: 4,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Erstelle deinen ersten Trainingsplan',
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
                      'ERSTEN PLAN ERSTELLEN',
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
          ],
        ),
      ),
    );
  }

  // Navigation zum Editor
  void _navigateToEditPlan(BuildContext context, TrainingPlanModel plan) {
    final createProvider =
        Provider.of<CreateTrainingPlanProvider>(context, listen: false);

    // Plan in den Provider laden und direkt zum Editor navigieren
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

  void _confirmDeletePlan(
    BuildContext context,
    TrainingPlansProvider provider,
    TrainingPlanModel plan,
  ) {
    showDialog(
      context: context,
      barrierColor: _void.withOpacity(0.7),
      builder: (context) => AlertDialog(
        backgroundColor: _stellar,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _lunar.withOpacity(0.3),
            width: 1,
          ),
        ),
        title: Text(
          'Trainingsplan löschen',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _nova,
            letterSpacing: 0.3,
          ),
        ),
        content: Text(
          'Möchtest du den Trainingsplan "${plan.name}" wirklich löschen?',
          style: TextStyle(
            fontSize: 14,
            color: _stardust,
            height: 1.4,
          ),
        ),
        actions: [
          // Cancel button
          Container(
            decoration: BoxDecoration(
              color: _lunar.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _asteroid.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'ABBRECHEN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _stardust,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Delete button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[600]!, Colors.red[400]!],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await provider.deleteTrainingPlan(plan.id);
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'LÖSCHEN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _nova,
                      letterSpacing: 1,
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
}

class TrainingPlanCard extends StatelessWidget {
  final TrainingPlanModel plan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onActivate;

  // Color constants
  static const Color _void = Color(0xFF000000);
  static const Color _nebula = Color(0xFF0F0F12);
  static const Color _stellar = Color(0xFF18181C);
  static const Color _lunar = Color(0xFF242429);
  static const Color _asteroid = Color(0xFF35353C);
  static const Color _comet = Color(0xFF65656F);
  static const Color _stardust = Color(0xFFA5A5B0);
  static const Color _nova = Color(0xFFF5F5F7);
  static const Color _proverCore = Color(0xFFFF4500);
  static const Color _proverGlow = Color(0xFFFF6B3D);

  // System blue colors
  static const Color _systemBlue = Color(0xFF007AFF);
  static const Color _systemBlueLight = Color(0xFF40A2FF);

  // Elegant green colors for active state
  static const Color _activeGreen = Color(0xFF34C759);
  static const Color _activeGreenLight = Color(0xFF4CD964);

  const TrainingPlanCard({
    super.key,
    required this.plan,
    required this.onEdit,
    required this.onDelete,
    this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: plan.isActive
              ? [
                  _stellar.withOpacity(0.8),
                  _nebula.withOpacity(0.6),
                ]
              : [
                  _stellar.withOpacity(0.6),
                  _nebula.withOpacity(0.4),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: plan.isActive 
              ? _activeGreen.withOpacity(0.6)
              : _lunar.withOpacity(0.4),
          width: plan.isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: plan.isActive 
                ? _activeGreen.withOpacity(0.2)
                : _void.withOpacity(0.3),
            blurRadius: plan.isActive ? 24 : 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with title and options button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _nova,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showPlanOptions(context);
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
              ],
            ),

            const SizedBox(height: 8),

            // Gym name (if available)
            if (plan.gym != null && plan.gym!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 12,
                    color: _comet,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    plan.gym!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _comet,
                      fontStyle: FontStyle.italic,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            // Training days count
            Text(
              '${plan.days.length} Trainingstage',
              style: TextStyle(
                fontSize: 13,
                color: _stardust,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),

            // Metrics and status row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Metrics
                Row(
                  children: [
                    _buildMetric('${plan.days.length}', 'Tage'),
                    const SizedBox(width: 16),
                    _buildMetric('${_getTotalExercises(plan)}', 'Übungen'),
                  ],
                ),

                // Status and action
                if (plan.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_activeGreen, _activeGreenLight],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: _activeGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _nova,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AKTIV',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _nova,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (onActivate != null)
                  GestureDetector(
                    onTap: onActivate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_proverCore, _proverGlow],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: _proverCore.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'AKTIVIEREN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: _nova,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String value, String label) {
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _stardust,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: _comet,
          ),
        ),
      ],
    );
  }

  void _showPlanOptions(BuildContext context) {
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
                      'Plan Optionen',
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

                // Option: Plan bearbeiten
                _buildPlanOptionButton(
                  icon: Icons.edit_outlined,
                  label: 'Plan bearbeiten',
                  onTap: () {
                    Navigator.of(context).pop();
                    onEdit();
                  },
                  isPrimary: false,
                ),

                const SizedBox(height: 12),

                // Option: Plan löschen
                _buildPlanOptionButton(
                  icon: Icons.delete_outline,
                  label: 'Plan löschen',
                  onTap: () {
                    Navigator.of(context).pop();
                    onDelete();
                  },
                  isPrimary: false,
                  isDestructive: true,
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
    bool isDestructive = false,
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
              : isDestructive
                  ? Colors.red.withOpacity(0.4)
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
                  color: isPrimary 
                      ? _nova 
                      : isDestructive 
                          ? Colors.red 
                          : _stardust,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                    color: isPrimary 
                        ? _nova 
                        : isDestructive 
                            ? Colors.red 
                            : _stardust,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getTotalExercises(TrainingPlanModel plan) {
    return plan.days.fold(0, (sum, day) => sum + day.exercises.length);
  }
}
