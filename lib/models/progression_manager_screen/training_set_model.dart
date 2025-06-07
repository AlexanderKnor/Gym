// lib/models/progression_manager_screen/training_set_model.dart
class TrainingSetModel {
  final int id;
  double kg;
  int wiederholungen;
  int rir;
  bool abgeschlossen;

  // Felder für die Empfehlungswerte
  double? empfKg;
  int? empfWiederholungen;
  int? empfRir;
  bool empfehlungBerechnet = false;

  TrainingSetModel({
    required this.id,
    required this.kg,
    required this.wiederholungen,
    required this.rir,
    this.abgeschlossen = false,
    this.empfKg,
    this.empfWiederholungen,
    this.empfRir,
    this.empfehlungBerechnet = false,
  });

  TrainingSetModel copyWith({
    int? id,
    double? kg,
    int? wiederholungen,
    int? rir,
    bool? abgeschlossen,
    double? empfKg,
    int? empfWiederholungen,
    int? empfRir,
    bool? empfehlungBerechnet,
  }) {
    return TrainingSetModel(
      id: id ?? this.id,
      kg: kg ?? this.kg,
      wiederholungen: wiederholungen ?? this.wiederholungen,
      rir: rir ?? this.rir,
      abgeschlossen: abgeschlossen ?? this.abgeschlossen,
      empfKg: empfKg ?? this.empfKg,
      empfWiederholungen: empfWiederholungen ?? this.empfWiederholungen,
      empfRir: empfRir ?? this.empfRir,
      empfehlungBerechnet: empfehlungBerechnet ?? this.empfehlungBerechnet,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kg': kg,
      'wiederholungen': wiederholungen,
      'rir': rir,
      'abgeschlossen': abgeschlossen,
      'empfKg': empfKg,
      'empfWiederholungen': empfWiederholungen,
      'empfRir': empfRir,
      'empfehlungBerechnet': empfehlungBerechnet,
    };
  }

  factory TrainingSetModel.fromJson(Map<String, dynamic> json) {
    return TrainingSetModel(
      id: json['id'],
      kg: (json['kg'] ?? 0).toDouble(),
      wiederholungen: json['wiederholungen'] ?? 0,
      rir: json['rir'] ?? 0,
      abgeschlossen: json['abgeschlossen'] ?? false,
      empfKg: json['empfKg']?.toDouble(),
      empfWiederholungen: json['empfWiederholungen'],
      empfRir: json['empfRir'],
      empfehlungBerechnet: json['empfehlungBerechnet'] ?? false,
    );
  }
}
