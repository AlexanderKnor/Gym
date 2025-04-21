// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/shared/navigation_provider.dart';
import 'providers/create_training_plan_screen/create_training_plan_provider.dart';
import 'providers/auth/auth_provider.dart';
import 'providers/training_plans_screen/training_plans_screen_provider.dart';
import 'providers/progression_manager_screen/progression_manager_provider.dart';
import 'providers/training_session_screen/training_session_provider.dart';
import 'providers/profile_screen/profile_screen_provider.dart';
import 'providers/profile_screen/friendship_provider.dart';
import 'screens/auth/auth_checker_screen.dart';

void main() async {
  // Ensure Flutter widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with project-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => TrainingPlansProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => ProgressionManagerProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => TrainingSessionProvider(),
        ),
        // Provider für das Profil-Bildschirm
        ChangeNotifierProvider(
          create: (context) => ProfileProvider(),
        ),
        // Provider für die Freundschaftsfunktion
        ChangeNotifierProvider(
          create: (context) => FriendshipProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Prover',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        home: const AuthCheckerScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
