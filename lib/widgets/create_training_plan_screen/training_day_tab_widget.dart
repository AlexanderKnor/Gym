// lib/widgets/create_training_plan_screen/training_day_tab_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../models/training_plan_screen/exercise_model.dart';
import '../../widgets/create_training_plan_screen/exercise_form_widget.dart';
import '../../widgets/create_training_plan_screen/microcycle_exercise_form_widget.dart';

class TrainingDayTabWidget extends StatelessWidget {
  final int dayIndex;

  const TrainingDayTabWidget({
    Key? key,
    required this.dayIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final createProvider = Provider.of<CreateTrainingPlanProvider>(context);
    final progressionProvider =
        Provider.of<ProgressionManagerProvider>(context);
    final plan = createProvider.draftPlan;
    final isPeriodized = plan?.isPeriodized ?? false;
    final activeWeekIndex = createProvider.activeWeekIndex;

    if (plan == null || dayIndex >= plan.days.length) {
      return const Center(
        child: Text("Ungültiger Tag oder kein Plan verfügbar"),
      );
    }

    final day = plan.days[dayIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NEU: Wochenauswahl für periodisierte Pläne mit modernem Design
        if (isPeriodized) ...[
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 1),
                  blurRadius: 8,
                ),
              ],
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: Colors.purple[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mikrozyklus ${activeWeekIndex + 1} von ${plan.numberOfWeeks}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple[700],
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Wähle die Woche für die Konfiguration:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 16),
                // Moderne Wochenauswahl mit Chips
                SizedBox(
                  height: 42,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: plan.numberOfWeeks,
                    itemBuilder: (context, weekIndex) {
                      final isActive = weekIndex == activeWeekIndex;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          createProvider.setActiveWeekIndex(weekIndex);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.purple[600]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.3),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color:
                                    isActive ? Colors.white : Colors.grey[700],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Woche ${weekIndex + 1}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isActive
                                      ? Colors.white
                                      : Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (activeWeekIndex > 0) ...[
                  const SizedBox(height: 16),
                  // Verbesserte Kopier-Funktionalität
                  OutlinedButton.icon(
                    onPressed: () {
                      _showCopyWeekDialog(
                          context, createProvider, activeWeekIndex);
                    },
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 18,
                      color: Colors.purple[700],
                    ),
                    label: Text(
                      'Woche kopieren',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.purple[700],
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple[700],
                      side: BorderSide(color: Colors.purple[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        // Liste der Übungen mit verbessertem Design
        Expanded(
          child: day.exercises.isEmpty
              ? _buildEmptyState(context)
              : _buildExerciseList(
                  context,
                  day.exercises,
                  createProvider,
                  progressionProvider,
                  isPeriodized,
                  activeWeekIndex,
                ),
        ),

        // "Übung hinzufügen" Button mit besserem Design
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showAddExerciseDialog(
                context, isPeriodized, createProvider, progressionProvider),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Übung hinzufügen',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Dialog zum Kopieren einer Woche mit verbessertem Design
  void _showCopyWeekDialog(BuildContext context,
      CreateTrainingPlanProvider provider, int currentWeekIndex) {
    final availableWeeks = List<int>.generate(provider.numberOfWeeks, (i) => i)
      ..remove(currentWeekIndex);

    if (availableWeeks.isEmpty) return;

    int? selectedSourceWeek;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return Dialog(
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
                  'Woche kopieren',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Wähle die Quell-Woche, deren Konfiguration du in Woche ${currentWeekIndex + 1} kopieren möchtest:',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedSourceWeek,
                  hint: const Text('Quell-Woche auswählen'),
                  items: availableWeeks
                      .map((weekIndex) => DropdownMenuItem<int>(
                            value: weekIndex,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: Colors.purple[700],
                                ),
                                const SizedBox(width: 8),
                                Text('Woche ${weekIndex + 1}'),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSourceWeek = value;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.purple[700]!,
                        width: 2,
                      ),
                    ),
                  ),
                  icon: Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.purple[700],
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                      onPressed: selectedSourceWeek == null
                          ? null
                          : () {
                              // Kopiere die Einstellungen
                              provider.copyMicrocycleSettings(
                                  selectedSourceWeek!, currentWeekIndex);
                              Navigator.pop(context);
                              HapticFeedback.mediumImpact();

                              // Erfolgs-Snackbar
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Einstellungen aus Woche ${selectedSourceWeek! + 1} wurden kopiert',
                                  ),
                                  backgroundColor: Colors.green[600],
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[700],
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[600],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Kopieren',
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
        );
      }),
    );
  }

  // Verbesserte leere Zustandsanzeige
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fitness_center,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Keine Übungen vorhanden',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Füge deine erste Übung hinzu',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 15,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddExerciseDialog(
              context,
              Provider.of<CreateTrainingPlanProvider>(context, listen: false)
                  .isPeriodized,
              Provider.of<CreateTrainingPlanProvider>(context, listen: false),
              Provider.of<ProgressionManagerProvider>(context, listen: false),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Übung hinzufügen',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
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
          ),
        ],
      ),
    );
  }

  // Modernisierte Übungsliste
  Widget _buildExerciseList(
    BuildContext context,
    List<ExerciseModel> exercises,
    CreateTrainingPlanProvider createProvider,
    ProgressionManagerProvider progressionProvider,
    bool isPeriodized,
    int activeWeekIndex,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        // Bei periodisierten Plänen die Übung mit den Werten für die aktuelle Woche anzeigen
        final ExerciseModel exercise = isPeriodized
            ? createProvider.getExerciseForCurrentWeek(index)
            : exercises[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Übungssymbol mit verbessertem Design
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.fitness_center,
                              size: 20,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Übungstitel und Beschreibung
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${exercise.primaryMuscleGroup}${exercise.secondaryMuscleGroup.isNotEmpty ? ' / ${exercise.secondaryMuscleGroup}' : ''}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Optionen-Menü
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: Colors.grey[700],
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditExerciseDialog(
                                context,
                                index,
                                exercise,
                                isPeriodized,
                                activeWeekIndex,
                                createProvider,
                                progressionProvider,
                              );
                            } else if (value == 'delete') {
                              _confirmDeleteExercise(
                                  context, index, createProvider);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                    color: Colors.grey[800],
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Bearbeiten'),
                                ],
                              ),
                            ),
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

                    // Details-Abschnitt (Sätze, Wiederholungen, RIR)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Sätze
                          _buildDetailItem(
                            'Sätze',
                            '${exercise.numberOfSets}',
                            Icons.repeat_rounded,
                          ),

                          // Vertikaler Trenner
                          Container(
                            height: 28,
                            width: 1,
                            color: Colors.grey[300],
                          ),

                          // Wiederholungen
                          _buildDetailItem(
                            'Wiederholungen',
                            '${exercise.repRangeMin}-${exercise.repRangeMax}',
                            Icons.tag_rounded,
                          ),

                          // Vertikaler Trenner
                          Container(
                            height: 28,
                            width: 1,
                            color: Colors.grey[300],
                          ),

                          // RIR
                          _buildDetailItem(
                            'RIR',
                            '${exercise.rirRangeMin}-${exercise.rirRangeMax}',
                            Icons.battery_charging_full_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Progressionsprofil-Info, wenn gesetzt
              if (exercise.progressionProfileId != null &&
                  progressionProvider.progressionsProfile
                      .any((p) => p.id == exercise.progressionProfileId)) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        size: 18,
                        color: Colors.purple[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Progressionsprofil: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.purple[800],
                                  fontSize: 13,
                                ),
                              ),
                              TextSpan(
                                text: progressionProvider.progressionsProfile
                                    .firstWhere((p) =>
                                        p.id == exercise.progressionProfileId)
                                    .name,
                                style: TextStyle(
                                  color: Colors.purple[700],
                                  fontSize: 13,
                                ),
                              ),
                              if (isPeriodized)
                                TextSpan(
                                  text: ' (Woche ${activeWeekIndex + 1})',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.purple[600],
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Helper-Widget für Detail-Anzeige
  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: Colors.grey[700],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  void _showAddExerciseDialog(
    BuildContext context,
    bool isPeriodized,
    CreateTrainingPlanProvider createProvider,
    ProgressionManagerProvider progressionProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: isPeriodized
            ? MicrocycleExerciseFormWidget(
                weekIndex: createProvider.activeWeekIndex,
                weekCount: createProvider.numberOfWeeks,
                onSave: (exercise) {
                  createProvider.addExercise(exercise);
                  Navigator.pop(context);
                  HapticFeedback.mediumImpact();
                },
              )
            : ExerciseFormWidget(
                onSave: (exercise) {
                  createProvider.addExercise(exercise);
                  Navigator.pop(context);
                  HapticFeedback.mediumImpact();
                },
              ),
      ),
    );
  }

  void _showEditExerciseDialog(
    BuildContext context,
    int index,
    ExerciseModel exercise,
    bool isPeriodized,
    int activeWeekIndex,
    CreateTrainingPlanProvider createProvider,
    ProgressionManagerProvider progressionProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: isPeriodized
            ? MicrocycleExerciseFormWidget(
                initialExercise: exercise,
                weekIndex: activeWeekIndex,
                weekCount: createProvider.numberOfWeeks,
                onSave: (updatedExercise) {
                  // Werte für die aktuelle Woche aktualisieren
                  createProvider.updateMicrocycle(
                    index,
                    activeWeekIndex,
                    updatedExercise.numberOfSets,
                    updatedExercise.repRangeMin,
                    updatedExercise.repRangeMax,
                    updatedExercise.rirRangeMin,
                    updatedExercise.rirRangeMax,
                    updatedExercise.progressionProfileId,
                  );
                  Navigator.pop(context);
                  HapticFeedback.mediumImpact();
                },
              )
            : ExerciseFormWidget(
                initialExercise: exercise,
                onSave: (updatedExercise) {
                  createProvider.updateExercise(index, updatedExercise);
                  Navigator.pop(context);
                  HapticFeedback.mediumImpact();
                },
              ),
      ),
    );
  }

  void _confirmDeleteExercise(BuildContext context, int index,
      CreateTrainingPlanProvider createProvider) {
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
                'Übung löschen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Möchtest du diese Übung wirklich löschen?',
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
                      createProvider.removeExercise(index);
                      Navigator.pop(context);
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
}
