import 'package:flutter/foundation.dart';
import '../../models/progression_manager_screen/training_set_model.dart';
import '../../models/progression_manager_screen/progression_profile_model.dart';
import '../../services/progression_manager_screen/one_rm_calculator_service.dart';
import '../../services/progression_manager_screen/progression_calculator_service.dart';

/// Provider für Trainings-Management
/// Verantwortlich für Sätze, aktive Sätze und Empfehlungsberechnung
class ProgressionTrainingProvider with ChangeNotifier {
  // ===== STATE DECLARATIONS =====

  List<TrainingSetModel> _saetze = [
    TrainingSetModel(id: 1, kg: 80, wiederholungen: 8, rir: 2),
    TrainingSetModel(id: 2, kg: 85, wiederholungen: 6, rir: 1),
    TrainingSetModel(id: 3, kg: 87.5, wiederholungen: 5, rir: 1),
    TrainingSetModel(id: 4, kg: 75, wiederholungen: 8, rir: 3),
  ];
  int _aktiverSatz = 1;
  bool _trainingAbgeschlossen = false;

  // ===== GETTERS =====

  List<TrainingSetModel> get saetze => _saetze;
  int get aktiverSatz => _aktiverSatz;
  bool get trainingAbgeschlossen => _trainingAbgeschlossen;

  // ===== METHODEN =====

  void handleChange(int id, String feld, dynamic wert) {
    if (id != _aktiverSatz) return;

    final index = _saetze.indexWhere((satz) => satz.id == id);
    if (index == -1) return;

    final updatedSaetze = List<TrainingSetModel>.from(_saetze);

    switch (feld) {
      case 'kg':
        if (wert is String && wert.isEmpty) {
          // Leere Werte während der Bearbeitung zulassen
        } else {
          final neuerWert = double.tryParse(wert.toString()) ?? 0.0;
          updatedSaetze[index] = updatedSaetze[index].copyWith(kg: neuerWert);
        }
        break;
      case 'wiederholungen':
        if (wert is String && wert.isEmpty) {
          // Leere Werte während der Bearbeitung zulassen
        } else {
          final neuerWert = int.tryParse(wert.toString()) ?? 0;
          updatedSaetze[index] =
              updatedSaetze[index].copyWith(wiederholungen: neuerWert);
        }
        break;
      case 'rir':
        if (wert is String && wert.isEmpty) {
          // Leere Werte während der Bearbeitung zulassen
        } else {
          final neuerWert = int.tryParse(wert.toString()) ?? 0;
          updatedSaetze[index] = updatedSaetze[index].copyWith(rir: neuerWert);
        }
        break;
    }

    _saetze = updatedSaetze;
    notifyListeners();
  }

  double berechne1RM(double gewicht, int wiederholungen, int rir) {
    return OneRMCalculatorService.calculate1RM(gewicht, wiederholungen, rir);
  }

  Map<String, dynamic> berechneProgression(TrainingSetModel satz,
      ProgressionProfileModel? profil, List<TrainingSetModel> alleSaetze) {
    if (profil == null) {
      return {
        'kg': satz.kg,
        'wiederholungen': satz.wiederholungen,
        'rir': satz.rir,
        'neuer1RM': 0.0,
      };
    }

    return ProgressionCalculatorService.berechneProgression(
        satz, profil, alleSaetze);
  }

  // Berechnet die Empfehlung für den aktiven Satz (nur einmal)
  void berechneEmpfehlungFuerAktivenSatz(
      {ProgressionProfileModel? aktuellesProfil, bool notify = true}) {
    final aktiverSatzIndex =
        _saetze.indexWhere((satz) => satz.id == _aktiverSatz);
    if (aktiverSatzIndex == -1 || aktuellesProfil == null) return;

    final aktiverSatz = _saetze[aktiverSatzIndex];

    // Nur berechnen, wenn noch nicht berechnet wurde
    if (!aktiverSatz.empfehlungBerechnet) {
      final empfehlung = ProgressionCalculatorService.berechneProgression(
          aktiverSatz, aktuellesProfil, _saetze);

      final updatedSaetze = List<TrainingSetModel>.from(_saetze);
      updatedSaetze[aktiverSatzIndex] = aktiverSatz.copyWith(
        empfKg: empfehlung['kg'],
        empfWiederholungen: empfehlung['wiederholungen'],
        empfRir: empfehlung['rir'],
        empfehlungBerechnet: true,
      );

      _saetze = updatedSaetze;

      if (notify) {
        notifyListeners();
      }
    }
  }

  // Prüft, ob die Empfehlung angezeigt werden soll
  bool sollEmpfehlungAnzeigen(
      int satzId, int aktiverSatz, bool trainingAbgeschlossen) {
    final satz =
        _saetze.firstWhere((s) => s.id == satzId, orElse: () => _saetze.first);

    // Keine Empfehlung anzeigen, wenn der Satz nicht aktiv ist
    if (satzId != aktiverSatz || trainingAbgeschlossen) return false;

    // Keine Empfehlung anzeigen, wenn noch keine berechnet wurde
    if (!satz.empfehlungBerechnet) return false;

    // Keine Empfehlung anzeigen, wenn alle Werte exakt der Empfehlung entsprechen
    if (satz.kg == satz.empfKg &&
        satz.wiederholungen == satz.empfWiederholungen &&
        satz.rir == satz.empfRir) {
      return false;
    }

    // Ansonsten Empfehlung anzeigen
    return true;
  }

  void empfehlungUebernehmen() {
    final aktiverSatzIndex =
        _saetze.indexWhere((satz) => satz.id == _aktiverSatz);
    if (aktiverSatzIndex == -1) return;

    final aktiverSatz = _saetze[aktiverSatzIndex];

    // Zuerst sicherstellen, dass eine Empfehlung berechnet wurde
    if (!aktiverSatz.empfehlungBerechnet) {
      berechneEmpfehlungFuerAktivenSatz();
      return; // Warten auf nächsten Render-Zyklus
    }

    // Dann die Empfehlung übernehmen
    final updatedSaetze = List<TrainingSetModel>.from(_saetze);
    updatedSaetze[aktiverSatzIndex] = aktiverSatz.copyWith(
      kg: aktiverSatz.empfKg ?? aktiverSatz.kg,
      wiederholungen:
          aktiverSatz.empfWiederholungen ?? aktiverSatz.wiederholungen,
      rir: aktiverSatz.empfRir ?? aktiverSatz.rir,
    );

    _saetze = updatedSaetze;
    notifyListeners();
  }

  void satzAbschliessen() {
    final aktiverSatzDaten = _saetze.firstWhere(
      (satz) => satz.id == _aktiverSatz,
      orElse: () => _saetze.first,
    );

    if (aktiverSatzDaten.kg <= 0 || aktiverSatzDaten.wiederholungen <= 0) {
      return;
    }

    _saetze = _saetze.map((satz) {
      if (satz.id == _aktiverSatz) {
        return satz.copyWith(abgeschlossen: true);
      }
      return satz;
    }).toList();

    if (_aktiverSatz < 4) {
      _aktiverSatz++;

      // Für neuen aktiven Satz nach kurzem Delay die Empfehlung berechnen
      Future.microtask(() {
        berechneEmpfehlungFuerAktivenSatz();
      });
    } else {
      _trainingAbgeschlossen = true;
    }

    notifyListeners();
  }

  void trainingZuruecksetzen({ProgressionProfileModel? aktuellesProfil}) {
    // Sätze zurücksetzen und Empfehlungen löschen
    _saetze = _saetze
        .map((satz) => satz.copyWith(
              abgeschlossen: false,
              empfehlungBerechnet: false,
              empfKg: null,
              empfWiederholungen: null,
              empfRir: null,
            ))
        .toList();

    _aktiverSatz = 1;
    _trainingAbgeschlossen = false;

    // Für ersten Satz Empfehlung neu berechnen
    Future.microtask(() {
      berechneEmpfehlungFuerAktivenSatz(aktuellesProfil: aktuellesProfil);
    });

    notifyListeners();
  }

  // Übung abschließen und zur nächsten übergehen oder dieselbe wiederholen
  void uebungAbschliessen(
      {bool neueUebung = false, ProgressionProfileModel? aktuellesProfil}) {
    // Sätze zurücksetzen und Empfehlungen löschen
    _saetze = _saetze
        .map((satz) => satz.copyWith(
              abgeschlossen: false,
              empfehlungBerechnet: false,
              empfKg: null,
              empfWiederholungen: null,
              empfRir: null,
            ))
        .toList();

    _aktiverSatz = 1;
    _trainingAbgeschlossen = false;

    // Wenn zu neuer Übung gewechselt wird, könnte man hier theoretisch
    // zur nächsten Übung in einem Trainingsplan wechseln
    // (für zukünftige Erweiterung)

    // Für ersten Satz Empfehlung neu berechnen
    Future.microtask(() {
      berechneEmpfehlungFuerAktivenSatz(aktuellesProfil: aktuellesProfil);
    });

    notifyListeners();
  }
}
