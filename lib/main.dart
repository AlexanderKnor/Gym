// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'firebase_options.dart';
import 'providers/shared/navigation_provider.dart';
import 'providers/create_training_plan_screen/create_training_plan_provider.dart';
import 'providers/auth/auth_provider.dart';
import 'providers/training_plans_screen/training_plans_screen_provider.dart';
import 'providers/progression_manager_screen/progression_manager_provider.dart';
import 'providers/training_session_screen/training_session_provider.dart';
import 'providers/profile_screen/profile_screen_provider.dart';
import 'providers/profile_screen/friendship_provider.dart';
import 'providers/friend_profile_screen/friend_profile_provider.dart';
import 'screens/auth/auth_checker_screen.dart';

void main() async {
  // Ensure Flutter widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Setze die Orientierung auf nur Portrait-Modus
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase with project-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Füge einen globalen Interceptor für den Zurück-Button hinzu
    BackButtonInterceptor.add(myInterceptor);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  // Diese Funktion gibt 'true' zurück, um anzuzeigen, dass der Zurück-Button-Event
  // abgefangen wurde und nicht weiter verarbeitet werden soll
  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    return true; // Stoppt den Zurück-Button-Event
  }

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
        // NEU: Provider für die Freundesprofil-Anzeige
        ChangeNotifierProvider(
          create: (context) => FriendProfileProvider(),
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
