// lib/widgets/friend_profile_screen/friend_progression_profiles_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/friend_profile_screen/friend_profile_provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../models/progression_manager_screen/progression_profile_model.dart';

class FriendProgressionProfilesWidget extends StatelessWidget {
  const FriendProgressionProfilesWidget({Key? key}) : super(key: key);

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
    final profiles = provider.progressionProfiles;
    final activeProfileId = provider.activeProfileId;

    if (profiles.isEmpty) {
      return _buildEmptyState();
    }

    // Fixed: Remove Expanded from Column inside SliverToBoxAdapter
    // Build list directly without wrapping Column
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROGRESSIONSPROFILE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _proverCore,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        // Use a fixed height container or shrinkWrap ListView
        ...profiles.map((profile) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildProfileCard(context, profile, profile.id == activeProfileId),
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
                Icons.trending_up_rounded,
                size: 32,
                color: _comet,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'KEINE PROFILE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _stardust,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dein Freund hat noch keine\nProgressionsprofile erstellt',
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

  Widget _buildProfileCard(BuildContext context, ProgressionProfileModel profile, bool isActive) {
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
          onTap: () => _showProfileDetails(context, profile),
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
                        Icons.trending_up_rounded,
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
                                  profile.name.toUpperCase(),
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
                            profile.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                          _copyProfile(context, profile);
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
                          _showProfileDetails(context, profile);
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

  void _copyProfile(BuildContext context, ProgressionProfileModel profile) async {
    final provider = Provider.of<FriendProfileProvider>(context, listen: false);
    final progressionProvider = Provider.of<ProgressionManagerProvider>(context, listen: false);

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
                  'Profil wird kopiert...',
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
      final success = await provider.copyProfileToOwnCollection(profile);

      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!).pop();
      }

      await Future.delayed(const Duration(milliseconds: 200));
      await progressionProvider.refreshProfiles();

      if (context.mounted) {
        if (success) {
          _showSuccessDialog(context, profile);
        } else {
          _showErrorDialog(context, provider.errorMessage ?? 'Unbekannter Fehler');
        }
      }
    } catch (e) {
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!).pop();
      }

      await Future.delayed(const Duration(milliseconds: 200));

      if (context.mounted) {
        _showErrorDialog(context, e.toString());
      }
    }
  }

  void _showSuccessDialog(BuildContext context, ProgressionProfileModel profile) {
    showDialog(
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
              'Das Progressionsprofil "${profile.name}" wurde erfolgreich in deine Sammlung kopiert.',
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

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
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

  void _showProfileDetails(BuildContext context, ProgressionProfileModel profile) {
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
            child: SingleChildScrollView(
              controller: scrollController,
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
                    
                    // Profile Header
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
                          child: Icon(Icons.trending_up_rounded, color: _nova, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _nova,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _stardust,
                                  fontStyle: FontStyle.italic,
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
                        _copyProfile(context, profile);
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
                    
                    // Configuration Section
                    Text(
                      'KONFIGURATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _proverCore,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Container(
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
                        children: [
                          _buildConfigItem(
                            'Wiederholungsbereich',
                            '${profile.config['targetRepsMin'] ?? 0} - ${profile.config['targetRepsMax'] ?? 0} Wdh.',
                            Icons.repeat_rounded,
                          ),
                          const SizedBox(height: 12),
                          _buildConfigItem(
                            'RIR-Bereich',
                            '${profile.config['targetRIRMin'] ?? 0} - ${profile.config['targetRIRMax'] ?? 0} RIR',
                            Icons.battery_5_bar_rounded,
                          ),
                          const SizedBox(height: 12),
                          _buildConfigItem(
                            'Gewichtssteigerung',
                            '${profile.config['increment'] ?? 0} kg',
                            Icons.fitness_center_rounded,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Rules Section
                    Text(
                      'PROGRESSIONSREGELN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _proverCore,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    profile.rules.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: _lunar.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _stellar.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Keine Regeln definiert',
                                style: TextStyle(
                                  color: _comet,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: profile.rules.asMap().entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildRuleCard(entry.value, entry.key + 1),
                              );
                            }).toList(),
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

  Widget _buildConfigItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _proverCore.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: _proverCore),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _comet,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _nova,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRuleCard(dynamic rule, int index) {
    final ruleType = rule.type;
    final isCondition = ruleType == 'condition';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCondition 
          ? Colors.blue.withOpacity(0.05)
          : Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCondition
            ? Colors.blue.withOpacity(0.3)
            : Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCondition
                      ? [Colors.blue[600]!, Colors.blue[400]!]
                      : [Colors.green[600]!, Colors.green[400]!],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _nova,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCondition
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCondition ? 'BEDINGUNG' : 'ZUWEISUNG',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isCondition ? Colors.blue : Colors.green,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          if (isCondition && rule.conditions != null && rule.conditions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'WENN:',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _comet,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            ...List.generate(rule.conditions.length, (i) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text(
                _buildConditionText(rule.conditions[i]),
                style: TextStyle(
                  fontSize: 12,
                  color: _stardust,
                ),
              ),
            )),
          ],
          if (rule.children != null && rule.children.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'DANN:',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _comet,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            ...rule.children.map((action) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text(
                '${_getTargetLabel(action.target ?? '')} = ${_renderValueNode(action.value ?? {})}',
                style: TextStyle(
                  fontSize: 12,
                  color: _stardust,
                ),
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  String _buildConditionText(dynamic condition) {
    if (condition == null) return '';
    final left = condition.left?['value'] ?? '';
    final operator = condition.operator ?? '';
    final right = condition.right?['value'] ?? '';
    return '${_getVariableLabel(left.toString())} ${_getOperatorLabel(operator)} ${right}';
  }

  String _getTargetLabel(String target) {
    switch (target) {
      case 'kg': return 'GEWICHT';
      case 'reps': return 'WIEDERHOLUNGEN';
      case 'rir': return 'RIR';
      default: return target.toUpperCase();
    }
  }

  String _getVariableLabel(String variableId) {
    final labels = {
      'lastKg': 'Letztes Gewicht',
      'lastReps': 'Letzte Wdh.',
      'lastRIR': 'Letzter RIR',
      'targetRepsMin': 'Ziel Wdh. Min',
      'targetRepsMax': 'Ziel Wdh. Max',
      'targetRIRMin': 'Ziel RIR Min',
      'targetRIRMax': 'Ziel RIR Max',
      'increment': 'Steigerung',
    };
    return labels[variableId] ?? variableId;
  }

  String _getOperatorLabel(String operatorId) {
    final operators = {
      'eq': '=',
      'gt': '>',
      'lt': '<',
      'gte': '>=',
      'lte': '<=',
    };
    return operators[operatorId] ?? operatorId;
  }

  String _renderValueNode(Map<String, dynamic> node) {
    if (node.isEmpty) return '';
    switch (node['type']) {
      case 'variable':
        return _getVariableLabel(node['value'] ?? '');
      case 'constant':
        return node['value'].toString();
      case 'operation':
        return '${_renderValueNode(node['left'] ?? {})} ${_getOperatorLabel(node['operator'] ?? '')} ${_renderValueNode(node['right'] ?? {})}';
      default:
        return 'Unbekannt';
    }
  }
}