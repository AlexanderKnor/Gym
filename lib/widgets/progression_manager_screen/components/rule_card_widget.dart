import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/progression_manager_screen/progression_rule_model.dart';
import '../../../providers/progression_manager_screen/progression_manager_provider.dart';

class RuleCardWidget extends StatelessWidget {
  final ProgressionRuleModel rule;
  final int index;

  const RuleCardWidget({
    Key? key,
    required this.rule,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);

    return Container(
      margin: EdgeInsets.only(
          bottom: index < provider.aktuellesProfil!.rules.length - 1 ? 1 : 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: index < provider.aktuellesProfil!.rules.length - 1
              ? BorderSide(color: Colors.grey[300]!)
              : BorderSide.none,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
        ),
        title: _buildRuleContent(context, provider),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => provider.openRuleEditor(rule),
              tooltip: 'Bearbeiten',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 18),
              onPressed: () => _confirmDeleteRule(context, provider),
              tooltip: 'Löschen',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
              color: Colors.red[700],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleContent(
      BuildContext context, ProgressionManagerProvider provider) {
    if (rule.type == 'condition') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wenn-Teil
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'WENN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _buildConditionText(provider),
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Dann-Teil
          if (rule.children.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.purple[300]!,
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: rule.children.map((action) {
                  if (action.type != 'assignment')
                    return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            provider
                                .getTargetLabel(action.target)
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[800],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '= ${provider.renderValueNode(action.value)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      );
    } else if (rule.type == 'assignment' && rule.children.isNotEmpty) {
      final action = rule.children.first;
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'SETZE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              provider.getTargetLabel(action.target).toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '= ${provider.renderValueNode(action.value)}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      );
    }

    return const Text('Ungültige Regel');
  }

  String _buildConditionText(ProgressionManagerProvider provider) {
    if (rule.conditions.isEmpty) return 'Keine Bedingungen';

    return rule.conditions.map((condition) {
      final leftLabel = provider.getVariableLabel(condition.left['value']);
      final operatorLabel = provider.getOperatorLabel(condition.operator);
      final rightLabel = condition.right['type'] == 'variable'
          ? provider.getVariableLabel(condition.right['value'])
          : condition.right['value'].toString();

      return '$leftLabel $operatorLabel $rightLabel';
    }).join(' UND ');
  }

  void _confirmDeleteRule(
      BuildContext context, ProgressionManagerProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regel löschen'),
        content: const Text('Möchtest du diese Regel wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteRule(rule.id);
              Navigator.of(context).pop();
            },
            child: const Text('Löschen'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
