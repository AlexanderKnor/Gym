import 'training_plan_screen/training_plan_model.dart';
import 'training_plan_screen/training_day_model.dart';
import 'training_plan_screen/exercise_model.dart';
import 'training_history/training_session_model.dart';
import 'progression_manager_screen/training_set_model.dart';

class ActiveTrainingSession {
  final TrainingPlanModel trainingPlan;
  final TrainingDayModel trainingDay;
  final int dayIndex;
  final int weekIndex;

  TrainingSessionModel? currentSession;
  bool hasBeenSaved = false;
  int currentExerciseIndex = 0;
  Map<int, List<TrainingSetModel>> exerciseSets = {};
  Map<int, int> activeSetByExercise = {};
  Map<int, bool> exerciseCompletionStatus = {};
  Map<int, int> lastCompletedSetIndexByExercise = {};
  bool isResting = false;
  int restTimeRemaining = 0;
  bool isPaused = false;
  bool isTrainingCompleted = false;
  Map<int, ExerciseModel> originalExercises = {};
  Map<int, bool> exerciseConfigModified = {};
  List<ExerciseModel> addedExercises = [];
  List<ExerciseModel> deletedExercises = [];

  ActiveTrainingSession({
    required this.trainingPlan,
    required this.trainingDay,
    required this.dayIndex,
    this.weekIndex = 0,
  });
}