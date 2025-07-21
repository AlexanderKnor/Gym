// lib/models/training_plan_screen/training_plan_model.dart
import 'training_day_model.dart';
import 'periodization_model.dart';

class TrainingPlanModel {
  final String id;
  String name;
  List<TrainingDayModel> days;
  bool isActive;

  // Optional gym field
  String? gym;

  // Neue Felder für Periodisierung
  bool isPeriodized;
  int numberOfWeeks;
  PeriodizationModel? periodization;

  TrainingPlanModel({
    required this.id,
    required this.name,
    required this.days,
    this.isActive = false,
    this.gym,
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
    String? gym,
    bool? isPeriodized,
    int? numberOfWeeks,
    PeriodizationModel? periodization,
  }) {
    return TrainingPlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      days: days ?? this.days,
      isActive: isActive ?? this.isActive,
      gym: gym ?? this.gym,
      isPeriodized: isPeriodized ?? this.isPeriodized,
      numberOfWeeks: numberOfWeeks ?? this.numberOfWeeks,
      periodization: periodization ?? this.periodization,
    );
  }

  // Methode zum Konvertieren in Map für Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'days': days.map((day) => day.toMap()).toList(),
      'isActive': isActive,
      'gym': gym,
      'isPeriodized': isPeriodized,
      'numberOfWeeks': numberOfWeeks,
      'periodization': periodization?.toMap(),
    };
  }

  // Alias für JSON-Serialisierung
  Map<String, dynamic> toJson() => toMap();

  // Factory-Methode zum Erstellen aus Map von Firestore
  factory TrainingPlanModel.fromMap(Map<String, dynamic> map) {
    return TrainingPlanModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      days: (map['days'] as List?)
              ?.map((day) =>
                  TrainingDayModel.fromMap(day as Map<String, dynamic>))
              .toList() ??
          [],
      isActive: map['isActive'] ?? false,
      gym: map['gym'],
      isPeriodized: map['isPeriodized'] ?? false,
      numberOfWeeks: map['numberOfWeeks'] ?? 1,
      periodization: map['periodization'] != null
          ? PeriodizationModel.fromMap(
              map['periodization'] as Map<String, dynamic>)
          : null,
    );
  }

  // Alias für JSON-Deserialisierung
  factory TrainingPlanModel.fromJson(Map<String, dynamic> json) => TrainingPlanModel.fromMap(json);

  // Factory-Methode für neuen Plan
  factory TrainingPlanModel.create(String name, int frequency, {String? gym}) {
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
      gym: gym,
    );
  }

  // Neue Factory-Methode für periodisierten Plan
  factory TrainingPlanModel.createPeriodized(
      String name, int frequency, int weeks, {String? gym}) {
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
      gym: gym,
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
