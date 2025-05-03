// lib/widgets/shared/bottom_navigation_bar_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/shared/navigation_provider.dart';
import '../../providers/profile_screen/friendship_provider.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  const BottomNavigationBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);

    // FriendshipProvider mit listen: false abrufen, um unnötige Rebuilds zu vermeiden
    final friendshipProvider =
        Provider.of<FriendshipProvider>(context, listen: false);

    // Wenn der Provider noch nicht initialisiert ist, initialisieren
    if (!friendshipProvider.isInitialized) {
      // Initialisierung im nächsten Frame ausführen, um Build-Konflikte zu vermeiden
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          // Sicherheitscheck, ob der Widget-Baum noch existiert
          print('BottomNavigationBarWidget: Initialisiere FriendshipProvider');
          friendshipProvider.init();
        }
      });
    }

    return BottomAppBar(
      // Shape entfernt, da kein FAB mehr in der Mitte platziert wird
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Training
          IconButton(
            icon: const Icon(Icons.fitness_center),
            color: navigationProvider.currentIndex == 0
                ? Theme.of(context).primaryColor
                : Colors.grey,
            onPressed: () => navigationProvider.setCurrentIndex(0),
          ),
          // Progression Manager
          IconButton(
            icon: const Icon(Icons.trending_up),
            color: navigationProvider.currentIndex == 1
                ? Theme.of(context).primaryColor
                : Colors.grey,
            onPressed: () => navigationProvider.setCurrentIndex(1),
          ),
          // Trainingspläne
          IconButton(
            icon: const Icon(Icons.calendar_today),
            color: navigationProvider.currentIndex == 2
                ? Theme.of(context).primaryColor
                : Colors.grey,
            onPressed: () => navigationProvider.setCurrentIndex(2),
          ),
          // Profil mit Badge für Freundschaftsanfragen
          // Verwende Consumer nur für das Badge, um Rebuilds zu minimieren
          Consumer<FriendshipProvider>(
            builder: (context, provider, child) {
              // Prüfen, ob wir Anfragen haben
              final hasRequests =
                  provider.isInitialized && provider.hasReceivedRequests;
              final requestCount = provider.receivedRequests.length;

              return Stack(
                children: [
                  child!, // Das Icon-Widget aus dem child-Parameter
                  if (hasRequests)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$requestCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
            // Das IconButton-Widget als child übergeben, damit nur das Badge neu gerendert wird
            child: IconButton(
              icon: const Icon(Icons.person),
              color: navigationProvider.currentIndex == 3
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
              onPressed: () {
                // Erst Navigation ausführen
                navigationProvider.setCurrentIndex(3);

                // Dann Daten aktualisieren im nächsten Frame
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted && friendshipProvider.isInitialized) {
                    friendshipProvider.refreshFriendData();
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
