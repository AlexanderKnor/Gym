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
    // FriendshipProvider hinzufügen, um auf offene Anfragen zugreifen zu können
    final friendshipProvider = Provider.of<FriendshipProvider>(context);

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
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
          // Platzhalter für den zentralen Button
          const SizedBox(width: 40),
          // Trainingspläne
          IconButton(
            icon: const Icon(Icons.calendar_today),
            color: navigationProvider.currentIndex == 2
                ? Theme.of(context).primaryColor
                : Colors.grey,
            onPressed: () => navigationProvider.setCurrentIndex(2),
          ),
          // Profil mit Badge für Freundschaftsanfragen
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.person),
                color: navigationProvider.currentIndex == 3
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                onPressed: () => navigationProvider.setCurrentIndex(3),
              ),
              // Badge anzeigen, wenn Anfragen vorhanden sind und Provider initialisiert ist
              if (friendshipProvider.isInitialized &&
                  friendshipProvider.hasReceivedRequests)
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
                      '${friendshipProvider.receivedRequests.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
