// lib/widgets/training_session_screen/rest_timer_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/training_session_screen/training_session_provider.dart';

class RestTimerWidget extends StatelessWidget {
  const RestTimerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<TrainingSessionProvider>(context);
    final exercise = sessionProvider.currentExercise;
    final restTimeRemaining = sessionProvider.restTimeRemaining;

    if (exercise == null) {
      return const SizedBox.shrink();
    }

    // Zeit-Berechnungen
    final totalRestTime = exercise.restPeriodSeconds;
    final progress = restTimeRemaining / totalRestTime;
    final minutes = restTimeRemaining ~/ 60;
    final seconds = restTimeRemaining % 60;

    // Farbe basierend auf verbleibender Zeit
    final Color timerColor = restTimeRemaining <= 3
        ? Colors.red
        : restTimeRemaining <= 10
            ? Colors.orange
            : Colors.black;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Timer-Sektion mit Label
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // "PAUSE" Label mit moderner Typografie
                Text(
                  'PAUSE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 6),

                // Modern gestaltete Timer-Uhr
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[50]!,
                        Colors.grey[100]!,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white,
                        blurRadius: 4,
                        spreadRadius: 1,
                        offset: const Offset(-1, -1),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(1, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Feiner Ziffernblatt-Rand
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 0.5,
                          ),
                        ),
                      ),

                      // Subtilere Tick-Marker
                      ...List.generate(
                        60,
                        (index) {
                          final bool isHour = index % 5 == 0;
                          return Transform.rotate(
                            angle: index * (2 * math.pi / 60),
                            child: Align(
                              alignment: const Alignment(0, -0.85),
                              child: Container(
                                width: isHour ? 1.5 : 0.5,
                                height: isHour ? 5 : 3,
                                decoration: BoxDecoration(
                                  color: isHour
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                  borderRadius: BorderRadius.circular(0.5),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Fortschrittskreis mit abgerundeten Enden
                      SizedBox(
                        width: 62,
                        height: 62,
                        child: CircularProgressIndicator(
                          value: 1 - progress,
                          strokeWidth: 3,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                          strokeCap: StrokeCap.round,
                        ),
                      ),

                      // Zeit mit verbesserter Typografie
                      Text(
                        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: timerColor,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Eleganter Trennstrich
            Container(
              height: 50,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey[300]!.withOpacity(0.0),
                    Colors.grey[300]!.withOpacity(0.8),
                    Colors.grey[300]!.withOpacity(0.0),
                  ],
                ),
              ),
            ),

            // Satz-Information mit besserer Typografie
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nächster Satz',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${sessionProvider.activeSetIndex + 1}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '/${sessionProvider.currentExerciseSets.length}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Modernere Steuerelemente
            Container(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: [
                  // Pause/Play Button mit verbessertem Schatten
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: sessionProvider.isPaused
                          ? Colors.black
                          : Colors.white,
                      shape: const CircleBorder(),
                      elevation: 0,
                      child: InkWell(
                        onTap: () {
                          sessionProvider.toggleRestTimer();
                          HapticFeedback.mediumImpact();
                        },
                        customBorder: const CircleBorder(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            sessionProvider.isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            color: sessionProvider.isPaused
                                ? Colors.white
                                : Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Skip Button mit verbessertem Schatten
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.black,
                      shape: const CircleBorder(),
                      elevation: 0,
                      child: InkWell(
                        onTap: () {
                          sessionProvider.skipRestTimer();
                          HapticFeedback.mediumImpact();
                        },
                        customBorder: const CircleBorder(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: const Icon(
                            Icons.skip_next_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
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
    );
  }
}
