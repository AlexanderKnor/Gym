import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../widgets/progression_manager_screen/components/rule_list_widget.dart';
import '../../widgets/progression_manager_screen/components/set_card_widget.dart';
import 'rule_editor_screen.dart';
import 'profile_editor_screen.dart';

class ProfileDetailScreen extends StatefulWidget {
  final dynamic profile;
  final int initialTab;

  const ProfileDetailScreen({
    Key? key,
    required this.profile,
    this.initialTab = 0, // 0 = Editor, 1 = Demo
  }) : super(key: key);

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );

    // Bei Demo-Tab das aktuelle Profil setzen
    if (widget.initialTab == 1) {
      // Nach dem ersten Build das Demo-Profil initialisieren
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider =
            Provider.of<ProgressionManagerProvider>(context, listen: false);
        provider.setDemoProfileId(widget.profile.id);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);

    // Dialog-Screens anzeigen, falls aktiv
    if (provider.zeigeRegelEditor) {
      return const RuleEditorScreen();
    }

    if (provider.zeigeProfilEditor) {
      return const ProfileEditorScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.edit),
              text: 'Bearbeiten',
            ),
            Tab(
              icon: Icon(Icons.science),
              text: 'Demo',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Editor
          _buildEditorTab(context, provider),

          // Tab 2: Demo
          _buildDemoTab(context, provider),
        ],
      ),
    );
  }

  Widget _buildEditorTab(
      BuildContext context, ProgressionManagerProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basis-Informationen
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Profilinformationen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          provider.openProfileEditor(widget.profile);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Bearbeiten'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.profile.description,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildConfigItem(
                          'Wiederholungen:',
                          '${widget.profile.config['targetRepsMin']} - ${widget.profile.config['targetRepsMax']} Wdh.',
                        ),
                      ),
                      Expanded(
                        child: _buildConfigItem(
                          'RIR-Bereich:',
                          '${widget.profile.config['targetRIRMin']} - ${widget.profile.config['targetRIRMax']} RIR',
                        ),
                      ),
                      Expanded(
                        child: _buildConfigItem(
                          'Steigerung:',
                          '${widget.profile.config['increment']} kg',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Regelliste
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progressionsregeln',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      provider.openRuleEditor(null);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Neue Regel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const RuleListWidget(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDemoTab(
      BuildContext context, ProgressionManagerProvider provider) {
    // Im Demo-Tab muss das ausgewählte Profil für die Berechnungen verwendet werden
    if (_tabController.index == 1) {
      // Stellen Sie sicher, dass das aktuelle Demo-Profil auf das angezeigte Profil gesetzt ist
      provider.setDemoProfileId(widget.profile.id);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profil-Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.science, color: Colors.purple[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Demo: ${widget.profile.name}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Diese Demo ermöglicht dir, die Progressionsregeln mit Beispieldaten zu testen. Trage Werte ein und schließe Sätze ab, um zu sehen, wie die Progression funktioniert.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Demo-Sätze
          const Text(
            'Demo Übung',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Training-Status
          provider.trainingAbgeschlossen
              ? _buildCompletedTrainingUI(context, provider)
              : _buildActiveTrainingUI(context, provider),

          const SizedBox(height: 16),

          // Sätze-Karten
          ...provider.saetze.map((satz) => SetCardWidget(satz: satz)),
        ],
      ),
    );
  }

  Widget _buildCompletedTrainingUI(
      BuildContext context, ProgressionManagerProvider provider) {
    return Card(
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
              onPressed: () => provider.trainingZuruecksetzen(),
              icon: const Icon(Icons.refresh),
              label: const Text('Demo zurücksetzen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTrainingUI(
      BuildContext context, ProgressionManagerProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
              ],
            ),
            const SizedBox(height: 16),
            Row(
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
          ],
        ),
      ),
    );
  }
}
