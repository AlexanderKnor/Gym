// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/shared/navigation_provider.dart';
import '../providers/auth/auth_provider.dart';
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

class _MainScreenState extends State<MainScreen> {

  // Ultra-refined color system
  static const Color _midnight = Color(0xFF000000);
  static const Color _obsidian = Color(0xFF0F0F0F);
  static const Color _charcoal = Color(0xFF1C1C1E);
  static const Color _graphite = Color(0xFF2C2C2E);
  static const Color _steel = Color(0xFF48484A);
  static const Color _mercury = Color(0xFF8E8E93);
  static const Color _silver = Color(0xFFAEAEB2);
  static const Color _platinum = Color(0xFFE5E5EA);
  static const Color _snow = Color(0xFFFFFFFF);

  // Signature orange gradient system
  static const Color _emberCore = Color(0xFFFF4500);
  static const Color _emberBright = Color(0xFFFF6B35);
  static const Color _emberSoft = Color(0xFFFF8C69);

  @override
  void initState() {
    super.initState();

    // Set ultra-dark theme system UI
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _midnight,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
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

    return Scaffold(
      backgroundColor: _midnight,
      extendBodyBehindAppBar: true,
      body: screens[navigationProvider.currentIndex],
      bottomNavigationBar: const BottomNavigationBarWidget(),
    );
  }
}
