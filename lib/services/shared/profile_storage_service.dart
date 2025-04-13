import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/progression_manager_screen/progression_profile_model.dart';
import '../../models/progression_manager_screen/progression_rule_model.dart';
import '../../models/progression_manager_screen/progression_condition_model.dart';
import '../../models/progression_manager_screen/progression_action_model.dart';

class ProfileStorageService {
  static const String PROFILES_KEY = 'saved_progression_profiles';
  static const String ACTIVE_PROFILE_KEY = 'active_progression_profile';

  // Sicherstellen, dass immer die Standardprofile verfügbar sind
  static List<ProgressionProfileModel> _standardProfiles = [];

  static void setStandardProfiles(List<ProgressionProfileModel> profiles) {
    _standardProfiles = List.from(profiles);
  }

  // Profile laden
  static Future<List<ProgressionProfileModel>> loadProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? profilesJson = prefs.getString(PROFILES_KEY);

      if (profilesJson == null || profilesJson.isEmpty) {
        return _standardProfiles;
      }

      final List<dynamic> decodedProfiles = jsonDecode(profilesJson);
      final List<ProgressionProfileModel> loadedProfiles = [];

      // Standard-Profile immer hinzufügen
      loadedProfiles.addAll(_standardProfiles);

      // Gespeicherte benutzerdefinierte Profile hinzufügen
      for (var profileJson in decodedProfiles) {
        try {
          final profile = _decodeProfileFromJson(profileJson);

          // Prüfen, ob das Profil bereits in der Liste ist (Standard-Profile nicht überschreiben)
          final existingIndex =
              loadedProfiles.indexWhere((p) => p.id == profile.id);
          if (existingIndex != -1) {
            // Wenn es ein benutzerdefiniertes Profil ist, aktualisieren wir es
            if (!_isStandardProfile(profile.id)) {
              loadedProfiles[existingIndex] = profile;
            }
          } else {
            // Wenn es noch nicht in der Liste ist, fügen wir es hinzu
            loadedProfiles.add(profile);
          }
        } catch (e) {
          print('Fehler beim Dekodieren eines Profils: $e');
          // Fahre mit dem nächsten Profil fort
        }
      }

      return loadedProfiles;
    } catch (e) {
      print('Fehler beim Laden der Profile: $e');
      return _standardProfiles;
    }
  }

  // Aktives Profil laden
  static Future<String> loadActiveProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? activeProfileId = prefs.getString(ACTIVE_PROFILE_KEY);

      if (activeProfileId == null || activeProfileId.isEmpty) {
        return _standardProfiles.isNotEmpty ? _standardProfiles.first.id : '';
      }

      return activeProfileId;
    } catch (e) {
      print('Fehler beim Laden des aktiven Profils: $e');
      return _standardProfiles.isNotEmpty ? _standardProfiles.first.id : '';
    }
  }

  // Profile speichern
  static Future<bool> saveProfiles(
      List<ProgressionProfileModel> profiles) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Filtere die Standard-Profile heraus, um nur benutzerdefinierte zu speichern
      final customProfiles =
          profiles.where((p) => !_isStandardProfile(p.id)).toList();

      // Kodiere die benutzerdefinierten Profile in JSON
      final List<Map<String, dynamic>> encodedProfiles = customProfiles
          .map((profile) => _encodeProfileToJson(profile))
          .toList();

      final String profilesJson = jsonEncode(encodedProfiles);

      return await prefs.setString(PROFILES_KEY, profilesJson);
    } catch (e) {
      print('Fehler beim Speichern der Profile: $e');
      return false;
    }
  }

  // Aktives Profil speichern
  static Future<bool> saveActiveProfile(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(ACTIVE_PROFILE_KEY, profileId);
    } catch (e) {
      print('Fehler beim Speichern des aktiven Profils: $e');
      return false;
    }
  }

  // Helper-Methode: Prüfen, ob es sich um ein Standard-Profil handelt
  static bool _isStandardProfile(String profileId) {
    return profileId == 'double-progression' ||
        profileId == 'linear-periodization' ||
        profileId == 'rir-based' ||
        profileId == 'set-consistency';
  }

  // Helper-Methode: Profil in JSON kodieren
  static Map<String, dynamic> _encodeProfileToJson(
      ProgressionProfileModel profile) {
    return {
      'id': profile.id,
      'name': profile.name,
      'description': profile.description,
      'config': profile.config,
      'rules': profile.rules.map((rule) => _encodeRuleToJson(rule)).toList(),
    };
  }

  // Helper-Methode: Regel in JSON kodieren
  static Map<String, dynamic> _encodeRuleToJson(ProgressionRuleModel rule) {
    return {
      'id': rule.id,
      'type': rule.type,
      'conditions': rule.conditions
          .map((condition) => {
                'left': condition.left,
                'operator': condition.operator,
                'right': condition.right,
              })
          .toList(),
      'logicalOperator': rule.logicalOperator,
      'children': rule.children
          .map((action) => {
                'id': action.id,
                'type': action.type,
                'target': action.target,
                'value': action.value,
              })
          .toList(),
    };
  }

  // Helper-Methode: Profil aus JSON dekodieren
  static ProgressionProfileModel _decodeProfileFromJson(
      Map<String, dynamic> json) {
    final List<dynamic> rulesJson = json['rules'] ?? [];
    final List<ProgressionRuleModel> rules = rulesJson.map((ruleJson) {
      return _decodeRuleFromJson(ruleJson);
    }).toList();

    return ProgressionProfileModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      config: Map<String, dynamic>.from(json['config']),
      rules: rules,
    );
  }

  // Helper-Methode: Regel aus JSON dekodieren
  static ProgressionRuleModel _decodeRuleFromJson(Map<String, dynamic> json) {
    final List<dynamic> conditionsJson = json['conditions'] ?? [];
    final List<ProgressionConditionModel> conditions =
        conditionsJson.map((conditionJson) {
      return ProgressionConditionModel(
        left: Map<String, dynamic>.from(conditionJson['left']),
        operator: conditionJson['operator'],
        right: Map<String, dynamic>.from(conditionJson['right']),
      );
    }).toList();

    final List<dynamic> childrenJson = json['children'] ?? [];
    final List<ProgressionActionModel> children =
        childrenJson.map((actionJson) {
      return ProgressionActionModel(
        id: actionJson['id'],
        type: actionJson['type'],
        target: actionJson['target'],
        value: Map<String, dynamic>.from(actionJson['value']),
      );
    }).toList();

    return ProgressionRuleModel(
      id: json['id'],
      type: json['type'],
      conditions: conditions,
      logicalOperator: json['logicalOperator'],
      children: children,
    );
  }
}
