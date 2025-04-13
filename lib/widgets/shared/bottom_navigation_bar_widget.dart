import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/shared/navigation_provider.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  const BottomNavigationBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Training
          IconButton(
            icon: const Icon(Icons.fitness_center),
            color:
                navigationProvider.currentIndex == 0
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
            onPressed: () => navigationProvider.setCurrentIndex(0),
          ),
          // Progression Manager
          IconButton(
            icon: const Icon(Icons.trending_up),
            color:
                navigationProvider.currentIndex == 1
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
            onPressed: () => navigationProvider.setCurrentIndex(1),
          ),
          // Platzhalter für den zentralen Button
          const SizedBox(width: 40),
          // Trainingspläne
          IconButton(
            icon: const Icon(Icons.calendar_today),
            color:
                navigationProvider.currentIndex == 2
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
            onPressed: () => navigationProvider.setCurrentIndex(2),
          ),
          // Profil
          IconButton(
            icon: const Icon(Icons.person),
            color:
                navigationProvider.currentIndex == 3
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
            onPressed: () => navigationProvider.setCurrentIndex(3),
          ),
        ],
      ),
    );
  }
}
