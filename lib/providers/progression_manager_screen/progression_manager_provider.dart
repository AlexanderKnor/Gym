// lib/providers/progression_manager_screen/progression_manager_provider.dart
import 'package:flutter/foundation.dart';
import 'progression_training_provider.dart';
import 'progression_profile_provider.dart';
import 'progression_rule_provider.dart';
import 'progression_ui_provider.dart';
import '../../models/progression_manager_screen/training_set_model.dart';
import '../../models/progression_manager_screen/progression_profile_model.dart';
import '../../models/progression_manager_screen/progression_rule_model.dart';
import '../../models/progression_manager_screen/progression_condition_model.dart';
import '../../models/progression_manager_screen/progression_action_model.dart';
import '../../models/progression_manager_screen/progression_variable_model.dart';
import '../../models/progression_manager_screen/progression_operator_model.dart';
import '../../services/progression_manager_screen/progression_calculator_service.dart';

/// Hauptprovider für den Progression Manager Screen
/// Dieser Provider orchestriert die spezialisierten Sub-Provider
class ProgressionManagerProvider with ChangeNotifier {
  // Sub-Provider
  final ProgressionTrainingProvider _trainingProvider;
  // Mit late als nicht-null deklarieren, wird im Konstruktor immer initialisiert
  late final ProgressionProfileProvider profileProvider;
  final ProgressionRuleProvider _ruleProvider;
  final ProgressionUIProvider _uiProvider;

  // Für Demo-Zwecke können wir eine lokale ID verwenden
  String? _currentDemoProfileId;

  ProgressionManagerProvider({
    ProgressionTrainingProvider? trainingProvider,
    ProgressionProfileProvider? profileProvider,
    ProgressionRuleProvider? ruleProvider,
    ProgressionUIProvider? uiProvider,
  })  : _trainingProvider = trainingProvider ?? ProgressionTrainingProvider(),
        _ruleProvider = ruleProvider ?? ProgressionRuleProvider(),
        _uiProvider = uiProvider ?? ProgressionUIProvider() {
    // Initialisierung von profileProvider innerhalb des Konstruktors
    this.profileProvider = profileProvider ?? ProgressionProfileProvider();

    _initializeListeners();

    // Profile laden
    Future.microtask(() async {
      await this.profileProvider.loadSavedProfiles();
      // Verwende das erste Profil in der Liste für Demo-Zwecke
      if (this.profileProvider.progressionsProfile.isNotEmpty) {
        _currentDemoProfileId =
            this.profileProvider.progressionsProfile.first.id;
      }
      // Initialisiere die Trainingsberechnung
      _trainingProvider.berechneEmpfehlungFuerAktivenSatz(
          aktuellesProfil:
              this.profileProvider.getProfileById(_currentDemoProfileId));
    });
  }

  void _initializeListeners() {
    // Verbinde die Sub-Provider miteinander
    profileProvider.addListener(notifyListeners);
    _trainingProvider.addListener(notifyListeners);
    _ruleProvider.addListener(notifyListeners);
    _uiProvider.addListener(notifyListeners);
  }

  @override
  void dispose() {
    profileProvider.removeListener(notifyListeners);
    _trainingProvider.removeListener(notifyListeners);
    _ruleProvider.removeListener(notifyListeners);
    _uiProvider.removeListener(notifyListeners);

    profileProvider.dispose();
    _trainingProvider.dispose();
    _ruleProvider.dispose();
    _uiProvider.dispose();
    super.dispose();
  }

  // ===== DELEGIERTE GETTERS =====

  // Training Provider Getters
  List<TrainingSetModel> get saetze => _trainingProvider.saetze;
  int get aktiverSatz => _trainingProvider.aktiverSatz;
  bool get trainingAbgeschlossen => _trainingProvider.trainingAbgeschlossen;

  // Profile Provider Getters
  Map<String, dynamic> get progressionsConfig {
    final profil = aktuellesProfil;
    return profil?.config ?? {};
  }

  List<ProgressionProfileModel> get progressionsProfile =>
      profileProvider.progressionsProfile;

  ProgressionProfileModel? get aktuellesProfil => _currentDemoProfileId != null
      ? profileProvider.getProfileById(_currentDemoProfileId)
      : null;

  ProgressionProfileModel? get bearbeitetesProfil =>
      profileProvider.bearbeitetesProfil;

  // Rule Provider Getters
  ProgressionRuleModel? get bearbeiteteRegel => _ruleProvider.bearbeiteteRegel;
  String get regelTyp => _ruleProvider.regelTyp;
  List<ProgressionConditionModel> get regelBedingungen =>
      _ruleProvider.regelBedingungen;
  Map<String, dynamic> get kgAktion => _ruleProvider.kgAktion;
  Map<String, dynamic> get repsAktion => _ruleProvider.repsAktion;
  Map<String, dynamic> get rirAktion => _ruleProvider.rirAktion;
  String? get draggedRuleId => _ruleProvider.draggedRuleId;
  String? get dragOverRuleId => _ruleProvider.dragOverRuleId;
  ProgressionRuleModel get neueRegel => _ruleProvider.neueRegel;
  List<ProgressionVariableModel> get verfuegbareVariablen =>
      _ruleProvider.verfuegbareVariablen;
  List<ProgressionOperatorModel> get verfuegbareOperatoren =>
      _ruleProvider.verfuegbareOperatoren;

  // UI Provider Getters
  bool get zeigePQB => _uiProvider.zeigePQB;
  bool get zeigeRegelEditor => _uiProvider.zeigeRegelEditor;
  bool get zeigeProfilEditor => _uiProvider.zeigeProfilEditor;

  // Setter für das Demo-Profil
  void setDemoProfileId(String profileId) {
    // Wenn wir zu einem anderen Profil wechseln, setzen wir das Training zurück
    if (_currentDemoProfileId != profileId) {
      _currentDemoProfileId = profileId;

      // Training vollständig zurücksetzen, einschließlich aller Empfehlungen
      _trainingProvider.trainingZuruecksetzen(
          aktuellesProfil:
              profileProvider.getProfileById(_currentDemoProfileId),
          resetRecommendations: true);
    } else {
      // Nur Berechnung neu anstoßen
      _trainingProvider.berechneEmpfehlungFuerAktivenSatz(
          aktuellesProfil:
              profileProvider.getProfileById(_currentDemoProfileId));
    }

    notifyListeners();
  }

  // ===== BERECHNUNGS-METHODEN =====

  // GEÄNDERT: Berechnet eine Empfehlung mit einem bestimmten Profil, nun mit zusätzlichen Parametern für repRange und rirRange
  Map<String, dynamic> berechneEmpfehlungMitProfil(
      TrainingSetModel satz, String profilId, List<TrainingSetModel> alleSaetze,
      {double? customIncrement,
      int? repRangeMin,
      int? repRangeMax,
      int? rirRangeMin,
      int? rirRangeMax}) {
    // Das gewünschte Profil finden
    final profil = profileProvider.getProfileById(profilId);
    if (profil == null) {
      return {
        'kg': satz.kg,
        'wiederholungen': satz.wiederholungen,
        'rir': satz.rir,
        'neuer1RM': 0.0,
      };
    }

    // Temporär config anpassen (kopieren, um das Original nicht zu verändern)
    final tempConfig = Map<String, dynamic>.from(profil.config);

    // Optional den Increment-Wert anpassen
    if (customIncrement != null) {
      tempConfig['increment'] = customIncrement;
    }

    // Optional die repRange-Werte anpassen
    if (repRangeMin != null) {
      tempConfig['targetRepsMin'] = repRangeMin;
    }
    if (repRangeMax != null) {
      tempConfig['targetRepsMax'] = repRangeMax;
    }

    // Optional die rirRange-Werte anpassen
    if (rirRangeMin != null) {
      tempConfig['targetRIRMin'] = rirRangeMin;
    }
    if (rirRangeMax != null) {
      tempConfig['targetRIRMax'] = rirRangeMax;
    }

    // Temporäres Profil mit angepassten Werten erstellen
    ProgressionProfileModel tempProfil = profil.copyWith(config: tempConfig);

    // Berechnung ohne Profilwechsel durchführen
    final empfehlung = ProgressionCalculatorService.berechneProgression(
        satz, tempProfil, alleSaetze);

    return empfehlung;
  }

  // ===== DELEGIERTE METHODEN =====

  // Training Methoden
  void handleChange(int id, String feld, dynamic wert) {
    print('DEBUG: handleChange aufgerufen für Satz $id, Feld: $feld, Wert: $wert');
    _trainingProvider.handleChange(id, feld, wert);
    
    // WICHTIGER FIX: Empfehlungen SYNCHRON neu berechnen, nicht asynchron!
    // Asynchrone Berechnung führt dazu, dass die UI alte Werte anzeigt
    _trainingProvider.aktualisiereFolgeSatzEmpfehlungen(aktuellesProfil);
  }

  void toggleProgressionManager() => _uiProvider.toggleProgressionManager();

  void handleConfigChange(String key, dynamic value) =>
      profileProvider.handleConfigChange(key, value, aktuellesProfil);

  double berechne1RM(double gewicht, int wiederholungen, int rir) =>
      _trainingProvider.berechne1RM(gewicht, wiederholungen, rir);

  // GEÄNDERT: Überarbeitete Methode für berechneProgression mit zusätzlichen Parametern
  Map<String, dynamic> berechneProgression(
      TrainingSetModel satz,
      ProgressionProfileModel? aktuellesProfilParam,
      List<TrainingSetModel> alleSaetze,
      {double? customIncrement,
      int? repRangeMin,
      int? repRangeMax,
      int? rirRangeMin,
      int? rirRangeMax}) {
    // Wenn kein Profil übergeben wurde und auch kein aktuelles Profil existiert,
    // geben wir einen Standardwert zurück
    ProgressionProfileModel? profilToUse =
        aktuellesProfilParam ?? aktuellesProfil;

    if (profilToUse == null) {
      // Wenn kein Profil verfügbar ist, direkt Standardwerte zurückgeben
      return {
        'kg': satz.kg,
        'wiederholungen': satz.wiederholungen,
        'rir': satz.rir,
        'neuer1RM': 0.0,
      };
    }

    // Wenn Parameter übergeben wurden, temporär die Config anpassen
    Map<String, dynamic>? originalConfig;

    if (customIncrement != null ||
        repRangeMin != null ||
        repRangeMax != null ||
        rirRangeMin != null ||
        rirRangeMax != null) {
      // Originalwert sichern
      originalConfig = Map<String, dynamic>.from(profilToUse.config);

      // Temporär die Config-Werte setzen
      final tempConfig = Map<String, dynamic>.from(profilToUse.config);

      if (customIncrement != null) {
        tempConfig['increment'] = customIncrement;
      }
      if (repRangeMin != null) {
        tempConfig['targetRepsMin'] = repRangeMin;
      }
      if (repRangeMax != null) {
        tempConfig['targetRepsMax'] = repRangeMax;
      }
      if (rirRangeMin != null) {
        tempConfig['targetRIRMin'] = rirRangeMin;
      }
      if (rirRangeMax != null) {
        tempConfig['targetRIRMax'] = rirRangeMax;
      }

      // Config im Profil aktualisieren
      profilToUse = profilToUse.copyWith(config: tempConfig);
    }

    // Progression mit potenziell angepasster Config berechnen
    // Jetzt übergeben wir ein nicht-nullables ProgressionProfileModel
    final ergebnis = ProgressionCalculatorService.berechneProgression(
        satz, profilToUse, alleSaetze);

    // Wenn wir die Config temporär angepasst haben, den Originalwert wiederherstellen
    if (originalConfig != null) {
      profilToUse = profilToUse.copyWith(config: originalConfig);
    }

    return ergebnis;
  }

  // GEÄNDERT: Erweiterte Methode für berechneEmpfehlungFuerAktivenSatz
  void berechneEmpfehlungFuerAktivenSatz(
      {ProgressionProfileModel? aktuellesProfil,
      bool notify = true,
      double? customIncrement,
      int? repRangeMin,
      int? repRangeMax,
      int? rirRangeMin,
      int? rirRangeMax}) {
    final aktiverSatzIndex = _trainingProvider.saetze
        .indexWhere((satz) => satz.id == _trainingProvider.aktiverSatz);

    if (aktiverSatzIndex == -1) return;

    final aktiverSatz = _trainingProvider.saetze[aktiverSatzIndex];

    // Neue Berechnung erzwingen, um sicherzustellen, dass die korrekten Regeln angewendet werden
    final empfehlung = berechneProgression(
        aktiverSatz, aktuellesProfil, _trainingProvider.saetze,
        customIncrement: customIncrement,
        repRangeMin: repRangeMin,
        repRangeMax: repRangeMax,
        rirRangeMin: rirRangeMin,
        rirRangeMax: rirRangeMax);

    final updatedSaetze = List<TrainingSetModel>.from(_trainingProvider.saetze);
    updatedSaetze[aktiverSatzIndex] = aktiverSatz.copyWith(
      empfKg: empfehlung['kg'],
      empfWiederholungen: empfehlung['wiederholungen'],
      empfRir: empfehlung['rir'],
      empfehlungBerechnet: true,
    );

    // Statt direkter Zuweisung die updateSaetze Methode verwenden
    _trainingProvider.updateSaetze(updatedSaetze);

    if (notify) {
      notifyListeners();
    }
  }

  // Methode zum Setzen der standardIncrease für eine spezifische Übung
  void setExerciseStandardIncrease(double value) {
    final config = Map<String, dynamic>.from(progressionsConfig);
    config['increment'] = value;

    // Alle aktuellen Profile aktualisieren
    if (aktuellesProfil != null) {
      handleConfigChange('increment', value);
    }

    notifyListeners();
  }

  bool sollEmpfehlungAnzeigen(int satzId) => _trainingProvider
      .sollEmpfehlungAnzeigen(satzId, aktiverSatz, trainingAbgeschlossen);

  void empfehlungUebernehmen() => _trainingProvider.empfehlungUebernehmen();

  void satzAbschliessen() =>
      _trainingProvider.satzAbschliessen(aktuellesProfil: aktuellesProfil);

  void trainingZuruecksetzen({bool resetRecommendations = false}) =>
      _trainingProvider.trainingZuruecksetzen(
          aktuellesProfil: aktuellesProfil,
          resetRecommendations: resetRecommendations);

  void uebungAbschliessen({bool neueUebung = false}) =>
      _trainingProvider.uebungAbschliessen(
          neueUebung: neueUebung, aktuellesProfil: aktuellesProfil);

  // Profile Methoden
  void openProfileEditor(ProgressionProfileModel? profil) =>
      profileProvider.openProfileEditor(profil, _uiProvider);

  void closeProfileEditor() => profileProvider.closeProfileEditor(_uiProvider);

  void updateProfile(String feld, dynamic wert) =>
      profileProvider.updateProfile(feld, wert);

  // VERBESSERTE METHODE: saveProfile mit verbesserter Aktualisierungslogik
  // Erweiterter saveProfile-Rückgabewert, der Navigationsinformationen enthält
  Future<Map<String, dynamic>> saveProfile() async {
    if (bearbeitetesProfil == null) {
      return {'success': false, 'profileId': null};
    }

    try {
      print('Starte Speichern des Profils...');
      final String profileId =
          bearbeitetesProfil!.id; // Speichern der ID vor dem Speichern

      // GEÄNDERT: Erkenne sowohl neue als auch duplizierte Profile
      final bool isNewProfile =
          profileId.contains('profile_') || // Neue Profile
              profileId.contains('-copy-'); // Duplizierte Profile

      // Profil speichern - für neue Profile Editor NICHT schließen
      await profileProvider.saveProfile(_uiProvider, closeEditor: !isNewProfile);

      // Längere Verzögerung, um sicherzustellen, dass Firebase-Operationen abgeschlossen sind
      await Future.delayed(const Duration(milliseconds: 500));

      // Profile explizit neu laden
      await refreshProfiles();

      // WICHTIG: Wenn es ein neues Profil ist, setzen wir es als aktuelles Profil
      if (isNewProfile) {
        final savedProfile = profileProvider.progressionsProfile.firstWhere(
          (p) => p.id == profileId,
          orElse: () => profileProvider.progressionsProfile.first,
        );

        // Das neue Profil als aktuelles Profil setzen
        setDemoProfileId(savedProfile.id);
      }

      // Zusätzliche Benachrichtigung für die UI
      notifyListeners();

      print('Profil erfolgreich gespeichert und UI aktualisiert');
      return {
        'success': true,
        'profileId': profileId,
        'isNewProfile': isNewProfile,
      };
    } catch (e) {
      print('Fehler beim Speichern des Profils: $e');
      closeProfileEditor();
      return {'success': false, 'profileId': null};
    }
  }

  void duplicateProfile(String profilId) =>
      profileProvider.duplicateProfile(profilId, _uiProvider);

  Future<void> deleteProfile(String profileId) async {
    await profileProvider.deleteProfile(profileId);
    // Nach dem Löschen explizit die Profile aktualisieren
    await refreshProfiles();
  }

  // Regel Methoden
  void setRegelTyp(String typ) => _ruleProvider.setRegelTyp(typ);

  void openRuleEditor(ProgressionRuleModel? regel) =>
      _ruleProvider.openRuleEditor(regel, _uiProvider);

  void closeRuleEditor() => _ruleProvider.closeRuleEditor(_uiProvider);

  void updateRegelBedingung(int index, String feld, dynamic wert) =>
      _ruleProvider.updateRegelBedingung(index, feld, wert);

  void addRegelBedingung() => _ruleProvider.addRegelBedingung();

  void removeRegelBedingung(int index) =>
      _ruleProvider.removeRegelBedingung(index);

  void updateKgAktion(String feld, dynamic wert) =>
      _ruleProvider.updateKgAktion(feld, wert);

  void updateRepsAktion(String feld, dynamic wert) =>
      _ruleProvider.updateRepsAktion(feld, wert);

  void updateRirAktion(String feld, dynamic wert) =>
      _ruleProvider.updateRirAktion(feld, wert);

  // GEÄNDERTE METHODE: saveRule mit await für die asynchrone Speicherung
  Future<void> saveRule() async {
    if (_currentDemoProfileId == null) return;

    try {
      await _ruleProvider.saveRule(
          _currentDemoProfileId!,
          progressionsProfile,
          profileProvider.saveProfiles,
          _trainingProvider,
          aktuellesProfil,
          _uiProvider);

      // Nach dem Speichern der Regel immer explizit die Profile in Firestore aktualisieren
      await profileProvider.saveProfiles();

      // Dann die lokale Liste aktualisieren
      await refreshProfiles();

      print('Regel erfolgreich gespeichert und Datenbank aktualisiert');
    } catch (e) {
      print('Fehler beim Speichern der Regel: $e');
    }
  }

  // GEÄNDERTE METHODE: deleteRule mit await für die asynchrone Speicherung
  Future<void> deleteRule(String ruleId) async {
    if (_currentDemoProfileId == null) return;

    try {
      await _ruleProvider.deleteRule(
          ruleId,
          _currentDemoProfileId!,
          progressionsProfile,
          profileProvider.saveProfiles,
          _trainingProvider,
          aktuellesProfil);

      // Nach dem Löschen der Regel immer explizit die Profile in Firestore aktualisieren
      await profileProvider.saveProfiles();

      // Dann die lokale Liste aktualisieren
      await refreshProfiles();

      print('Regel erfolgreich gelöscht und Datenbank aktualisiert');
    } catch (e) {
      print('Fehler beim Löschen der Regel: $e');
    }
  }

  // Drag & Drop Methoden
  void handleDragStart(String ruleId) => _ruleProvider.handleDragStart(ruleId);

  void handleDragOver(String ruleId) => _ruleProvider.handleDragOver(ruleId);

  void handleDragLeave() => _ruleProvider.handleDragLeave();

  // GEÄNDERTE METHODE: handleDrop mit await für die asynchrone Speicherung
  Future<void> handleDrop(String targetRuleId) async {
    if (_currentDemoProfileId == null) return;

    try {
      await _ruleProvider.handleDrop(
          targetRuleId,
          _currentDemoProfileId!,
          progressionsProfile,
          profileProvider.saveProfiles,
          _trainingProvider,
          aktuellesProfil);

      // Nach dem Drag & Drop immer explizit die Profile in Firestore aktualisieren
      await profileProvider.saveProfiles();

      // Dann die lokale Liste aktualisieren
      await refreshProfiles();

      print(
          'Regelreihenfolge erfolgreich aktualisiert und Datenbank aktualisiert');
    } catch (e) {
      print('Fehler beim Aktualisieren der Regelreihenfolge: $e');
    }
  }

  // Hilfsmethoden
  String getVariableLabel(String variableId) =>
      _ruleProvider.getVariableLabel(variableId);

  String getOperatorLabel(String operatorId) =>
      _ruleProvider.getOperatorLabel(operatorId);

  String getTargetLabel(String targetId) =>
      _ruleProvider.getTargetLabel(targetId);

  String renderValueNode(Map<String, dynamic> node) =>
      _ruleProvider.renderValueNode(node);

  /// VERBESSERTE METHODE: Lädt die gespeicherten Profile explizit neu mit verbesserter Fehlerbehandlung und Benachrichtigung
  Future<void> refreshProfiles() async {
    try {
      print('Starte Aktualisierung der Profile...');

      // Profile neu laden
      await profileProvider.loadSavedProfiles();

      // Aktuelles Demo-Profil neu referenzieren, falls es existiert
      if (_currentDemoProfileId != null) {
        // Überprüfen, ob das ausgewählte Profil noch existiert
        final existierendesProfil =
            profileProvider.getProfileById(_currentDemoProfileId);
        if (existierendesProfil == null &&
            profileProvider.progressionsProfile.isNotEmpty) {
          // Falls nicht, das erste verfügbare Profil verwenden
          _currentDemoProfileId = profileProvider.progressionsProfile.first.id;
        }
      }

      // Sicherstellen, dass alle Listener benachrichtigt werden
      notifyListeners();

      print('Profile erfolgreich aktualisiert und UI benachrichtigt');
    } catch (e) {
      print('Fehler beim Aktualisieren der Profile: $e');
    }
  }
}
