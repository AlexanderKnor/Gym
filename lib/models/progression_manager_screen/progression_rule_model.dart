import 'progression_condition_model.dart';
import 'progression_action_model.dart';

class ProgressionRuleModel {
  final String id;
  String type; // 'condition' oder 'assignment'
  List<ProgressionConditionModel> conditions;
  String logicalOperator; // 'AND' oder 'OR'
  List<ProgressionActionModel> children;

  ProgressionRuleModel({
    required this.id,
    required this.type,
    this.conditions = const [],
    this.logicalOperator = 'AND',
    this.children = const [],
  });

  ProgressionRuleModel copyWith({
    String? id,
    String? type,
    List<ProgressionConditionModel>? conditions,
    String? logicalOperator,
    List<ProgressionActionModel>? children,
  }) {
    return ProgressionRuleModel(
      id: id ?? this.id,
      type: type ?? this.type,
      conditions: conditions ?? List.from(this.conditions),
      logicalOperator: logicalOperator ?? this.logicalOperator,
      children: children ?? List.from(this.children),
    );
  }

  factory ProgressionRuleModel.ifCondition(
    String id, {
    List<ProgressionConditionModel>? conditions,
    List<ProgressionActionModel>? actions,
  }) {
    return ProgressionRuleModel(
      id: id,
      type: 'condition',
      conditions: conditions ?? [ProgressionConditionModel.defaultCondition()],
      children: actions ?? [],
    );
  }
}
