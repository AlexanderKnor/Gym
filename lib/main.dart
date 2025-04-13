import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/shared/navigation_provider.dart';
import 'providers/create_training_plan_screen/create_training_plan_provider.dart';
import 'screens/training_screen/training_screen.dart';
import 'screens/progression_manager_screen/progression_manager_screen.dart';
import 'screens/training_plans_screen/training_plans_screen.dart';
import 'screens/profile_screen/profile_screen.dart';
import 'screens/create_training_plan_screen/create_training_plan_screen.dart';
import 'widgets/shared/bottom_navigation_bar_widget.dart';

void main() async {
  // Sicherstellen, dass Flutter-Widgets initialisiert sind
  WidgetsFlutterBinding.ensureInitialized();

  // SharedPreferences initialisieren
  await SharedPreferences.getInstance();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
        ChangeNotifierProvider(
          create: (context) => CreateTrainingPlanProvider(),
        ),
        // Hier kÃ¶nnen spÃ¤ter weitere Provider hinzugefÃ¼gt werden
      ],
      child: MaterialApp(
        title: 'Fitness App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);

    // Liste der Screens
    final screens = [
      const TrainingScreen(),
      const ProgressionManagerScreen(),
      const TrainingPlansScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[navigationProvider.currentIndex],
      bottomNavigationBar: const BottomNavigationBarWidget(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigation zum Screen fÃ¼r die Erstellung eines neuen Trainingsplans
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
