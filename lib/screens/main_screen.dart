// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/shared/navigation_provider.dart';
import 'training_screen/training_screen.dart';
import 'progression_manager_screen/progression_manager_screen.dart';
import 'training_plans_screen/training_plans_screen.dart';
import 'profile_screen/profile_screen.dart';
import '../widgets/shared/bottom_navigation_bar_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Set system UI overlay style to match the aesthetic
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Initialize animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

    // Screen titles for the app bar
    final screenTitles = [
      'Training',
      'Progressionsprofile',
      'Trainingspläne',
      'Profil',
    ];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            screenTitles[navigationProvider.currentIndex],
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          actions: [
            // Add action buttons specific to each screen
            // Benachrichtigungsbutton wurde entfernt

            if (navigationProvider.currentIndex == 2) // Training plans screen
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 22),
                splashRadius: 20,
                onPressed: () {
                  // Handle add training plan
                  HapticFeedback.lightImpact();
                },
              ),

            if (navigationProvider.currentIndex == 3) // Profile screen
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 22),
                splashRadius: 20,
                onPressed: () {
                  // Handle settings
                  HapticFeedback.lightImpact();
                },
              ),
          ],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: screens[navigationProvider.currentIndex],
        ),
        bottomNavigationBar: const BottomNavigationBarWidget(),
      ),
    );
  }
}
