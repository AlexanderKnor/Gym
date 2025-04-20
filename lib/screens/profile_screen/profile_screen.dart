import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth/auth_provider.dart';
import '../auth/auth_checker_screen.dart'; // Importieren für die Navigation

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bildschirmtitel
              const Text(
                'Profil',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // Hier könnten weitere Profil-Informationen angezeigt werden
              // ...

              // Logout-Button am Ende der Seite
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Dialog zum Bestätigen des Abmeldens anzeigen
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Abmelden'),
                        content:
                            const Text('Möchtest du dich wirklich abmelden?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Abbrechen'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context); // Dialog schließen
                              await authProvider.signOut(); // Abmelden

                              // Nach dem Abmelden direkt zur AuthCheckerScreen navigieren
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AuthCheckerScreen(),
                                  ),
                                  (route) =>
                                      false, // Alle vorherigen Routen entfernen
                                );
                              }
                            },
                            child: const Text('Abmelden'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
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
            ],
          ),
        ),
      ),
    );
  }
}
