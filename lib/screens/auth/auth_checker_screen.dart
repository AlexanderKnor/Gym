import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/shared/navigation_provider.dart';
import '../../providers/profile_screen/friendship_provider.dart';
import '../main_screen.dart';
import 'login_screen.dart';

class AuthCheckerScreen extends StatefulWidget {
  const AuthCheckerScreen({Key? key}) : super(key: key);

  @override
  State<AuthCheckerScreen> createState() => _AuthCheckerScreenState();
}

class _AuthCheckerScreenState extends State<AuthCheckerScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _transitionController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  bool _isTransitioning = false;
  AuthStatus? _lastAuthStatus;
  
  // Clean color system
  static const Color _midnight = Color(0xFF000000);
  static const Color _charcoal = Color(0xFF1C1C1E);
  static const Color _silver = Color(0xFFAEAEB2);
  static const Color _snow = Color(0xFFFFFFFF);
  static const Color _emberCore = Color(0xFFFF4500);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  Future<void> _initializeAndTransition(BuildContext context) async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    // Navigation zum ersten Tab (Training) setzen
    Provider.of<NavigationProvider>(context, listen: false).setCurrentIndex(0);

    // Freundschaftsdaten initialisieren
    final friendshipProvider =
        Provider.of<FriendshipProvider>(context, listen: false);

    if (!friendshipProvider.isInitialized) {
      await friendshipProvider.init();
    } else {
      await friendshipProvider.refreshFriendData();
    }

    // Session-Recovery Check wird im TrainingScreen durchgeführt

    // Start fade out animation
    await _transitionController.forward();
    
    // Simple transition
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Track auth status changes
    if (_lastAuthStatus != authProvider.status) {
      // Reset transition flag when auth status changes from unauthenticated to authenticated
      if (_lastAuthStatus == AuthStatus.unauthenticated && 
          authProvider.status == AuthStatus.authenticated) {
        _isTransitioning = false;
        print('AUTH CHECKER: Reset _isTransitioning nach Login');
      }
      _lastAuthStatus = authProvider.status;
    }

    switch (authProvider.status) {
      case AuthStatus.authenticated:
        // Trigger transition after frame only if not already transitioning
        if (!_isTransitioning) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isTransitioning) {
              _initializeAndTransition(context);
            }
          });
        }
        // Show loading screen during transition
        return _buildLoadingScreen();
        
      case AuthStatus.unauthenticated:
        // Reset transition flag when showing login
        _isTransitioning = false;
        return const LoginScreen();
        
      case AuthStatus.uninitialized:
      default:
        return _buildLoadingScreen();
    }
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: _midnight,
      body: Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Simple animated logo
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _emberCore.withOpacity(0.15),
                        border: Border.all(color: _emberCore.withOpacity(0.4), width: 2),
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        size: 50,
                        color: _emberCore,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'PROVER',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: _snow,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Wird geladen...',
                style: TextStyle(
                  fontSize: 16,
                  color: _silver,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              // Simple loading indicator
              SizedBox(
                width: 40,
                height: 2,
                child: LinearProgressIndicator(
                  backgroundColor: _charcoal,
                  valueColor: const AlwaysStoppedAnimation<Color>(_emberCore),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}