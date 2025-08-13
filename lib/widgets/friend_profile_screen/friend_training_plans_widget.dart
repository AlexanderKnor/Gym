// lib/widgets/friend_profile_screen/friend_training_plans_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/friend_profile_screen/friend_profile_provider.dart';
import '../../providers/training_plans_screen/training_plans_screen_provider.dart';
import '../../models/training_plan_screen/training_plan_model.dart';

class FriendTrainingPlansWidget extends StatelessWidget {
  const FriendTrainingPlansWidget({Key? key}) : super(key: key);

  // PROVER color system - consistent with other screens
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
    final provider = Provider.of<FriendProfileProvider>(context);
    final trainingPlans = provider.trainingPlans;

    if (trainingPlans.isEmpty) {
      return _buildEmptyState();
    }

    // Fixed: Remove Expanded from Column inside SliverToBoxAdapter
    // Build list directly without wrapping Column
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRAININGSPLÄNE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _proverCore,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        // Use a fixed height container or shrinkWrap ListView
        ...trainingPlans.map((plan) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTrainingPlanCard(context, plan, plan.isActive),
        )).toList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
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
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _lunar.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                size: 32,
                color: _comet,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'KEINE PLÄNE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _stardust,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dein Freund hat noch keine\nTrainingspläne erstellt',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _comet,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingPlanCard(BuildContext context, TrainingPlanModel plan, bool isActive) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isActive 
              ? _proverCore.withOpacity(0.15)
              : _stellar.withOpacity(0.6),
            isActive
              ? _proverGlow.withOpacity(0.08)
              : _nebula.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive 
            ? _proverCore.withOpacity(0.5)
            : _lunar.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive 
              ? _proverCore.withOpacity(0.1)
              : _void.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTrainingPlanDetails(context, plan),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isActive 
                            ? [_proverCore, _proverGlow]
                            : [_asteroid, _comet.withOpacity(0.8)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isActive 
                              ? _proverCore.withOpacity(0.3)
                              : _asteroid.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.fitness_center_rounded,
                        color: _nova,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  plan.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isActive ? _proverCore : _nova,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              if (isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [_proverCore, _proverGlow],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'AKTIV',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: _nova,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${plan.days.length} Trainingstage • ${_getTotalExercises(plan)} Übungen',
                            style: TextStyle(
                              fontSize: 13,
                              color: _stardust,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    // Copy Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _copyTrainingPlan(context, plan);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green[600]!, Colors.green[400]!],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.copy_rounded, color: _nova, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'KOPIEREN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: _nova,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Details Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showTrainingPlanDetails(context, plan);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isActive 
                              ? _proverCore.withOpacity(0.2)
                              : _lunar.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isActive 
                                ? _proverCore.withOpacity(0.5)
                                : _stellar.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline_rounded, 
                                color: isActive ? _proverCore : _stardust, 
                                size: 16
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'DETAILS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isActive ? _proverCore : _stardust,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
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
      ),
    );
  }

  int _getTotalExercises(TrainingPlanModel plan) {
    int total = 0;
    for (var day in plan.days) {
      total += day.exercises.length;
    }
    return total;
  }

  void _copyTrainingPlan(BuildContext context, TrainingPlanModel plan) async {
    final provider = Provider.of<FriendProfileProvider>(context, listen: false);
    final trainingPlansProvider = Provider.of<TrainingPlansProvider>(context, listen: false);

    BuildContext? dialogContext;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: _void.withOpacity(0.7),
      builder: (context) {
        dialogContext = context;
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: _stellar,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: _lunar.withOpacity(0.3),
                width: 1,
              ),
            ),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: _proverCore,
                  strokeWidth: 2,
                ),
                const SizedBox(width: 20),
                Text(
                  'Trainingsplan wird kopiert...',
                  style: TextStyle(
                    color: _nova,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final result = await provider.copyTrainingPlanToOwnCollection(plan);

      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!).pop();
      }

      if (!context.mounted) {
        return;
      }

      await Future.delayed(const Duration(milliseconds: 200));

      if (context.mounted) {
        if (result['success'] == true) {
          final missingProfileIds = result['missingProfileIds'] as List;

          await trainingPlansProvider.refreshTrainingPlans();

          if (missingProfileIds.isNotEmpty) {
            await _showMissingProfilesDialog(context, missingProfileIds, plan, result['plan']);
          } else {
            await _showSuccessDialog(context, plan);
          }
        } else {
          await _showErrorDialog(context, result['error'] ?? 'Unbekannter Fehler');
        }
      }
    } catch (e) {
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!).pop();
      }

      if (!context.mounted) {
        return;
      }

      await Future.delayed(const Duration(milliseconds: 200));

      if (context.mounted) {
        await _showErrorDialog(context, e.toString());
      }
    }
  }

  Future<void> _showMissingProfilesDialog(
      BuildContext context,
      List missingProfileIds,
      TrainingPlanModel originalPlan,
      TrainingPlanModel copiedPlan) async {
    
    final provider = Provider.of<FriendProfileProvider>(context, listen: false);
    final trainingPlansProvider = Provider.of<TrainingPlansProvider>(context, listen: false);

    bool? shouldCopyProfiles;

    final String profilesList = missingProfileIds.map((id) {
      try {
        final profile = provider.progressionProfiles.firstWhere(
          (p) => p.id == id.toString(),
        );
        return '• ${profile.name}';
      } catch (e) {
        return '• Profil ID: $id';
      }
    }).join('\n');

    await showDialog(
      context: context,
      barrierColor: _void.withOpacity(0.7),
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _stellar,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.orange.withOpacity(0.3),
            width: 1,
          ),
        ),
        title: Text(
          'Fehlende Progressionsprofile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _nova,
            letterSpacing: 0.3,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Der Trainingsplan verwendet Progressionsprofile, die in deiner Sammlung fehlen:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _nova,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_rounded, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Fehlende Profile:',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _nova,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profilesList,
                      style: TextStyle(
                        color: _stardust,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Möchtest du diese Profile ebenfalls kopieren?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _nova,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              color: _lunar.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _stellar.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  shouldCopyProfiles = false;
                  Navigator.of(dialogContext).pop();
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'NUR PLAN',
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
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[600]!, Colors.green[400]!],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  shouldCopyProfiles = true;
                  Navigator.of(dialogContext).pop();
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'ALLES KOPIEREN',
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

    if (!context.mounted) {
      return;
    }

    if (shouldCopyProfiles == true) {
      BuildContext? loadingContext;

      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: _void.withOpacity(0.7),
        builder: (ctx) {
          loadingContext = ctx;
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              backgroundColor: _stellar,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _lunar.withOpacity(0.3),
                  width: 1,
                ),
              ),
              content: Row(
                children: [
                  CircularProgressIndicator(
                    color: _proverCore,
                    strokeWidth: 2,
                  ),
                  const SizedBox(width: 20),
                  Text(
                    'Profile werden kopiert...',
                    style: TextStyle(
                      color: _nova,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      try {
        final success = await provider.copyMissingProfiles(
            missingProfileIds.map((id) => id.toString()).toList());

        if (loadingContext != null && Navigator.canPop(loadingContext!)) {
          Navigator.of(loadingContext!).pop();
        }

        if (!context.mounted) {
          return;
        }

        await Future.delayed(const Duration(milliseconds: 200));

        if (context.mounted) {
          if (success) {
            await trainingPlansProvider.refreshTrainingPlans();
            await _showSuccessDialog(context, originalPlan, withProfiles: true);
          } else {
            await _showErrorDialog(context,
                provider.errorMessage ?? 'Fehler beim Kopieren der Profile');
          }
        }
      } catch (e) {
        if (loadingContext != null && Navigator.canPop(loadingContext!)) {
          Navigator.of(loadingContext!).pop();
        }

        if (context.mounted) {
          await Future.delayed(const Duration(milliseconds: 200));
          if (context.mounted) {
            await _showErrorDialog(context, e.toString());
          }
        }
      }
    } else if (shouldCopyProfiles == false) {
      if (context.mounted) {
        await _showSuccessDialog(context, originalPlan,
            withWarning: 'Einige Übungen verwenden Profile, die du nicht kopiert hast.');
      }
    }
  }

  Future<void> _showSuccessDialog(BuildContext context, TrainingPlanModel plan,
      {String? withWarning, bool withProfiles = false}) async {
    await showDialog(
      context: context,
      barrierColor: _void.withOpacity(0.7),
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _stellar,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.green.withOpacity(0.3),
            width: 1,
          ),
        ),
        title: Text(
          'Erfolgreich kopiert',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _nova,
            letterSpacing: 0.3,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Der Trainingsplan "${plan.name}" wurde erfolgreich in deine Sammlung kopiert.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _stardust,
                height: 1.4,
              ),
            ),
            if (withProfiles) ...[
              const SizedBox(height: 12),
              Text(
                'Alle benötigten Progressionsprofile wurden ebenfalls kopiert.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
            if (withWarning != null) ...[
              const SizedBox(height: 12),
              Text(
                withWarning,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ],
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_proverCore, _proverGlow],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: _proverCore.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(dialogContext).pop();
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'OK',
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

  Future<void> _showErrorDialog(BuildContext context, String errorMessage) async {
    await showDialog(
      context: context,
      barrierColor: _void.withOpacity(0.7),
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _stellar,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.red.withOpacity(0.3),
            width: 1,
          ),
        ),
        title: Text(
          'Fehler',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _nova,
            letterSpacing: 0.3,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Beim Kopieren ist ein Fehler aufgetreten:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _nova,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _stardust,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              color: _lunar.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _stellar.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(dialogContext).pop();
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'OK',
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
        ],
      ),
    );
  }

  void _showTrainingPlanDetails(BuildContext context, TrainingPlanModel plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
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
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _asteroid,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_proverCore, _proverGlow],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.fitness_center_rounded, color: _nova, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      plan.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: _nova,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  if (plan.isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [_proverCore, _proverGlow],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'AKTIV',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: _nova,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${plan.days.length} Tage • ${_getTotalExercises(plan)} Übungen',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _stardust,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Copy Button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                        _copyTrainingPlan(context, plan);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green[600]!, Colors.green[400]!],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.copy_rounded, color: _nova, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'IN MEINE SAMMLUNG KOPIEREN',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _nova,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    Text(
                      'TRAININGSTAGE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _proverCore,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Scrollable content
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: plan.days.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => _buildDayDetails(context, plan.days[i], i),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayDetails(BuildContext context, dynamic day, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _lunar.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _stellar.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_proverCore, _proverGlow],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _nova,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                day.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _nova,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Exercises
          ...day.exercises.asMap().entries.map((entry) {
            final exercise = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _stellar.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _lunar.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exercise.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _nova,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_proverCore.withOpacity(0.8), _proverGlow.withOpacity(0.8)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${exercise.numberOfSets}×',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _nova,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (exercise.primaryMuscleGroup.isNotEmpty ||
                        exercise.secondaryMuscleGroup.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _getMuscleGroups(exercise),
                        style: TextStyle(
                          fontSize: 12,
                          color: _stardust,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: _comet),
                        const SizedBox(width: 4),
                        Text(
                          '${exercise.restPeriodSeconds}s',
                          style: TextStyle(
                            fontSize: 12,
                            color: _comet,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.trending_up_rounded, size: 14, color: _comet),
                        const SizedBox(width: 4),
                        Text(
                          '+${exercise.standardIncrease}kg',
                          style: TextStyle(
                            fontSize: 12,
                            color: _comet,
                          ),
                        ),
                        if (exercise.progressionProfileId != null &&
                            exercise.progressionProfileId!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.auto_graph_rounded, size: 14, color: _proverCore),
                          const SizedBox(width: 4),
                          Text(
                            _getProfileNameById(context, exercise.progressionProfileId!),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _proverCore,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  String _getMuscleGroups(dynamic exercise) {
    List<String> groups = [];
    if (exercise.primaryMuscleGroup.isNotEmpty) {
      groups.add(exercise.primaryMuscleGroup);
    }
    if (exercise.secondaryMuscleGroup.isNotEmpty) {
      groups.add(exercise.secondaryMuscleGroup);
    }
    return groups.join(' • ');
  }

  String _getProfileNameById(BuildContext context, String profileId) {
    final provider = Provider.of<FriendProfileProvider>(context, listen: false);
    try {
      final profile = provider.progressionProfiles.firstWhere(
        (profile) => profile.id == profileId,
      );
      return profile.name;
    } catch (e) {
      return 'Profil';
    }
  }
}