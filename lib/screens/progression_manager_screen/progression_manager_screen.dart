import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import 'progression_manager_detail_screen.dart';
import '../../widgets/progression_manager_screen/components/set_card_widget.dart';
import '../../widgets/progression_manager_screen/components/modals/rule_editor_screen.dart';
import '../../widgets/progression_manager_screen/components/modals/profile_editor_screen.dart';

class ProgressionManagerScreen extends StatelessWidget {
  const ProgressionManagerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProgressionManagerProvider(),
      child: const ProgressionManagerScreenContent(),
    );
  }
}

class ProgressionManagerScreenContent extends StatelessWidget {
  const ProgressionManagerScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progression Manager'),
        // Info-Button entfernt
      ),
      body: provider.zeigeRegelEditor || provider.zeigeProfilEditor
          ? _buildEditorScreen(context, provider)
          : _buildMainScreen(context, provider),
    );
  }

  Widget _buildMainScreen(
      BuildContext context, ProgressionManagerProvider provider) {
    final profil = provider.aktuellesProfil;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // Demo Übung Header wurde komplett entfernt

              // Aktives Profil anzeigen - nach oben verschoben
              if (profil != null)
                Card(
                  elevation: 1,
                  color: Colors.purple[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.trending_up, color: Colors.purple[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Aktives Profil: ${profil.name}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profil.description,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.purple[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Sätze als Karten anzeigen
              for (final satz in provider.saetze) SetCardWidget(satz: satz),
              const SizedBox(height: 24),

              // Button zum Öffnen des detaillierten Progression Manager Screens
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ProgressionManagerDetailScreen(provider: provider),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Detaillierten Progression Manager öffnen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
        // Bottom Action Bar
        _buildBottomActionBar(context, provider),
      ],
    );
  }

  Widget _buildEditorScreen(
      BuildContext context, ProgressionManagerProvider provider) {
    if (provider.zeigeRegelEditor) {
      return const RuleEditorScreen();
    } else if (provider.zeigeProfilEditor) {
      return const ProfileEditorScreen();
    }
    return const SizedBox.shrink();
  }

  Widget _buildCompletedTrainingCard(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);

    return Card(
      elevation: 2,
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 32,
                ),
                SizedBox(width: 8),
                Text(
                  'Übung abgeschlossen!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Alle Sätze für diese Übung wurden erfolgreich abgeschlossen. Was möchtest du als nächstes tun?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Zwei Buttons mit unterschiedlichen Funktionen
            Row(
              children: [
                // Button zum Weitergehen zur nächsten Übung
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        provider.uebungAbschliessen(neueUebung: true),
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Nächste Übung'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Button zum Wiederholen derselben Übung
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.trainingZuruecksetzen,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Übung wiederholen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(
      BuildContext context, ProgressionManagerProvider provider) {
    // Container für die Action Bar beibehalten, auch wenn das Training abgeschlossen ist
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: provider.trainingAbgeschlossen
          // Wenn Training abgeschlossen, "Übung abschließen" Button anzeigen
          ? ElevatedButton.icon(
              onPressed: () => provider.uebungAbschliessen(),
              icon: const Icon(Icons.refresh),
              label: const Text('Übung abschließen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            )
          // Wenn Training noch läuft, normale Buttons anzeigen
          : Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.empfehlungUebernehmen,
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('Empfehlung übernehmen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.satzAbschliessen,
                    icon: const Icon(Icons.check),
                    label: const Text('Satz abschließen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
