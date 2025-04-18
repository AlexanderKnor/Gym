import 'package:flutter/foundation.dart';

/// Provider für UI-Zustände im Progression Manager Screen
/// Verantwortlich für die Steuerung der UI-Elemente wie Modals, Panels, etc.
class ProgressionUIProvider with ChangeNotifier {
  // ===== STATE DECLARATIONS =====

  bool _zeigePQB = false;
  bool _zeigeRegelEditor = false;
  bool _zeigeProfilEditor = false;

  // ===== GETTERS =====

  bool get zeigePQB => _zeigePQB;
  bool get zeigeRegelEditor => _zeigeRegelEditor;
  bool get zeigeProfilEditor => _zeigeProfilEditor;

  // ===== METHODEN =====

  void toggleProgressionManager() {
    _zeigePQB = !_zeigePQB;
    notifyListeners();
  }

  void showRuleEditor() {
    _zeigeRegelEditor = true;
    notifyListeners();
  }

  void hideRuleEditor() {
    _zeigeRegelEditor = false;
    notifyListeners();
  }

  void showProfileEditor() {
    _zeigeProfilEditor = true;
    notifyListeners();
  }

  void hideProfileEditor() {
    _zeigeProfilEditor = false;
    notifyListeners();
  }
}
