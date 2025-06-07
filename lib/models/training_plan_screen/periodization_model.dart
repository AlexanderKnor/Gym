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

  // Alias für JSON-Serialisierung
  Map<String, dynamic> toJson() => toMap();

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

  // Alias für JSON-Deserialisierung
  factory PeriodizationModel.fromJson(Map<String, dynamic> json) => PeriodizationModel.fromMap(json);
}

class MicrocycleConfiguration {
  final int numberOfSets;
  final int repRangeMin; // Neues Feld
  final int repRangeMax; // Neues Feld
  final int rirRangeMin; // Neues Feld
  final int rirRangeMax; // Neues Feld
  final String? progressionProfileId;

  MicrocycleConfiguration({
    required this.numberOfSets,
    this.repRangeMin = 8, // Standardwert
    this.repRangeMax = 12, // Standardwert
    this.rirRangeMin = 1, // Standardwert
    this.rirRangeMax = 3, // Standardwert
    this.progressionProfileId,
  });

  // Copy-Methode
  MicrocycleConfiguration copyWith({
    int? numberOfSets,
    int? repRangeMin,
    int? repRangeMax,
    int? rirRangeMin,
    int? rirRangeMax,
    String? progressionProfileId,
  }) {
    return MicrocycleConfiguration(
      numberOfSets: numberOfSets ?? this.numberOfSets,
      repRangeMin: repRangeMin ?? this.repRangeMin,
      repRangeMax: repRangeMax ?? this.repRangeMax,
      rirRangeMin: rirRangeMin ?? this.rirRangeMin,
      rirRangeMax: rirRangeMax ?? this.rirRangeMax,
      progressionProfileId: progressionProfileId ?? this.progressionProfileId,
    );
  }

  // JSON-Konvertierung
  Map<String, dynamic> toMap() {
    return {
      'numberOfSets': numberOfSets,
      'repRangeMin': repRangeMin,
      'repRangeMax': repRangeMax,
      'rirRangeMin': rirRangeMin,
      'rirRangeMax': rirRangeMax,
      'progressionProfileId': progressionProfileId,
    };
  }

  // Alias für JSON-Serialisierung
  Map<String, dynamic> toJson() => toMap();

  // Aus JSON erstellen
  factory MicrocycleConfiguration.fromMap(Map<String, dynamic> map) {
    return MicrocycleConfiguration(
      numberOfSets: map['numberOfSets'] ?? 3,
      repRangeMin: map['repRangeMin'] ?? 8,
      repRangeMax: map['repRangeMax'] ?? 12,
      rirRangeMin: map['rirRangeMin'] ?? 1,
      rirRangeMax: map['rirRangeMax'] ?? 3,
      progressionProfileId: map['progressionProfileId'],
    );
  }

  // Alias für JSON-Deserialisierung
  factory MicrocycleConfiguration.fromJson(Map<String, dynamic> json) => MicrocycleConfiguration.fromMap(json);
}
