import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/shared/navigation_provider.dart';
import '../../providers/profile_screen/friendship_provider.dart';
import '../main_screen.dart';
import 'login_screen.dart';

class AuthCheckerScreen extends StatelessWidget {
  const AuthCheckerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    print('AuthCheckerScreen: Auth-Status ist ${authProvider.status}');

    // Based on auth status, show the appropriate screen
    switch (authProvider.status) {
      case AuthStatus.authenticated:
        // Initialisiere den FriendshipProvider, wenn der Benutzer angemeldet ist
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // Navigation zum ersten Tab (Training) setzen
          Provider.of<NavigationProvider>(context, listen: false)
              .setCurrentIndex(0);

          // Freundschaftsdaten initialisieren und Laden sofort starten
          final friendshipProvider =
              Provider.of<FriendshipProvider>(context, listen: false);

          if (!friendshipProvider.isInitialized) {
            print('AuthCheckerScreen: Initialisiere FriendshipProvider');
            // Auf die vollständige Initialisierung warten
            await friendshipProvider.init();
          } else {
            // Auch wenn bereits initialisiert, Daten aktualisieren
            print(
                'AuthCheckerScreen: FriendshipProvider bereits initialisiert, aktualisiere Daten');
            await friendshipProvider.refreshFriendData();
          }
        });
        return const MainScreen();
      case AuthStatus.unauthenticated:
        print('AuthCheckerScreen: Zeige LoginScreen');
        return const LoginScreen();
      case AuthStatus.uninitialized:
      default:
        // Loading screen while auth state is being initialized
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo or name
                const Icon(
                  Icons.fitness_center,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Prover',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fitness & Progression Tracker',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text(
                  'Wird geladen...',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}
