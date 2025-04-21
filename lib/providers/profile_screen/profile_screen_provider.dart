// lib/providers/profile_screen/profile_screen_provider.dart
import 'package:flutter/material.dart';
import '../../providers/auth/auth_provider.dart';
import 'friendship_provider.dart';

class ProfileProvider extends ChangeNotifier {
  // Tabs für den Profil-Bildschirm
  int _selectedTabIndex = 0;

  // Getters
  int get selectedTabIndex => _selectedTabIndex;

  // Tab ändern
  void setSelectedTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  // Abmelden mit Bestätigung
  Future<bool> confirmSignOut(
      BuildContext context, AuthProvider authProvider) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abmelden'),
        content: const Text('Möchtest du dich wirklich abmelden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abmelden'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await authProvider.signOut();
      return true;
    }

    return false;
  }
}
