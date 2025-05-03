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
    } else {
      // Auch im Editor-Tab das aktuelle Profil initialisieren
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
    final theme = Theme.of(context);

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
              icon: Icon(Icons.edit_outlined),
              text: 'Bearbeiten',
            ),
            Tab(
              icon: Icon(Icons.science_outlined),
              text: 'Demo',
            ),
          ],
          labelColor: Colors.black,
          indicatorColor: Colors.black,
          unselectedLabelColor: Colors.grey[700],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Editor
          _buildEditorTab(context, provider, theme),

          // Tab 2: Demo
          _buildDemoTab(context, provider),
        ],
      ),
    );
  }

  Widget _buildEditorTab(
    BuildContext context,
    ProgressionManagerProvider provider,
    ThemeData theme,
  ) {
    return Scaffold(
      body: Column(
        children: [
          // Action Bar - Apple-Stil
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Profil bearbeiten Button
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          provider.openProfileEditor(widget.profile);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: Colors.grey[800],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Profil bearbeiten',
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
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profilinformationen Card
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Profilinformationen',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.profile.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(color: Colors.grey[200]),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              _buildConfigItemRefined(
                                context,
                                'Wiederholungen',
                                '${widget.profile.config['targetRepsMin']} - ${widget.profile.config['targetRepsMax']}',
                                'Wdh',
                                Icons.repeat_rounded,
                              ),
                              _buildConfigSeparator(),
                              _buildConfigItemRefined(
                                context,
                                'RIR-Bereich',
                                '${widget.profile.config['targetRIRMin']} - ${widget.profile.config['targetRIRMax']}',
                                'RIR',
                                Icons.battery_5_bar_rounded,
                              ),
                              _buildConfigSeparator(),
                              _buildConfigItemRefined(
                                context,
                                'Steigerung',
                                '${widget.profile.config['increment']}',
                                'kg',
                                Icons.fitness_center_rounded,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Angepasste Regel-Liste mit eigenem Header
                  _buildCustomRuleListHeader(context, provider, theme),

                  // Regel-Liste ohne eigenen Header
                  _buildCustomRuleList(context, provider, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Eigener Header für die Regel-Liste im konsistenten Design
  Widget _buildCustomRuleListHeader(
    BuildContext context,
    ProgressionManagerProvider provider,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Progressionsregeln',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => provider.openRuleEditor(null),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Neue Regel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Angepasste Regelliste ohne Header, um Dopplung zu vermeiden
  Widget _buildCustomRuleList(
    BuildContext context,
    ProgressionManagerProvider provider,
    ThemeData theme,
  ) {
    final profil = provider.aktuellesProfil;

    if (profil == null) {
      return const Center(
        child: Text('Kein Profil ausgewählt'),
      );
    }

    // Leere Liste oder Regelliste
    return profil.rules.isEmpty
        ? _buildEmptyRulesList()
        : Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Regeln werden wie if/else-if von oben nach unten ausgewertet. Nur die erste zutreffende Regel wird angewendet.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: profil.rules.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey[300]),
                  itemBuilder: (context, index) {
                    final rule = profil.rules[index];
                    return _buildRuleCard(
                        context, provider, rule, index, profil.rules.length);
                  },
                ),
              ),
            ],
          );
  }

  // Leere Regel-Liste
  Widget _buildEmptyRulesList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.rule_folder,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          const Text(
            'Keine Regeln definiert',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Füge eine Regel hinzu, um das Progressionsverhalten zu definieren',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Regelkarte
  Widget _buildRuleCard(
      BuildContext context,
      ProgressionManagerProvider provider,
      dynamic rule,
      int index,
      int totalRules) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => provider.openRuleEditor(rule),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Regel-Typ anzeigen
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: rule.type == 'condition'
                          ? Colors.blue[100]
                          : Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      rule.type == 'condition' ? 'WENN' : 'SETZE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: rule.type == 'condition'
                            ? Colors.blue[800]
                            : Colors.green[800],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Bearbeiten & Löschen Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Reorder Buttons - nur anzeigen wenn mehr als eine Regel
                      if (totalRules > 1) ...[
                        // Nach oben Button - nicht für erste Regel
                        if (index > 0)
                          IconButton(
                            icon: const Icon(Icons.arrow_upward, size: 18),
                            onPressed: () async {
                              await _moveRule(provider, rule, index, index - 1);
                            },
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                          ),

                        // Nach unten Button - nicht für letzte Regel
                        if (index < totalRules - 1)
                          IconButton(
                            icon: const Icon(Icons.arrow_downward, size: 18),
                            onPressed: () async {
                              await _moveRule(provider, rule, index, index + 1);
                            },
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                          ),
                      ],

                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        color: Colors.red[700],
                        onPressed: () async {
                          await _confirmDeleteRule(context, provider, rule.id);
                        },
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Regel-Inhalt
              if (rule.type == 'condition') ...[
                // Bedingungstext
                Wrap(
                  children:
                      rule.conditions.asMap().entries.map<Widget>((entry) {
                    int i = entry.key;
                    final condition = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          if (i > 0) ...[
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'UND',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                          Expanded(
                            child: Text(
                              _buildConditionText(provider, condition),
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 4),

                // Dann-Teil (Aktionen)
                if (rule.children.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: rule.children.map<Widget>((action) {
                        if (action.type != 'assignment') {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getTargetColor(action.target)[0],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  provider
                                      .getTargetLabel(action.target)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _getTargetColor(action.target)[1],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '= ${provider.renderValueNode(action.value)}',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ] else if (rule.type == 'assignment' &&
                  rule.children.isNotEmpty) ...[
                // Direkte Zuweisungen (für Typ "assignment")
                ...rule.children.map<Widget>((action) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getTargetColor(action.target)[0],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            provider
                                .getTargetLabel(action.target)
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getTargetColor(action.target)[1],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '= ${provider.renderValueNode(action.value)}',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Hilfsfunktion für Bedingungstext
  String _buildConditionText(
      ProgressionManagerProvider provider, dynamic condition) {
    final leftLabel = provider.getVariableLabel(condition.left['value']);
    final operatorLabel = provider.getOperatorLabel(condition.operator);
    final rightLabel = condition.right['type'] == 'variable'
        ? provider.getVariableLabel(condition.right['value'])
        : condition.right['value'].toString();

    return '$leftLabel $operatorLabel $rightLabel';
  }

  // Hilfsfunktion für zielbasierte Farben
  List<Color> _getTargetColor(String target) {
    switch (target) {
      case 'kg':
        return [Colors.grey[200]!, Colors.grey[800]!];
      case 'reps':
        return [Colors.grey[200]!, Colors.grey[800]!];
      case 'rir':
        return [Colors.grey[200]!, Colors.grey[800]!];
      default:
        return [Colors.grey[200]!, Colors.grey[800]!];
    }
  }

  // Regel-Reihenfolge ändern
  Future<void> _moveRule(ProgressionManagerProvider provider, dynamic rule,
      int oldIndex, int newIndex) async {
    provider.handleDragStart(rule.id);

    if (oldIndex < newIndex) {
      // Nach unten verschieben
      final targetRule = provider.aktuellesProfil!.rules[newIndex];
      await provider.handleDrop(targetRule.id);
    } else {
      // Nach oben verschieben
      final targetRule = provider.aktuellesProfil!.rules[newIndex];
      await provider.handleDrop(targetRule.id);
    }
  }

  // Bestätigungsdialog zum Löschen
  Future<void> _confirmDeleteRule(BuildContext context,
      ProgressionManagerProvider provider, String ruleId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regel löschen'),
        content: const Text('Möchtest du diese Regel wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await provider.deleteRule(ruleId);
    }
  }

  // Verfeinertes Konfigurations-Item
  Widget _buildConfigItemRefined(
    BuildContext context,
    String label,
    String value,
    String unit,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: unit.isNotEmpty ? ' $unit' : '',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Vertikaler Separator zwischen den Konfigurationsitems
  Widget _buildConfigSeparator() {
    return Container(
      height: 36,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[200]!.withOpacity(0.0),
            Colors.grey[300]!.withOpacity(0.7),
            Colors.grey[200]!.withOpacity(0.0),
          ],
        ),
      ),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sätze-Karten
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
