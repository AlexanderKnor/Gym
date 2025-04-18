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
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              isEditMode ? '${plan.name} bearbeiten' : 'Neuen Plan erstellen'),
          bottom: TabBar(
            isScrollable: true,
            tabs: plan.days.map((day) {
              return Tab(text: day.name);
            }).toList(),
            onTap: (index) {
              createProvider.setSelectedDayIndex(index);
            },
          ),
          actions: [
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
