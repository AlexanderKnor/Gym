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
  final ProgressionProfileProvider _profileProvider;
  final ProgressionRuleProvider _ruleProvider;
  final ProgressionUIProvider _uiProvider;

  // Flag, um zu verfolgen, ob der Provider im Demo-Modus oder Trainingsmodus aktiv ist
  bool _isInTrainingSession = false;
  String? _originalActiveProfileId;

  ProgressionManagerProvider({
    ProgressionTrainingProvider? trainingProvider,
    ProgressionProfileProvider? profileProvider,
    ProgressionRuleProvider? ruleProvider,
    ProgressionUIProvider? uiProvider,
  })  : _trainingProvider = trainingProvider ?? ProgressionTrainingProvider(),
        _profileProvider = profileProvider ?? ProgressionProfileProvider(),
        _ruleProvider = ruleProvider ?? ProgressionRuleProvider(),
        _uiProvider = uiProvider ?? ProgressionUIProvider() {
    _initializeListeners();

    // Profile laden und erste Empfehlung berechnen
    Future.microtask(() async {
      await _profileProvider.loadSavedProfiles();
      _trainingProvider.berechneEmpfehlungFuerAktivenSatz(
          aktuellesProfil: aktuellesProfil);
    });
  }

  void _initializeListeners() {
    // Verbinde die Sub-Provider miteinander
    _profileProvider.addListener(notifyListeners);
    _trainingProvider.addListener(notifyListeners);
    _ruleProvider.addListener(notifyListeners);
    _uiProvider.addListener(notifyListeners);

    // Auch bei Profiländerungen Empfehlung neu berechnen
    _profileProvider.addListener(() {
      if (_profileProvider.profilWurdeGewechselt) {
        _trainingProvider.berechneEmpfehlungFuerAktivenSatz(
            aktuellesProfil: aktuellesProfil);
      }
    });
  }

  @override
  void dispose() {
    _profileProvider.removeListener(notifyListeners);
    _trainingProvider.removeListener(notifyListeners);
    _ruleProvider.removeListener(notifyListeners);
    _uiProvider.removeListener(notifyListeners);

    _profileProvider.dispose();
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
  String get aktivesProgressionsProfil =>
      _profileProvider.aktivesProgressionsProfil;
  Map<String, dynamic> get progressionsConfig =>
      _profileProvider.progressionsConfig;
  List<ProgressionProfileModel> get progressionsProfile =>
      _profileProvider.progressionsProfile;
  ProgressionProfileModel? get aktuellesProfil =>
      _profileProvider.aktuellesProfil;
  ProgressionProfileModel? get bearbeitetesProfil =>
      _profileProvider.bearbeitetesProfil;

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

  // ===== TRAININGS-SESSION METHODEN =====

  /// Markiert den Beginn einer Trainings-Session und speichert den ursprünglichen Zustand
  void beginTrainingSession() {
    _isInTrainingSession = true;
    _originalActiveProfileId = _profileProvider.aktivesProgressionsProfil;
  }

  /// Beendet die Trainings-Session und stellt den ursprünglichen Zustand wieder her
  void endTrainingSession() {
    if (_isInTrainingSession && _originalActiveProfileId != null) {
      _profileProvider.wechsleProgressionsProfil(_originalActiveProfileId!);
      _trainingProvider.berechneEmpfehlungFuerAktivenSatz(
          aktuellesProfil: aktuellesProfil);
    }
    _isInTrainingSession = false;
    _originalActiveProfileId = null;
  }

  /// Wechselt temporär zu einem Profil für die Berechnung und stellt dann den ursprünglichen Zustand wieder her
  Map<String, dynamic> berechneEmpfehlungMitProfil(
      TrainingSetModel satz, String profilId, List<TrainingSetModel> alleSaetze,
      {double? customIncrement}) {
    // Speichere das aktuelle Profil
    final originalProfileId = _profileProvider.aktivesProgressionsProfil;

    // Wechsle temporär zum gewünschten Profil
    _profileProvider.wechsleProgressionsProfil(profilId);

    // Berechne die Empfehlung
    final profil = _profileProvider.aktuellesProfil;
    final empfehlung = berechneProgression(satz, profil, alleSaetze,
        customIncrement: customIncrement);

    // Stelle das ursprüngliche Profil wieder her
    _profileProvider.wechsleProgressionsProfil(originalProfileId);

    return empfehlung;
  }

  // ===== DELEGIERTE METHODEN =====

  // Training Methoden
  void handleChange(int id, String feld, dynamic wert) =>
      _trainingProvider.handleChange(id, feld, wert);

  void toggleProgressionManager() => _uiProvider.toggleProgressionManager();

  void wechsleProgressionsProfil(String profilId) =>
      _profileProvider.wechsleProgressionsProfil(profilId);

  void handleConfigChange(String key, dynamic value) =>
      _profileProvider.handleConfigChange(key, value, aktuellesProfil);

  double berechne1RM(double gewicht, int wiederholungen, int rir) =>
      _trainingProvider.berechne1RM(gewicht, wiederholungen, rir);

  // BUGFIX: Überarbeitete Methode für berechneProgression
  Map<String, dynamic> berechneProgression(
      TrainingSetModel satz,
      ProgressionProfileModel? aktuellesProfilParam,
      List<TrainingSetModel> alleSaetze,
      {double? customIncrement}) {
    // Wenn kein Profil übergeben wurde und auch kein aktuelles Profil existiert,
    // geben wir einen Standardwert zurück
    ProgressionProfileModel? profilToUse =
        aktuellesProfilParam ?? _profileProvider.aktuellesProfil;

    if (profilToUse == null) {
      // Wenn kein Profil verfügbar ist, direkt Standardwerte zurückgeben
      return {
        'kg': satz.kg,
        'wiederholungen': satz.wiederholungen,
        'rir': satz.rir,
        'neuer1RM': 0.0,
      };
    }

    // Wenn ein benutzerdefinierter increment Wert übergeben wurde, temporär die Config anpassen
    Map<String, dynamic>? originalConfig;

    if (customIncrement != null) {
      // Originalwert sichern
      originalConfig = Map<String, dynamic>.from(profilToUse.config);

      // Temporär den customIncrement Wert setzen
      final tempConfig = Map<String, dynamic>.from(profilToUse.config);
      tempConfig['increment'] = customIncrement;

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

  // BUGFIX: Überarbeitete Methode für berechneEmpfehlungFuerAktivenSatz
  void berechneEmpfehlungFuerAktivenSatz(
      {ProgressionProfileModel? aktuellesProfil,
      bool notify = true,
      double? customIncrement}) {
    final aktiverSatzIndex = _trainingProvider.saetze
        .indexWhere((satz) => satz.id == _trainingProvider.aktiverSatz);

    if (aktiverSatzIndex == -1) return;

    final aktiverSatz = _trainingProvider.saetze[aktiverSatzIndex];

    // Nur berechnen, wenn noch nicht berechnet wurde oder wenn wir im Training-Modus sind
    if (!aktiverSatz.empfehlungBerechnet) {
      final empfehlung = berechneProgression(
          aktiverSatz, aktuellesProfil, _trainingProvider.saetze,
          customIncrement: customIncrement);

      final updatedSaetze =
          List<TrainingSetModel>.from(_trainingProvider.saetze);
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

  void satzAbschliessen() => _trainingProvider.satzAbschliessen();

  void trainingZuruecksetzen() =>
      _trainingProvider.trainingZuruecksetzen(aktuellesProfil: aktuellesProfil);

  void uebungAbschliessen({bool neueUebung = false}) =>
      _trainingProvider.uebungAbschliessen(
          neueUebung: neueUebung, aktuellesProfil: aktuellesProfil);

  // Profile Methoden
  void openProfileEditor(ProgressionProfileModel? profil) =>
      _profileProvider.openProfileEditor(profil, _uiProvider);

  void closeProfileEditor() => _profileProvider.closeProfileEditor(_uiProvider);

  void updateProfile(String feld, dynamic wert) =>
      _profileProvider.updateProfile(feld, wert);

  void saveProfile() => _profileProvider.saveProfile(_uiProvider);

  void duplicateProfile(String profilId) =>
      _profileProvider.duplicateProfile(profilId, _uiProvider);

  Future<void> deleteProfile(String profileId) =>
      _profileProvider.deleteProfile(profileId);

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

  void saveRule() => _ruleProvider.saveRule(
      aktivesProgressionsProfil,
      progressionsProfile,
      _profileProvider.saveProfiles,
      _trainingProvider,
      aktuellesProfil,
      _uiProvider);

  void deleteRule(String ruleId) => _ruleProvider.deleteRule(
      ruleId,
      aktivesProgressionsProfil,
      progressionsProfile,
      _profileProvider.saveProfiles,
      _trainingProvider,
      aktuellesProfil);

  // Drag & Drop Methoden
  void handleDragStart(String ruleId) => _ruleProvider.handleDragStart(ruleId);

  void handleDragOver(String ruleId) => _ruleProvider.handleDragOver(ruleId);

  void handleDragLeave() => _ruleProvider.handleDragLeave();

  void handleDrop(String targetRuleId) => _ruleProvider.handleDrop(
      targetRuleId,
      aktivesProgressionsProfil,
      progressionsProfile,
      _profileProvider.saveProfiles,
      _trainingProvider,
      aktuellesProfil);

  // Hilfsmethoden
  String getVariableLabel(String variableId) =>
      _ruleProvider.getVariableLabel(variableId);

  String getOperatorLabel(String operatorId) =>
      _ruleProvider.getOperatorLabel(operatorId);

  String getTargetLabel(String targetId) =>
      _ruleProvider.getTargetLabel(targetId);

  String renderValueNode(Map<String, dynamic> node) =>
      _ruleProvider.renderValueNode(node);
}
