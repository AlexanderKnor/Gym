class ProgressionConditionModel {
  Map<String, dynamic> left;
  String operator;
  Map<String, dynamic> right;

  ProgressionConditionModel({
    required this.left,
    required this.operator,
    required this.right,
  });

  ProgressionConditionModel copyWith({
    Map<String, dynamic>? left,
    String? operator,
    Map<String, dynamic>? right,
  }) {
    return ProgressionConditionModel(
      left: left ?? Map.from(this.left),
      operator: operator ?? this.operator,
      right: right ?? Map.from(this.right),
    );
  }

  factory ProgressionConditionModel.defaultCondition() {
    return ProgressionConditionModel(
      left: {'type': 'variable', 'value': 'lastReps'},
      operator: 'lt',
      right: {'type': 'constant', 'value': 10},
    );
  }
}
