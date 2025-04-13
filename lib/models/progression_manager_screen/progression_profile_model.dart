import 'progression_rule_model.dart';

class ProgressionProfileModel {
  final String id;
  String name;
  String description;
  Map<String, dynamic> config;
  List<ProgressionRuleModel> rules;

  ProgressionProfileModel({
    required this.id,
    required this.name,
    required this.description,
    required this.config,
    required this.rules,
  });

  ProgressionProfileModel copyWith({
    String? id,
    String? name,
    String? description,
    Map<String, dynamic>? config,
    List<ProgressionRuleModel>? rules,
  }) {
    return ProgressionProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      config: config ?? Map.from(this.config),
      rules: rules ?? List.from(this.rules),
    );
  }

  factory ProgressionProfileModel.empty(String id) {
    return ProgressionProfileModel(
      id: id,
      name: 'Neues Profil',
      description: 'Benutzerdefiniertes Progressionsprofil',
      config: {
        'targetRepsMin': 8,
        'targetRepsMax': 10,
        'targetRIRMin': 1,
        'targetRIRMax': 2,
        'increment': 2.5,
      },
      rules: [],
    );
  }
}
