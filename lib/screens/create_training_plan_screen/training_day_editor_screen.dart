// lib/screens/create_training_plan_screen/training_day_editor_screen.dart
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

class TrainingDayEditorScreen extends StatefulWidget {
  const TrainingDayEditorScreen({Key? key}) : super(key: key);

  @override
  State<TrainingDayEditorScreen> createState() =>
      _TrainingDayEditorScreenState();
}

class _TrainingDayEditorScreenState extends State<TrainingDayEditorScreen>
    with TickerProviderStateMixin {
  bool _isSaving = false;
  late TabController _tabController;

  // Performance-Optimierung
  final ScrollController _tabScrollController = ScrollController();
  final Map<int, Widget> _tabContentCache = {};

  // Vereinfachte State-Variablen (weniger Rebuilds)
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();

    // Initialisierung mit Standardwert
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final provider = Provider.of<CreateTrainingPlanProvider>(context);
    if (provider.draftPlan != null) {
      final int tabCount = provider.draftPlan!.days.length;
      final int initialIndex = provider.selectedDayIndex < tabCount
          ? provider.selectedDayIndex
          : tabCount - 1;

      // Nur aktualisieren, wenn nötig
      if (_tabController.length != tabCount) {
        // Vorherigen Controller sauber entsorgen
        if (_tabController.hasListeners) {
          _tabController.removeListener(_handleTabChange);
        }
        _tabController.dispose();

        // Neuen Controller erstellen
        _tabController = TabController(
          length: tabCount,
          vsync: this,
          initialIndex: initialIndex,
        );

        // Listener hinzufügen
        _tabController.addListener(_handleTabChange);

        // Cache leeren nur bei Strukturänderungen
        _tabContentCache.clear();
      } else if (_tabController.index != initialIndex) {
        _tabController.animateTo(initialIndex);
      }
    }
  }

  // Optimierte Tab-Änderung ohne setState
  void _handleTabChange() {
    if (!_tabController.indexIsChanging && mounted) {
      final provider =
          Provider.of<CreateTrainingPlanProvider>(context, listen: false);
      if (provider.selectedDayIndex != _tabController.index) {
        provider.setSelectedDayIndex(_tabController.index);
      }
    }
  }

  @override
  void dispose() {
    if (_tabController.hasListeners) {
      _tabController.removeListener(_handleTabChange);
    }
    _tabController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  // Trainingstag hinzufügen (optimiert)
  void _addTrainingDay() {
    final createProvider =
        Provider.of<CreateTrainingPlanProvider>(context, listen: false);

    final newDayNumber = (createProvider.draftPlan?.days.length ?? 0) + 1;
    final defaultName = 'Tag $newDayNumber';

    createProvider.addTrainingDay(defaultName);
    HapticFeedback.mediumImpact();

    // Nur bei Strukturänderungen Cache leeren
    _tabContentCache.clear();
  }

  // Vereinfachte Umordnung ohne komplexe Drag-Logik
  void _reorderTrainingDays(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final createProvider =
        Provider.of<CreateTrainingPlanProvider>(context, listen: false);
    createProvider.reorderTrainingDays(oldIndex, newIndex);

    _tabContentCache.clear();
    HapticFeedback.mediumImpact();
  }

  // Plan speichern
  Future<void> _processSave(bool activate) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final createProvider =
          Provider.of<CreateTrainingPlanProvider>(context, listen: false);
      final plansProvider =
          Provider.of<TrainingPlansProvider>(context, listen: false);
      final navigationProvider =
          Provider.of<NavigationProvider>(context, listen: false);

      final planToSave = createProvider.draftPlan!;
      final wasAlreadyActive = planToSave.isActive;

      navigationProvider.setCurrentIndex(wasAlreadyActive || activate ? 0 : 2);

      await plansProvider.saveTrainingPlan(planToSave, activate);
      await createProvider.cleanupDeletedItems();
      createProvider.reset();

      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Fehler beim Speichern: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final createProvider = Provider.of<CreateTrainingPlanProvider>(context);
    final plan = createProvider.draftPlan;
    final isEditMode = createProvider.isEditMode;

    if (plan == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Kein Trainingsplan verfügbar"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Zurück"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(plan, isEditMode),
      body: Column(
        children: [
          // Vereinfachte, performante TabBar
          _buildOptimizedTabBar(plan),

          // Optimiertes TabBarView mit besserer Performance
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: _isDragging
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              children: List.generate(
                plan.days.length,
                (index) {
                  // Effizienteres Caching
                  return _tabContentCache.putIfAbsent(
                      index, () => TrainingDayTabWidget(dayIndex: index));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Optimierte AppBar
  PreferredSizeWidget _buildAppBar(TrainingPlanModel plan, bool isEditMode) {
    return AppBar(
      title: Text(
        isEditMode ? '${plan.name} bearbeiten' : 'Plan erstellen',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => _showExitConfirmation(context),
        splashRadius: 24,
      ),
      actions: [
        _isSaving
            ? Container(
                margin: const EdgeInsets.only(right: 16),
                width: 20,
                height: 20,
                child: const CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black),
              )
            : TextButton(
                onPressed: () => _saveTrainingPlan(context),
                child: const Text(
                  'Speichern',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
      ],
    );
  }

  // Vereinfachte, performante TabBar
  Widget _buildOptimizedTabBar(TrainingPlanModel plan) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          // Scrollbare Tabs
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                controller: _tabScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: plan.days.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final day = plan.days[index];
                  final isActive = index == _tabController.index;

                  return _buildSimpleTab(day, index, isActive);
                },
              ),
            ),
          ),

          // "+" Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _addTrainingDay,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.withOpacity(0.1),
                  ),
                  child: const Icon(Icons.add, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Vereinfachter Tab ohne komplexe Drag-Logik für bessere Performance
  Widget _buildSimpleTab(TrainingDayModel day, int index, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Provider.of<CreateTrainingPlanProvider>(context, listen: false)
                .setSelectedDayIndex(index);
            _tabController.animateTo(index);
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _showTabContextMenu(context, index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isActive ? Colors.black : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? Colors.transparent
                    : Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                day.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? Colors.white : Colors.grey[800],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Eleganter Dialog zum Umbenennen von Trainingstagen
  void _showRenameDialog(BuildContext context, int index) {
    final createProvider =
        Provider.of<CreateTrainingPlanProvider>(context, listen: false);
    final currentName = createProvider.draftPlan!.days[index].name;
    final TextEditingController controller =
        TextEditingController(text: currentName);
    final FocusNode focusNode = FocusNode();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header mit Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),

              // Titel
              const Text(
                'Trainingstag umbenennen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Beschreibung
              Text(
                'Gib einen neuen Namen für deinen Trainingstag ein',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Textfeld mit elegantem Design
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'z.B. Oberkörper, Push, Beine...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.fitness_center,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      createProvider.setDayName(index, value.trim());
                      Navigator.pop(context);
                      HapticFeedback.mediumImpact();

                      // Erfolgsmeldung
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Trainingstag wurde zu "$value" umbenannt'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  // Abbrechen
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Abbrechen',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Bestätigen
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final newName = controller.text.trim();
                        if (newName.isNotEmpty) {
                          createProvider.setDayName(index, newName);
                          Navigator.pop(context);
                          HapticFeedback.mediumImpact();

                          // Erfolgsmeldung
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Trainingstag wurde zu "$newName" umbenannt'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Umbenennen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
    ).then((_) {
      // FocusNode nach Dialog-Schließung entsorgen
      focusNode.dispose();
      controller.dispose();
    });
  }

  // Tab-Kontextmenü mit optimiertem Design
  void _showTabContextMenu(BuildContext context, int index) {
    final createProvider =
        Provider.of<CreateTrainingPlanProvider>(context, listen: false);
    final day = createProvider.draftPlan!.days[index];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Trainingstag-Info
                Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 24,
                    color: Colors.grey[800],
                  ),
                ),

                Text(
                  day.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "${day.exercises.length} Übung${day.exercises.length != 1 ? 'en' : ''}",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(height: 1),

                // Umbenennen-Option
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text("Umbenennen"),
                  subtitle: const Text("Namen des Trainingstages ändern"),
                  onTap: () {
                    Navigator.pop(context);
                    _showRenameDialog(context, index);
                  },
                ),

                // Löschen-Option (nur wenn mehr als ein Tag)
                if (createProvider.draftPlan!.days.length > 1)
                  ListTile(
                    leading:
                        const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text("Löschen",
                        style: TextStyle(color: Colors.red)),
                    subtitle: const Text("Tag und alle Übungen löschen"),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDeleteDay(context, index);
                    },
                  ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Dialog: Tag löschen
  void _confirmDeleteDay(BuildContext context, int dayIndex) {
    final createProvider =
        Provider.of<CreateTrainingPlanProvider>(context, listen: false);
    final dayName =
        createProvider.draftPlan?.days[dayIndex].name ?? 'Trainingstag';
    final exerciseCount =
        createProvider.draftPlan?.days[dayIndex].exercises.length ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Trainingstag löschen'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Möchtest du den Trainingstag "$dayName" wirklich löschen?',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alle $exerciseCount Übungen dieses Tages werden ebenfalls gelöscht.',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              createProvider.removeTrainingDay(dayIndex);

              _tabContentCache.clear();

              HapticFeedback.mediumImpact();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Trainingstag "$dayName" wurde gelöscht'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Löschen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog: Bearbeitung beenden
  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Bearbeitung abbrechen?'),
          ],
        ),
        content: const Text(
            'Möchtest du die Bearbeitung wirklich abbrechen? Alle nicht gespeicherten Änderungen gehen verloren.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Weiter bearbeiten',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Abbrechen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog: Plan speichern
  void _saveTrainingPlan(BuildContext context) {
    final createProvider =
        Provider.of<CreateTrainingPlanProvider>(context, listen: false);
    final plan = createProvider.draftPlan;

    if (plan == null) return;

    if (plan.isActive) {
      _processSave(true);
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.save, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Trainingsplan speichern'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Möchtest du den Trainingsplan aktivieren?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Als aktiver Plan wird dieser sofort auf dem Startbildschirm angezeigt.',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _processSave(false);
              },
              child: const Text('Nur speichern',
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _processSave(true);
              },
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Aktivieren'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
