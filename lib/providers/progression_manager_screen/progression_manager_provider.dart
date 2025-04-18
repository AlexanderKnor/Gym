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

/// Hauptprovider für den Progression Manager Screen
/// Dieser Provider orchestriert die spezialisierten Sub-Provider
class ProgressionManagerProvider with ChangeNotifier {
  // Sub-Provider
  final ProgressionTrainingProvider _trainingProvider;
  final ProgressionProfileProvider _profileProvider;
  final ProgressionRuleProvider _ruleProvider;
  final ProgressionUIProvider _uiProvider;

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

  Map<String, dynamic> berechneProgression(TrainingSetModel satz) =>
      _trainingProvider.berechneProgression(satz, aktuellesProfil, saetze);

  void berechneEmpfehlungFuerAktivenSatz({bool notify = true}) =>
      _trainingProvider.berechneEmpfehlungFuerAktivenSatz(
          aktuellesProfil: aktuellesProfil, notify: notify);

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

  // Hilfsmethotden
  String getVariableLabel(String variableId) =>
      _ruleProvider.getVariableLabel(variableId);

  String getOperatorLabel(String operatorId) =>
      _ruleProvider.getOperatorLabel(operatorId);

  String getTargetLabel(String targetId) =>
      _ruleProvider.getTargetLabel(targetId);

  String renderValueNode(Map<String, dynamic> node) =>
      _ruleProvider.renderValueNode(node);
}
