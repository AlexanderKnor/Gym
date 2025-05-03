// lib/widgets/progression_manager_screen/training_tracker_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import 'components/set_card_widget.dart';
import 'components/progression_config_panel_widget.dart';
import '../../screens/progression_manager_screen/rule_editor_screen.dart';
import '../../screens/progression_manager_screen/profile_editor_screen.dart';

class TrainingTrackerWidget extends StatelessWidget {
  const TrainingTrackerWidget({Key? key}) : super(key: key);

  bool _hasCompletedSets(List<dynamic> sets) {
    return sets.any((satz) => satz.abgeschlossen);
  }

  void _showActionsMenu(
      BuildContext context, ProgressionManagerProvider provider) {
    // Prüfen, ob es abgeschlossene Sätze gibt
    if (!_hasCompletedSets(provider.saetze)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Keine abgeschlossenen Sätze vorhanden'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    // Haptisches Feedback
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Satz-Optionen',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Training zurücksetzen
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    provider.trainingZuruecksetzen(resetRecommendations: false);
                    Navigator.pop(context);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.replay_rounded,
                          size: 24,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Training zurücksetzen',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);

    return Stack(
      children: [
        // Main content with Scaffold for bottom bar layout
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profilinformation
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

                  const SizedBox(height: 24),

                  // Action Bar - Apple-Stil
                  if (!provider.trainingAbgeschlossen) ...[
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Kraftrechner Button (Progress)
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: (!provider.sollEmpfehlungAnzeigen(
                                            provider.aktiverSatz) ||
                                        provider.trainingAbgeschlossen)
                                    ? null
                                    : () {
                                        HapticFeedback.mediumImpact();
                                        provider.empfehlungUebernehmen();
                                      },
                                borderRadius: BorderRadius.circular(12),
                                child: Opacity(
                                  opacity: (!provider.sollEmpfehlungAnzeigen(
                                              provider.aktiverSatz) ||
                                          provider.trainingAbgeschlossen)
                                      ? 0.5
                                      : 1.0,
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.bolt,
                                          size: 18,
                                          color: Colors.grey[800],
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Progress',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[800],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Trennlinie
                          Container(
                            width: 1,
                            height: 24,
                            color: Colors.grey[300],
                          ),

                          // Zurück-Button
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: !_hasCompletedSets(provider.saetze)
                                    ? null
                                    : () => _showActionsMenu(context, provider),
                                borderRadius: BorderRadius.circular(12),
                                child: Opacity(
                                  opacity: !_hasCompletedSets(provider.saetze)
                                      ? 0.5
                                      : 1.0,
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.replay_rounded,
                                          size: 18,
                                          color: Colors.grey[800],
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Zurück',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[800],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Demo-Übung Titel
                  const Text(
                    'Demo Übung',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Training abgeschlossen (nur anzeigen, wenn abgeschlossen)
                  if (provider.trainingAbgeschlossen)
                    _buildCompletedTrainingUI(context),

                  // Satz-Karten mit der verbesserten UI
                  ..._buildSetCards(context, provider),
                ],
              ),
            ),
          ),
          // Satz abschließen Button am unteren Bildschirmrand
          bottomNavigationBar: !provider.trainingAbgeschlossen
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress indicator
                    LinearProgressIndicator(
                      value: provider.saetze.isEmpty
                          ? 0.0
                          : provider.saetze
                                  .where((satz) => satz.abgeschlossen)
                                  .length /
                              provider.saetze.length,
                      minHeight: 2,
                      backgroundColor: Colors.grey[200],
                      color: Colors.black,
                    ),

                    // Hauptbutton für Satz abschließen
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: provider.saetze
                                    .every((satz) => satz.abgeschlossen)
                                ? null
                                : provider.satzAbschliessen,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              provider.saetze
                                      .every((satz) => satz.abgeschlossen)
                                  ? 'Training abschließen'
                                  : 'Satz abschließen',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : null,
        ),

        // Dialoge als Overlays
        if (provider.zeigeRegelEditor) const RuleEditorScreen(),
        if (provider.zeigeProfilEditor) const ProfileEditorScreen(),
      ],
    );
  }

  List<Widget> _buildSetCards(
      BuildContext context, ProgressionManagerProvider provider) {
    return provider.saetze.map((satz) => SetCardWidget(satz: satz)).toList();
  }

  Widget _buildCompletedTrainingUI(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);

    return Card(
      color: Colors.green[50],
      margin: const EdgeInsets.only(bottom: 16),
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
                  'Training abgeschlossen!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  provider.trainingZuruecksetzen(resetRecommendations: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Demo zurücksetzen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
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
