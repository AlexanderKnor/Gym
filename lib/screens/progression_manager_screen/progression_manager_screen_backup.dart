import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import 'profile_detail_screen.dart';
import 'profile_editor_screen.dart';

class ProgressionManagerScreen extends StatelessWidget {
  const ProgressionManagerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider =
        Provider.of<ProgressionManagerProvider>(context, listen: false);
    return ChangeNotifierProvider.value(
      value: provider,
      child: const ProgressionManagerScreenContent(),
    );
  }
}

class ProgressionManagerScreenContent extends StatefulWidget {
  const ProgressionManagerScreenContent({Key? key}) : super(key: key);

  @override
  State<ProgressionManagerScreenContent> createState() =>
      _ProgressionManagerScreenContentState();
}

class _ProgressionManagerScreenContentState
    extends State<ProgressionManagerScreenContent>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  AnimationController? _fadeController;
  AnimationController? _heroController;
  Animation<double>? _fadeAnimation;
  Animation<double>? _heroScaleAnimation;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

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

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: _void,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    _initializeAnimations();

    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<ProgressionManagerProvider>(context, listen: false);
      _loadProfiles(provider);
    });
  }

  void _initializeAnimations() {
    _fadeController?.dispose();
    _heroController?.dispose();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _heroController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController!,
      curve: Curves.easeOutQuart,
    );

    _heroScaleAnimation = CurvedAnimation(
      parent: _heroController!,
      curve: const Cubic(0.175, 0.885, 0.32, 1.275),
    );

    _fadeController!.forward();
    _heroController!.forward();
  }

  Future<void> _loadProfiles(ProgressionManagerProvider provider) async {
    setState(() {
      _isLoading = true;
    });

    await provider.refreshProfiles();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    _heroController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);
    final profiles = provider.progressionsProfile;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _void,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            bottom: false,
            child: _fadeAnimation != null
                ? FadeTransition(
                    opacity: _fadeAnimation!,
                    child: _isLoading
                        ? _buildLoadingView()
                        : profiles.isEmpty
                            ? _buildEmptyState()
                            : _buildProfilesView(context, profiles),
                  )
                : _isLoading
                    ? _buildLoadingView()
                    : profiles.isEmpty
                        ? _buildEmptyState()
                        : _buildProfilesView(context, profiles),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const SizedBox.shrink();
  }

  Widget _buildProfilesView(BuildContext context, List<dynamic> profiles) {
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
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo
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

                    // Add button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _createNewProfile(context);
                      },
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: _nova, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'NEU',
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
                  ],
                ),

                // Plan info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'PROGRESSION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _comet,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'PROFILE MANAGER',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _nova,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
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
              ],
            ),
          ),
        ),

        // Profile list with stagger animation
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with animation
            _heroScaleAnimation != null
                ? ScaleTransition(
                    scale: _heroScaleAnimation!,
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
                  )
                : Stack(
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(
          profile: profile,
          initialTab: 1,
        ),
      ),
    );
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NewProfileScreen(),
                      ),
                    );
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    const Text(
                      'Profil auswählen',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 16),

              // Liste der Profile
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.progressionsProfile.length,
                  itemBuilder: (context, index) {
                    final profile = provider.progressionsProfile[index];
                    final bool isSystemProfile = _isStandardProfile(profile.id);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSystemProfile
                              ? Colors.blue[50]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isSystemProfile
                              ? Icons.verified_outlined
                              : Icons.settings_outlined,
                          size: 18,
                          color: isSystemProfile
                              ? Colors.blue[700]
                              : Colors.grey[700],
                        ),
                      ),
                      title: Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.3,
                        ),
                      ),
                      subtitle: Text(
                        profile.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                DuplicateProfileScreen(profileId: profile.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
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
}

class ProfileCard extends StatelessWidget {
  final dynamic profile;
  final VoidCallback onDemo;

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
    Key? key,
    required this.profile,
    required this.onDemo,
  }) : super(key: key);

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
            // Header row with title and system badge
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

  void _confirmDeleteProfile(BuildContext context, dynamic profile) {
    final provider =
        Provider.of<ProgressionManagerProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red[700],
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Profil löschen',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Möchtest du das Profil "${profile.name}" wirklich löschen?',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Löschen-Button (jetzt links)
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await provider.deleteProfile(profile.id);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Löschen',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Abbrechen-Button (jetzt rechts)
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Abbrechen',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
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
}

class DuplicateProfileScreen extends StatefulWidget {
  final String profileId;

  const DuplicateProfileScreen({
    Key? key,
    required this.profileId,
  }) : super(key: key);

  @override
  State<DuplicateProfileScreen> createState() => _DuplicateProfileScreenState();
}

class _DuplicateProfileScreenState extends State<DuplicateProfileScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<ProgressionManagerProvider>(context, listen: false);
      provider.duplicateProfile(widget.profileId);
      setState(() {
        _isInitialized = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Profil duplizieren',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -0.3,
            ),
          ),
          centerTitle: false,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Colors.black,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return const ProfileEditorScreen();
  }
}

class NewProfileScreen extends StatefulWidget {
  const NewProfileScreen({Key? key}) : super(key: key);

  @override
  State<NewProfileScreen> createState() => _NewProfileScreenState();
}

class _NewProfileScreenState extends State<NewProfileScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<ProgressionManagerProvider>(context, listen: false);
      provider.openProfileEditor(null);
      setState(() {
        _isInitialized = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Neues Profil',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -0.3,
            ),
          ),
          centerTitle: false,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Colors.black,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return const ProfileEditorScreen();
  }
}
