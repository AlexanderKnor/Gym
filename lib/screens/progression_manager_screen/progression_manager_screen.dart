import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../utils/smooth_page_route.dart';
import 'profile_detail_screen.dart';
import 'profile_editor_screen.dart';

class ProgressionManagerScreen extends StatefulWidget {
  const ProgressionManagerScreen({super.key});

  @override
  State<ProgressionManagerScreen> createState() =>
      _ProgressionManagerScreenState();
}

class _ProgressionManagerScreenState extends State<ProgressionManagerScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _heroController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _heroScaleAnimation;

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

    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfiles();
    });
  }

  Future<void> _loadProfiles() async {
    if (_sessionRecoveryChecked) return;
    _sessionRecoveryChecked = true;

    final provider =
        Provider.of<ProgressionManagerProvider>(context, listen: false);
    await provider.refreshProfiles();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _heroController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);
    final profiles = provider.progressionsProfile;

    return Scaffold(
      backgroundColor: _void,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            bottom: false,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: profiles.isEmpty
                  ? _buildEmptyStateView(context)
                  : _buildProfilesView(context, profiles),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Widget _buildProfilesView(BuildContext context, List<dynamic> profiles) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Space for fixed header and page content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                24, 76, 24, 24), // 60px header + 16px spacing
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
                        'PROGRESSION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _proverCore,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'PROFILE MANAGER',
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
                        '${profiles.length} Profile verfügbar',
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
                    _createNewProfile(context);
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

        // Profile list with stagger animation
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final profile = profiles[index];

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
                          child: ProfileCard(
                            profile: profile,
                            onDemo: () => _openProfileDemo(context, profile),
                            onOptions: () => _showProfileOptions(context, profile),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              childCount: profiles.length,
            ),
          ),
        ),
      ],
    );
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
                'PROGRESSION',
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
              'Intelligente Trainingssteuerung',
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
                    _createNewProfile(context);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Text(
                      'ERSTES PROFIL ERSTELLEN',
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

  void _openProfileDemo(BuildContext context, dynamic profile) {
    SmoothNavigator.push(context, (context) => ProfileDetailScreen(
      profile: profile,
      initialTab: 1,
    ));
  }

  void _createNewProfile(BuildContext context) {
    final provider =
        Provider.of<ProgressionManagerProvider>(context, listen: false);

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
                        Icons.add_rounded,
                        color: _nova,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Neues Profil erstellen',
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

                // Option 1: Leeres Profil
                _buildOptionButton(
                  icon: Icons.note_add_outlined,
                  label: 'Leeres Profil erstellen',
                  onTap: () {
                    Navigator.of(context).pop();
                    SmoothNavigator.push(context, (context) => const NewProfileScreen());
                  },
                  isPrimary: false,
                ),

                const SizedBox(height: 12),

                // Option 2: Duplizieren
                _buildOptionButton(
                  icon: Icons.content_copy_rounded,
                  label: 'Bestehendes Profil duplizieren',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showProfileSelectionSheet(context, provider);
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

  Widget _buildOptionButton({
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

  void _showProfileSelectionSheet(
      BuildContext context, ProgressionManagerProvider provider) {
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
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                child: Row(
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
                        Icons.content_copy_rounded,
                        color: _nova,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Profil auswählen',
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
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _lunar.withOpacity(0.0),
                      _lunar.withOpacity(0.8),
                      _lunar.withOpacity(0.0),
                    ],
                  ),
                ),
              ),

              // Liste der Profile
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.progressionsProfile.length,
                  itemBuilder: (context, index) {
                    final profile = provider.progressionsProfile[index];
                    final bool isSystemProfile = _isStandardProfile(profile.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _lunar.withOpacity(0.3),
                            _lunar.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _lunar.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            SmoothNavigator.push(context, (context) =>
                                DuplicateProfileScreen(profileId: profile.id));
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: isSystemProfile
                                        ? LinearGradient(
                                            colors: [Color(0xFF007AFF), Color(0xFF40A2FF)],
                                          )
                                        : LinearGradient(
                                            colors: [_asteroid, _comet],
                                          ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isSystemProfile
                                        ? Icons.verified_outlined
                                        : Icons.settings_outlined,
                                    size: 20,
                                    color: _nova,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              profile.name,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: -0.3,
                                                color: _nova,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isSystemProfile)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [Color(0xFF007AFF), Color(0xFF40A2FF)],
                                                ),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'SYSTEM',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  color: _nova,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        profile.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _stardust,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Arrow
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: _comet,
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
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  bool _isStandardProfile(String profileId) {
    return profileId == 'double-progression' ||
        profileId == 'linear-periodization' ||
        profileId == 'rir-based' ||
        profileId == 'set-consistency';
  }

  void _showProfileOptions(BuildContext context, dynamic profile) {
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
                        Icons.settings_outlined,
                        color: _nova,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Profil Optionen',
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

                // Option 1: Profil bearbeiten
                _buildProfileOptionButton(
                  icon: Icons.edit_outlined,
                  label: 'Profil bearbeiten',
                  onTap: () {
                    Navigator.of(context).pop();
                    _editProfile(context, profile);
                  },
                  isPrimary: false,
                ),

                const SizedBox(height: 12),

                // Option 2: Profil löschen
                _buildProfileOptionButton(
                  icon: Icons.delete_outline,
                  label: 'Profil löschen',
                  onTap: () {
                    Navigator.of(context).pop();
                    _confirmDeleteProfile(context, profile);
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

  Widget _buildProfileOptionButton({
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

  void _editProfile(BuildContext context, dynamic profile) {
    SmoothNavigator.push(context, (context) => ProfileDetailScreen(
      profile: profile,
      initialTab: 0, // Editor tab (0 = Editor, 1 = Demo)
    ));
  }

  void _confirmDeleteProfile(BuildContext context, dynamic profile) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: AlertDialog(
          backgroundColor: _stellar,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _lunar.withOpacity(0.3)),
          ),
          title: Text(
            'Profil löschen',
            style: TextStyle(
              color: _nova,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Sind Sie sicher, dass Sie "${profile.name}" dauerhaft löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.',
            style: TextStyle(
              color: _stardust,
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Abbrechen',
                style: TextStyle(
                  color: _stardust,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red, Colors.red.shade400],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    _deleteProfile(context, profile);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Löschen',
                      style: TextStyle(
                        color: _nova,
                        fontWeight: FontWeight.w600,
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

  void _deleteProfile(BuildContext context, dynamic profile) async {
    final provider = Provider.of<ProgressionManagerProvider>(context, listen: false);
    
    try {
      await provider.deleteProfile(profile.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profil "${profile.name}" wurde gelöscht',
              style: TextStyle(color: _nova),
            ),
            backgroundColor: _stellar,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fehler beim Löschen des Profils',
              style: TextStyle(color: _nova),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class ProfileCard extends StatelessWidget {
  final dynamic profile;
  final VoidCallback onDemo;
  final VoidCallback onOptions;

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

  const ProfileCard({
    super.key,
    required this.profile,
    required this.onDemo,
    required this.onOptions,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSystemProfile = _isStandardProfile(profile.id);

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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _lunar.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: _void.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with title and badge/options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    profile.name,
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
                if (isSystemProfile)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_systemBlue, _systemBlueLight],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'SYSTEM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _nova,
                        letterSpacing: 0.8,
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onOptions();
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

            // Description text
            Text(
              profile.description,
              style: TextStyle(
                fontSize: 13,
                color: _stardust,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),

            // Metrics and action row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Metrics
                Row(
                  children: [
                    _buildMetric(
                        '${profile.config['targetRepsMin']}-${profile.config['targetRepsMax']}',
                        'Wdh'),
                    const SizedBox(width: 16),
                    _buildMetric(
                        '${profile.config['targetRIRMin']}-${profile.config['targetRIRMax']}',
                        'RIR'),
                    const SizedBox(width: 16),
                    _buildMetric('${profile.rules.length}', 'Regeln'),
                  ],
                ),

                // Demo button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onDemo();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      'DEMO',
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

  bool _isStandardProfile(String profileId) {
    return profileId == 'double-progression' ||
        profileId == 'linear-periodization' ||
        profileId == 'rir-based' ||
        profileId == 'set-consistency';
  }
}

class DuplicateProfileScreen extends StatefulWidget {
  final String profileId;

  const DuplicateProfileScreen({
    super.key,
    required this.profileId,
  });

  @override
  State<DuplicateProfileScreen> createState() => _DuplicateProfileScreenState();
}

class _DuplicateProfileScreenState extends State<DuplicateProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return ProfileEditorScreen(
      initialProfileAction: () => Provider.of<ProgressionManagerProvider>(context, listen: false).duplicateProfile(widget.profileId),
    );
  }
}

class NewProfileScreen extends StatefulWidget {
  const NewProfileScreen({super.key});

  @override
  State<NewProfileScreen> createState() => _NewProfileScreenState();
}

class _NewProfileScreenState extends State<NewProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return ProfileEditorScreen(
      initialProfileAction: () => Provider.of<ProgressionManagerProvider>(context, listen: false).openProfileEditor(null),
    );
  }
}
