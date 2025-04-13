import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import 'components/set_table_widget.dart';
import 'components/progression_config_panel_widget.dart';
import 'components/modals/rule_editor_dialog.dart';
import 'components/modals/profile_editor_dialog.dart';

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
                    'Bankdrücken Tracking',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

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

                // Erklärungspanel
                _buildExplanationPanel(context),
              ],
            ),
          ),
        ),

        // Dialoge
        if (provider.zeigeRegelEditor) const RuleEditorDialog(),

        if (provider.zeigeProfilEditor) const ProfileEditorDialog(),
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
    final profil = provider.aktuellesProfil;

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
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Profil: ${profil?.name ?? ""}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.purple[700],
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: provider.empfehlungUebernehmen,
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
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aktuelles Progressionsmodell: ${profil?.name ?? ""}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            profil?.description ?? "",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                        color: Colors.grey[500],
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
                        color: Colors.grey[500],
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
                        color: Colors.grey[500],
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
