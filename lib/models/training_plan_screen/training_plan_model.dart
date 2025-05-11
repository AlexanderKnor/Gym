// lib/models/training_plan_screen/training_plan_model.dart
import 'training_day_model.dart';
import 'periodization_model.dart';

class TrainingPlanModel {
  final String id;
  String name;
  List<TrainingDayModel> days;
  bool isActive;

  // Neue Felder für Periodisierung
  bool isPeriodized;
  int numberOfWeeks;
  PeriodizationModel? periodization;

  TrainingPlanModel({
    required this.id,
    required this.name,
    required this.days,
    this.isActive = false,
    this.isPeriodized = false,
    this.numberOfWeeks = 1,
    this.periodization,
  });

  // Copy-Methode
  TrainingPlanModel copyWith({
    String? id,
    String? name,
    List<TrainingDayModel>? days,
    bool? isActive,
    bool? isPeriodized,
    int? numberOfWeeks,
    PeriodizationModel? periodization,
  }) {
    return TrainingPlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      days: days ?? this.days,
      isActive: isActive ?? this.isActive,
      isPeriodized: isPeriodized ?? this.isPeriodized,
      numberOfWeeks: numberOfWeeks ?? this.numberOfWeeks,
      periodization: periodization ?? this.periodization,
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

  // Neue Factory-Methode für periodisierten Plan
  factory TrainingPlanModel.createPeriodized(
      String name, int frequency, int weeks) {
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
      isPeriodized: true,
      numberOfWeeks: weeks,
      periodization: PeriodizationModel(
        weeks: weeks,
        dayConfigurations: {},
      ),
    );
  }

  // Erweiterte Methode zum Hinzufügen einer Mikrozyklen-Konfiguration für eine Übung
  void addExerciseMicrocycle(
      String exerciseId,
      int dayIndex,
      int weekIndex,
      int sets,
      int repRangeMin,
      int repRangeMax,
      int rirRangeMin,
      int rirRangeMax,
      String? profileId) {
    periodization ??=
        PeriodizationModel(weeks: numberOfWeeks, dayConfigurations: {});

    final dayId = days[dayIndex].id;
    if (!periodization!.dayConfigurations.containsKey(dayId)) {
      periodization!.dayConfigurations[dayId] = {};
    }

    if (!periodization!.dayConfigurations[dayId]!.containsKey(exerciseId)) {
      periodization!.dayConfigurations[dayId]![exerciseId] = {};
    }

    periodization!.dayConfigurations[dayId]![exerciseId]![weekIndex] =
        MicrocycleConfiguration(
            numberOfSets: sets,
            repRangeMin: repRangeMin,
            repRangeMax: repRangeMax,
            rirRangeMin: rirRangeMin,
            rirRangeMax: rirRangeMax,
            progressionProfileId: profileId);
  }

  // Methode zum Abrufen einer Mikrozyklen-Konfiguration für eine Übung
  MicrocycleConfiguration? getExerciseMicrocycle(
      String exerciseId, int dayIndex, int weekIndex) {
    if (periodization == null) return null;

    final dayId = days[dayIndex].id;
    if (!periodization!.dayConfigurations.containsKey(dayId)) return null;
    if (!periodization!.dayConfigurations[dayId]!.containsKey(exerciseId))
      return null;

    return periodization!.dayConfigurations[dayId]![exerciseId]![weekIndex];
  }

  // Aktuelle Woche im Plan abrufen
  int getCurrentWeek() {
    if (!isPeriodized) return 0;

    // TODO: Hier kann eine Logik implementiert werden, um die aktuelle Woche basierend auf dem Startdatum zu berechnen
    // Für jetzt geben wir einfach 0 zurück (erste Woche)
    return 0;
  }
}
