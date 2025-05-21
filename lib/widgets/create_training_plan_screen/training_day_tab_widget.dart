// lib/widgets/create_training_plan_screen/training_day_tab_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../models/training_plan_screen/exercise_model.dart';
import '../../widgets/create_training_plan_screen/exercise_form_widget.dart';
import '../../widgets/create_training_plan_screen/microcycle_exercise_form_widget.dart';

class TrainingDayTabWidget extends StatefulWidget {
  final int dayIndex;

  const TrainingDayTabWidget({
    Key? key,
    required this.dayIndex,
  }) : super(key: key);

  @override
  State<TrainingDayTabWidget> createState() => _TrainingDayTabWidgetState();
}

class _TrainingDayTabWidgetState extends State<TrainingDayTabWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Optimierte Performance-Variablen
  final Map<String, Widget> _exerciseCardCache = {};
  final ScrollController _scrollController = ScrollController();
  bool _isScrolledToTop = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Cache nur bei relevanten Änderungen leeren
    final provider = Provider.of<CreateTrainingPlanProvider>(context);
    if (provider.draftPlan != null && provider.isPeriodized) {
      // Cache leeren bei Wochenwechsel
      _exerciseCardCache.clear();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isScrolled = _scrollController.offset > 20;
    if (isScrolled != _isScrolledToTop) {
      setState(() {
        _isScrolledToTop = !isScrolled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final createProvider = Provider.of<CreateTrainingPlanProvider>(context);
    final progressionProvider =
        Provider.of<ProgressionManagerProvider>(context);
    final plan = createProvider.draftPlan;

    if (plan == null || widget.dayIndex >= plan.days.length) {
      return const Center(
        child: Text("Ungültiger Tag oder kein Plan verfügbar"),
      );
    }

    final day = plan.days[widget.dayIndex];
    final isPeriodized = plan.isPeriodized;
    final activeWeekIndex = createProvider.activeWeekIndex;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Periodisierungs-Header
            if (isPeriodized)
              _buildPeriodizationHeader(createProvider, plan, activeWeekIndex),

            // Übungsliste
            Expanded(
              child: day.exercises.isEmpty
                  ? _buildEmptyState(context, isPeriodized, createProvider,
                      progressionProvider)
                  : _buildOptimizedExerciseList(
                      day.exercises,
                      createProvider,
                      progressionProvider,
                      isPeriodized,
                      activeWeekIndex,
                    ),
            ),
          ],
        ),

        // Floating Action Button
        _buildFloatingAddButton(
            context, isPeriodized, createProvider, progressionProvider),
      ],
    );
  }

  // [Alle anderen Methoden bleiben gleich bis auf _showExerciseOptionsMenu]

  // Periodisierungs-Header (vereinfacht für bessere Performance)
  Widget _buildPeriodizationHeader(
    CreateTrainingPlanProvider createProvider,
    dynamic plan,
    int activeWeekIndex,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: Colors.purple[700],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Mikrozyklus ${activeWeekIndex + 1}/${plan.numberOfWeeks}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: plan.numberOfWeeks,
              itemBuilder: (context, weekIndex) {
                final isActive = weekIndex == activeWeekIndex;
                return _buildWeekSelectChip(
                    weekIndex, isActive, createProvider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelectChip(
    int weekIndex,
    bool isActive,
    CreateTrainingPlanProvider createProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            createProvider.setActiveWeekIndex(weekIndex);
            _exerciseCardCache.clear();
          },
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? Colors.purple[600] : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Woche ${weekIndex + 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Colors.white : Colors.grey[800],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isPeriodized,
    CreateTrainingPlanProvider createProvider,
    ProgressionManagerProvider progressionProvider,
  ) {
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
            child:
                Icon(Icons.fitness_center, size: 36, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text(
            'Keine Übungen vorhanden',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isPeriodized
                  ? 'Füge Übungen für Woche ${createProvider.activeWeekIndex + 1} hinzu'
                  : 'Füge deine erste Übung hinzu, um deinen Trainingsplan zu gestalten',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddExerciseDialog(
              context,
              isPeriodized,
              createProvider,
              progressionProvider,
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Übung hinzufügen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizedExerciseList(
    List<ExerciseModel> exercises,
    CreateTrainingPlanProvider createProvider,
    ProgressionManagerProvider progressionProvider,
    bool isPeriodized,
    int activeWeekIndex,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      physics: const BouncingScrollPhysics(),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final ExerciseModel exercise = isPeriodized
            ? createProvider.getExerciseForCurrentWeek(index)
            : exercises[index];

        // Optimierter Cache-Key
        final String cacheKey =
            '${exercise.id}_${activeWeekIndex}_${exercise.hashCode}';

        return _exerciseCardCache.putIfAbsent(
          cacheKey,
          () => _buildExerciseCard(
            context,
            index,
            exercise,
            createProvider,
            progressionProvider,
            isPeriodized,
            activeWeekIndex,
          ),
        );
      },
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    int index,
    ExerciseModel exercise,
    CreateTrainingPlanProvider createProvider,
    ProgressionManagerProvider progressionProvider,
    bool isPeriodized,
    int activeWeekIndex,
  ) {
    final hasProfile = exercise.progressionProfileId != null &&
        progressionProvider.progressionsProfile
            .any((p) => p.id == exercise.progressionProfileId);

    final profileName = hasProfile
        ? progressionProvider.progressionsProfile
            .firstWhere((p) => p.id == exercise.progressionProfileId)
            .name
        : null;

    return Card(
      key: ValueKey('exercise_${exercise.id}_$activeWeekIndex'),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showExerciseOptionsMenu(
            context,
            index,
            exercise,
            isPeriodized,
            activeWeekIndex,
            createProvider,
            progressionProvider,
          );
        },
        onTap: () {
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.fitness_center,
                            size: 22,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${exercise.primaryMuscleGroup}${exercise.secondaryMuscleGroup.isNotEmpty ? ' / ${exercise.secondaryMuscleGroup}' : ''}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.more_vert, color: Colors.grey[700]),
                        splashRadius: 20,
                        onPressed: () {
                          _showExerciseOptionsMenu(
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
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMetricItem(
                          label: 'Sätze',
                          value: '${exercise.numberOfSets}',
                          icon: Icons.repeat_rounded,
                        ),
                        Container(
                            height: 30, width: 1, color: Colors.grey[300]),
                        _buildMetricItem(
                          label: 'Wiederholungen',
                          value:
                              '${exercise.repRangeMin}-${exercise.repRangeMax}',
                          icon: Icons.tag_rounded,
                        ),
                        Container(
                            height: 30, width: 1, color: Colors.grey[300]),
                        _buildMetricItem(
                          label: 'RIR',
                          value:
                              '${exercise.rirRangeMin}-${exercise.rirRangeMax}',
                          icon: Icons.battery_charging_full_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (hasProfile)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up_rounded,
                        size: 16, color: Colors.purple[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
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
                              text: profileName,
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
                                  fontSize: 12,
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
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.grey[700]),
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
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingAddButton(
    BuildContext context,
    bool isPeriodized,
    CreateTrainingPlanProvider createProvider,
    ProgressionManagerProvider progressionProvider,
  ) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: AnimatedScale(
        scale: _isScrolledToTop ? 1.0 : 0.8,
        duration: const Duration(milliseconds: 200),
        child: AnimatedOpacity(
          opacity: _isScrolledToTop ? 1.0 : 0.8,
          duration: const Duration(milliseconds: 200),
          child: FloatingActionButton(
            onPressed: () => _showAddExerciseDialog(
              context,
              isPeriodized,
              createProvider,
              progressionProvider,
            ),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ),
    );
  }

  // Verbessertes Übungsoptionen-Menü mit Umbenennungs-Dialog
  void _showExerciseOptionsMenu(
    BuildContext context,
    int index,
    ExerciseModel exercise,
    bool isPeriodized,
    int activeWeekIndex,
    CreateTrainingPlanProvider createProvider,
    ProgressionManagerProvider progressionProvider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.primaryMuscleGroup}${exercise.secondaryMuscleGroup.isNotEmpty ? ' / ${exercise.secondaryMuscleGroup}' : ''}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Umbenennen-Option
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text("Umbenennen"),
                subtitle: const Text("Namen der Übung ändern"),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameExerciseDialog(
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

              // Bearbeiten-Option
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text("Bearbeiten"),
                subtitle: const Text("Einstellungen der Übung ändern"),
                onTap: () {
                  Navigator.pop(context);
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
              ),

              // Löschen-Option
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title:
                    const Text("Löschen", style: TextStyle(color: Colors.red)),
                subtitle: const Text("Übung aus dem Plan entfernen"),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteExercise(context, index, createProvider);
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // Eleganter Dialog zum Umbenennen von Übungen
  void _showRenameExerciseDialog(
    BuildContext context,
    int index,
    ExerciseModel exercise,
    bool isPeriodized,
    int activeWeekIndex,
    CreateTrainingPlanProvider createProvider,
    ProgressionManagerProvider progressionProvider,
  ) {
    final TextEditingController controller =
        TextEditingController(text: exercise.name);
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
                  Icons.fitness_center,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),

              // Titel
              const Text(
                'Übung umbenennen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Beschreibung
              Text(
                'Gib einen neuen Namen für deine Übung ein',
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
                    hintText: 'z.B. Bankdrücken, Kniebeugen...',
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
                      _updateExerciseName(
                        index,
                        exercise,
                        value.trim(),
                        isPeriodized,
                        activeWeekIndex,
                        createProvider,
                        progressionProvider,
                      );
                      Navigator.pop(context);
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
                          _updateExerciseName(
                            index,
                            exercise,
                            newName,
                            isPeriodized,
                            activeWeekIndex,
                            createProvider,
                            progressionProvider,
                          );
                          Navigator.pop(context);
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
      focusNode.dispose();
      controller.dispose();
    });
  }

  // Übungsname aktualisieren
  void _updateExerciseName(
    int index,
    ExerciseModel exercise,
    String newName,
    bool isPeriodized,
    int activeWeekIndex,
    CreateTrainingPlanProvider createProvider,
    ProgressionManagerProvider progressionProvider,
  ) {
    final updatedExercise = exercise.copyWith(name: newName);

    if (isPeriodized) {
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
    } else {
      createProvider.updateExercise(index, updatedExercise);
    }

    // Cache zurücksetzen
    _exerciseCardCache.clear();

    HapticFeedback.mediumImpact();

    // Erfolgsmeldung
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Übung wurde zu "$newName" umbenannt'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // [Alle anderen Dialog-Methoden bleiben gleich wie zuvor]

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
                  _exerciseCardCache.clear();
                },
              )
            : ExerciseFormWidget(
                onSave: (exercise) {
                  createProvider.addExercise(exercise);
                  Navigator.pop(context);
                  HapticFeedback.mediumImpact();
                  _exerciseCardCache.clear();
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
                  _exerciseCardCache.clear();
                },
              )
            : ExerciseFormWidget(
                initialExercise: exercise,
                onSave: (updatedExercise) {
                  createProvider.updateExercise(index, updatedExercise);
                  Navigator.pop(context);
                  HapticFeedback.mediumImpact();
                  _exerciseCardCache.clear();
                },
              ),
      ),
    );
  }

  void _confirmDeleteExercise(
    BuildContext context,
    int index,
    CreateTrainingPlanProvider createProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Übung löschen'),
        content: const Text('Möchtest du diese Übung wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              createProvider.removeExercise(index);
              Navigator.pop(context);
              HapticFeedback.mediumImpact();
              _exerciseCardCache.clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
