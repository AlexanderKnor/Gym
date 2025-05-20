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
        if (!_tabController.indexIsChanging) {
          if (provider.selectedDayIndex != _tabController.index) {
            provider.setSelectedDayIndex(_tabController.index);
          }
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Möchtest du einen neuen Trainingstag hinzufügen?',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
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
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _addTrainingDayWithoutNameDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Hinzufügen',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
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

    // TabController aktualisieren wenn selectedDayIndex geändert wurde
    if (_tabController.index != createProvider.selectedDayIndex) {
      _tabController.animateTo(createProvider.selectedDayIndex);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => _showExitConfirmation(context),
          splashRadius: 24,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            // Benutzerdefinierte, draggable TabBar-Implementierung
            child: _buildDraggableTabBar(plan),
          ),
        ),
        actions: [
          // Trainingstag hinzufügen Button
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 24),
            tooltip: 'Trainingstag hinzufügen',
            onPressed: () => _showAddTrainingDayConfirmation(context),
            splashRadius: 24,
          ),
          // Status-Indikator für den Speichervorgang
          _isSaving
              ? Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 20,
                  height: 20,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : TextButton(
                  onPressed: () => _saveTrainingPlan(context),
                  child: Text(
                    'Speichern',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
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
                (index) => TrainingDayTabWidget(dayIndex: index),
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
                    color: Colors.black.withOpacity(0.1),
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
      height: 48,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        // Anpassen des Aussehens des gezogenen Elements
        proxyDecorator: (child, index, animation) {
          return Material(
            elevation: 4.0,
            color: Colors.white,
            shadowColor: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            // Animation für das Hochheben und Vergrößern während des Ziehens
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.black.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              transformAlignment: Alignment.center,
              transform: Matrix4.identity()..scale(1.05),
              child: child,
            ),
          );
        },
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        onReorder: (oldIndex, newIndex) {
          // Korrektur des newIndex, wie in der Dokumentation empfohlen
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }

          // Haptisches Feedback
          HapticFeedback.mediumImpact();

          // Wirkliche Umordnung im Provider ausführen
          Provider.of<CreateTrainingPlanProvider>(context, listen: false)
              .reorderTrainingDays(oldIndex, newIndex);

          // Zusätzliches setState für den Fall, dass der Provider nicht neu rendert
          setState(() {});
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
              child: TextField(
                controller: _renameController,
                focusNode: _renameFocusNode,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  isDense: true,
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
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
              // Wenn im Bearbeitungsmodus, erst beenden
              if (_editingIndex != null) {
                _finishRenaming();
              }

              Provider.of<CreateTrainingPlanProvider>(context, listen: false)
                  .setSelectedDayIndex(index);
              _tabController.animateTo(index);
            },
            onDoubleTap: () {
              // Bearbeitungsmodus starten
              setState(() {
                _editingIndex = index;
                _renameController.text = day.name;
              });

              // Kurze Verzögerung für den Fokus
              Future.delayed(const Duration(milliseconds: 50),
                  () => _renameFocusNode.requestFocus());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.black.withOpacity(0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: Colors.black.withOpacity(0.1))
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag-Handle als visueller Hinweis
                  Icon(
                    Icons.drag_indicator,
                    size: 16,
                    color: isSelected ? Colors.black : Colors.grey[500],
                  ),
                  const SizedBox(width: 8),

                  // Tab-Titel
                  Text(
                    day.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.black : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // PopupMenuButton für Optionen
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.more_vert,
                      size: 16,
                      color: isSelected ? Colors.black : Colors.grey[600],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'rename') {
                        // Bearbeitungsmodus starten
                        setState(() {
                          _editingIndex = index;
                          _renameController.text = day.name;
                        });

                        // Kurze Verzögerung für den Fokus
                        Future.delayed(const Duration(milliseconds: 50),
                            () => _renameFocusNode.requestFocus());
                      } else if (value == 'delete') {
                        _confirmDeleteDay(context, index);
                      }
                    },
                    itemBuilder: (context) => [
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
                      if (plan.days.length > 1)
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
    if (plan == null || dayIndex >= plan.days.length) return;

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Möchtest du den Trainingstag "$dayName" wirklich löschen? Alle Übungen dieses Tages werden ebenfalls gelöscht.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
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
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      createProvider.removeTrainingDay(dayIndex);
                      HapticFeedback.mediumImpact();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Löschen',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Möchtest du die Bearbeitung wirklich abbrechen? Alle nicht gespeicherten Änderungen gehen verloren.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
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
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Dialog schließen
                      Navigator.pop(context); // Screen verlassen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Abbrechen',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Möchtest du den Trainingsplan aktivieren?',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
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
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _processSave(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Aktivieren',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
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

    try {
      final createProvider =
          Provider.of<CreateTrainingPlanProvider>(context, listen: false);
      final plansProvider =
          Provider.of<TrainingPlansProvider>(context, listen: false);
      final navigationProvider =
          Provider.of<NavigationProvider>(context, listen: false);
      final planToSave = createProvider.draftPlan!;
      final wasAlreadyActive = planToSave.isActive;

      // Setze Navigation Index
      navigationProvider.setCurrentIndex(wasAlreadyActive || activate ? 0 : 2);

      // Speichere Plan
      await plansProvider.saveTrainingPlan(planToSave, activate);

      // Gelöschte Übungen und Trainingstage bereinigen
      await createProvider.cleanupDeletedItems();

      // Provider zurücksetzen
      createProvider.reset();

      // Visuelles Feedback
      HapticFeedback.mediumImpact();

      // Navigation
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      print('Fehler beim Speichern: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        // Fehler-Feedback
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
}
