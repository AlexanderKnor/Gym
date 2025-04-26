// lib/widgets/training_session_screen/rest_timer_widget.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/training_session_screen/training_session_provider.dart';

class RestTimerWidget extends StatelessWidget {
  const RestTimerWidget({Key? key}) : super(key: key);

  // Format time as MM:SS with precision typography
  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<TrainingSessionProvider>(context);
    final exercise = sessionProvider.currentExercise;
    final restTimeRemaining = sessionProvider.restTimeRemaining;

    if (exercise == null) {
      return const SizedBox.shrink();
    }

    // Rest time calculations for UI
    final totalRestTime = exercise.restPeriodSeconds;
    final progress = restTimeRemaining / totalRestTime;

    // Color theme based on remaining time
    final Color timerColor = restTimeRemaining <= 3
        ? Colors.red
        : restTimeRemaining <= 10
            ? Colors.orange
            : Colors.black;

    // Calculate animations for ticking effect
    final bool isLastThreeSeconds = restTimeRemaining <= 3;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: timerColor.withOpacity(isLastThreeSeconds ? 0.3 : 0.1),
                width: isLastThreeSeconds ? 1.5 : 1,
              ),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Elegant timer circle
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Progress circle with subtle shadow
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),

                        // Progress animation
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: 1 - progress),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, double value, child) {
                            return CircularProgressIndicator(
                              value: value,
                              strokeWidth: 4,
                              backgroundColor: Colors.transparent,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(timerColor),
                            );
                          },
                        ),

                        // Pulsing animation for last seconds
                        if (isLastThreeSeconds)
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0.8, end: 1.0),
                            duration: const Duration(milliseconds: 500),
                            builder: (context, double value, child) {
                              return AnimatedOpacity(
                                opacity: value,
                                duration: const Duration(milliseconds: 500),
                                child: Container(
                                  width: 88 * value,
                                  height: 88 * value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                        // Timer display with precise typography
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(restTimeRemaining),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                                color: timerColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Rest information with refined typography
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Timer title
                        const Text(
                          'Erholungspause',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Next set info
                        Text(
                          'Nächster Satz: ${sessionProvider.activeSetIndex + 1} von ${sessionProvider.currentExerciseSets.length}',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                            letterSpacing: -0.3,
                          ),
                        ),

                        // Minimal progress bar (Apple-like subtle UI)
                        const SizedBox(height: 12),
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 1 - progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: timerColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Timer controls with refined design
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pause/Play button
                      GestureDetector(
                        onTap: () {
                          sessionProvider.toggleRestTimer();
                          HapticFeedback.mediumImpact();
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sessionProvider.isPaused
                                ? Colors.black
                                : Colors.white,
                            border: Border.all(
                              color: sessionProvider.isPaused
                                  ? Colors.transparent
                                  : Colors.grey[300]!,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            sessionProvider.isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            color: sessionProvider.isPaused
                                ? Colors.white
                                : Colors.black,
                            size: 24,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Skip button with minimalist design
                      GestureDetector(
                        onTap: () {
                          sessionProvider.skipRestTimer();
                          HapticFeedback.mediumImpact();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.skip_next_rounded,
                                size: 16,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Skip',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
