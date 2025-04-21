// lib/providers/friend_profile_screen/friend_profile_provider.dart
import 'package:flutter/material.dart';
import '../../models/training_plan_screen/training_plan_model.dart';
import '../../models/progression_manager_screen/progression_profile_model.dart';
import '../../models/profile_screen/friendship_model.dart';
import '../../services/friend_profile_screen/friend_profile_service.dart';

class FriendProfileProvider with ChangeNotifier {
  final FriendProfileService _friendProfileService = FriendProfileService();

  // State-Variablen
  FriendshipModel? _friendship;
  List<TrainingPlanModel> _trainingPlans = [];
  List<ProgressionProfileModel> _progressionProfiles = [];
  String _activeProfileId = '';
  String _activeTrainingPlanId = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _isTabViewEnabled = false;

  // Getters
  FriendshipModel? get friendship => _friendship;
  List<TrainingPlanModel> get trainingPlans => _trainingPlans;
  List<ProgressionProfileModel> get progressionProfiles => _progressionProfiles;
  String get activeProfileId => _activeProfileId;
  String get activeTrainingPlanId => _activeTrainingPlanId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isTabViewEnabled => _isTabViewEnabled;

  // Tab-Steuerung
  void enableTabView() {
    _isTabViewEnabled = true;
    notifyListeners();
  }

  void disableTabView() {
    _isTabViewEnabled = false;
    notifyListeners();
  }

  // Daten laden
  Future<void> loadFriendData(FriendshipModel friendship) async {
    _setLoading(true);
    _errorMessage = null;
    _friendship = friendship;

    try {
      // Prüfen, ob eine Freundschaft besteht
      final isFriend =
          await _friendProfileService.isFriendWith(friendship.friendId);

      if (!isFriend) {
        _errorMessage = 'Keine Freundschaft mit diesem Benutzer';
        _setLoading(false);
        return;
      }

      // Trainingspläne laden
      _trainingPlans = await _friendProfileService
          .getTrainingPlansFromFriend(friendship.friendId);

      // Progressionsprofile laden
      _progressionProfiles = await _friendProfileService
          .getProgressionProfilesFromFriend(friendship.friendId);

      // Aktives Profil und aktiven Trainingsplan laden
      _activeProfileId = await _friendProfileService
          .getActiveProfileFromFriend(friendship.friendId);

      _activeTrainingPlanId = await _friendProfileService
          .getActiveTrainingPlanFromFriend(friendship.friendId);

      enableTabView(); // Aktiviere Tab-Ansicht nach erfolgreichem Laden
    } catch (e) {
      _errorMessage = 'Fehler beim Laden der Freundesdaten: $e';
      print(_errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // NEU: Profil in die eigene Sammlung kopieren
  Future<bool> copyProfileToOwnCollection(
      ProgressionProfileModel profile) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final result =
          await _friendProfileService.copyProgressionProfile(profile);

      if (result) {
        return true;
      } else {
        _errorMessage = 'Fehler beim Kopieren des Profils';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Fehler beim Kopieren des Profils: $e';
      print(_errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NEU: Trainingsplan in die eigene Sammlung kopieren
  Future<Map<String, dynamic>> copyTrainingPlanToOwnCollection(
      TrainingPlanModel plan) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final result = await _friendProfileService.copyTrainingPlan(
          plan, _progressionProfiles);

      if (result['success'] == true) {
        return result;
      } else {
        _errorMessage =
            'Fehler beim Kopieren des Trainingsplans: ${result['error']}';
        return {
          'success': false,
          'error': _errorMessage,
        };
      }
    } catch (e) {
      _errorMessage = 'Fehler beim Kopieren des Trainingsplans: $e';
      print(_errorMessage);
      return {
        'success': false,
        'error': _errorMessage,
      };
    } finally {
      _setLoading(false);
    }
  }

  // NEU: Fehlende Profile kopieren
  Future<bool> copyMissingProfiles(List<String> profileIds) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final copiedIds = await _friendProfileService.copySpecificProfiles(
          profileIds, _progressionProfiles);

      if (copiedIds.length == profileIds.length) {
        return true;
      } else {
        _errorMessage = 'Nicht alle Profile konnten kopiert werden';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Fehler beim Kopieren der fehlenden Profile: $e';
      print(_errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Hilfsmethode zum Aktualisieren des Loading-Status
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Löschen des Providers-Zustands beim Beenden
  void reset() {
    _friendship = null;
    _trainingPlans = [];
    _progressionProfiles = [];
    _activeProfileId = '';
    _activeTrainingPlanId = '';
    _isLoading = false;
    _errorMessage = null;
    _isTabViewEnabled = false;
    notifyListeners();
  }
}
