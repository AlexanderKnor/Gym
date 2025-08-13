// lib/screens/profile_screen/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/profile_screen/profile_screen_provider.dart';
import '../../providers/profile_screen/friendship_provider.dart';
import '../auth/auth_checker_screen.dart';
import '../../widgets/profile_screen/components/friend_list_widget.dart';
import '../../widgets/profile_screen/components/add_friend_dialog_widget.dart';
import '../../widgets/profile_screen/components/friend_request_widget.dart';
import '_friend_components.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isInitialized = false;

  // PROVER color system - consistent with progression manager and training plans
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeAndRefresh();
  }

  // Initialisiert den FriendshipProvider wenn nötig und aktualisiert die Daten
  Future<void> _initializeAndRefresh() async {
    if (_isInitialized) return;

    final friendshipProvider =
        Provider.of<FriendshipProvider>(context, listen: false);

    // Initialisieren, falls nicht geschehen
    if (!friendshipProvider.isInitialized) {
      print('ProfileScreen: Initialisiere FriendshipProvider');
      await friendshipProvider.init();
    } else {
      // Sonst nur Daten aktualisieren
      print('ProfileScreen: Aktualisiere Freundschaftsdaten');
      await friendshipProvider.refreshFriendData();
    }

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final friendshipProvider = Provider.of<FriendshipProvider>(context);
    final userData = authProvider.userData;

    return Scaffold(
      backgroundColor: _void,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header with title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ACCOUNT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _proverCore,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'DEIN PROFIL',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: _nova,
                                  letterSpacing: -0.5,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action buttons
                        Row(
                          children: [
                            // Add Friend Button
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                showDialog(
                                  context: context,
                                  builder: (context) => const AddFriendDialogWidget(),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_proverCore.withOpacity(0.8), _proverGlow.withOpacity(0.6)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _proverCore.withOpacity(0.3),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _proverCore.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.person_add_rounded, color: _nova, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'FREUND',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: _nova,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Settings button
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _showSettingsMenu(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _stellar.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _lunar.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.settings_rounded,
                                  color: _stardust,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Profile Header Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: _buildProfileCard(context, userData),
                  ),
                ),

                // Quick Actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: _buildQuickActions(context, friendshipProvider),
                  ),
                ),

                // Account Settings
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: _buildAccountSettings(context),
                  ),
                ),

                // Bottom spacer
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
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

  Widget _buildProfileCard(BuildContext context, dynamic userData) {
    final username = userData?.username ?? 'Benutzer';
    final email = userData?.email ?? '';
    
    return Container(
      padding: const EdgeInsets.all(24),
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
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _void.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Picture
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              // TODO: Implement profile picture selection
            },
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_proverCore, _proverGlow],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _proverCore.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      username.isNotEmpty
                          ? username.substring(0, 1).toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: _nova,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _stellar,
                      shape: BoxShape.circle,
                      border: Border.all(color: _void, width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: _stardust,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 20),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _nova,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    color: _stardust,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _lunar.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Seit ${DateTime.now().year}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _comet,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToFriendsList(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FriendsListScreen(friendshipProvider: Provider.of<FriendshipProvider>(context, listen: false)),
      ),
    );
  }

  void _navigateToFriendRequests(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FriendRequestsScreen(friendshipProvider: Provider.of<FriendshipProvider>(context, listen: false)),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, FriendshipProvider friendshipProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SOCIAL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _comet,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Freunde',
                Icons.people_rounded,
                '${friendshipProvider.friends.length}',
                () {
                  _navigateToFriendsList(context);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Anfragen',
                Icons.mail_rounded,
                '${friendshipProvider.receivedRequests.length}',
                () {
                  _navigateToFriendRequests(context);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, String count, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _proverCore.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _proverCore, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _comet,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _nova,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: _comet, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACCOUNT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _comet,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
          child: Column(
            children: [
              _buildSettingsItem('Benachrichtigungen', Icons.notifications_rounded, () {}),
              _buildSettingsItem('Privatsphäre', Icons.lock_rounded, () {}),
              _buildSettingsItem('Daten exportieren', Icons.download_rounded, () {}),
              _buildSettingsItem('Support', Icons.help_rounded, () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(String title, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: _stardust, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _nova,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: _comet, size: 16),
            ],
          ),
        ),
      ),
    );
  }


  void _showSettingsMenu(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final friendshipProvider = Provider.of<FriendshipProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_proverCore, _proverGlow]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.settings_rounded, color: _nova, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Einstellungen',
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
              _buildMenuOption(
                'Dark Mode',
                Icons.dark_mode_rounded,
                'Aktiviert',
                () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
              _buildMenuOption(
                'Sprache',
                Icons.language_rounded,
                'Deutsch',
                () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
              _buildMenuOption(
                'Über PROVER',
                Icons.info_rounded,
                'v1.0.0',
                () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
              Divider(color: _lunar.withOpacity(0.5), height: 1),
              const SizedBox(height: 20),
              // Sign out option
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.withOpacity(0.15), Colors.red.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context); // Close settings menu first
                      
                      final shouldSignOut = await profileProvider.confirmSignOut(context);
                      
                      if (shouldSignOut && context.mounted) {
                        print('PROFILE SCREEN: Benutzer hat Abmelden bestätigt');
                        
                        friendshipProvider.reset();
                        print('PROFILE SCREEN: FriendshipProvider zurückgesetzt');
                        
                        await authProvider.signOut();
                        print('PROFILE SCREEN: Benutzer abgemeldet');
                        
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => const AuthCheckerScreen()),
                            (route) => false,
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 18, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Abmelden',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.3,
                                    color: Colors.red,
                                  ),
                                ),
                                Text(
                                  'Aus deinem Account ausloggen',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, color: Colors.red.withOpacity(0.5), size: 14),
                        ],
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
  }

  Widget _buildMenuOption(String title, IconData icon, String subtitle, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_lunar.withOpacity(0.3), _lunar.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _lunar.withOpacity(0.4), width: 1),
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
                Icon(icon, size: 18, color: _stardust),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.3,
                          color: _nova,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: _comet,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: _comet, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Friends List Screen
class _FriendsListScreen extends StatelessWidget {
  final FriendshipProvider friendshipProvider;

  const _FriendsListScreen({required this.friendshipProvider});

  // PROVER color system
  static const Color _void = Color(0xFF000000);
  static const Color _nebula = Color(0xFF0F0F12);
  static const Color _stellar = Color(0xFF18181C);
  static const Color _lunar = Color(0xFF242429);
  static const Color _comet = Color(0xFF65656F);
  static const Color _nova = Color(0xFFF5F5F7);
  static const Color _proverCore = Color(0xFFFF4500);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _void,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _stellar.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _lunar.withOpacity(0.5)),
                            ),
                            child: Icon(Icons.arrow_back_rounded, color: _nova, size: 20),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SOCIAL',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _proverCore,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'DEINE FREUNDE',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: _nova,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Friends List Content
                ChangeNotifierProvider.value(
                  value: friendshipProvider,
                  child: Consumer<FriendshipProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(50),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }

                      if (provider.friends.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: _stellar.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _lunar.withOpacity(0.4)),
                                    ),
                                    child: Icon(
                                      Icons.people_outline_rounded,
                                      size: 40,
                                      color: _comet,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Noch keine Freunde',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: _nova,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Füge Freunde hinzu, um deine\nFortschritte zu teilen',
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
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final friend = provider.friends[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: FriendCard(friend: friend, friendshipProvider: provider),
                              );
                            },
                            childCount: provider.friends.length,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}

// Friend Requests Screen
class _FriendRequestsScreen extends StatelessWidget {
  final FriendshipProvider friendshipProvider;

  const _FriendRequestsScreen({required this.friendshipProvider});

  // PROVER color system
  static const Color _void = Color(0xFF000000);
  static const Color _nebula = Color(0xFF0F0F12);
  static const Color _stellar = Color(0xFF18181C);
  static const Color _lunar = Color(0xFF242429);
  static const Color _comet = Color(0xFF65656F);
  static const Color _nova = Color(0xFFF5F5F7);
  static const Color _proverCore = Color(0xFFFF4500);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _void,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _stellar.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _lunar.withOpacity(0.5)),
                            ),
                            child: Icon(Icons.arrow_back_rounded, color: _nova, size: 20),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SOCIAL',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _proverCore,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'FREUNDSCHAFTSANFRAGEN',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: _nova,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Friend Requests Content
                ChangeNotifierProvider.value(
                  value: friendshipProvider,
                  child: Consumer<FriendshipProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(50),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }

                      if (provider.receivedRequests.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: _stellar.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _lunar.withOpacity(0.4)),
                                    ),
                                    child: Icon(
                                      Icons.mail_outline_rounded,
                                      size: 40,
                                      color: _comet,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Keine Anfragen',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: _nova,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Du hast aktuell keine\nFreundschaftsanfragen',
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
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final request = provider.receivedRequests[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: FriendRequestCard(request: request, provider: provider),
                              );
                            },
                            childCount: provider.receivedRequests.length,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}
