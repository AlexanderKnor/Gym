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

  // Set orientation to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style for clean appearance
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

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
    // Add global back button interceptor
    BackButtonInterceptor.add(myInterceptor);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
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
      child: MaterialApp(
        title: 'Prover',
        theme: ThemeData(
          // Set color scheme to match training session screen
          colorScheme: ColorScheme.light(
            primary: Colors.black,
            secondary: Colors.grey[800]!,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            surface: Colors.white,
            background: Colors.white,
            error: Colors.red[700]!,
          ),

          // Clean, modern typography
          textTheme: TextTheme(
            titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: Colors.grey[900],
            ),
            titleMedium: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: Colors.grey[900],
            ),
            titleSmall: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.grey[800],
            ),
            bodyMedium: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.grey[800],
            ),
            bodySmall: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.grey[600],
            ),
          ),

          // Clean app bar style
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.grey[900],
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: Colors.grey[900],
            ),
            iconTheme: IconThemeData(
              color: Colors.grey[900],
              size: 22,
            ),
          ),

          // Modern button style
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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

          // Matching text button style
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[800],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),

          // Card style with subtle shadows
          cardTheme: CardTheme(
            color: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),

          // Input decoration
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 15,
            ),
          ),

          // Global scaffold background
          scaffoldBackgroundColor: Colors.white,

          // Visual density
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const AuthCheckerScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
