// lib/services/progression_manager_screen/firestore_profile_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/progression_manager_screen/progression_profile_model.dart';
import '../../models/progression_manager_screen/progression_rule_model.dart';
import '../../models/progression_manager_screen/progression_condition_model.dart';
import '../../models/progression_manager_screen/progression_action_model.dart';

class FirestoreProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Standardprofile
  static List<ProgressionProfileModel> _standardProfiles = [];

  // Standardprofile setzen (wird beim Start vom Provider aufgerufen)
  static void setStandardProfiles(List<ProgressionProfileModel> profiles) {
    _standardProfiles = List.from(profiles);
  }

  // Hilfsmethode, um die Benutzer-ID zu erhalten
  String? _getUserId() {
    return _auth.currentUser?.uid;
  }

  // Referenz zur Benutzerprofile-Sammlung
  CollectionReference _getProfilesCollection() {
    final userId = _getUserId();
    if (userId == null) throw Exception('Benutzer ist nicht angemeldet');

    return _firestore.collection('users').doc(userId).collection('profiles');
  }

  // Referenz zum Benutzerdokument
  DocumentReference _getUserDoc() {
    final userId = _getUserId();
    if (userId == null) throw Exception('Benutzer ist nicht angemeldet');

    return _firestore.collection('users').doc(userId);
  }

  // Profile laden
  Future<List<ProgressionProfileModel>> loadProfiles() async {
    try {
      // Wenn nicht angemeldet, nur Standardprofile zurückgeben
      final userId = _getUserId();
      if (userId == null) {
        print('Benutzer nicht angemeldet, gebe nur Standardprofile zurück');
        return _standardProfiles;
      }

      print('Lade Profile für Benutzer: $userId');

      // Gespeicherte Profile abrufen
      final snapshot = await _getProfilesCollection().get();
      final List<ProgressionProfileModel> loadedProfiles = [];

      // Standardprofile hinzufügen
      loadedProfiles.addAll(_standardProfiles);
      print('${_standardProfiles.length} Standardprofile hinzugefügt');

      // Benutzerdefinierte Profile hinzufügen
      for (var doc in snapshot.docs) {
        try {
          final profileJson = doc.data() as Map<String, dynamic>;
          final profile = _decodeProfileFromJson(profileJson);

          // Überprüfen, ob das Profil bereits in der Liste ist
          final existingIndex =
              loadedProfiles.indexWhere((p) => p.id == profile.id);
          if (existingIndex != -1) {
            // Wenn es ein benutzerdefiniertes Profil ist, aktualisieren
            if (!_isStandardProfile(profile.id)) {
              loadedProfiles[existingIndex] = profile;
              print('Bestehendes Profil aktualisiert: ${profile.id}');
            }
          } else {
            // Wenn es noch nicht in der Liste ist, hinzufügen
            loadedProfiles.add(profile);
            print('Neues Profil hinzugefügt: ${profile.id}');
          }
        } catch (e) {
          print('Fehler beim Dekodieren eines Profils: $e');
        }
      }

      print('Insgesamt ${loadedProfiles.length} Profile geladen');
      return loadedProfiles;
    } catch (e) {
      print('Fehler beim Laden der Profile: $e');
      return _standardProfiles;
    }
  }

  // Profile speichern
  Future<bool> saveProfiles(List<ProgressionProfileModel> profiles) async {
    try {
      // Wenn nicht angemeldet, nicht speichern
      final userId = _getUserId();
      if (userId == null) {
        print('Kann Profile nicht speichern, Benutzer nicht angemeldet');
        return false;
      }

      // Benutzerdefinierte Profile filtern
      final customProfiles =
          profiles.where((p) => !_isStandardProfile(p.id)).toList();
      print(
          'Speichere ${customProfiles.length} benutzerdefinierte Profile für Benutzer $userId');

      // Batch-Operationen für effizientes Speichern
      final batch = _firestore.batch();

      // Bestehende Profile löschen
      final existingProfilesSnapshot = await _getProfilesCollection().get();
      for (var doc in existingProfilesSnapshot.docs) {
        batch.delete(doc.reference);
        print('Lösche bestehendes Profil: ${doc.id}');
      }

      // Neue benutzerdefinierte Profile speichern
      for (var profile in customProfiles) {
        final profileJson = _encodeProfileToJson(profile);
        batch.set(_getProfilesCollection().doc(profile.id), profileJson);
        print('Speichere Profil: ${profile.id}');
      }

      await batch.commit();
      print('Profile erfolgreich gespeichert');
      return true;
    } catch (e) {
      print('Fehler beim Speichern der Profile: $e');
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

  // Public-Methode für die Decodierung eines Profils aus JSON (für MigrationService)
  static ProgressionProfileModel decodeProfileFromJson(
      Map<String, dynamic> json) {
    return _decodeProfileFromJson(json);
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
      logicalOperator: json['logicalOperator'] ?? 'AND',
      children: children,
    );
  }

  // Migrationsmethode: Lokale Profile zu Firestore migrieren
  Future<bool> migrateLocalProfilesToFirestore(
      List<ProgressionProfileModel> localProfiles) async {
    try {
      print(
          'Starte Migration von ${localProfiles.length} lokalen Profilen zu Firestore');
      return await saveProfiles(localProfiles);
    } catch (e) {
      print('Fehler bei der Migration lokaler Profile: $e');
      return false;
    }
  }

  // Einzelnes Profil in Firestore speichern
  Future<bool> saveProfileToFirestore(ProgressionProfileModel profile) async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print('Kann Profil nicht speichern, Benutzer nicht angemeldet');
        return false;
      }

      final profileJson = _encodeProfileToJson(profile);
      await _getProfilesCollection().doc(profile.id).set(profileJson);

      print('Profil erfolgreich gespeichert: ${profile.id}');
      return true;
    } catch (e) {
      print('Fehler beim Speichern des Profils: $e');
      return false;
    }
  }
}
