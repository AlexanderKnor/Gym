// lib/widgets/training_screen/active_plan_card_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/training_plan_screen/training_plan_model.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';
import '../../providers/training_plans_screen/training_plans_screen_provider.dart';
import '../../providers/training_session_screen/training_session_provider.dart';
import '../../screens/create_training_plan_screen/training_day_editor_screen.dart';
import '../../screens/training_session_screen/training_session_screen.dart';

class ActivePlanCardWidget extends StatefulWidget {
  final TrainingPlanModel plan;

  const ActivePlanCardWidget({
    Key? key,
    required this.plan,
  }) : super(key: key);

  @override
  State<ActivePlanCardWidget> createState() => _ActivePlanCardWidgetState();
}

class _ActivePlanCardWidgetState extends State<ActivePlanCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
    _expandController.forward();
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plansProvider = Provider.of<TrainingPlansProvider>(context);
    final isPeriodized = widget.plan.isPeriodized;
    final currentWeekIndex = plansProvider.currentWeekIndex;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
                if (_isExpanded) {
                  _expandController.forward();
                } else {
                  _expandController.reverse();
                }
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Plan Icon with gradient background
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.plan.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.plan.days.length} Trainingstage',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action buttons
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: Colors.grey[700],
                        size: 20,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _navigateToEditPlan(context);
                      },
                      tooltip: 'Trainingsplan bearbeiten',
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Periodization selector for periodized plans
          if (isPeriodized) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_view_week,
                              color: Colors.purple[700],
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Woche ${currentWeekIndex + 1} von ${widget.plan.numberOfWeeks}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Week selector chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(widget.plan.numberOfWeeks, (weekIndex) {
                        final isActive = weekIndex == currentWeekIndex;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: ChoiceChip(
                              label: Text('W${weekIndex + 1}'),
                              selected: isActive,
                              selectedColor: Colors.purple[400],
                              backgroundColor: Colors.grey[100],
                              labelStyle: TextStyle(
                                color: isActive ? Colors.white : Colors.grey[700],
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  HapticFeedback.selectionClick();
                                  plansProvider.setCurrentWeekIndex(weekIndex);
                                }
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              side: BorderSide(
                                color: isActive ? Colors.purple[400]! : Colors.grey[300]!,
                                width: isActive ? 2 : 1,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: Colors.grey[200],
            ),
          ],

          // Training days list with animation
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.plan.days.length,
              itemBuilder: (context, index) {
                final day = widget.plan.days[index];
                
                // Calculate exercises and sets for current microcycle
                int totalExercises = day.exercises.length;
                int totalSets = 0;

                if (isPeriodized && widget.plan.periodization != null) {
                  for (var exercise in day.exercises) {
                    final config = widget.plan.getExerciseMicrocycle(
                        exercise.id, index, currentWeekIndex);
                    if (config != null) {
                      totalSets += config.numberOfSets;
                    } else {
                      totalSets += exercise.numberOfSets;
                    }
                  }
                } else {
                  for (var exercise in day.exercises) {
                    totalSets += exercise.numberOfSets;
                  }
                }

                return Container(
                  margin: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: index == 0 ? 20 : 8,
                    bottom: index == widget.plan.days.length - 1 ? 20 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: day.exercises.isEmpty
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              _startTraining(context, index);
                            },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Day number indicator
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue[400]!,
                                    Colors.blue[600]!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Day info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    day.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.fitness_center,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$totalExercises Übungen',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.repeat,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$totalSets Sätze',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Start button
                            Container(
                              decoration: BoxDecoration(
                                gradient: day.exercises.isEmpty
                                    ? null
                                    : LinearGradient(
                                        colors: [
                                          Theme.of(context).primaryColor,
                                          Theme.of(context).primaryColor.withOpacity(0.8),
                                        ],
                                      ),
                                color: day.exercises.isEmpty ? Colors.grey[300] : null,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: day.exercises.isEmpty
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: day.exercises.isEmpty
                                      ? null
                                      : () {
                                          HapticFeedback.lightImpact();
                                          _startTraining(context, index);
                                        },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.play_arrow,
                                          color: day.exercises.isEmpty
                                              ? Colors.grey[500]
                                              : Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Start',
                                          style: TextStyle(
                                            color: day.exercises.isEmpty
                                                ? Colors.grey[500]
                                                : Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEditPlan(BuildContext context) {
    final createProvider =
        Provider.of<CreateTrainingPlanProvider>(context, listen: false);

    createProvider.skipToEditor(widget.plan);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: createProvider,
          child: const TrainingDayEditorScreen(),
        ),
      ),
    );
  }

  void _startTraining(BuildContext context, int dayIndex) {
    if (widget.plan.days[dayIndex].exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Keine Übungen für diesen Tag definiert.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final plansProvider =
        Provider.of<TrainingPlansProvider>(context, listen: false);
    final currentWeekIndex =
        widget.plan.isPeriodized ? plansProvider.currentWeekIndex : 0;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ChangeNotifierProvider(
            create: (context) => TrainingSessionProvider(),
            child: TrainingSessionScreen(
              trainingPlan: widget.plan,
              dayIndex: dayIndex,
              weekIndex: currentWeekIndex,
            ),
          );
        },
      ),
    );
  }
}