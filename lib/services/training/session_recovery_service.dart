import 'package:flutter/material.dart';
import '../../providers/training_session_screen/training_session_provider.dart';
import '../../screens/training_session_screen/training_session_screen.dart';

class SessionRecoveryService {
  static Future<void> checkAndRecoverSession(
    BuildContext context,
    TrainingSessionProvider trainingProvider,
  ) async {
    try {
      print('Session-Recovery Check gestartet...');
      final hasActiveSession = await trainingProvider.hasSavedSession();
      print('Hat aktive Session: $hasActiveSession');
      
      if (hasActiveSession && context.mounted) {
        print('Zeige Recovery Dialog...');
        // Session-Recovery Dialog anzeigen
        final shouldRecover = await _showRecoveryDialog(context);
        print('User Entscheidung: $shouldRecover');
        
        if (shouldRecover == true) {
          // Session wiederherstellen
          print('Lade gespeicherte Session...');
          final success = await trainingProvider.loadSavedSession();
          print('Session geladen: $success');
          
          if (success && context.mounted) {
            // Navigation zur TrainingSessionScreen mit eleganten Übergang
            print('Navigiere zur TrainingSessionScreen...');
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => TrainingSessionScreen(
                  trainingPlan: trainingProvider.trainingPlan!,
                  dayIndex: trainingProvider.dayIndex,
                  weekIndex: trainingProvider.weekIndex,
                  isRecoveredSession: true, // Signalisiert wiederhergestellte Session
                ),
                transitionDuration: const Duration(milliseconds: 400),
                reverseTransitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  // Nur Background-Schutz, kein Layout-breaking Container
                  return ColoredBox(
                    color: const Color(0xFF000000), // Prevent white edges
                    child: FadeTransition(
                      opacity: Tween<double>(
                        begin: 0.0,
                        end: 1.0,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      )),
                      child: child,
                    ),
                  );
                },
              ),
            );
            
            // Elegante Success notification
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4500).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFFFF4500),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Session erfolgreich wiederhergestellt',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                backgroundColor: const Color(0xFF1C1C1E),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 3),
                elevation: 8,
              ),
            );
          }
        } else {
          // Session verwerfen
          print('Session wird verworfen...');
          await trainingProvider.clearSavedSession();
        }
      } else {
        print('Keine aktive Session gefunden oder Context nicht mounted');
      }
    } catch (e) {
      print('Fehler beim Session-Recovery Check: $e');
    }
  }

  static Future<bool?> _showRecoveryDialog(BuildContext context) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xFF000000).withOpacity(0.85), // Darker barrier to prevent white edges
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: _SessionRecoveryDialog(),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

class _SessionRecoveryDialog extends StatefulWidget {
  @override
  State<_SessionRecoveryDialog> createState() => _SessionRecoveryDialogState();
}

class _SessionRecoveryDialogState extends State<_SessionRecoveryDialog>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _iconController;
  late Animation<double> _iconRotation;

  // Design system matching training screens
  static const Color _midnight = Color(0xFF000000);
  static const Color _charcoal = Color(0xFF1C1C1E);
  static const Color _graphite = Color(0xFF2C2C2E);
  static const Color _steel = Color(0xFF48484A);
  static const Color _mercury = Color(0xFF8E8E93);
  static const Color _silver = Color(0xFFAEAEB2);
  static const Color _snow = Color(0xFFFFFFFF);
  static const Color _emberCore = Color(0xFFFF4500);

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _iconRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeOutBack,
    ));

    _iconController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: _charcoal,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _steel.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header mit Icon
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      // Animiertes Icon
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: AnimatedBuilder(
                              animation: _iconRotation,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _iconRotation.value * 0.1,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _emberCore.withOpacity(0.15),
                                      border: Border.all(
                                        color: _emberCore,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.restore_rounded,
                                      size: 40,
                                      color: _emberCore,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Title
                      const Text(
                        'Session gefunden',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _snow,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Subtitle
                      Text(
                        'Es wurde eine unterbrochene Trainingssession gefunden. '
                        'Möchtest du diese fortsetzen?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: _silver,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Buttons
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Primärer Button - Fortsetzen
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _emberCore,
                            foregroundColor: _snow,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Ja, fortsetzen',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Sekundärer Button - Neue Session
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            foregroundColor: _silver,
                            backgroundColor: _graphite.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Nein, neue Session starten',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}