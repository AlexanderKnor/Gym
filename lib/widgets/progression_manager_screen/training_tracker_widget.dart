import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import 'components/set_table_widget.dart';
import 'components/progression_config_panel_widget.dart';
import '../../screens/progression_manager_screen/rule_editor_screen.dart';
import '../../screens/progression_manager_screen/profile_editor_screen.dart';

class TrainingTrackerWidget extends StatelessWidget {
  const TrainingTrackerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);

    return Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titel
                const Center(
                  child: Text(
                    'Demo Übung Tracking', // Geändert von Bankdrücken zu Demo Übung
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Profilinformation wird jetzt oben angezeigt
                _buildExplanationPanel(context),

                const SizedBox(height: 16),

                // Progressions-Manager Toggle Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => provider.toggleProgressionManager(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[100],
                        foregroundColor: Colors.purple[700],
                      ),
                      child: Text(provider.zeigePQB
                          ? 'Progressions-Manager schließen'
                          : 'Progressions-Manager öffnen'),
                    ),
                  ],
                ),

                // Progressions-Manager Panel (wenn geöffnet)
                if (provider.zeigePQB) ...[
                  const SizedBox(height: 16),
                  const ProgressionConfigPanelWidget(),
                ],

                const SizedBox(height: 16),

                // Training abgeschlossen oder aktives Training
                if (provider.trainingAbgeschlossen) ...[
                  _buildCompletedTrainingUI(context),
                ] else ...[
                  _buildActiveTrainingUI(context),
                ],

                const SizedBox(height: 16),

                // Satz-Tabelle
                const SetTableWidget(),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Dialoge
        if (provider.zeigeRegelEditor) const RuleEditorScreen(),

        if (provider.zeigeProfilEditor) const ProfileEditorScreen(),
      ],
    );
  }

  Widget _buildCompletedTrainingUI(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);

    return Center(
      child: Column(
        children: [
          const Text(
            'Training abgeschlossen! 💪',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => provider.uebungAbschliessen(),
            icon: const Icon(Icons.refresh),
            label: const Text('Übung abschließen und neu starten'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(200, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTrainingUI(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'Aktueller Satz: ',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '${provider.aktiverSatz}/4',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: provider.sollEmpfehlungAnzeigen(provider.aktiverSatz)
                  ? provider.empfehlungUebernehmen
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Empfehlung übernehmen'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: provider.satzAbschliessen,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Satz abschließen'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExplanationPanel(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);
    final profil = provider.aktuellesProfil;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.purple[700]),
              const SizedBox(width: 8),
              Text(
                'Aktives Progressionsmodell: ${profil?.name ?? ""}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            profil?.description ?? "",
            style: TextStyle(color: Colors.purple[600], fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WIEDERHOLUNGEN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[500],
                      ),
                    ),
                    Text(
                      '${profil?.config['targetRepsMin'] ?? ""} - ${profil?.config['targetRepsMax'] ?? ""} Wdh.',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RIR-BEREICH',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[500],
                      ),
                    ),
                    Text(
                      '${profil?.config['targetRIRMin'] ?? ""} - ${profil?.config['targetRIRMax'] ?? ""} RIR',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GEWICHTS-STEIGERUNG',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[500],
                      ),
                    ),
                    Text(
                      '${profil?.config['increment'] ?? ""} kg',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
