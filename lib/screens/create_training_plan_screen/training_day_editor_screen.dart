// lib/screens/create_training_plan_screen/training_day_editor_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';
import '../../providers/training_plans_screen/training_plans_screen_provider.dart';
import '../../providers/shared/navigation_provider.dart';
import '../../widgets/create_training_plan_screen/training_day_tab_widget.dart';
import '../../models/training_plan_screen/training_plan_model.dart';
import '../../models/training_plan_screen/training_day_model.dart';
import '../../screens/main_screen.dart';
import 'create_plan_wizard_screen.dart';
import '../../utils/smooth_page_route.dart';

class TrainingDayEditorScreen extends StatefulWidget {
  const TrainingDayEditorScreen({Key? key}) : super(key: key);

  @override
  State<TrainingDayEditorScreen> createState() =>
      _TrainingDayEditorScreenState();
}

class _TrainingDayEditorScreenState extends State<TrainingDayEditorScreen>
    with TickerProviderStateMixin {
  bool _isSaving = false;
  bool _showTabOptions = false;
  late TabController _tabController;

  // Neue Zustandsvariablen für Inline-Bearbeitung
  int? _editingIndex;
  final TextEditingController _renameController = TextEditingController();
  final FocusNode _renameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Den FocusNode so konfigurieren, dass er beim Verlieren des Fokus
    // die Bearbeitung beendet
    _renameFocusNode.addListener(() {
      if (!_renameFocusNode.hasFocus && _editingIndex != null) {
        _finishRenaming();
      }
    });

    // TabController wird in didChangeDependencies initialisiert
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // TabController initialisieren
    final provider = Provider.of<CreateTrainingPlanProvider>(context);
    if (provider.draftPlan != null) {
      _tabController = TabController(
        length: provider.draftPlan!.days.length,
        vsync: this,
        initialIndex:
            provider.selectedDayIndex < provider.draftPlan!.days.length
                ? provider.selectedDayIndex
                : provider.draftPlan!.days.length - 1,
      );

      // TabController-Listener für Updates der selectedDayIndex
      _tabController.addListener(() {
        // Sofortige Synchronisation sowohl bei Swipe als auch bei Tap
        if (_tabController.index != provider.selectedDayIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              provider.setSelectedDayIndex(_tabController.index);
            }
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(TrainingDayEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // TabController aktualisieren, wenn sich die Anzahl der Tabs ändert
    final provider =
        Provider.of<CreateTrainingPlanProvider>(context, listen: false);
    if (provider.draftPlan != null &&
        _tabController.length != provider.draftPlan!.days.length) {
      // Alten Controller korrekt entsorgen
      _tabController.dispose();

      // Neuen Controller erstellen
      _tabController = TabController(
        length: provider.draftPlan!.days.length,
        vsync: this,
        initialIndex:
            provider.selectedDayIndex < provider.draftPlan!.days.length
                ? provider.selectedDayIndex
                : provider.draftPlan!.days.length - 1,
      );
    }
  }

  @override
  void dispose() {
    _renameController.dispose();
    _renameFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Methode zum Beenden der Bearbeitung und Anwenden der Änderungen
  void _finishRenaming() {
    if (_editingIndex != null) {
      final newName = _renameController.text.trim();
      if (newName.isNotEmpty) {
        final createProvider =
            Provider.of<CreateTrainingPlanProvider>(context, listen: false);

        // Namen aktualisieren
        createProvider.setDayName(_editingIndex!, newName);

        // Haptisches Feedback
        HapticFeedback.mediumImpact();
      }

      // Bearbeitungsmodus beenden
      setState(() {
        _editingIndex = null;
      });
    }
  }

  // Methode zum Anzeigen eines Bestätigungsdialogs zum Hinzufügen eines Trainingstages
  void _showAddTrainingDayConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1C1C1E), // Charcoal
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFF48484A).withOpacity(0.3), // Steel
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trainingstag hinzufügen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFFFFF), // Snow
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Möchtest du einen neuen Trainingstag hinzufügen?',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFFAEAEB2), // Silver
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Abbrechen',
                      style: TextStyle(
                        color: Color(0xFF8E8E93), // Mercury
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF4500), // Orange
                          Color(0xFFFF6B3D), // Orange glow
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4500).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _addTrainingDayWithoutNameDialog();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Text(
                            'Hinzufügen',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFFFFF), // Snow
                            ),
                          ),
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
    );
  }

  // Methode zum Hinzufügen eines Trainingstages mit Standardnamen
  void _addTrainingDayWithoutNameDialog() {
    final createProvider =
        Provider.of<CreateTrainingPlanProvider>(context, listen: false);

    // Aktuellen Index berechnen, um einen Standard-Namen zu generieren
    final newDayNumber = (createProvider.draftPlan?.days.length ?? 0) + 1;
    final defaultName = 'Tag $newDayNumber';

    // Tag mit Standard-Namen hinzufügen
    createProvider.addTrainingDay(defaultName);

    // Haptisches Feedback
    HapticFeedback.mediumImpact();

    // Sicherstellen, dass die UI aktualisiert wird
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final createProvider = Provider.of<CreateTrainingPlanProvider>(context);
    final plan = createProvider.draftPlan;
    final isEditMode = createProvider.isEditMode;

    // Fallback wenn kein Plan vorhanden ist
    if (plan == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // TabController aktualisieren wenn sich die Anzahl der Tage geändert hat
    if (_tabController.length != plan.days.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Alten Controller entsorgen
          _tabController.dispose();
          
          // Neuen Controller erstellen
          _tabController = TabController(
            length: plan.days.length,
            vsync: this,
            initialIndex: createProvider.selectedDayIndex < plan.days.length
                ? createProvider.selectedDayIndex
                : plan.days.length - 1,
          );

          // TabController-Listener für Updates der selectedDayIndex
          _tabController.addListener(() {
            if (_tabController.index != createProvider.selectedDayIndex) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  createProvider.setSelectedDayIndex(_tabController.index);
                }
              });
            }
          });

          // UI neu aufbauen
          setState(() {});
        }
      });
    }

    // TabController aktualisieren wenn selectedDayIndex geändert wurde
    if (_tabController.index != createProvider.selectedDayIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tabController.index != createProvider.selectedDayIndex) {
          _tabController.animateTo(createProvider.selectedDayIndex);
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Midnight background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF000000), // Midnight
                const Color(0xFF000000).withOpacity(0.95),
                const Color(0xFF000000).withOpacity(0.8),
                const Color(0xFF000000).withOpacity(0.4),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 0.6, 0.85, 1.0],
            ),
          ),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withOpacity(0.8), // Charcoal
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF48484A).withOpacity(0.5), // Steel
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showExitConfirmation(context),
              borderRadius: BorderRadius.circular(12),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Color(0xFFFFFFFF), // Snow
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        title: Flexible(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _editPlanBasics(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1C1C1E), // Charcoal
                      Color(0xFF000000), // Midnight
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF4500).withOpacity(0.3), // Orange
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4500).withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Plan name with edit icon - compact single row
                    Row(
                      children: [
                        Expanded(
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFFF4500), Color(0xFFFF6B3D)], // Orange gradient
                            ).createShader(bounds),
                            child: Text(
                              _truncateText(plan.name.toUpperCase(), 25),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFFFFFF), // Snow
                                letterSpacing: 1.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.edit_outlined,
                          size: 12,
                          color: const Color(0xFFFF4500).withOpacity(0.8),
                        ),
                      ],
                    ),
                    
                    // Compact info line - prioritize most important info
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        // Always show training days
                        Icon(
                          Icons.calendar_today,
                          size: 8,
                          color: const Color(0xFF65656F), // Comet
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${plan.days.length} TAGE',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF65656F), // Comet
                            letterSpacing: 0.3,
                          ),
                        ),
                        
                        // Show weeks only if periodized
                        if (plan.isPeriodized && plan.numberOfWeeks > 1) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 2,
                            height: 2,
                            decoration: BoxDecoration(
                              color: const Color(0xFF65656F),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${plan.numberOfWeeks}W',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF65656F), // Comet
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                        
                        // Show gym only if there's space (short gym names)
                        if (plan.gym != null && plan.gym!.isNotEmpty && plan.gym!.length <= 12) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 2,
                            height: 2,
                            decoration: BoxDecoration(
                              color: const Color(0xFF65656F),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.fitness_center,
                            size: 8,
                            color: const Color(0xFF65656F), // Comet
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              _truncateText(plan.gym!.toUpperCase(), 10),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF65656F), // Comet
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF000000).withOpacity(0.4),
                  const Color(0xFF1C1C1E).withOpacity(0.8),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF48484A).withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: _buildDraggableTabBar(plan),
          ),
        ),
        actions: [
          // Trainingstag hinzufügen Button
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E).withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF48484A).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showAddTrainingDayConfirmation(context),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.add_rounded,
                    color: Color(0xFFFF4500), // Orange
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          // Status-Indikator für den Speichervorgang
          _isSaving
              ? Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 20,
                  height: 20,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFF4500), // Orange
                  ),
                )
              : Container(
                  margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF4500), // Orange
                        Color(0xFFFF6B3D), // Orange glow
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4500).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _saveTrainingPlan(context),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'SPEICHERN',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF), // Snow
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
      body: GestureDetector(
        // Beim Tippen auf den Hintergrund die Bearbeitung beenden
        onTap: () {
          if (_editingIndex != null) {
            _finishRenaming();
          }
        },
        child: Stack(
          children: [
            // TabBarView für die Trainingstage
            TabBarView(
              controller: _tabController,
              physics: _showTabOptions || _editingIndex != null
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(),
              children: List.generate(
                plan.days.length,
                (index) => Container(
                  margin: const EdgeInsets.only(top: 150), // Account for app bar + tab bar
                  child: TrainingDayTabWidget(dayIndex: index),
                ),
              ),
            ),

            // Semi-transparentes Overlay, wenn Optionen angezeigt werden
            if (_showTabOptions)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showTabOptions = false;
                  });
                },
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    color: const Color(0xFF000000).withOpacity(0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Benutzerdefinierte, draggable TabBar-Implementierung
  Widget _buildDraggableTabBar(TrainingPlanModel plan) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        // Anpassen des Aussehens des gezogenen Elements
        proxyDecorator: (child, index, animation) {
          return Material(
            elevation: 8.0,
            color: const Color(0xFF1C1C1E), // Charcoal
            shadowColor: const Color(0xFFFF4500).withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFF4500).withOpacity(0.6),
                  width: 2,
                ),
              ),
              transform: Matrix4.identity()..scale(1.05),
              child: child,
            ),
          );
        },
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        onReorder: (oldIndex, newIndex) {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          HapticFeedback.mediumImpact();
          Provider.of<CreateTrainingPlanProvider>(context, listen: false)
              .reorderTrainingDays(oldIndex, newIndex);
        },
        itemCount: plan.days.length,
        itemBuilder: (context, index) {
          final day = plan.days[index];
          final isSelected = _tabController.index == index;

          // Wenn dieser Tab aktuell bearbeitet wird, zeige ein TextField
          if (_editingIndex == index) {
            return Container(
              key: ValueKey('tab_edit_${day.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E), // Charcoal
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF4500).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _renameController,
                focusNode: _renameFocusNode,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  isDense: true,
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFFFFF), // Snow
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _finishRenaming(),
              ),
            );
          }

          // Ansonsten den normalen, ziehbaren Tab anzeigen
          return GestureDetector(
            key: ValueKey('tab_${day.id}'),
            onTap: () {
              if (_editingIndex != null) {
                _finishRenaming();
              }
              // Sofortige Synchronisation
              _tabController.animateTo(index);
              Provider.of<CreateTrainingPlanProvider>(context, listen: false)
                  .setSelectedDayIndex(index);
            },
            onDoubleTap: () {
              setState(() {
                _editingIndex = index;
                _renameController.text = day.name;
              });
              Future.delayed(const Duration(milliseconds: 50),
                  () => _renameFocusNode.requestFocus());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [
                          Color(0xFFFF4500), // Orange
                          Color(0xFFFF6B3D), // Orange glow
                        ],
                      )
                    : null,
                color: isSelected
                    ? null
                    : const Color(0xFF1C1C1E).withOpacity(0.6), // Charcoal
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF4500).withOpacity(0.8)
                      : const Color(0xFF48484A).withOpacity(0.3), // Steel
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF4500).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag-Handle als visueller Hinweis
                  Icon(
                    Icons.drag_indicator,
                    size: 16,
                    color: isSelected
                        ? const Color(0xFFFFFFFF) // Snow
                        : const Color(0xFF8E8E93), // Mercury
                  ),
                  const SizedBox(width: 8),

                  // Tab-Titel
                  Text(
                    day.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFFFFFFFF) // Snow
                          : const Color(0xFFAEAEB2), // Silver
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // PopupMenuButton für Optionen
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.more_vert,
                      size: 16,
                      color: isSelected
                          ? const Color(0xFFFFFFFF) // Snow
                          : const Color(0xFF8E8E93), // Mercury
                    ),
                    color: const Color(0xFF1C1C1E), // Charcoal
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'rename') {
                        setState(() {
                          _editingIndex = index;
                          _renameController.text = day.name;
                        });
                        Future.delayed(const Duration(milliseconds: 50),
                            () => _renameFocusNode.requestFocus());
                      } else if (value == 'delete') {
                        _confirmDeleteDay(context, index);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'rename',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: Color(0xFFAEAEB2), // Silver
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Umbenennen',
                              style: TextStyle(
                                color: Color(0xFFFFFFFF), // Snow
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (plan.days.length > 1)
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Color(0xFFFF453A), // Error red
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Löschen',
                                style: TextStyle(
                                  color: Color(0xFFFF453A), // Error red
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Zeigt das Optionsmenü für einen Trainingstag
  void _showDayOptionsMenu(BuildContext context, int dayIndex) {
    final createProvider =
        Provider.of<CreateTrainingPlanProvider>(context, listen: false);
    final plan = createProvider.draftPlan;
    if (plan == null || dayIndex >= (plan.days.length)) return;

    final dayName = plan.days[dayIndex].name;
    final canDelete = plan.days.length > 1;

    setState(() {
      _showTabOptions = true;
    });

    // Statt die genaue Position zu berechnen, zeigen wir das Menü relativ zum Cursor an
    // Das Offset ist relativ zum gesamten Bildschirm
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          100, 80, 0, 0), // Positioniert das Menü unterhalb des Tabs
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 8,
      items: [
        // Option zum Umbenennen
        PopupMenuItem<String>(
          value: 'rename',
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 20,
                color: Colors.grey[800],
              ),
              const SizedBox(width: 12),
              const Text('Umbenennen'),
            ],
          ),
        ),
        // Option zum Löschen (nur wenn mehr als ein Tag vorhanden)
        if (canDelete)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.red,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Löschen',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
      ],
    ).then((value) {
      setState(() {
        _showTabOptions = false;
      });

      // Aktion basierend auf der Auswahl
      if (value == 'rename') {
        // Bearbeitungsmodus starten
        setState(() {
          _editingIndex = dayIndex;
          _renameController.text = plan.days[dayIndex].name;
        });

        // Kurze Verzögerung, um sicherzustellen, dass das Textfeld erstellt wurde
        Future.delayed(const Duration(milliseconds: 50),
            () => _renameFocusNode.requestFocus());
      } else if (value == 'delete') {
        _confirmDeleteDay(context, dayIndex);
      }
    });
  }

  // Bestätigungsdialog zum Löschen eines Trainingstags
  void _confirmDeleteDay(BuildContext context, int dayIndex) {
    final createProvider =
        Provider.of<CreateTrainingPlanProvider>(context, listen: false);
    final dayName =
        createProvider.draftPlan?.days[dayIndex].name ?? 'Trainingstag';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1C1C1E), // Charcoal
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFF48484A).withOpacity(0.3), // Steel
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trainingstag löschen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFFFFF), // Snow
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Möchtest du den Trainingstag "$dayName" wirklich löschen? Alle Übungen dieses Tages werden ebenfalls gelöscht.',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFFAEAEB2), // Silver
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Abbrechen',
                      style: TextStyle(
                        color: Color(0xFF8E8E93), // Mercury
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF453A), // Error red
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF453A).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          createProvider.removeTrainingDay(dayIndex);
                          HapticFeedback.mediumImpact();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Text(
                            'Löschen',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFFFFF), // Snow
                            ),
                          ),
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
    );
  }

  // Bestätigungsdialog zum Verlassen des Screens
  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1C1C1E), // Charcoal
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFF48484A).withOpacity(0.3), // Steel
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bearbeitung abbrechen?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFFFFF), // Snow
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Möchtest du die Bearbeitung wirklich abbrechen? Alle nicht gespeicherten Änderungen gehen verloren.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFFAEAEB2), // Silver
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Weiter bearbeiten',
                      style: TextStyle(
                        color: Color(0xFF8E8E93), // Mercury
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF453A), // Error red
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF453A).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context); // Dialog schließen
                          Navigator.pop(context); // Screen verlassen
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Text(
                            'Abbrechen',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFFFFF), // Snow
                            ),
                          ),
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
    );
  }

  void _saveTrainingPlan(BuildContext context) {
    final createProvider =
        Provider.of<CreateTrainingPlanProvider>(context, listen: false);
    final plan = createProvider.draftPlan;

    if (plan == null) return;

    // Prüfen, ob der Plan bereits aktiviert ist
    if (plan.isActive) {
      // Wenn bereits aktiv, direkt speichern ohne nachzufragen
      _processSave(context, true);
    } else {
      // Wenn nicht aktiv, Dialog anzeigen
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: const Color(0xFF1C1C1E), // Charcoal
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: const Color(0xFF48484A).withOpacity(0.3), // Steel
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trainingsplan speichern',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF), // Snow
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Möchtest du den Trainingsplan aktivieren?',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFFAEAEB2), // Silver
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _processSave(context, false);
                      },
                      child: const Text(
                        'Nur speichern',
                        style: TextStyle(
                          color: Color(0xFF8E8E93), // Mercury
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF4500), // Orange
                            Color(0xFFFF6B3D), // Orange glow
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4500).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _processSave(context, true);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Text(
                              'Aktivieren',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFFFFFF), // Snow
                              ),
                            ),
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
      );
    }
  }

  Future<void> _processSave(BuildContext context, bool activate) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    // Context-abhängige Objekte VOR async-Aufrufen holen
    final createProvider =
        Provider.of<CreateTrainingPlanProvider>(context, listen: false);
    final plansProvider =
        Provider.of<TrainingPlansProvider>(context, listen: false);
    final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final planToSave = createProvider.draftPlan!;

      // Speichere Plan
      await plansProvider.saveTrainingPlan(planToSave, activate);

      // Gelöschte Übungen und Trainingstage bereinigen
      await createProvider.cleanupDeletedItems();

      // Visuelles Feedback
      HapticFeedback.mediumImpact();

      // Navigation
      if (mounted) {
        final targetIndex = activate ? 0 : 2;
        
        // Index sofort setzen
        navigationProvider.setCurrentIndex(targetIndex);
        
        // Navigation mit kurzer Verzögerung
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MainScreen()),
              (route) => false,
            );
          }
        });
      }
    } catch (e) {
      print('Fehler beim Speichern: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        // Fehler-Feedback mit vorher geholtem ScaffoldMessenger
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Fehler beim Speichern: $e',
              style: const TextStyle(
                color: Color(0xFFFFFFFF), // Snow
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFFFF453A), // Error red
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  // Methode zum intelligenten Kürzen von Text
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  // Methode zum Bearbeiten der Grundinformationen
  void _editPlanBasics() {
    final createProvider = Provider.of<CreateTrainingPlanProvider>(context, listen: false);
    
    HapticFeedback.lightImpact();
    
    // Sicherstellen, dass alle Provider-Eigenschaften mit aktuellen Plan-Werten synchronisiert sind
    if (createProvider.draftPlan != null) {
      createProvider.loadExistingPlanForEditing(createProvider.draftPlan!);
    }
    
    // Navigate to wizard with current plan data now properly loaded in provider
    Navigator.of(context).push(
      SmoothPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: createProvider,
          child: const CreatePlanWizardScreen(isEditingExisting: true),
        ),
      ),
    );
  }
}
