// lib/screens/create_training_plan_screen/training_day_editor_screen.dart
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final createProvider = Provider.of<CreateTrainingPlanProvider>(context);
    final plan = createProvider.draftPlan;
    final isEditMode = createProvider.isEditMode;

    print(
        "TrainingDayEditorScreen gebaut - Plan: ${plan?.name} - Edit Mode: $isEditMode");

    if (plan == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Kein Trainingsplan verfügbar"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
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
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              isEditMode ? '${plan.name} bearbeiten' : 'Neuen Plan erstellen'),
          bottom: TabBar(
            isScrollable: true,
            tabs: plan.days.map((day) {
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(day.name),
                    // Button zum Löschen des Tages nur anzeigen, wenn mehr als ein Tag vorhanden ist
                    if (plan.days.length > 1)
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          _confirmDeleteDay(context, plan.days.indexOf(day));
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 16,
                      ),
                  ],
                ),
              );
            }).toList(),
            onTap: (index) {
              createProvider.setSelectedDayIndex(index);
            },
          ),
          actions: [
            // Button zum Hinzufügen eines neuen Tages
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Trainingstag hinzufügen',
              onPressed: () => _showAddDayDialog(context),
            ),
            // Zeige Ladeindikator während des Speicherns
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: () => _saveTrainingPlan(context),
                    child: const Text(
                      'Speichern',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          ],
        ),
        body: TabBarView(
          children: List.generate(
            plan.days.length,
            (index) => TrainingDayTabWidget(dayIndex: index),
          ),
        ),
      ),
    );
  }

  // NEU: Dialog zum Hinzufügen eines Trainingstages anzeigen
  void _showAddDayDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    final createProvider =
        Provider.of<CreateTrainingPlanProvider>(context, listen: false);

    // Vorschlag für den neuen Tagesnamen generieren (Tag X+1)
    if (createProvider.draftPlan != null) {
      controller.text = 'Tag ${createProvider.draftPlan!.days.length + 1}';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neuen Trainingstag hinzufügen'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name des Trainingstags',
            hintText: 'z.B. Brust & Trizeps, Beine, ...',
          ),
          autofocus: true,
          onSubmitted: (value) {
            Navigator.pop(context);
            createProvider.addTrainingDay(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              createProvider.addTrainingDay(controller.text);
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    ).then((_) {
      controller
          .dispose(); // Controller aufräumen, wenn der Dialog geschlossen wird
    });
  }

  // NEU: Bestätigungsdialog zum Löschen eines Trainingstages
  void _confirmDeleteDay(BuildContext context, int dayIndex) {
    final createProvider =
        Provider.of<CreateTrainingPlanProvider>(context, listen: false);
    final dayName =
        createProvider.draftPlan?.days[dayIndex].name ?? 'Trainingstag';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trainingstag löschen'),
        content: Text(
            'Möchtest du den Trainingstag "$dayName" wirklich löschen? Alle Übungen dieses Tages werden ebenfalls gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              createProvider.removeTrainingDay(dayIndex);
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _saveTrainingPlan(BuildContext context) {
    final createProvider =
        Provider.of<CreateTrainingPlanProvider>(context, listen: false);
    final plan = createProvider.draftPlan;

    // Wenn kein Plan vorhanden ist, nichts tun
    if (plan == null) return;

    // Prüfen, ob der Plan bereits aktiviert ist
    if (plan.isActive) {
      // Wenn bereits aktiv, direkt speichern ohne nachzufragen
      _processSave(
          context, true); // Mit true, um den aktiven Status beizubehalten
    } else {
      // Wenn nicht aktiv, Dialog anzeigen
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Trainingsplan speichern'),
          content: const Text('Möchtest du den Trainingsplan aktivieren?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _processSave(context, false);
              },
              child: const Text('Nur speichern'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _processSave(context, true);
              },
              child: const Text('Aktivieren'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _processSave(BuildContext context, bool activate) async {
    if (_isSaving) return; // Verhindere doppeltes Speichern

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

      // Setze Navigation Index auf 0 (Trainings-Tab) oder 2 (Pläne-Tab)
      // Wenn der Plan aktiviert ist oder wird, gehe zum Training-Tab (0), sonst zum Pläne-Tab (2)
      navigationProvider.setCurrentIndex(wasAlreadyActive || activate ? 0 : 2);

      // Speichere Plan
      await plansProvider.saveTrainingPlan(planToSave, activate);

      // GEÄNDERT: Jetzt gelöschte Übungen und Trainingstage aus der Datenbank entfernen
      await createProvider.cleanupDeletedItems();

      // Provider zurücksetzen
      createProvider.reset();

      // Navigation ohne Meldung
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false, // Entferne alle vorherigen Routen
      );

      // SnackBar-Meldungen wurden entfernt
    } catch (e) {
      print('Fehler beim Speichern: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        // Fehler-SnackBar entfernt
      }
    }
  }
}
