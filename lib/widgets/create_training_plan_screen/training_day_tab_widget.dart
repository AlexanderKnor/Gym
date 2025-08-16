// lib/widgets/create_training_plan_screen/training_day_tab_widget.dart
import 'dart:ui';
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
        // PROVER-styled Mikrozyklus Dropdown für periodisierte Pläne
        if (isPeriodized) ...[
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: MicrocycleDropdown(
              currentWeek: activeWeekIndex,
              totalWeeks: plan.numberOfWeeks,
              onWeekChanged: (weekIndex) {
                HapticFeedback.selectionClick();
                createProvider.setActiveWeekIndex(weekIndex);
              },
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


  // PROVER-styled Exercise Options Bottom Sheet
  void _showExerciseOptions(
    BuildContext context,
    int index,
    ExerciseModel exercise,
    bool isPeriodized,
    int activeWeekIndex,
    CreateTrainingPlanProvider createProvider,
    ProgressionManagerProvider progressionProvider,
  ) {
    // PROVER color system
    const Color _void = Color(0xFF000000);
    const Color _nebula = Color(0xFF0F0F12);
    const Color _stellar = Color(0xFF18181C);
    const Color _lunar = Color(0xFF242429);
    const Color _stardust = Color(0xFFA5A5B0);
    const Color _nova = Color(0xFFF5F5F7);
    const Color _proverCore = Color(0xFFFF4500);
    const Color _proverGlow = Color(0xFFFF6B3D);

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
              colors: [_stellar, _nebula],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: _lunar.withOpacity(0.3),
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
                          colors: [_proverCore, _proverGlow],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        color: _nova,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        exercise.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: _nova,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 22, color: _stardust),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Option 1: Übung bearbeiten
                _buildExerciseOptionButton(
                  icon: Icons.edit_outlined,
                  label: 'Bearbeiten',
                  onTap: () {
                    Navigator.of(context).pop();
                    HapticFeedback.lightImpact();
                    _showEditExerciseDialog(
                      context,
                      index,
                      exercise,
                      isPeriodized,
                      activeWeekIndex,
                      createProvider,
                      progressionProvider,
                    );
                  },
                  colors: [_lunar.withOpacity(0.3), _lunar.withOpacity(0.1)],
                  borderColor: _lunar.withOpacity(0.4),
                  iconColor: _stardust,
                  textColor: _stardust,
                ),

                const SizedBox(height: 12),

                // Option 2: Übung löschen
                _buildExerciseOptionButton(
                  icon: Icons.delete_outline,
                  label: 'Löschen',
                  onTap: () {
                    Navigator.of(context).pop();
                    HapticFeedback.mediumImpact();
                    _confirmDeleteExercise(context, index, createProvider);
                  },
                  colors: [Colors.red.withOpacity(0.15), Colors.red.withOpacity(0.05)],
                  borderColor: Colors.red.withOpacity(0.4),
                  iconColor: Colors.red,
                  textColor: Colors.red,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required List<Color> colors,
    required Color borderColor,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: iconColor,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

  // Modernisierte Übungsliste mit Drag & Drop
  Widget _buildExerciseList(
    BuildContext context,
    List<ExerciseModel> exercises,
    CreateTrainingPlanProvider createProvider,
    ProgressionManagerProvider progressionProvider,
    bool isPeriodized,
    int activeWeekIndex,
  ) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      itemCount: exercises.length,
      // Proxy decorator für visuelles Feedback beim Ziehen
      proxyDecorator: (Widget child, int index, Animation<double> animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            final double animValue = Curves.easeInOut.transform(animation.value);
            final double scale = 1 + (animValue * 0.05); // Leichte Vergrößerung beim Ziehen
            
            return Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4500).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      onReorder: (int oldIndex, int newIndex) {
        // Haptisches Feedback beim Neuordnen
        HapticFeedback.mediumImpact();
        
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        
        // Übungen im Provider umordnen
        createProvider.reorderExercises(dayIndex, oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        // Bei periodisierten Plänen die Übung mit den Werten für die aktuelle Woche anzeigen
        final ExerciseModel exercise = isPeriodized
            ? createProvider.getExerciseForCurrentWeek(index)
            : exercises[index];

        // Material widget als direktes Kind für ReorderableListView
        return Material(
          key: ValueKey('exercise_${exercise.id}_$index'), // Unique key für ReorderableListView
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1C1C1E), // Charcoal
                  const Color(0xFF0F0F12), // Darker variant
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF48484A).withOpacity(0.4), // Steel
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withOpacity(0.4),
                  offset: const Offset(0, 4),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFF48484A).withOpacity(0.1),
                  offset: const Offset(0, 1),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Drag Handle - zeigt an, dass die Übung verschiebbar ist
                            Container(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                Icons.drag_indicator,
                                size: 24,
                                color: const Color(0xFF8E8E93).withOpacity(0.8), // Mercury
                              ),
                            ),
                            
                            // Übungssymbol mit verbessertem Design
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF2C2C2E), // Graphite
                                    const Color(0xFF242429), // Darker graphite
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      const Color(0xFF48484A).withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF4500)
                                        .withOpacity(0.2),
                                    offset: const Offset(0, 2),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.fitness_center,
                                  size: 22,
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

                      // PROVER-styled Options Button
                      IconButton(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Color(0xFFA5A5B0), // stardust
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _showExerciseOptions(
                            context,
                            index,
                            exercise,
                            isPeriodized,
                            activeWeekIndex,
                            createProvider,
                            progressionProvider,
                          );
                        },
                      ),
                    ],
                  ),

                  // Details-Abschnitt (Sätze, Wiederholungen, RIR)
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF2C2C2E), // Graphite
                          const Color(0xFF1C1C1E), // Charcoal
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            const Color(0xFF48484A).withOpacity(0.4), // Steel
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF000000).withOpacity(0.2),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
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
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF242429), // Dark graphite
                      const Color(0xFF1C1C1E), // Charcoal
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFF48484A).withOpacity(0.4), // Steel
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
      ),
            ),
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
    // Navigate directly to configuration screen for editing
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseConfigurationScreen(
          exercise: exercise,
          isNewExercise: false,
          onExerciseSaved: (updatedExercise) {
            createProvider.updateExercise(index, updatedExercise);
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

// PROVER-styled Microcycle Dropdown Widget
class MicrocycleDropdown extends StatefulWidget {
  final int currentWeek;
  final int totalWeeks;
  final Function(int) onWeekChanged;

  const MicrocycleDropdown({
    Key? key,
    required this.currentWeek,
    required this.totalWeeks,
    required this.onWeekChanged,
  }) : super(key: key);

  @override
  State<MicrocycleDropdown> createState() => _MicrocycleDropdownState();
}

class _MicrocycleDropdownState extends State<MicrocycleDropdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  bool _isExpanded = false;

  // PROVER color system
  static const Color _void = Color(0xFF000000);
  static const Color _cosmos = Color(0xFF050507);
  static const Color _nebula = Color(0xFF0F0F12);
  static const Color _stellar = Color(0xFF18181C);
  static const Color _lunar = Color(0xFF242429);
  static const Color _asteroid = Color(0xFF35353C);
  static const Color _comet = Color(0xFF65656F);
  static const Color _stardust = Color(0xFFA5A5B0);
  static const Color _nova = Color(0xFFF5F5F7);
  
  // Prover signature gradient
  static const Color _proverCore = Color(0xFFFF4500);
  static const Color _proverGlow = Color(0xFFFF6B3D);
  static const Color _proverFlare = Color(0xFFFFA500);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Dropdown Button
        GestureDetector(
          onTap: _toggleDropdown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _stellar.withOpacity(0.8),
                  _nebula.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isExpanded 
                    ? _proverCore.withOpacity(0.5)
                    : _lunar.withOpacity(0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isExpanded 
                      ? _proverCore.withOpacity(0.15)
                      : _void.withOpacity(0.3),
                  blurRadius: _isExpanded ? 12 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Cycle Icon with glow effect
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _proverCore.withOpacity(0.2),
                        _proverGlow.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.repeat_rounded,
                    size: 16,
                    color: _proverCore,
                  ),
                ),
                const SizedBox(width: 12),
                // Week text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MIKROZYKLUS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _comet,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Woche ${widget.currentWeek + 1} von ${widget.totalWeeks}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _nova,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Animated Arrow
                RotationTransition(
                  turns: _rotateAnimation,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _proverCore,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Expanded Dropdown List
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _stellar.withOpacity(0.95),
                  _nebula.withOpacity(0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _lunar.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _void.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  widget.totalWeeks,
                  (index) {
                    final isSelected = index == widget.currentWeek;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          widget.onWeekChanged(index);
                          _toggleDropdown();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      _proverCore.withOpacity(0.2),
                                      _proverGlow.withOpacity(0.1),
                                    ],
                                  )
                                : null,
                            border: Border(
                              bottom: index < widget.totalWeeks - 1
                                  ? BorderSide(
                                      color: _lunar.withOpacity(0.2),
                                      width: 1,
                                    )
                                  : BorderSide.none,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Week number badge
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [_proverCore, _proverGlow],
                                        )
                                      : LinearGradient(
                                          colors: [
                                            _asteroid.withOpacity(0.8),
                                            _lunar.withOpacity(0.6),
                                          ],
                                        ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: _proverCore.withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? _nova : _stardust,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Week label
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Woche ${index + 1}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? _nova : _stardust,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'AKTIV',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: _proverCore,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Check icon for selected
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: _proverCore,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
