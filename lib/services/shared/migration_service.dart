import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../progression_manager_screen/firestore_profile_service.dart';
import '../../models/progression_manager_screen/progression_profile_model.dart';
import '../../models/progression_manager_screen/progression_rule_model.dart';
import '../../models/progression_manager_screen/progression_condition_model.dart';
import '../../models/progression_manager_screen/progression_action_model.dart';

/// Service zur Migration lokaler Profile zu Firebase
class MigrationService {
  static const String MIGRATION_COMPLETED_KEY = 'profile_migration_completed';
  static const String PROFILES_KEY = 'saved_progression_profiles';
  static const String ACTIVE_PROFILE_KEY = 'active_progression_profile';

  /// Prüft und führt die Migration durch, wenn nötig
  static Future<bool> checkAndPerformMigration() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Prüfen, ob die Migration bereits durchgeführt wurde
      final migrationCompleted =
          prefs.getBool(MIGRATION_COMPLETED_KEY) ?? false;
      if (migrationCompleted) {
        print('Migration wurde bereits durchgeführt.');
        return true;
      }

      // Prüfen, ob lokale Profile existieren
      final profilesJson = prefs.getString(PROFILES_KEY);
      if (profilesJson == null || profilesJson.isEmpty) {
        print('Keine lokalen Profile gefunden. Migration nicht erforderlich.');
        // Keine lokalen Profile, Migration als abgeschlossen markieren
        await prefs.setBool(MIGRATION_COMPLETED_KEY, true);
        return true;
      }

      print('Lokale Profile gefunden. Starte Migration zu Firebase...');

      // Lokale Profile laden
      List<ProgressionProfileModel> localProfiles = [];
      try {
        final List<dynamic> decodedProfiles = jsonDecode(profilesJson);
        for (var profileData in decodedProfiles) {
          try {
            // Verwende die öffentliche Dekodiermethode
            final profile = FirestoreProfileService.decodeProfileFromJson(
                Map<String, dynamic>.from(profileData));
            localProfiles.add(profile);
            print('Lokales Profil dekodiert: ${profile.id} - ${profile.name}');
          } catch (e) {
            print('Fehler beim Dekodieren eines lokalen Profils: $e');
          }
        }
      } catch (e) {
        print('Fehler beim Parsen der lokalen Profile: $e');
      }

      if (localProfiles.isNotEmpty) {
        print(
            '${localProfiles.length} lokale Profile gefunden. Migriere zu Firebase...');

        final firestoreService = FirestoreProfileService();
        final success = await firestoreService
            .migrateLocalProfilesToFirestore(localProfiles);

        if (success) {
          print('Migration der Profile erfolgreich.');

          // Lokales aktives Profil laden und in Firestore speichern
          final activeProfileId = prefs.getString(ACTIVE_PROFILE_KEY) ?? '';
          if (activeProfileId.isNotEmpty) {
            print('Migriere aktives Profil: $activeProfileId');
            await firestoreService.saveActiveProfile(activeProfileId);
          }

          // Migration als abgeschlossen markieren
          await prefs.setBool(MIGRATION_COMPLETED_KEY, true);
          print('Migration abgeschlossen und als erfolgreich markiert.');
          return true;
        } else {
          print('Migration der Profile zu Firebase fehlgeschlagen.');
        }
      }

      return false;
    } catch (e) {
      print('Allgemeiner Fehler bei der Migration: $e');
      return false;
    }
  }
}
