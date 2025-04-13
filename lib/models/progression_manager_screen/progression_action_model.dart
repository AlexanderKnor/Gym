class ProgressionActionModel {
  final String id;
  String type; // 'assignment'
  String target; // 'kg', 'reps', 'rir'
  Map<String, dynamic> value;

  ProgressionActionModel({
    required this.id,
    required this.type,
    required this.target,
    required this.value,
  });

  ProgressionActionModel copyWith({
    String? id,
    String? type,
    String? target,
    Map<String, dynamic>? value,
  }) {
    return ProgressionActionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      target: target ?? this.target,
      value: value ?? Map.from(this.value),
    );
  }

  factory ProgressionActionModel.kg(String id,
      {required Map<String, dynamic> value}) {
    return ProgressionActionModel(
      id: id,
      type: 'assignment',
      target: 'kg',
      value: value,
    );
  }

  factory ProgressionActionModel.reps(String id,
      {required Map<String, dynamic> value}) {
    return ProgressionActionModel(
      id: id,
      type: 'assignment',
      target: 'reps',
      value: value,
    );
  }

  factory ProgressionActionModel.rir(String id,
      {required Map<String, dynamic> value}) {
    return ProgressionActionModel(
      id: id,
      type: 'assignment',
      target: 'rir',
      value: value,
    );
  }
}
