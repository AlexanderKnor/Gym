import 'package:flutter/material.dart';

/// Professional smooth page transition with premium vertical slide animation
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget Function(BuildContext) builder;
  final VoidCallback? onTransitionComplete;
  final Duration? customDuration;

  SmoothPageRoute({
    required this.builder,
    this.onTransitionComplete,
    this.customDuration,
  }) : super(
          transitionDuration: customDuration ?? const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            
            // PREMIUM VERTICAL SLIDE ANIMATION
            // Opening: Slides up from bottom (elegant entrance)
            // Closing: Slides down to bottom (natural exit)
            
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.0, 1.0), // Start below screen
              end: Offset.zero,               // End at normal position
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Cubic(0.4, 0.0, 0.2, 1.0), // Material Design easing
            ));

            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
            ));

            // Call completion callback when animation is done
            if (animation.isCompleted && onTransitionComplete != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onTransitionComplete!();
              });
            }

            // Clean vertical slide animation with fade
            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Extension to make smooth navigation easier throughout the app
extension SmoothNavigation on NavigatorState {
  /// Push a new route with smooth animation
  Future<T?> pushSmooth<T extends Object?>(Widget Function(BuildContext) builder) {
    return push<T>(SmoothPageRoute<T>(builder: builder));
  }
  
  /// Replace current route with smooth animation
  Future<T?> pushReplacementSmooth<T extends Object?, TO extends Object?>(
    Widget Function(BuildContext) builder, {
    TO? result,
  }) {
    return pushReplacement<T, TO>(
      SmoothPageRoute<T>(builder: builder),
      result: result,
    );
  }
  
  /// Push and remove until with smooth animation
  Future<T?> pushAndRemoveUntilSmooth<T extends Object?>(
    Widget Function(BuildContext) builder,
    bool Function(Route<dynamic>) predicate,
  ) {
    return pushAndRemoveUntil<T>(
      SmoothPageRoute<T>(builder: builder),
      predicate,
    );
  }
}

/// Quick utility methods for common navigation patterns
class SmoothNavigator {
  /// Push with smooth animation
  static Future<T?> push<T>(BuildContext context, Widget Function(BuildContext) builder) {
    return Navigator.of(context).push<T>(SmoothPageRoute<T>(builder: builder));
  }
  
  /// Replace with smooth animation
  static Future<T?> pushReplacement<T, TO>(
    BuildContext context, 
    Widget Function(BuildContext) builder, {
    TO? result,
  }) {
    return Navigator.of(context).pushReplacement<T, TO>(
      SmoothPageRoute<T>(builder: builder),
      result: result,
    );
  }
  
  /// Pop with custom result
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }
}