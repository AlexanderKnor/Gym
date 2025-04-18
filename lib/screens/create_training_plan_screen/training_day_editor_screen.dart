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

    print("TrainingDayEditorScreen gebaut - Plan: ${plan?.name}");

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
          title: Text('${plan.name} bearbeiten'),
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

      print('Speichere Plan: ${planToSave.name}');

      // Setze Navigation Index auf 0 (Trainings-Tab)
      navigationProvider.setCurrentIndex(0);

      // Speichere Plan
      final success =
          await plansProvider.saveTrainingPlan(planToSave, activate);

      // Provider zurücksetzen
      createProvider.reset();

      if (success) {
        // WICHTIG: Diese Navigation entfernt ALLE vorherigen Routen und ersetzt sie durch MainScreen
        // Das entfernt den Zurück-Button in der TopBar
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false, // Entferne alle vorherigen Routen
        );

        // SnackBar für Feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(activate
                ? 'Trainingsplan aktiviert'
                : 'Trainingsplan gespeichert'),
          ),
        );
      } else {
        // Fehlerbehandlung
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fehler beim Speichern des Trainingsplans'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isSaving = false;
          });
        }
      }
    } catch (e) {
      print('Fehler beim Speichern: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
