import 'package:flutter/material.dart';

/// Professional smooth page transition for consistent UX throughout the app
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget Function(BuildContext) builder;
  final VoidCallback? onTransitionComplete;
  final Duration? customDuration;

  SmoothPageRoute({
    required this.builder,
    this.onTransitionComplete,
    this.customDuration,
  }) : super(
          transitionDuration: customDuration ?? const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Professional curved animations for premium feel
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.15, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Cubic(0.25, 0.1, 0.0, 1.0), // Custom iOS-like easing
            ));

            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
            ));

            final scaleAnimation = Tween<double>(
              begin: 0.97,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Cubic(0.25, 0.1, 0.0, 1.0),
            ));

            // Call completion callback when animation is done
            if (animation.isCompleted && onTransitionComplete != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onTransitionComplete!();
              });
            }

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: child,
                ),
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