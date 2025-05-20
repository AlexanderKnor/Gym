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
import '../../screens/main_screen.dart';

class TrainingDayEditorScreen extends StatefulWidget {
  const TrainingDayEditorScreen({Key? key}) : super(key: key);

  @override
  State<TrainingDayEditorScreen> createState() =>
      _TrainingDayEditorScreenState();
}

class _TrainingDayEditorScreenState extends State<TrainingDayEditorScreen> {
  bool _isSaving = false;
  final _tabController = GlobalKey();
  bool _showTabOptions = false;

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
  }

  @override
  void dispose() {
    _renameController.dispose();
    _renameFocusNode.dispose();
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

    return DefaultTabController(
      length: plan.days.length,
      initialIndex: createProvider.selectedDayIndex,
      key: _tabController,
      child: Scaffold(
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
              child: TabBar(
                isScrollable: true,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Colors.black,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: plan.days.asMap().entries.map((entry) {
                  final index = entry.key;
                  final day = entry.value;

                  // Wenn dieser Tab aktuell bearbeitet wird, zeige ein TextField
                  if (_editingIndex == index) {
                    return Tab(
                      height: 48,
                      child: Container(
                        width: 150, // Breiter Bereich für das Textfeld
                        child: TextField(
                          controller: _renameController,
                          focusNode: _renameFocusNode,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 0),
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
                      ),
                    );
                  }

                  // Ansonsten den normalen Tab anzeigen
                  return Tab(
                    height: 48,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tagesname mit GestureDetector für Doppeltipp
                        GestureDetector(
                          onDoubleTap: () {
                            // Bearbeitungsmodus starten
                            setState(() {
                              _editingIndex = index;
                              _renameController.text = day.name;
                            });

                            // Kurze Verzögerung, um sicherzustellen, dass
                            // das Textfeld erstellt wurde
                            Future.delayed(const Duration(milliseconds: 50),
                                () => _renameFocusNode.requestFocus());
                          },
                          child: Text(day.name),
                        ),
                        const SizedBox(width: 8),
                        // Drei-Punkte-Menü
                        InkWell(
                          onTap: () => _showDayOptionsMenu(context, index),
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.more_vert,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onTap: (index) {
                  // Wenn im Bearbeitungsmodus, zuerst die Bearbeitung beenden
                  if (_editingIndex != null) {
                    _finishRenaming();
                  }
                  createProvider.setSelectedDayIndex(index);
                },
              ),
            ),
          ),
          actions: [
            // Trainingstag hinzufügen Button mit eleganterer Darstellung
            IconButton(
              icon: const Icon(Icons.add_rounded, size: 24),
              tooltip: 'Trainingstag hinzufügen',
              onPressed: () => _showAddDayDialog(context),
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
      ),
    );
  }

  // Zeigt den Dialog zum Hinzufügen eines Trainingstages
  void _showAddDayDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    final createProvider =
        Provider.of<CreateTrainingPlanProvider>(context, listen: false);

    // Vorschlag für den neuen Tagesnamen
    if (createProvider.draftPlan != null) {
      controller.text = 'Tag ${createProvider.draftPlan!.days.length + 1}';
    }

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
                'Neuen Trainingstag hinzufügen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Name des Trainingstags',
                  hintText: 'z.B. Brust & Trizeps, Beine, ...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                autofocus: true,
                onSubmitted: (value) {
                  Navigator.pop(context);
                  createProvider.addTrainingDay(value);
                },
                textCapitalization: TextCapitalization.words,
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
                      createProvider.addTrainingDay(controller.text);
                      HapticFeedback.mediumImpact();
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
    ).then((_) {
      controller.dispose();
    });
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

    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(const Offset(0, 80), ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
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
