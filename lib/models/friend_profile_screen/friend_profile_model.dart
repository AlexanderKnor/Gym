import '../../models/training_plan_screen/training_plan_model.dart';
import '../../models/progression_manager_screen/progression_profile_model.dart';
import '../../models/profile_screen/friendship_model.dart';

class FriendProfileModel {
  final FriendshipModel friendship;
  final List<TrainingPlanModel> trainingPlans;
  final List<ProgressionProfileModel> progressionProfiles;

  FriendProfileModel({
    required this.friendship,
    required this.trainingPlans,
    required this.progressionProfiles,
  });
}
