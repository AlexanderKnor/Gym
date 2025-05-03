// lib/screens/progression_manager_screen/profile_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    // Auf Tab-Wechsel reagieren
    _tabController.addListener(_handleTabChange);

    // Bei Demo-Tab das aktuelle Profil setzen
    if (widget.initialTab == 1) {
      // Nach dem ersten Build das Demo-Profil initialisieren
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeDemoProfile();
      });
    }
  }

  void _handleTabChange() {
    // Wenn der Tab-Wechsel abgeschlossen ist
    if (!_tabController.indexIsChanging) {
      // Wenn zu Demo-Tab gewechselt wird
      if (_tabController.index == 1) {
        _initializeDemoProfile();
      }
    }
  }

  void _initializeDemoProfile() {
    final provider =
        Provider.of<ProgressionManagerProvider>(context, listen: false);

    // Profil setzen - dadurch wird auch das Training zurückgesetzt
    provider.setDemoProfileId(widget.profile.id);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  bool _hasCompletedSets(ProgressionManagerProvider provider) {
    return provider.saetze.any((satz) => satz.abgeschlossen);
  }

  void _showActionsMenu(
      BuildContext context, ProgressionManagerProvider provider) {
    // Prüfen, ob es abgeschlossene Sätze gibt
    if (!_hasCompletedSets(provider)) {
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
                    // Start training anew for demo mode
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

          // Tab 2: Demo mit verbesserter UI
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
          const RuleListWidget(),
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
    final bool allSetsCompleted =
        provider.saetze.every((satz) => satz.abgeschlossen);
    final bool hasMoreSets = provider.saetze.any((satz) => !satz.abgeschlossen);
    final bool hasCompletedSets = _hasCompletedSets(provider);
    final bool hasRecommendation =
        provider.sollEmpfehlungAnzeigen(provider.aktiverSatz);

    return Scaffold(
      body: Column(
        children: [
          // Action Bar - Apple-Stil
          if (!provider.trainingAbgeschlossen)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  16, 8, 16, 4), // Unterer Abstand reduziert
              child: Container(
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
                          onTap: (!hasRecommendation || allSetsCompleted)
                              ? null
                              : () {
                                  if (hasRecommendation) {
                                    HapticFeedback.mediumImpact();
                                    provider.empfehlungUebernehmen();
                                  }
                                },
                          borderRadius: BorderRadius.circular(12),
                          child: Opacity(
                            opacity: (!hasRecommendation || allSetsCompleted)
                                ? 0.5
                                : 1.0,
                            child: Container(
                              height: 38,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
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
                          onTap: !hasCompletedSets
                              ? null
                              : () => _showActionsMenu(context, provider),
                          borderRadius: BorderRadius.circular(12),
                          child: Opacity(
                            opacity: !hasCompletedSets ? 0.5 : 1.0,
                            child: Container(
                              height: 38,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
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
            ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  16, 8, 16, 16), // Oberer Abstand reduziert
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sätze-Karten mit verbesserter UI
                  ...provider.saetze.map((satz) => SetCardWidget(satz: satz)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator - nur anzeigen, wenn das Training noch nicht abgeschlossen ist
          if (!provider.trainingAbgeschlossen)
            LinearProgressIndicator(
              value: provider.saetze.isEmpty
                  ? 0.0
                  : provider.saetze.where((satz) => satz.abgeschlossen).length /
                      provider.saetze.length,
              minHeight: 2,
              backgroundColor: Colors.grey[200],
              color: Colors.black,
            ),

          // Hauptbutton
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: provider.trainingAbgeschlossen
                      ? () => provider.trainingZuruecksetzen(
                          resetRecommendations: true)
                      : allSetsCompleted
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
                    provider.trainingAbgeschlossen
                        ? 'Demo zurücksetzen'
                        : allSetsCompleted
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
      ),
    );
  }
}
