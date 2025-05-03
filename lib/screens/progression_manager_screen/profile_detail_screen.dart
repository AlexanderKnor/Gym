// lib/screens/progression_manager_screen/profile_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../widgets/progression_manager_screen/components/rule_list_widget.dart';
import '../../widgets/progression_manager_screen/components/set_card_widget.dart';
import 'rule_editor_screen.dart';
import 'profile_editor_screen.dart';

// Klasse zum Zeichnen der gestrichelten Linie - jetzt auf oberster Ebene
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double startY = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width
      ..style = PaintingStyle.stroke;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profilinformationen Card mit integriertem "Bearbeiten"-Button
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header mit Titel und Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Profilinformationen',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            provider.openProfileEditor(widget.profile);
                          },
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Bearbeiten'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
                  ),

                  // Beschreibung
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      widget.profile.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ),

                  // Trennlinie
                  Divider(color: Colors.grey[200]),

                  // Konfigurationswerte in moderner Darstellung
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _buildConfigValue(
                          context,
                          'Wiederholungen',
                          '${widget.profile.config['targetRepsMin']} - ${widget.profile.config['targetRepsMax']}',
                          'Wdh',
                        ),
                        _buildConfigSeparator(),
                        _buildConfigValue(
                          context,
                          'RIR-Bereich',
                          '${widget.profile.config['targetRIRMin']} - ${widget.profile.config['targetRIRMax']}',
                          'RIR',
                        ),
                        _buildConfigSeparator(),
                        _buildConfigValue(
                          context,
                          'Steigerung',
                          '${widget.profile.config['increment']}',
                          'kg',
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
    );
  }

  // Elegante Wertanzeige ohne Icons
  Widget _buildConfigValue(
    BuildContext context,
    String label,
    String value,
    String unit,
  ) {
    return Expanded(
      child: Column(
        children: [
          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          // Wert mit Einheit
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
      height: 32,
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

  // Eigener Header für die Regel-Liste
  Widget _buildCustomRuleListHeader(
    BuildContext context,
    ProgressionManagerProvider provider,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
              foregroundColor: Colors.grey[800],
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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

  // Angepasste Regelliste mit elegantem Kettendesign
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
        ? _buildEmptyRulesList(context, provider)
        : Column(
            children: [
              // Subtiles Info-Banner
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Regeln werden von oben nach unten geprüft. Nur die erste zutreffende Regel wird ausgeführt.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                          height: 1.4,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Container für die Regelliste mit eleganter Kette
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border(
                    left: BorderSide(color: Colors.grey[200]!),
                    right: BorderSide(color: Colors.grey[200]!),
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: List.generate(profil.rules.length, (i) {
                    final rule = profil.rules[i];
                    final isLastRule = i == profil.rules.length - 1;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Regelkarte
                        _buildElegantRuleCard(
                            context, provider, rule, i, profil.rules.length),

                        // Verbindungselement zwischen den Karten, außer bei der letzten Karte
                        if (!isLastRule) _buildRuleConnection(),
                      ],
                    );
                  }),
                ),
              ),
            ],
          );
  }

  // Verbesserte Kettenverbindung zwischen den Regelkarten
  Widget _buildRuleConnection() {
    return Container(
      height: 60,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Oberes Kettenglied
          Positioned(
            top: 0,
            child: Container(
              width: 16,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),

          // Vertikale Kettenverbindung mit gestrichelter Linie
          Center(
            child: Container(
              width: 2,
              height: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: CustomPaint(
                painter: DashedLinePainter(
                  color: Colors.grey[400]!,
                  dashWidth: 3,
                  dashSpace: 3,
                ),
              ),
            ),
          ),

          // "Sonst" Indikator als Kettenglied
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey[50]!,
                    Colors.grey[100]!,
                  ],
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'sonst',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Unteres Kettenglied
          Positioned(
            bottom: 0,
            child: Container(
              width: 16,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Leere Regel-Liste
  Widget _buildEmptyRulesList(
      BuildContext context, ProgressionManagerProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        children: [
          // Leichter Grauton für das Icon
          Icon(
            Icons.rule,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Keine Regeln definiert',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: -0.3,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Definiere Regeln, um festzulegen, wie sich deine Trainingsparameter entwickeln sollen.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => provider.openRuleEditor(null),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Erste Regel erstellen'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[800],
              backgroundColor: Colors.grey[50],
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Optimierte Version für elegante und dezente Regel-Karte
  Widget _buildElegantRuleCard(
      BuildContext context,
      ProgressionManagerProvider provider,
      dynamic rule,
      int index,
      int totalRules) {
    final bool isCondition = rule.type == 'condition';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(1, 0, 1, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[100]!,
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => provider.openRuleEditor(rule),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header mit Nummer, Typ und Aktionsbuttons
                Row(
                  children: [
                    // Nummerierter Kreis
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: isCondition
                              ? Colors.grey[400]!
                              : Colors.grey[400]!,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Regeltyp
                    Text(
                      isCondition ? 'Wenn-Dann Regel' : 'Direkte Zuweisung',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        letterSpacing: -0.3,
                      ),
                    ),

                    const Spacer(),

                    // Aktionsbuttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Reorder Buttons
                        if (totalRules > 1) ...[
                          if (index > 0)
                            _buildMinimalIconButton(
                              icon: Icons.arrow_upward,
                              tooltip: 'Nach oben',
                              onPressed: () async {
                                await _handleRuleReorder(
                                    provider, rule, index, index - 1);
                              },
                            ),
                          if (index < totalRules - 1)
                            _buildMinimalIconButton(
                              icon: Icons.arrow_downward,
                              tooltip: 'Nach unten',
                              onPressed: () async {
                                await _handleRuleReorder(
                                    provider, rule, index, index + 1);
                              },
                            ),
                        ],

                        _buildMinimalIconButton(
                          icon: Icons.edit_outlined,
                          tooltip: 'Bearbeiten',
                          onPressed: () => provider.openRuleEditor(rule),
                        ),

                        _buildMinimalIconButton(
                          icon: Icons.delete_outline,
                          tooltip: 'Löschen',
                          onPressed: () async {
                            await _showDeleteRuleDialog(
                                context, provider, rule.id);
                          },
                          color: Colors.grey[700],
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Regelinhalt mit voller Breite
                if (isCondition) ...[
                  // WENN-Teil (Bedingungen)
                  Container(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wenn:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...rule.conditions.asMap().entries.map<Widget>((entry) {
                          int i = entry.key;
                          final condition = entry.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (i > 0) ...[
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    'UND',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ),
                              ],
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Text(
                                  _formatConditionText(provider, condition),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Eleganter Trennstrich mit Pfeil
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.grey[200],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[100],
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Icon(
                          Icons.arrow_downward,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.grey[200],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // DANN-Teil (Aktionen)
                  if (rule.children.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dann:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...rule.children.map<Widget>((action) {
                            if (action.type != 'assignment') {
                              return const SizedBox.shrink();
                            }

                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                children: [
                                  // Zieltyp mit dezenter Darstellung
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(4),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Text(
                                      provider.getTargetLabel(action.target),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Zuweisung mit Expanded, um den Rest der Breite zu nutzen
                                  Expanded(
                                    child: Text(
                                      '= ${provider.renderValueNode(action.value)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[800],
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ] else if (rule.type == 'assignment' &&
                    rule.children.isNotEmpty) ...[
                  // Direkte Zuweisungen für den gesamten verfügbaren Platz
                  Container(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Setze Werte:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...rule.children.map<Widget>((action) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              children: [
                                // Zieltyp
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Text(
                                    provider.getTargetLabel(action.target),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Zuweisung mit Expanded
                                Expanded(
                                  child: Text(
                                    '= ${provider.renderValueNode(action.value)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Minimalistischer Icon-Button ohne Farbe
  Widget _buildMinimalIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color ?? Colors.grey[500],
          ),
        ),
      ),
    );
  }

  // Hilfsfunktion für Bedingungstext - umbenannt um Namenskonflikte zu vermeiden
  String _formatConditionText(
      ProgressionManagerProvider provider, dynamic condition) {
    final leftLabel = provider.getVariableLabel(condition.left['value']);
    final operatorLabel = provider.getOperatorLabel(condition.operator);
    final rightLabel = condition.right['type'] == 'variable'
        ? provider.getVariableLabel(condition.right['value'])
        : condition.right['value'].toString();

    return '$leftLabel $operatorLabel $rightLabel';
  }

  // Regel-Reihenfolge ändern - umbenannt um Namenskonflikte zu vermeiden
  Future<void> _handleRuleReorder(ProgressionManagerProvider provider,
      dynamic rule, int oldIndex, int newIndex) async {
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

  // Bestätigungsdialog zum Löschen - umbenannt um Namenskonflikte zu vermeiden
  Future<void> _showDeleteRuleDialog(BuildContext context,
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
