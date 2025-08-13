import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/profile_screen/friendship_model.dart';
import '../../providers/friend_profile_screen/friend_profile_provider.dart';
import '../../widgets/friend_profile_screen/friend_training_plans_widget.dart';
import '../../widgets/friend_profile_screen/friend_progression_profiles_widget.dart';

class FriendProfileScreen extends StatefulWidget {
  final FriendshipModel friendship;

  const FriendProfileScreen({
    Key? key,
    required this.friendship,
  }) : super(key: key);

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  int _selectedTabIndex = 0;

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
  void initState() {
    super.initState();
    // Daten beim Öffnen des Bildschirms laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFriendData();
    });
  }

  Future<void> _loadFriendData() async {
    final provider = Provider.of<FriendProfileProvider>(context, listen: false);
    await provider.loadFriendData(widget.friendship);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FriendProfileProvider>(context);
    
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
                // Header with back button and title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 76, 24, 24),
                    child: Row(
                      children: [
                        // Back button
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
                              border: Border.all(
                                color: _lunar.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: _nova,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title section
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
                                widget.friendship.friendUsername.toUpperCase(),
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

                // Friend Profile Header Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: _buildFriendProfileCard(provider),
                  ),
                ),

                // Tab Navigation
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: _buildTabNavigation(provider),
                  ),
                ),

                // Tab Content
                _buildTabContent(provider),
              ],
            ),
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

  Widget _buildFriendProfileCard(FriendProfileProvider provider) {
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
                widget.friendship.friendUsername.isNotEmpty
                    ? widget.friendship.friendUsername.substring(0, 1).toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: _nova,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 20),
          
          // Friend Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.friendship.friendUsername,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _nova,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.friendship.friendEmail,
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
                    'Freund',
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

  Widget _buildTabNavigation(FriendProfileProvider provider) {
    if (!provider.isTabViewEnabled) {
      return _buildLoadingCard(provider);
    }

    return Container(
      padding: const EdgeInsets.all(4),
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
          _buildTabButton('Trainingspläne', Icons.fitness_center_rounded, 0),
          _buildTabButton('Profile', Icons.trending_up_rounded, 1),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, IconData icon, int index) {
    final isSelected = _selectedTabIndex == index;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedTabIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        _proverCore.withOpacity(0.2),
                        _proverGlow.withOpacity(0.1),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: _proverCore.withOpacity(0.5),
                      width: 1,
                    )
                  : null,
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isSelected ? _proverCore : _comet,
                  size: 22,
                ),
                const SizedBox(height: 8),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? _proverCore : _comet,
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(FriendProfileProvider provider) {
    if (provider.isLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
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
            children: [
              CircularProgressIndicator(
                color: _proverCore,
                strokeWidth: 2,
              ),
              const SizedBox(height: 16),
              Text(
                'Lade Freundschaftsdaten...',
                style: TextStyle(
                  fontSize: 14,
                  color: _stardust,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.errorMessage != null) {
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Fehler beim Laden',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _nova,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: _stardust,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _loadFriendData();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                    'ERNEUT VERSUCHEN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _nova,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Initial loading state
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _lunar.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Center(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _loadFriendData();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                Icon(Icons.refresh_rounded, color: _nova, size: 16),
                const SizedBox(width: 8),
                Text(
                  'DATEN LADEN',
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
      ),
    );
  }

  Widget _buildTabContent(FriendProfileProvider provider) {
    if (!provider.isTabViewEnabled) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (_selectedTabIndex == 0) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 100),
          child: FriendTrainingPlansWidget(),
        ),
      );
    } else {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 100),
          child: FriendProgressionProfilesWidget(),
        ),
      );
    }
  }
}
