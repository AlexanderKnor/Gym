// lib/widgets/create_training_plan_screen/training_day_tab_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../models/training_plan_screen/exercise_model.dart';
import '../../widgets/create_training_plan_screen/exercise_form_widget.dart';
import '../../widgets/create_training_plan_screen/microcycle_exercise_form_widget.dart';
import '../../screens/create_training_plan_screen/exercise_selection_screen.dart';

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
        child: Text(
          "Ungültiger Tag oder kein Plan verfügbar",
          style: TextStyle(
            color: Color(0xFFFFFFFF), // Snow
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
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
              color: const Color(0xFF1C1C1E), // Charcoal
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withOpacity(0.3),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
              border: Border.all(
                color: const Color(0xFF48484A).withOpacity(0.3), // Steel
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: Color(0xFFFF4500), // Orange
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mikrozyklus ${activeWeekIndex + 1} von ${plan.numberOfWeeks}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF4500), // Orange
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Wähle die Woche für die Konfiguration:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFAEAEB2), // Silver
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
                                ? const Color(0xFFFF4500) // Orange
                                : const Color(0xFF48484A), // Steel
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFF4500).withOpacity(0.3),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: isActive 
                                    ? const Color(0xFFFFFFFF) // Snow
                                    : const Color(0xFFAEAEB2), // Silver
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
                                      ? const Color(0xFFFFFFFF) // Snow
                                      : const Color(0xFFAEAEB2), // Silver
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
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFFF4500).withOpacity(0.3),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _showCopyWeekDialog(
                              context, createProvider, activeWeekIndex);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy_rounded,
                                size: 18,
                                color: Color(0xFFFF4500), // Orange
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Woche kopieren',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFFF4500), // Orange
                                ),
                              ),
                            ],
                          ),
                        ),
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
              onTap: () => _showAddExerciseDialog(
                  context, isPeriodized, createProvider, progressionProvider),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_rounded, 
                      size: 20,
                      color: Color(0xFFFFFFFF), // Snow
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Übung hinzufügen',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: Color(0xFFFFFFFF), // Snow
                      ),
                    ),
                  ],
                ),
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
                  'Woche kopieren',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF), // Snow
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Wähle die Quell-Woche, deren Konfiguration du in Woche ${currentWeekIndex + 1} kopieren möchtest:',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFFAEAEB2), // Silver
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedSourceWeek,
                  hint: const Text(
                    'Quell-Woche auswählen',
                    style: TextStyle(
                      color: Color(0xFF8E8E93), // Mercury
                    ),
                  ),
                  items: availableWeeks
                      .map((weekIndex) => DropdownMenuItem<int>(
                            value: weekIndex,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: Color(0xFFFF4500), // Orange
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Woche ${weekIndex + 1}',
                                  style: const TextStyle(
                                    color: Color(0xFFFFFFFF), // Snow
                                  ),
                                ),
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
                    filled: true,
                    fillColor: const Color(0xFF2C2C2E), // Graphite
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF4500), // Orange
                        width: 2,
                      ),
                    ),
                  ),
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF), // Snow
                  ),
                  dropdownColor: const Color(0xFF1C1C1E), // Charcoal
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Color(0xFFFF4500), // Orange
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
                          onTap: selectedSourceWeek == null
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
                                        style: const TextStyle(
                                          color: Color(0xFFFFFFFF), // Snow
                                        ),
                                      ),
                                      backgroundColor: const Color(0xFF34C759), // Success green
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      margin: const EdgeInsets.all(16),
                                    ),
                                  );
                                },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Text(
                              'Kopieren',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: selectedSourceWeek == null
                                    ? const Color(0xFF8E8E93) // Mercury
                                    : const Color(0xFFFFFFFF), // Snow
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
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1E), // Charcoal
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fitness_center,
              size: 40,
              color: Color(0xFF8E8E93), // Mercury
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Keine Übungen vorhanden',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF), // Snow
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Füge deine erste Übung hinzu',
            style: TextStyle(
              color: Color(0xFFAEAEB2), // Silver
              fontSize: 15,
              letterSpacing: -0.3,
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
          color: const Color(0xFF1C1C1E), // Charcoal
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: const Color(0xFF48484A).withOpacity(0.3), // Steel
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E), // Charcoal
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
                            color: const Color(0xFF2C2C2E), // Graphite
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.fitness_center,
                              size: 20,
                              color: Color(0xFFFF4500), // Orange
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
                                  color: Color(0xFFFFFFFF), // Snow
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${exercise.primaryMuscleGroup}${exercise.secondaryMuscleGroup.isNotEmpty ? ' / ${exercise.secondaryMuscleGroup}' : ''}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFAEAEB2), // Silver
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Optionen-Menü
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Color(0xFFAEAEB2), // Silver
                          ),
                          color: const Color(0xFF1C1C1E), // Charcoal
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
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
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                    color: Color(0xFFAEAEB2), // Silver
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Bearbeiten',
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF), // Snow
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Color(0xFFFF453A), // Error red
                                  ),
                                  SizedBox(width: 12),
                                  Text(
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

                    // Details-Abschnitt (Sätze, Wiederholungen, RIR)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E), // Graphite
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF48484A).withOpacity(0.3), // Steel
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
                            color: const Color(0xFF48484A), // Steel
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
                            color: const Color(0xFF48484A), // Steel
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
                    color: const Color(0xFF2C2C2E), // Graphite
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: const Color(0xFF48484A).withOpacity(0.3), // Steel
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        size: 18,
                        color: Color(0xFFFF4500), // Orange
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Progressionsprofil: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFFF4500), // Orange
                                  fontSize: 13,
                                ),
                              ),
                              TextSpan(
                                text: progressionProvider.progressionsProfile
                                    .firstWhere((p) =>
                                        p.id == exercise.progressionProfileId)
                                    .name,
                                style: const TextStyle(
                                  color: Color(0xFFFFFFFF), // Snow
                                  fontSize: 13,
                                ),
                              ),
                              if (isPeriodized)
                                TextSpan(
                                  text: ' (Woche ${activeWeekIndex + 1})',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFFAEAEB2), // Silver
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
              color: const Color(0xFFAEAEB2), // Silver
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFAEAEB2), // Silver
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
            color: Color(0xFFFFFFFF), // Snow
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExerciseSelectionScreen(),
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
        backgroundColor: const Color(0xFF1C1C1E), // Charcoal
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFF48484A).withOpacity(0.3), // Steel
            width: 1,
          ),
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
                'Übung löschen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFFFFF), // Snow
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Möchtest du diese Übung wirklich löschen?',
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
                          createProvider.removeExercise(index);
                          Navigator.pop(context);
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
}