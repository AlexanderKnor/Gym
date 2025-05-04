// lib/models/training_plan_screen/periodization_model.dart

class PeriodizationModel {
  final int weeks;

  // Verschachtelte Map:
  // dayId -> exerciseId -> weekIndex -> MicrocycleConfiguration
  Map<String, Map<String, Map<int, MicrocycleConfiguration>>> dayConfigurations;

  // Startdatum des Mesozyklus (optional)
  DateTime? startDate;

  PeriodizationModel({
    required this.weeks,
    required this.dayConfigurations,
    this.startDate,
  });

  // Copy-Methode
  PeriodizationModel copyWith({
    int? weeks,
    Map<String, Map<String, Map<int, MicrocycleConfiguration>>>?
        dayConfigurations,
    DateTime? startDate,
  }) {
    return PeriodizationModel(
      weeks: weeks ?? this.weeks,
      dayConfigurations: dayConfigurations ?? this.dayConfigurations,
      startDate: startDate ?? this.startDate,
    );
  }

  // JSON-Konvertierung für Firebase
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      'weeks': weeks,
      'startDate': startDate?.toIso8601String(),
      'dayConfigurations': {},
    };

    dayConfigurations.forEach((dayId, exerciseMap) {
      map['dayConfigurations'][dayId] = {};
      exerciseMap.forEach((exerciseId, weekMap) {
        map['dayConfigurations'][dayId][exerciseId] = {};
        weekMap.forEach((weekIndex, config) {
          map['dayConfigurations'][dayId][exerciseId][weekIndex.toString()] =
              config.toMap();
        });
      });
    });

    return map;
  }

  // Aus JSON erstellen
  factory PeriodizationModel.fromMap(Map<String, dynamic> map) {
    final dayConfigs =
        <String, Map<String, Map<int, MicrocycleConfiguration>>>{};

    if (map['dayConfigurations'] != null) {
      (map['dayConfigurations'] as Map<String, dynamic>)
          .forEach((dayId, exerciseMap) {
        dayConfigs[dayId] = {};
        (exerciseMap as Map<String, dynamic>).forEach((exerciseId, weekMap) {
          dayConfigs[dayId]![exerciseId] = {};
          (weekMap as Map<String, dynamic>).forEach((weekIndexStr, configMap) {
            final weekIndex = int.parse(weekIndexStr);
            dayConfigs[dayId]![exerciseId]![weekIndex] =
                MicrocycleConfiguration.fromMap(
                    configMap as Map<String, dynamic>);
          });
        });
      });
    }

    return PeriodizationModel(
      weeks: map['weeks'] ?? 1,
      dayConfigurations: dayConfigs,
      startDate:
          map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
    );
  }
}

class MicrocycleConfiguration {
  final int numberOfSets;
  final String? progressionProfileId;

  MicrocycleConfiguration({
    required this.numberOfSets,
    this.progressionProfileId,
  });

  // Copy-Methode
  MicrocycleConfiguration copyWith({
    int? numberOfSets,
    String? progressionProfileId,
  }) {
    return MicrocycleConfiguration(
      numberOfSets: numberOfSets ?? this.numberOfSets,
      progressionProfileId: progressionProfileId ?? this.progressionProfileId,
    );
  }

  // JSON-Konvertierung
  Map<String, dynamic> toMap() {
    return {
      'numberOfSets': numberOfSets,
      'progressionProfileId': progressionProfileId,
    };
  }

  // Aus JSON erstellen
  factory MicrocycleConfiguration.fromMap(Map<String, dynamic> map) {
    return MicrocycleConfiguration(
      numberOfSets: map['numberOfSets'] ?? 3,
      progressionProfileId: map['progressionProfileId'],
    );
  }
}
