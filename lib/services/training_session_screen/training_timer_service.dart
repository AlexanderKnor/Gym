// lib/services/training_session_screen/training_timer_service.dart
import 'dart:async';
import 'package:flutter/services.dart';

/// Service zum Verwalten von Timer-Funktionalitäten während des Trainings
class TrainingTimerService {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isRunning = false;

  // Callback-Funktionen
  Function(int)? onTick;
  Function()? onComplete;

  // Getters
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;

  /// Startet den Timer mit einer bestimmten Dauer in Sekunden
  void startTimer(int durationInSeconds) {
    // Timer zurücksetzen, falls einer läuft
    stopTimer();

    // Neue Timer-Werte setzen
    _remainingSeconds = durationInSeconds;
    _isRunning = true;

    // Timer starten
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;

        // Callback für Tick ausführen
        onTick?.call(_remainingSeconds);

        // Vibrieren, wenn nur noch 3 Sekunden übrig sind
        if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
          HapticFeedback.mediumImpact();
        }
      } else {
        // Timer ist abgelaufen
        _isRunning = false;
        timer.cancel();
        _timer = null;

        // Abschluss-Callback ausführen
        onComplete?.call();

        // Starke Vibration, wenn der Timer abgelaufen ist
        HapticFeedback.heavyImpact();
      }
    });
  }

  /// Stoppt den laufenden Timer
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  /// Pausiert oder setzt den Timer fort
  void togglePause() {
    if (_isRunning) {
      // Timer pausieren
      _timer?.cancel();
      _timer = null;
      _isRunning = false;
    } else if (_remainingSeconds > 0) {
      // Timer fortsetzen
      _isRunning = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          onTick?.call(_remainingSeconds);

          // Vibrieren, wenn nur noch 3 Sekunden übrig sind
          if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
            HapticFeedback.mediumImpact();
          }
        } else {
          // Timer ist abgelaufen
          _isRunning = false;
          timer.cancel();
          _timer = null;
          onComplete?.call();

          // Starke Vibration, wenn der Timer abgelaufen ist
          HapticFeedback.heavyImpact();
        }
      });
    }
  }

  /// Überspringt den Timer
  void skipTimer() {
    stopTimer();
    _remainingSeconds = 0;
    onComplete?.call();
  }

  /// Bereinigt Ressourcen
  void dispose() {
    stopTimer();
    onTick = null;
    onComplete = null;
  }

  /// Konvertiert Sekunden in ein lesbares Format (MM:SS)
  static String formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
