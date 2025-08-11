// lib/screens/progression_manager_screen/profile_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // Import für BackdropFilter
import 'dart:math'; // Import für sin, pi
import 'package:provider/provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../utils/smooth_page_route.dart';
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
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _setCard1Key = GlobalKey();
  final GlobalKey _setCard2Key = GlobalKey();
  final GlobalKey _setCard3Key = GlobalKey();

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

    // NUR bei Demo-Tab das aktuelle Profil setzen
    if (widget.initialTab == 1) {
      // Nach dem ersten Build das Demo-Profil initialisieren
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeDemoProfile();
      });
    }
    // Editor-Tab (initialTab == 0) setzt KEIN Demo-Profil!
    // Es verwendet direkt widget.profile für die Regel-Anzeige
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
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToNextSet() {
    final provider =
        Provider.of<ProgressionManagerProvider>(context, listen: false);
    
    // Finde das aktuelle Set
    final currentSetIndex = provider.aktiverSatz - 1;
    
    // Bestimme das Ziel-Widget basierend auf dem Index
    GlobalKey? targetKey;
    if (currentSetIndex == 0) {
      targetKey = _setCard2Key;
    } else if (currentSetIndex == 1) {
      targetKey = _setCard3Key;
    }
    
    if (targetKey != null && targetKey.currentContext != null) {
      // Berechne die Position des Ziel-Widgets
      final RenderBox renderBox = targetKey.currentContext!.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      
      // Scrolle mit Animation zum nächsten Set
      _scrollController.animateTo(
        _scrollController.offset + position.dy - 100, // 100px Offset für bessere Sichtbarkeit
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _hasCompletedSets(ProgressionManagerProvider provider) {
    // Prüfen, ob es unter den ersten 3 Sätzen abgeschlossene gibt
    return provider.saetze.take(3).any((satz) => satz.abgeschlossen);
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

  // Helper method to get current profile data (fresh from provider if available)
  dynamic _getCurrentProfile() {
    // Für Demo-Tab: Verwende Provider-Profil für Training-Simulation
    // Für Editor-Tab: Verwende direkt widget.profile
    try {
      final currentTabIndex = _tabController.index;
      if (currentTabIndex == 0) {
        // Editor-Tab: Verwende direkt widget.profile, keine Provider-Interferenz
        return widget.profile;
      } else {
        // Demo-Tab: Verwende Provider-Profil für Training-Simulation
        final provider = Provider.of<ProgressionManagerProvider>(context, listen: false);
        final freshProfile = provider.profileProvider.getProfileById(widget.profile.id);
        return freshProfile ?? widget.profile;
      }
    } catch (e) {
      // Fallback auf widget.profile wenn TabController noch nicht initialisiert
      return widget.profile;
    }
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
      backgroundColor: _midnight,
      appBar: AppBar(
        backgroundColor: _midnight,
        title: Text(
          widget.profile.name,
          style: const TextStyle(color: _snow),
        ),
        iconTheme: const IconThemeData(color: _snow),
        elevation: 0, // Kein Schatten
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _steel.withOpacity(0.2), width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Bearbeiten'),
                Tab(text: 'Demo'),
              ],
              labelColor: _snow,
              unselectedLabelColor: _mercury,
              indicatorWeight: 3,
              indicatorColor: _emberCore,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
              ),
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(color: _emberCore, width: 3),
                insets: const EdgeInsets.symmetric(horizontal: 24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              splashFactory: NoSplash.splashFactory,
              overlayColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                  return states.contains(MaterialState.focused)
                      ? null
                      : Colors.transparent;
                },
              ),
            ),
          ),
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
      backgroundColor: _midnight,
      body: Column(
        children: [
          // Einfacher Header
          _buildSimpleHeader(context, provider),
          
          // Main Content Area
          Expanded(
            child: _buildMainContent(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleHeader(BuildContext context, ProgressionManagerProvider provider) {
    return const SizedBox(height: 8);
  }

  Widget _buildMainContent(BuildContext context, ProgressionManagerProvider provider) {
    // Editor-Tab: Verwende IMMER widget.profile (das übergebene Profil)
    final profil = widget.profile;
    
    if (profil == null || profil.rules.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Configuration Section
            _buildConfigurationSection(context, provider),
            
            const SizedBox(height: 24),
            
            // Rules Section Header
            _buildSimpleRulesSection(context, provider, profil),
            
            const SizedBox(height: 16),
            
            // Empty State
            _buildSimpleEmptyState(context, provider),
            
            const SizedBox(height: 24),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Fixed Header Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Configuration Section
              _buildConfigurationSection(context, provider),
              
              const SizedBox(height: 24),
              
              // Rules Section Header
              _buildSimpleRulesSection(context, provider, profil),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
        
        // Expanded Reorderable List for auto-scroll
        Expanded(
          child: _buildReorderableRulesList(context, provider, profil),
        ),
      ],
    );
  }

  Widget _buildConfigurationSection(BuildContext context, ProgressionManagerProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        const Text(
          'Konfiguration',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _snow,
            letterSpacing: -0.5,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Configuration Card
        _buildQuickStats(context, provider),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, ProgressionManagerProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _charcoal.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _steel.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildMinimalStatItem(
                  '${_formatInteger(widget.profile.config['targetRepsMin'])}-${_formatInteger(widget.profile.config['targetRepsMax'])}',
                  'Wdhl',
                ),
                _buildMinimalDivider(),
                _buildMinimalStatItem(
                  '${_formatInteger(widget.profile.config['targetRIRMin'])}-${_formatInteger(widget.profile.config['targetRIRMax'])}',
                  'RIR',
                ),
                _buildMinimalDivider(),
                _buildMinimalStatItem(
                  '${_formatNumber(widget.profile.config['increment'])} kg',
                  'Steigerung',
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Edit Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => provider.openProfileEditor(widget.profile),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _steel.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _steel.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  color: _mercury,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumStatItem(String value, String label, IconData icon, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accentColor.withOpacity(0.08),
              accentColor.withOpacity(0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Icon mit eleganter Gestaltung
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withOpacity(0.2),
                    accentColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 18,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Wert - prominent
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _snow,
                letterSpacing: -0.4,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Label - dezent aber klar
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _mercury.withOpacity(0.8),
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalStatItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _snow,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _mercury.withOpacity(0.8),
              letterSpacing: -0.1,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalDivider() {
    return Container(
      height: 32,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: _steel.withOpacity(0.2),
    );
  }

  Widget _buildPremiumStatDivider() {
    return const SizedBox(width: 12);
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: _emberCore,
            size: 18,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _snow,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _mercury,
              letterSpacing: -0.1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: _steel.withOpacity(0.2),
    );
  }

  Widget _buildSimpleRulesSection(BuildContext context, ProgressionManagerProvider provider, dynamic profil) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Regeln',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _snow,
            letterSpacing: -0.5,
          ),
        ),
        // Add Rule Button - exaktes Design wie "NEU" Button
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            provider.openRuleEditor(null);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _charcoal.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _emberCore.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _midnight.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: _emberCore, size: 16),
                const SizedBox(width: 8),
                Text(
                  'NEU',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _emberCore,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReorderableRulesList(BuildContext context, ProgressionManagerProvider provider, dynamic profil) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: profil.rules.length,
      proxyDecorator: (child, index, animation) {
        final rule = profil.rules[index];
        
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            final double animValue = Curves.easeInOut.transform(animation.value);
            final double elevation = lerpDouble(2, 16, animValue)!;
            final double scale = lerpDouble(1, 1.05, animValue)!;
            final double opacity = lerpDouble(1.0, 0.9, animValue)!;
            
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _emberCore.withOpacity(0.4),
                        blurRadius: elevation,
                        offset: Offset(0, elevation / 2),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: elevation * 1.5,
                        offset: Offset(0, elevation / 3),
                      ),
                    ],
                  ),
                  // Nur die Card anzeigen, keine Flow Connection
                  child: _buildDraggableRuleCard(
                    context, 
                    provider, 
                    rule, 
                    index, 
                    profil.rules.length,
                    key: ValueKey('${rule.id}_proxy'),
                  ),
                ),
              ),
            );
          },
        );
      },
      onReorder: (oldIndex, newIndex) async {
        // Provide haptic feedback
        HapticFeedback.mediumImpact();
        
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        
        // Skip if no actual movement
        if (oldIndex == newIndex) return;
        
        try {
          // Get the rule to move
          final rule = profil.rules[oldIndex];
          
          // Use existing provider methods for reordering
          provider.handleDragStart(rule.id);
          
          // Calculate target rule ID
          String targetRuleId;
          if (newIndex >= profil.rules.length - 1) {
            // Moving to end - use the last rule's ID
            targetRuleId = profil.rules.last.id;
          } else {
            // Moving to specific position
            targetRuleId = profil.rules[newIndex].id;
          }
          
          await provider.handleDrop(targetRuleId);
        } catch (e) {
          print('Error reordering rules: $e');
          // Could show a snackbar here if needed
        }
      },
      itemBuilder: (context, index) {
        final rule = profil.rules[index];
        final isLastRule = index == profil.rules.length - 1;
        
        return Column(
          key: ValueKey(rule.id),
          children: [
            _buildDraggableRuleCard(
              context, 
              provider, 
              rule, 
              index, 
              profil.rules.length,
              key: ValueKey('${rule.id}_card'),
            ),
            // Flow connection between rules
            if (!isLastRule) _buildFlowConnection(context, index),
          ],
        );
      },
    );
  }


  void _showRuleOptionsMenu(BuildContext context, ProgressionManagerProvider provider, dynamic rule) {
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_charcoal, _graphite],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: _steel.withOpacity(0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header mit Titel
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_emberCore, _emberCore.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.rule_outlined,
                        color: _snow,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Regel Optionen',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: _snow,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, size: 22, color: _mercury),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Option 1: Regel bearbeiten
                _buildRuleOptionButton(
                  icon: Icons.edit_outlined,
                  label: 'Regel bearbeiten',
                  onTap: () {
                    Navigator.of(context).pop();
                    provider.openRuleEditor(rule);
                  },
                  isPrimary: false,
                ),

                const SizedBox(height: 12),

                // Option 2: Regel löschen
                _buildRuleOptionButton(
                  icon: Icons.delete_outline,
                  label: 'Regel löschen',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showDeleteRuleDialog(context, provider, rule.id);
                  },
                  isPrimary: false,
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRuleOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
    bool isDestructive = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDestructive 
                  ? Colors.red.withOpacity(0.1)
                  : _steel.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDestructive 
                    ? Colors.red.withOpacity(0.3)
                    : _steel.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isDestructive ? Colors.red : _snow,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                    color: isDestructive ? Colors.red : _snow,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlowConnection(BuildContext context, int index) {
    return Transform.translate(
      offset: const Offset(0, -6), // Verschiebt das gesamte Element nach oben
      child: Container(
        height: 40,
        width: double.infinity,
        child: Stack(
          children: [
          // Main flow line
          Positioned(
            left: 32, // Align with drag handle
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _emberCore.withOpacity(0.4),
                    _emberCore.withOpacity(0.7),
                    _emberCore.withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
          
          // Flow arrows animation
          _buildAnimatedFlowArrows(),
          
          // "Sonst" Label zentriert neben der Pfeilkaskade
          Positioned(
            left: 42, // Näher an der Pfeilkaskade, aber ohne Überlappung
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                'sonst',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _emberCore, // Gleiche Farbe wie die Pfeile
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildAnimatedFlowArrows() {
    return Positioned(
      left: 28,
      top: 4,
      bottom: 4,
      child: _FlowArrowsAnimationWidget(color: _emberCore),
    );
  }


  Widget _buildSimpleEmptyState(BuildContext context, ProgressionManagerProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _charcoal.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _steel.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.rule_rounded,
            color: _mercury,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Regeln',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _snow,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Erstelle Regeln für automatische Progression',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _mercury,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableRuleCard(BuildContext context, ProgressionManagerProvider provider, dynamic rule, int index, int totalRules, {required Key key}) {
    final bool isCondition = rule.type == 'condition';
    
    return Container(
      key: key,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _charcoal.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _steel.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                // Kompakter Header
                Row(
                  children: [
                    // Eleganter Drag Handle
                    Icon(
                      Icons.drag_handle_rounded,
                      color: _mercury.withOpacity(0.6),
                      size: 18,
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Rule Number
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _emberCore.withOpacity(0.15),
                        border: Border.all(
                          color: _emberCore.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _emberCore,
                          ),
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // More Actions
                    GestureDetector(
                      onTap: () => _showRuleOptionsMenu(context, provider, rule),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.more_horiz_rounded,
                          size: 16,
                          color: _mercury.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Rule Content - responsive und sauber
                if (isCondition) 
                  _buildCleanConditionContent(context, provider, rule)
                else 
                  _buildCleanDirectContent(context, provider, rule),
              ],
            ),
          ),
    );
  }
  
  Widget _buildCleanConditionContent(BuildContext context, ProgressionManagerProvider provider, dynamic rule) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _graphite.withOpacity(0.3),
            _charcoal.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _steel.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // WENN Section mit eleganter Visualisierung
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  _emberCore.withOpacity(0.12),
                  _emberCore.withOpacity(0.06),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              border: Border(
                bottom: BorderSide(
                  color: _emberCore.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Subtiles WENN Label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _emberCore.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _emberCore.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'WENN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _emberCore,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Bedingungen mit eleganter Typografie
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rule.conditions.asMap().entries.map<Widget>((entry) {
                      int i = entry.key;
                      final condition = entry.value;
                      
                      return Padding(
                        padding: EdgeInsets.only(top: i > 0 ? 6 : 0),
                        child: Row(
                          children: [
                            if (i > 0) 
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _emberCore.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'UND',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: _emberCore,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                _formatConditionText(provider, condition),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _snow,
                                  height: 1.2,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Visueller Pfeil-Übergang
          Container(
            height: 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Gradient Linie
                Container(
                  width: double.infinity,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _emberCore.withOpacity(0.3),
                        Colors.green.withOpacity(0.8),
                        Colors.green.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
                // Eleganter Pfeil
                Container(
                  width: 32,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        _emberCore,
                        Colors.green,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 12,
                    color: _snow,
                  ),
                ),
              ],
            ),
          ),
          
          // DANN Section mit beeindruckender Visualisierung
          if (rule.children.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.green.withOpacity(0.12),
                    Colors.green.withOpacity(0.06),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  // Subtiles DANN Label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'DANN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Aktionen - elegant und subtil
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: rule.children.where((action) => action.type == 'assignment').map<Widget>((action) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            children: [
                              // Dezenter Punkt
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green.withOpacity(0.6),
                                ),
                              ),
                              
                              const SizedBox(width: 8),
                              
                              // Parameter Label - dezent
                              Text(
                                provider.getTargetLabel(action.target),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.withOpacity(0.8),
                                  letterSpacing: 0.1,
                                ),
                              ),
                              
                              const SizedBox(width: 6),
                              
                              // Eleganter Trenner
                              Container(
                                width: 8,
                                height: 1,
                                color: Colors.green.withOpacity(0.4),
                              ),
                              
                              const SizedBox(width: 6),
                              
                              // Wert - elegant
                              Flexible(
                                child: Text(
                                  provider.renderValueNode(action.value),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _snow,
                                    letterSpacing: -0.1,
                                  ),
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
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildCleanDirectContent(BuildContext context, ProgressionManagerProvider provider, dynamic rule) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _emberCore.withOpacity(0.15),
            _emberCore.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _emberCore.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _emberCore.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Subtiles SETZE Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _emberCore.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _emberCore.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              'SETZE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _emberCore,
                letterSpacing: 0.3,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Zuweisungen - elegant und subtil
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rule.children.map<Widget>((action) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      // Dezenter Punkt
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _emberCore.withOpacity(0.6),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Parameter Label - dezent
                      Text(
                        provider.getTargetLabel(action.target),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _emberCore.withOpacity(0.8),
                          letterSpacing: 0.1,
                        ),
                      ),
                      
                      const SizedBox(width: 6),
                      
                      // Eleganter Trenner
                      Container(
                        width: 8,
                        height: 1,
                        color: _emberCore.withOpacity(0.4),
                      ),
                      
                      const SizedBox(width: 6),
                      
                      // Wert - elegant
                      Flexible(
                        child: Text(
                          provider.renderValueNode(action.value),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _snow,
                            letterSpacing: -0.1,
                          ),
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
      ),
    );
  }

  Widget _buildSimpleRuleCard(BuildContext context, ProgressionManagerProvider provider, dynamic rule, int index, int totalRules) {
    final bool isCondition = rule.type == 'condition';
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _charcoal.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _steel.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => provider.openRuleEditor(rule),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Rule Number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _emberCore.withOpacity(0.15),
                    border: Border.all(
                      color: _emberCore.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _emberCore,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Rule Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCondition ? 'Wenn-Dann Regel' : 'Direkte Zuweisung',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _snow,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isCondition && rule.conditions.isNotEmpty)
                        Text(
                          _formatConditionText(provider, rule.conditions.first),
                          style: TextStyle(
                            fontSize: 12,
                            color: _mercury,
                            letterSpacing: -0.1,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index > 0)
                      _buildQuickActionButton(
                        Icons.keyboard_arrow_up_rounded,
                        () => _handleRuleReorder(provider, rule, index, index - 1),
                      ),
                    if (index < totalRules - 1)
                      _buildQuickActionButton(
                        Icons.keyboard_arrow_down_rounded,
                        () => _handleRuleReorder(provider, rule, index, index + 1),
                      ),
                    _buildQuickActionButton(
                      Icons.delete_outline_rounded,
                      () => _showDeleteRuleDialog(context, provider, rule.id),
                      isDestructive: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 16,
            color: isDestructive ? Colors.red.withOpacity(0.8) : _silver,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard(BuildContext context, ProgressionManagerProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _charcoal.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _steel.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _emberCore.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              // Profile Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _emberCore.withOpacity(0.15),
                  border: Border.all(
                    color: _emberCore.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.settings_rounded,
                  color: _emberCore,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Profile Name & Edit Button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.profile.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: _snow,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Progressionsprofil',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _mercury,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Edit Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => provider.openProfileEditor(widget.profile),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _emberCore.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _emberCore.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      color: _emberCore,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Description
          if (widget.profile.description.isNotEmpty) ...[
            Text(
              widget.profile.description,
              style: TextStyle(
                fontSize: 14,
                color: _silver,
                height: 1.4,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Configuration Values in Grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _graphite.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _steel.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _buildModernConfigValue(
                  'Wiederholungen',
                  '${_formatInteger(widget.profile.config['targetRepsMin'])} - ${_formatInteger(widget.profile.config['targetRepsMax'])}',
                  Icons.repeat_rounded,
                ),
                _buildVerticalDivider(),
                _buildModernConfigValue(
                  'RIR-Bereich',
                  '${_formatInteger(widget.profile.config['targetRIRMin'])} - ${_formatInteger(widget.profile.config['targetRIRMax'])}',
                  Icons.trending_down_rounded,
                ),
                _buildVerticalDivider(),
                _buildModernConfigValue(
                  'Steigerung',
                  '${_formatNumber(widget.profile.config['increment'])} kg',
                  Icons.trending_up_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernConfigValue(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: _emberCore,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _mercury,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _snow,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 60,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _steel.withOpacity(0.0),
            _steel.withOpacity(0.3),
            _steel.withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesSection(BuildContext context, ProgressionManagerProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(
              Icons.rule_rounded,
              color: _emberCore,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Progressionsregeln',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _snow,
                letterSpacing: -0.4,
              ),
            ),
            const Spacer(),
            // Add Rule Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => provider.openRuleEditor(null),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _emberCore.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _emberCore.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: _emberCore,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Regel',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _emberCore,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Rules Content
        _buildModernRulesList(context, provider),
      ],
    );
  }

  Widget _buildModernRulesList(BuildContext context, ProgressionManagerProvider provider) {
    // Editor-Tab: Verwende IMMER widget.profile (das übergebene Profil)  
    final profil = widget.profile;
    
    if (profil == null) {
      return _buildModernEmptyState(context, provider);
    }

    if (profil.rules.isEmpty) {
      return _buildModernEmptyState(context, provider);
    }

    return Column(
      children: [
        // Info Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _graphite.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _steel.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: _emberCore,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Regeln werden von oben nach unten ausgewertet. Die erste zutreffende Regel wird angewendet.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _silver,
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Rules List
        ...profil.rules.asMap().entries.map((entry) {
          final index = entry.key;
          final rule = entry.value;
          final isLastRule = index == profil.rules.length - 1;
          
          return Column(
            children: [
              _buildModernRuleCard(context, provider, rule, index, profil.rules.length),
              if (!isLastRule) _buildModernRuleConnection(),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildModernEmptyState(BuildContext context, ProgressionManagerProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _charcoal.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _steel.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _emberCore.withOpacity(0.1),
              border: Border.all(
                color: _emberCore.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.rule_rounded,
              color: _emberCore,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Keine Regeln definiert',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _snow,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Erstelle Regeln, um festzulegen, wie sich deine Trainingsparameter automatisch entwickeln sollen.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _mercury,
              height: 1.4,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 24),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => provider.openRuleEditor(null),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _emberCore.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _emberCore.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: _emberCore,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Erste Regel erstellen',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _emberCore,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernRuleConnection() {
    return Container(
      height: 32,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Connection Line
          Container(
            width: 2,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _steel.withOpacity(0.3),
                  _steel.withOpacity(0.6),
                  _steel.withOpacity(0.3),
                ],
              ),
            ),
          ),
          
          // "Sonst" Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _charcoal,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _steel.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              'sonst',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _mercury,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernRuleCard(BuildContext context, ProgressionManagerProvider provider, dynamic rule, int index, int totalRules) {
    final bool isCondition = rule.type == 'condition';
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _charcoal.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _steel.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _emberCore.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => provider.openRuleEditor(rule),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Rule Number
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _emberCore.withOpacity(0.15),
                        border: Border.all(
                          color: _emberCore.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _emberCore,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Rule Type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCondition ? 'Wenn-Dann Regel' : 'Direkte Zuweisung',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _snow,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            isCondition ? 'Bedingte Ausführung' : 'Sofortige Anwendung',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _mercury,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Actions
                    _buildModernRuleActions(context, provider, rule, index, totalRules),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Rule Content Preview
                _buildRuleContentPreview(context, provider, rule, isCondition),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernRuleActions(BuildContext context, ProgressionManagerProvider provider, dynamic rule, int index, int totalRules) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Move Up
        if (index > 0)
          _buildModernActionButton(
            icon: Icons.keyboard_arrow_up_rounded,
            onTap: () => _handleRuleReorder(provider, rule, index, index - 1),
          ),
        
        // Move Down  
        if (index < totalRules - 1)
          _buildModernActionButton(
            icon: Icons.keyboard_arrow_down_rounded,
            onTap: () => _handleRuleReorder(provider, rule, index, index + 1),
          ),
        
        // Edit
        _buildModernActionButton(
          icon: Icons.edit_outlined,
          onTap: () => provider.openRuleEditor(rule),
        ),
        
        // Delete
        _buildModernActionButton(
          icon: Icons.delete_outline_rounded,
          onTap: () => _showDeleteRuleDialog(context, provider, rule.id),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildModernActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 16,
            color: isDestructive ? Colors.red.withOpacity(0.8) : _silver,
          ),
        ),
      ),
    );
  }

  Widget _buildRuleContentPreview(BuildContext context, ProgressionManagerProvider provider, dynamic rule, bool isCondition) {
    if (isCondition && rule.conditions.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _graphite.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _steel.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wenn: ${_formatConditionText(provider, rule.conditions.first)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _silver,
                letterSpacing: -0.1,
              ),
            ),
            if (rule.conditions.length > 1)
              Text(
                '+ ${rule.conditions.length - 1} weitere Bedingung${rule.conditions.length > 2 ? 'en' : ''}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _mercury,
                  letterSpacing: -0.1,
                ),
              ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
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
              color: _mercury,
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
                    color: _snow,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: unit.isNotEmpty ? ' $unit' : '',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _silver,
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
    // Editor-Tab: Verwende IMMER widget.profile (das übergebene Profil)
    final profil = widget.profile;

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

              // Container für alle Regeln mit Padding
              Container(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
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
                ),
                child: Column(
                  children: List.generate(profil.rules.length, (i) {
                    final rule = profil.rules[i];
                    final isLastRule = i == profil.rules.length - 1;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Regelkarte mit Rahmen
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

  // Verbindungselement zwischen den Regelkarten
  Widget _buildRuleConnection() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vertikale Verbindungslinie - jetzt breiter und sichtbarer
          Center(
            child: Container(
              width: 2,
              height: double.infinity,
              color: _steel.withOpacity(0.3),
            ),
          ),

          // "Sonst" Indikator als subtiler Pill-Button auf der Linie
          Positioned(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                'sonst',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                  letterSpacing: -0.2,
                ),
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
        color: _charcoal.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _steel.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _emberCore.withOpacity(0.05),
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
            color: _mercury,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Regeln definiert',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: -0.3,
              color: _snow,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Definiere Regeln, um festzulegen, wie sich deine Trainingsparameter entwickeln sollen.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _mercury,
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
              foregroundColor: _silver,
              backgroundColor: _graphite.withOpacity(0.5),
              side: BorderSide(color: _steel.withOpacity(0.4)),
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
      margin: const EdgeInsets.fromLTRB(1, 4, 1, 4),
      decoration: BoxDecoration(
        color: _charcoal.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _steel.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _emberCore.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => provider.openRuleEditor(rule),
          borderRadius: BorderRadius.circular(8),
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
                            color: _silver,
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
                        color: _snow,
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
                          color: _steel.withOpacity(0.2),
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
                          color: _steel.withOpacity(0.2),
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
                                      // Ersetzt "Wiederholungen" mit "Wdh" wenn nötig
                                      _getCustomTargetLabel(
                                          provider, action.target),
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
                                    // Ersetzt "Wiederholungen" mit "Wdh" wenn nötig
                                    _getCustomTargetLabel(
                                        provider, action.target),
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

  // Hilfsmethode, um "Wiederholungen" durch "Wdh" zu ersetzen
  String _getCustomTargetLabel(
      ProgressionManagerProvider provider, String target) {
    String originalLabel = provider.getTargetLabel(target);
    return originalLabel == 'Wiederholungen' ? 'Wdh' : originalLabel;
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
    // Editor-Tab: Verwende IMMER widget.profile (das übergebene Profil)
    final currentProfile = widget.profile;
    if (currentProfile == null || currentProfile.rules.isEmpty) return;
    
    provider.handleDragStart(rule.id);

    if (oldIndex < newIndex) {
      // Nach unten verschieben
      final targetRule = currentProfile.rules[newIndex];
      await provider.handleDrop(targetRule.id);
    } else {
      // Nach oben verschieben
      final targetRule = currentProfile.rules[newIndex];
      await provider.handleDrop(targetRule.id);
    }
  }

  // Verbesserte Methode für den Löschdialog - jetzt mit Bottom Sheet und Blur-Effekt
  Future<void> _showDeleteRuleDialog(BuildContext context,
      ProgressionManagerProvider provider, String ruleId) async {
    // Haptisches Feedback für bessere Interaktion
    HapticFeedback.mediumImpact();

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_charcoal, _graphite],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border.all(
              color: _steel.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Regel löschen',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: _snow,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Möchtest du diese Regel wirklich löschen?',
                  style: TextStyle(
                    fontSize: 15,
                    color: _mercury,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Löschen-Button (jetzt links)
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          provider.deleteRule(ruleId);
                          Navigator.of(context).pop(true);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Löschen',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Abbrechen-Button (jetzt rechts)
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          backgroundColor: _steel.withOpacity(0.2),
                          foregroundColor: _snow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Abbrechen',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Das Ergebnis wird direkt vom Button-Handler gesetzt,
    // daher brauchen wir hier keine weitere Prüfung
  }

  // Clean color system matching training screen
  static const Color _midnight = Color(0xFF000000);
  static const Color _charcoal = Color(0xFF1C1C1E);
  static const Color _graphite = Color(0xFF2C2C2E);
  static const Color _steel = Color(0xFF48484A);
  static const Color _mercury = Color(0xFF8E8E93);
  static const Color _silver = Color(0xFFAEAEB2);
  static const Color _snow = Color(0xFFFFFFFF);
  static const Color _emberCore = Color(0xFFFF4500);

  Widget _buildDemoTab(
      BuildContext context, ProgressionManagerProvider provider) {
    // Nur die ersten 3 Sätze berücksichtigen
    final displayedSets = provider.saetze.take(3).toList();

    final bool allSetsCompleted =
        displayedSets.every((satz) => satz.abgeschlossen);
    final bool hasMoreSets = displayedSets.any((satz) => !satz.abgeschlossen);
    final bool hasCompletedSets = _hasCompletedSets(provider);
    final bool hasRecommendation =
        provider.sollEmpfehlungAnzeigen(provider.aktiverSatz);

    // Angepasste Logik: Ein Training gilt als abgeschlossen, wenn alle angezeigten Sätze abgeschlossen sind
    final bool isTrainingCompleted = allSetsCompleted;

    return Scaffold(
      backgroundColor: _midnight,
      body: Column(
        children: [
          // Action Bar - Dark theme style matching training session
          if (!isTrainingCompleted)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: _charcoal.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _steel.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Progress Button - jetzt über volle Breite
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
                          borderRadius: BorderRadius.circular(16),
                          child: Opacity(
                            opacity: (!hasRecommendation || allSetsCompleted)
                                ? 0.5
                                : 1.0,
                            child: Container(
                              height: 44,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bolt,
                                    size: 20,
                                    color: _emberCore,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Progress',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _snow,
                                      letterSpacing: -0.3,
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
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sätze-Karten - nur die ersten 3 anzeigen
                  ...displayedSets.asMap().entries.map((entry) {
                    final index = entry.key;
                    final satz = entry.value;
                    
                    // Assign keys to each card
                    GlobalKey? cardKey;
                    if (index == 0) cardKey = _setCard1Key;
                    else if (index == 1) cardKey = _setCard2Key;
                    else if (index == 2) cardKey = _setCard3Key;
                    
                    return SetCardWidget(
                      key: cardKey,
                      satz: satz,
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: _midnight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress indicator - nur anzeigen, wenn das Training noch nicht abgeschlossen ist
            if (!isTrainingCompleted)
              LinearProgressIndicator(
                value: displayedSets.isEmpty
                    ? 0.0
                    : displayedSets.where((satz) => satz.abgeschlossen).length /
                        displayedSets.length,
                minHeight: 3,
                backgroundColor: _charcoal,
                color: _emberCore,
              ),

            // Hauptbutton - angepasste Logik
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isTrainingCompleted
                        ? () => provider.trainingZuruecksetzen(
                            resetRecommendations: true)
                        : allSetsCompleted
                            ? null
                            : () {
                                provider.satzAbschliessen();
                                // Nach kurzer Verzögerung zum nächsten Set scrollen
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (mounted) {
                                    _scrollToNextSet();
                                  }
                                });
                              },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _emberCore,
                      foregroundColor: _snow,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isTrainingCompleted
                          ? 'DEMO ZURÜCKSETZEN'
                          : allSetsCompleted
                              ? 'TRAINING ABSCHLIESSEN'
                              : 'SATZ ABSCHLIESSEN',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Stateful Widget für durchgängige Animation
class _FlowArrowsAnimationWidget extends StatefulWidget {
  final Color color;

  const _FlowArrowsAnimationWidget({required this.color});

  @override
  _FlowArrowsAnimationWidgetState createState() => _FlowArrowsAnimationWidgetState();
}

class _FlowArrowsAnimationWidgetState extends State<_FlowArrowsAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4000), // 4 Sekunden für elegante Bewegung
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear, // Gleichmäßige Bewegung
    ));
    
    // Animation in Endlosschleife starten
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(10, 32),
          painter: FlowArrowsPainter(
            animationValue: _animation.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

// Custom Painter for animated flow arrows
class FlowArrowsPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  FlowArrowsPainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw 2 animated arrows mit gleichmäßigem Abstand für regelmäßigen Rhythmus
    for (int i = 0; i < 2; i++) {
      final progress = (animationValue + (i * 0.5)) % 1.0; // Gleichmäßiger 50% Abstand zwischen den Pfeilen
      final y = size.height * progress;
      
      // Only draw if arrow is in visible area
      if (y > 4 && y < size.height - 4) {
        // Sanftere, längere Fade-Übergänge für elegantere Optik
        double opacity;
        if (progress < 0.15) {
          opacity = progress / 0.15; // Längeres Fade in
        } else if (progress > 0.85) {
          opacity = (1.0 - progress) / 0.15; // Längeres Fade out
        } else {
          opacity = 1.0; // Full opacity in middle
        }
        
        // Kleinere, subtilere Pfeile
        final arrowPaint = Paint()
          ..color = color.withOpacity(opacity * 0.6) // Subtilere Farbe
          ..style = PaintingStyle.fill;
        
        final arrowPath = Path();
        arrowPath.moveTo(size.width / 2, y + 2); // Kleinerer Pfeil - Bottom point
        arrowPath.lineTo(size.width / 2 - 2, y - 1.5); // Left point
        arrowPath.lineTo(size.width / 2 + 2, y - 1.5); // Right point
        arrowPath.close();
        
        canvas.drawPath(arrowPath, arrowPaint);
        
        // Subtilere, kürzere Spur hinter dem Pfeil
        final trailPaint = Paint()
          ..color = color.withOpacity(opacity * 0.2) // Noch subtiler
          ..strokeWidth = 1.5 // Dünner
          ..strokeCap = StrokeCap.round;
        
        canvas.drawLine(
          Offset(size.width / 2, y - 3),
          Offset(size.width / 2, y - 6), // Kürzere Spur
          trailPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant FlowArrowsPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// Helper functions for number formatting
String _formatInteger(dynamic value) {
  if (value == null) return '0';
  if (value is int) return value.toString();
  if (value is double) return value.toInt().toString();
  return value.toString();
}

String _formatNumber(dynamic value) {
  if (value == null) return '0';
  if (value is int) return value.toString();
  if (value is double) {
    // If it's a whole number, show without decimals
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    // Otherwise show with necessary decimals
    return value.toString();
  }
  return value.toString();
}

