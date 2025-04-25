// lib/screens/profile_screen/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/profile_screen/profile_screen_provider.dart';
import '../../providers/profile_screen/friendship_provider.dart';
import '../auth/auth_checker_screen.dart';
import '../../widgets/profile_screen/components/friend_list_widget.dart';
import '../../widgets/profile_screen/components/add_friend_dialog_widget.dart';
import '../../widgets/profile_screen/components/friend_request_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isInitialized = false;

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
      appBar: AppBar(
        title: const Text('Profil'),
        // Alle actions wurden entfernt (Glocke und Refresh-Button)
      ),
      floatingActionButton: profileProvider.selectedTabIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const AddFriendDialogWidget(),
                );
              },
              child: const Icon(Icons.person_add),
            )
          : null,
      body: Column(
        children: [
          // Profil-Header
          _buildProfileHeader(
              context, userData?.username ?? 'Benutzer', userData?.email ?? ''),

          // Tab-Navigation
          _buildTabBar(context, profileProvider),

          // Tab-Inhalt
          Expanded(
            child: _buildTabContent(
                profileProvider.selectedTabIndex, friendshipProvider),
          ),

          // Abmelden-Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final shouldSignOut =
                      await profileProvider.confirmSignOut(context);

                  if (shouldSignOut && context.mounted) {
                    print('PROFILE SCREEN: Benutzer hat Abmelden bestätigt');

                    // Vor dem Abmelden den FriendshipProvider zurücksetzen
                    Provider.of<FriendshipProvider>(context, listen: false)
                        .reset();
                    print('PROFILE SCREEN: FriendshipProvider zurückgesetzt');

                    // Dann abmelden (dadurch wird der Auth-Status geändert)
                    await authProvider.signOut();
                    print('PROFILE SCREEN: Benutzer abgemeldet');

                    // Manuell zum AuthCheckerScreen navigieren, um sicherzustellen, dass
                    // der Login-Screen angezeigt wird
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const AuthCheckerScreen()),
                        (route) => false, // Entferne alle bisherigen Routen
                      );
                    }
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Abmelden'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, String username, String email) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Profilbild
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue,
            child: Text(
              username.isNotEmpty
                  ? username.substring(0, 1).toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Benutzerdaten
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, ProfileProvider provider) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          _buildTabButton(
            context,
            'Freunde',
            Icons.people,
            0,
            provider.selectedTabIndex == 0,
            () => provider.setSelectedTab(0),
          ),
          _buildTabButton(
            context,
            'Anfragen',
            Icons.person_add,
            1,
            provider.selectedTabIndex == 1,
            () => provider.setSelectedTab(1),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context,
    String label,
    IconData icon,
    int index,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(int index, FriendshipProvider friendshipProvider) {
    if (index == 1) {
      // Anfragen-Tab
      return const FriendRequestWidget();
    } else {
      return const FriendListWidget();
    }
  }
}
