// lib/widgets/progression_manager_screen/components/rule_list_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/progression_manager_screen/progression_manager_provider.dart';

class RuleListWidget extends StatelessWidget {
  const RuleListWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);
    final profil = provider.aktuellesProfil;

    if (profil == null) {
      return const Center(
        child: Text('Kein Profil ausgewählt'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progressionsregeln',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => provider.openRuleEditor(null),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Neue Regel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple[700],
                side: BorderSide(color: Colors.purple[300]!),
                visualDensity: VisualDensity.compact,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Leere Liste oder Regelliste
        profil.rules.isEmpty
            ? _buildEmptyRulesList()
            : _buildRuleCards(context, provider, profil),
      ],
    );
  }

  Widget _buildEmptyRulesList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.rule_folder,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          const Text(
            'Keine Regeln definiert',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Füge eine Regel hinzu, um das Progressionsverhalten zu definieren',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCards(BuildContext context,
      ProgressionManagerProvider provider, dynamic profil) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Regeln werden wie if/else-if von oben nach unten ausgewertet. Nur die erste zutreffende Regel wird angewendet.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: profil.rules.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey[300]),
            itemBuilder: (context, index) {
              final rule = profil.rules[index];

              return _buildRuleCard(
                  context, provider, rule, index, profil.rules.length);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRuleCard(
      BuildContext context,
      ProgressionManagerProvider provider,
      dynamic rule,
      int index,
      int totalRules) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => provider.openRuleEditor(rule),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Regel-Typ anzeigen
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: rule.type == 'condition'
                          ? Colors.blue[100]
                          : Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      rule.type == 'condition' ? 'WENN' : 'SETZE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: rule.type == 'condition'
                            ? Colors.blue[800]
                            : Colors.green[800],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Bearbeiten & Löschen Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Reorder Buttons - nur anzeigen wenn mehr als eine Regel
                      if (totalRules > 1) ...[
                        // Nach oben Button - nicht für erste Regel
                        if (index > 0)
                          IconButton(
                            icon: const Icon(Icons.arrow_upward, size: 18),
                            onPressed: () async {
                              await _moveRule(provider, rule, index, index - 1);
                            },
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                          ),

                        // Nach unten Button - nicht für letzte Regel
                        if (index < totalRules - 1)
                          IconButton(
                            icon: const Icon(Icons.arrow_downward, size: 18),
                            onPressed: () async {
                              await _moveRule(provider, rule, index, index + 1);
                            },
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                          ),
                      ],

                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        color: Colors.red[700],
                        onPressed: () async {
                          await _confirmDeleteRule(context, provider, rule.id);
                        },
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Regel-Inhalt
              if (rule.type == 'condition') ...[
                // Bedingungstext
                Wrap(
                  children:
                      rule.conditions.asMap().entries.map<Widget>((entry) {
                    int i = entry.key;
                    final condition = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          if (i > 0) ...[
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'UND',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                          Expanded(
                            child: Text(
                              _buildConditionText(provider, condition),
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 4),

                // Dann-Teil (Aktionen)
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
                      children: rule.children.map<Widget>((action) {
                        if (action.type != 'assignment') {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getTargetColor(action.target)[0],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  provider
                                      .getTargetLabel(action.target)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _getTargetColor(action.target)[1],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '= ${provider.renderValueNode(action.value)}',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ] else if (rule.type == 'assignment' &&
                  rule.children.isNotEmpty) ...[
                // Direkte Zuweisungen (für Typ "assignment")
                ...rule.children.map<Widget>((action) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getTargetColor(action.target)[0],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            provider
                                .getTargetLabel(action.target)
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getTargetColor(action.target)[1],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '= ${provider.renderValueNode(action.value)}',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Hilfsfunktion für Bedingungstext
  String _buildConditionText(
      ProgressionManagerProvider provider, dynamic condition) {
    final leftLabel = provider.getVariableLabel(condition.left['value']);
    final operatorLabel = provider.getOperatorLabel(condition.operator);
    final rightLabel = condition.right['type'] == 'variable'
        ? provider.getVariableLabel(condition.right['value'])
        : condition.right['value'].toString();

    return '$leftLabel $operatorLabel $rightLabel';
  }

  // Hilfsfunktion für zielbasierte Farben
  List<Color> _getTargetColor(String target) {
    switch (target) {
      case 'kg':
        return [Colors.blue[50]!, Colors.blue[800]!];
      case 'reps':
        return [Colors.purple[50]!, Colors.purple[800]!];
      case 'rir':
        return [Colors.amber[50]!, Colors.amber[800]!];
      default:
        return [Colors.grey[50]!, Colors.grey[800]!];
    }
  }

  // Regel-Reihenfolge ändern - GEÄNDERT: Jetzt async mit await für Firebase
  Future<void> _moveRule(ProgressionManagerProvider provider, dynamic rule,
      int oldIndex, int newIndex) async {
    provider.handleDragStart(rule.id);

    if (oldIndex < newIndex) {
      // Nach unten verschieben
      final targetRule = provider.aktuellesProfil!.rules[newIndex];
      await provider.handleDrop(targetRule.id);
    } else {
      // Nach oben verschieben
      final targetRule = provider.aktuellesProfil!.rules[newIndex];
      await provider.handleDrop(targetRule.id);
    }
  }

  // Bestätigungsdialog zum Löschen - GEÄNDERT: Jetzt async mit await für Firebase
  Future<void> _confirmDeleteRule(BuildContext context,
      ProgressionManagerProvider provider, String ruleId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regel löschen'),
        content: const Text('Möchtest du diese Regel wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await provider.deleteRule(ruleId);
      // Keine weiteren Aktionen nötig, da deleteRule bereits notifyListeners aufruft
    }
  }
}
