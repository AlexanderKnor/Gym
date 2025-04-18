import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/shared/navigation_provider.dart';
import 'providers/create_training_plan_screen/create_training_plan_provider.dart';
import 'providers/auth/auth_provider.dart';
import 'screens/auth/auth_checker_screen.dart';

void main() async {
  // Ensure Flutter widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with project-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize other services (like SharedPreferences)
  // await SharedPreferences.getInstance();

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
        // Add Auth Provider
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
        ),
        // Add other providers as needed
      ],
      child: MaterialApp(
        title: 'Prover',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          // Additional theming options
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
        // Use AuthCheckerScreen as entry point
        home: const AuthCheckerScreen(),
        debugShowCheckedModeBanner: false, // Remove debug banner
      ),
    );
  }
}
