import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/progression_manager_screen/progression_manager_provider.dart';
import 'profile_detail_screen.dart'; // Import für den ProfileDetailScreen

/// Ein universeller Editor für Progressionsprofile, der sowohl als eigenständiger Screen
/// als auch als Dialog verwendet werden kann.
class ProfileEditorScreen extends StatelessWidget {
  /// Bestimmt, ob die Komponente als Dialog oder als Screen dargestellt wird
  final bool isDialog;

  const ProfileEditorScreen({
    Key? key,
    this.isDialog = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);
    final profil = provider.bearbeitetesProfil;

    if (profil == null) {
      // Timeout-Mechanismus, um aus dem Ladezustand zu kommen, falls etwas schief geht
      Future.delayed(const Duration(seconds: 3), () {
        if (context.mounted && provider.bearbeitetesProfil == null) {
          provider.closeProfileEditor();
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      });

      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil wird geladen...'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              provider.closeProfileEditor();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Dialog-Modus: Im Stack mit abgedunkeltem Hintergrund
    if (isDialog) {
      return Stack(
        children: [
          // Abgedunkelter Hintergrund
          GestureDetector(
            onTap: provider.closeProfileEditor,
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),

          // Dialog-Inhalt
          Center(
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(24),
                child: ProfileEditorContent(
                  profil: profil,
                  isDialog: true,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Screen-Modus: Als vollständiger Screen mit AppBar
    return WillPopScope(
      onWillPop: () async {
        provider.closeProfileEditor();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            profil.id.contains('profile_')
                ? 'Neues Profil erstellen'
                : 'Profil bearbeiten',
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              provider.closeProfileEditor();
              // Wenn möglich, Pop aufrufen
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                // Lade-Indikator anzeigen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Speichere Profil...'),
                    duration: Duration(seconds: 1),
                  ),
                );

                final result = await provider.saveProfile();

                if (context.mounted) {
                  // Navigationsplan erstellen, aber erst später ausführen
                  final bool isSuccess = result['success'] == true;
                  final String? profileId = result['profileId'];
                  final bool isNewProfile = result['isNewProfile'] ?? false;

                  // Wichtig: Erst Editor schließen
                  provider.closeProfileEditor();

                  // Kurze Verzögerung einbauen, damit der State sich aktualisieren kann
                  // und der Widget-Baum stabil ist
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      // Erneut prüfen, ob der Context noch gültig ist
                      if (isSuccess && isNewProfile && profileId != null) {
                        // Bei einem neuen Profil zum Detailscreen navigieren
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);

                          // Verzögerte Navigation zum Detailscreen, nach dem Pop abgeschlossen ist
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (context.mounted) {
                              // Profil aus dem Provider holen, nachdem der State aktualisiert wurde
                              final updatedProfile = provider.profileProvider
                                  .getProfileById(profileId);
                              if (updatedProfile != null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ProfileDetailScreen(
                                      profile: updatedProfile,
                                      initialTab: 0, // Editor-Tab
                                    ),
                                  ),
                                );
                              }
                            }
                          });
                        }
                      } else {
                        // Bei einem bearbeiteten Profil oder Fehler einfach zurück
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      }
                    }
                  });
                }
              },
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Speichern',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ProfileEditorContent(
              profil: profil,
              isDialog: false,
            ),
          ),
        ),
      ),
    );
  }
}

/// Der eigentliche Inhalt des Profil-Editors, der sowohl im Dialog als auch im Screen verwendet wird
class ProfileEditorContent extends StatelessWidget {
  final dynamic profil;
  final bool isDialog;

  const ProfileEditorContent({
    Key? key,
    required this.profil,
    required this.isDialog,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nur im Dialog-Modus Header mit Schließen-Button anzeigen
        if (isDialog) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profil bearbeiten: ${profil.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: provider.closeProfileEditor,
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
        ],

        // Gemeinsame Inhalte
        _buildBasicInfoSection(context, provider, profil),
        const SizedBox(height: 24),
        _buildConfigSection(context, provider, profil),

        // Buttons am Ende - im Dialog-Modus anders als im Screen
        const SizedBox(height: 24),
        if (isDialog)
          _buildDialogButtons(context, provider)
        else
          _buildScreenButtons(context, provider),
      ],
    );
  }

  Widget _buildBasicInfoSection(BuildContext context,
      ProgressionManagerProvider provider, dynamic profil) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Grundinformationen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name
            const Text(
              'Profilname',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: TextEditingController(text: profil.name),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Name des Progressionsprofils',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (value) => provider.updateProfile('name', value),
            ),
            const SizedBox(height: 16),

            // Beschreibung
            const Text(
              'Beschreibung',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: TextEditingController(text: profil.description),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Kurze Beschreibung des Profils',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              minLines: 2,
              maxLines: 3,
              onChanged: (value) =>
                  provider.updateProfile('description', value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSection(BuildContext context,
      ProgressionManagerProvider provider, dynamic profil) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Konfiguration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Diese Standardwerte werden verwendet, um die Progression zu berechnen:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Wiederholungen
            _buildConfigRow(
              context,
              'Wiederholungsbereich',
              [
                _buildConfigField(
                  context,
                  'Min',
                  profil.config['targetRepsMin'].toString(),
                  (value) =>
                      provider.updateProfile('config.targetRepsMin', value),
                ),
                _buildConfigField(
                  context,
                  'Max',
                  profil.config['targetRepsMax'].toString(),
                  (value) =>
                      provider.updateProfile('config.targetRepsMax', value),
                ),
              ],
              Icons.repeat,
            ),
            const SizedBox(height: 16),

            // RIR
            _buildConfigRow(
              context,
              'RIR-Bereich (Reps in Reserve)',
              [
                _buildConfigField(
                  context,
                  'Min',
                  profil.config['targetRIRMin'].toString(),
                  (value) =>
                      provider.updateProfile('config.targetRIRMin', value),
                ),
                _buildConfigField(
                  context,
                  'Max',
                  profil.config['targetRIRMax'].toString(),
                  (value) =>
                      provider.updateProfile('config.targetRIRMax', value),
                ),
              ],
              Icons.battery_5_bar,
            ),
            const SizedBox(height: 16),

            // Gewichtssteigerung
            _buildConfigRow(
              context,
              'Gewichtssteigerung (kg)',
              [
                Expanded(
                  child: _buildConfigField(
                    context,
                    'Wert',
                    profil.config['increment'].toString(),
                    (value) =>
                        provider.updateProfile('config.increment', value),
                    suffix: 'kg',
                  ),
                ),
                const Spacer(),
              ],
              Icons.fitness_center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigRow(
    BuildContext context,
    String label,
    List<Widget> children,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: children,
        ),
      ],
    );
  }

  Widget _buildConfigField(BuildContext context, String label, String value,
      Function(String) onChanged,
      {String suffix = ''}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: TextEditingController(text: value),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
              suffixText: suffix.isNotEmpty ? suffix : null,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // Buttons für Dialog-Modus
  Widget _buildDialogButtons(
      BuildContext context, ProgressionManagerProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () {
            provider.closeProfileEditor();
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          child: const Text('Abbrechen'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () async {
            await provider.saveProfile();
            if (context.mounted) {
              provider.closeProfileEditor();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
          ),
          child: const Text('Profil speichern'),
        ),
      ],
    );
  }

  // Buttons für Screen-Modus - optional, da bereits in der AppBar vorhanden
  Widget _buildScreenButtons(
      BuildContext context, ProgressionManagerProvider provider) {
    // Im Screen-Modus werden die Hauptbuttons in der AppBar angezeigt
    // Zusätzliche Aktionen können hier hinzugefügt werden, falls nötig
    return const SizedBox.shrink();
  }
}
