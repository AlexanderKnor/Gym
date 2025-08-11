// lib/widgets/training_session_screen/rest_timer_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/training_session_screen/training_session_provider.dart';

class RestTimerWidget extends StatelessWidget {
  const RestTimerWidget({Key? key}) : super(key: key);

  // Clean color system matching training screen
  static const Color _midnight = Color(0xFF000000);
  static const Color _charcoal = Color(0xFF1C1C1E);
  static const Color _graphite = Color(0xFF2C2C2E);
  static const Color _steel = Color(0xFF48484A);
  static const Color _mercury = Color(0xFF8E8E93);
  static const Color _silver = Color(0xFFAEAEB2);
  static const Color _snow = Color(0xFFFFFFFF);
  static const Color _emberCore = Color(0xFFFF4500);

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<TrainingSessionProvider>(context);
    final exercise = sessionProvider.currentExercise;
    final restTimeRemaining = sessionProvider.restTimeRemaining;

    // FIX: Keine Timer-Anzeige in folgenden Fällen (aber Timer läuft auch bei negativen Werten)
    final bool anyCompletedSets =
        sessionProvider.currentExerciseSets.any((set) => set.abgeschlossen);

    if (exercise == null ||
        sessionProvider.areAllSetsCompletedForCurrentExercise() ||
        (sessionProvider.activeSetIndex == 0 && !anyCompletedSets) ||
        !sessionProvider.isResting) {
      return const SizedBox.shrink();
    }

    // Zeit-Berechnungen (auch für negative Werte)
    final totalRestTime = exercise.restPeriodSeconds;
    final isOvertime = restTimeRemaining < 0;
    final absoluteTime = restTimeRemaining.abs();
    final progress = isOvertime ? 0.0 : restTimeRemaining / totalRestTime;
    final minutes = absoluteTime ~/ 60;
    final seconds = absoluteTime % 60;
    
    // Formatiere die Zeit mit optionalem Minus-Zeichen
    final timeDisplay = isOvertime 
        ? "-${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}"
        : "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label und Zeit in einer Zeile
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // "Satzpause" oder "Überschreitung" Label
                Text(
                  isOvertime ? "Überschreitung" : "Satzpause",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                    color: isOvertime ? Colors.red : _emberCore,
                  ),
                ),

                // Zeit-Anzeige (mit Minus für Überschreitung)
                Text(
                  timeDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: isOvertime
                        ? Colors.red
                        : restTimeRemaining <= 3
                            ? Colors.red
                            : restTimeRemaining <= 10
                                ? _emberCore
                                : _snow,
                  ),
                ),
              ],
            ),
          ),

          // Moderner Fortschrittsbalken (auch für Überschreitung)
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final progressWidth = isOvertime ? maxWidth : maxWidth * (1 - progress);

              return Stack(
                children: [
                  // Hintergrundbalken
                  Container(
                    height: 4,
                    width: maxWidth,
                    decoration: BoxDecoration(
                      color: isOvertime 
                          ? Colors.red.withOpacity(0.2) 
                          : _steel.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 1,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),

                  // Fortschrittsbalken mit moderner Animation
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: progressWidth),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutQuart,
                    builder: (context, width, _) {
                      return Container(
                        height: 4,
                        width: width,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isOvertime
                                ? [Colors.red.shade600, Colors.red.shade800]
                                : restTimeRemaining <= 3
                                    ? [Colors.red, Colors.red.shade800]
                                    : restTimeRemaining <= 10
                                        ? [_emberCore, _emberCore.withOpacity(0.8)]
                                        : [_emberCore.withOpacity(0.7), _emberCore.withOpacity(0.5)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: (isOvertime || restTimeRemaining <= 3
                                      ? Colors.red
                                      : restTimeRemaining <= 10
                                          ? Colors.orange
                                          : Colors.black)
                                  .withOpacity(0.15),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  // Pulsierender Effekt bei Überschreitung
                  if (isOvertime)
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.3, end: 0.8),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                      builder: (context, opacity, _) {
                        return Container(
                          height: 4,
                          width: maxWidth,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(opacity * 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      },
                      onEnd: () {
                        // Kontinuierliche Animation durch Widget-Rebuilds
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
