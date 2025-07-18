// lib/main.dart
import 'dart:async';
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
import 'services/training/session_recovery_service.dart';

void main() async {
  // Ensure Flutter widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set orientation to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // System UI wird jetzt kontinuierlich in MyAppState verwaltet

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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Timer? _systemUITimer;

  @override
  void initState() {
    super.initState();
    // Add global back button interceptor
    BackButtonInterceptor.add(myInterceptor);

    // System UI Observer hinzufügen
    WidgetsBinding.instance.addObserver(this);

    // Kontinuierliche System UI Unterdrückung
    _startSystemUIHiding();
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(myInterceptor);
    WidgetsBinding.instance.removeObserver(this);
    _systemUITimer?.cancel();
    super.dispose();
  }

  // Überwacht App-Lifecycle Änderungen
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App wurde wieder fokussiert - System UI erneut verstecken
      _hideSystemUI();
    }
  }

  // Startet kontinuierliche System UI Überwachung
  void _startSystemUIHiding() {
    _hideSystemUI();

    // Timer für periodische Überprüfung (alle 2 Sekunden)
    _systemUITimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _hideSystemUI();
    });
  }

  // Versteckt System UI komplett
  void _hideSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF000000),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  // Returns 'true' to indicate that the back button event
  // was intercepted and should not be processed further
  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    return true; // Stops the back button event
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
        // Provider for profile screen
        ChangeNotifierProvider(
          create: (context) => ProfileProvider(),
        ),
        // Provider for friendship functionality
        ChangeNotifierProvider(
          create: (context) => FriendshipProvider(),
        ),
        // Provider for friend profile display
        ChangeNotifierProvider(
          create: (context) => FriendProfileProvider(),
        ),
      ],
      child: Container(
        color: const Color(
            0xFF000000), // Prevent any white background at root level
        child: MaterialApp(
          title: 'Prover',
          theme: ThemeData(
            brightness: Brightness.dark, // Enforce dark theme globally
            // Comprehensive dark color scheme to prevent white flashing
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF4500), // Orange
              secondary: Color(0xFF48484A), // Steel
              onPrimary: Color(0xFF000000), // Midnight
              onSecondary: Color(0xFFFFFFFF), // Snow
              surface: Color(0xFF1C1C1E), // Charcoal
              background: Color(0xFF000000), // Midnight
              onSurface: Color(0xFFFFFFFF), // Snow
              onBackground: Color(0xFFFFFFFF), // Snow
              error: Color(0xFFFF453A),
            ),
            scaffoldBackgroundColor: const Color(0xFF000000), // Midnight
            canvasColor: const Color(0xFF000000), // Midnight
            cardColor: const Color(0xFF1C1C1E), // Dark card background
            dialogBackgroundColor:
                const Color(0xFF1C1C1E), // Dark dialog background

            // Dark typography
            textTheme: const TextTheme(
              titleLarge: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                color: Color(0xFFFFFFFF), // Snow
              ),
              titleMedium: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                color: Color(0xFFFFFFFF), // Snow
              ),
              titleSmall: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFFFFF), // Snow
              ),
              bodyLarge: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFFAEAEB2), // Silver
              ),
              bodyMedium: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFFAEAEB2), // Silver
              ),
              bodySmall: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF8E8E93), // Mercury
              ),
            ),

            // Dark app bar style
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF000000), // Midnight background
              foregroundColor: Color(0xFFFFFFFF), // Snow foreground
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                color: Color(0xFFFFFFFF), // Snow
              ),
              iconTheme: IconThemeData(
                color: Color(0xFFFFFFFF), // Snow
                size: 22,
              ),
            ),

            // Dark button style
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4500), // Orange
                foregroundColor: const Color(0xFFFFFFFF), // Snow
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ),

            // Dark text button style
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFAEAEB2), // Silver
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFAEAEB2), // Silver
                ),
              ),
            ),

            // Dark input decoration
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color(0xFF2C2C2E), // Graphite
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintStyle: TextStyle(
                color: Color(0xFF8E8E93), // Mercury
                fontSize: 15,
              ),
            ),

            // Visual density
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: const AuthCheckerScreen(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
