import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shared/navigation_provider.dart';
import 'training_screen/training_screen.dart';
import 'progression_manager_screen/progression_manager_screen.dart';
import 'training_plans_screen/training_plans_screen.dart';
import 'profile_screen/profile_screen.dart';
import 'create_training_plan_screen/create_training_plan_screen.dart';
import '../widgets/shared/bottom_navigation_bar_widget.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);

    // List of screens
    final screens = [
      const TrainingScreen(),
      const ProgressionManagerScreen(),
      const TrainingPlansScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      // AppBar wurde entfernt
      body: screens[navigationProvider.currentIndex],
      bottomNavigationBar: const BottomNavigationBarWidget(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'main_create_plan',
        onPressed: () {
          // Navigation to create a new training plan
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreateTrainingPlanScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
