// lib/models/training_plan_screen/training_plan_model.dart
import 'training_day_model.dart';

class TrainingPlanModel {
  final String id;
  String name;
  List<TrainingDayModel> days;
  bool isActive;

  TrainingPlanModel({
    required this.id,
    required this.name,
    required this.days,
    this.isActive = false,
  });

  // Copy-Methode
  TrainingPlanModel copyWith({
    String? id,
    String? name,
    List<TrainingDayModel>? days,
    bool? isActive,
  }) {
    return TrainingPlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      days: days ?? this.days,
      isActive: isActive ?? this.isActive,
    );
  }

  // Factory-Methode für neuen Plan
  factory TrainingPlanModel.create(String name, int frequency) {
    final id = 'plan_${DateTime.now().millisecondsSinceEpoch}';
    final days = List<TrainingDayModel>.generate(
      frequency,
      (index) => TrainingDayModel(
        id: 'day_${DateTime.now().millisecondsSinceEpoch}_$index',
        name: 'Tag ${index + 1}',
        exercises: [],
      ),
    );

    return TrainingPlanModel(
      id: id,
      name: name,
      days: days,
    );
  }
}
