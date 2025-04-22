// lib/widgets/friend_profile_screen/friend_progression_profiles_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/friend_profile_screen/friend_profile_provider.dart';
import '../../models/progression_manager_screen/progression_profile_model.dart';

class FriendProgressionProfilesWidget extends StatelessWidget {
  const FriendProgressionProfilesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FriendProfileProvider>(context);
    final profiles = provider.progressionProfiles;
    final activeProfileId = provider.activeProfileId;

    if (profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Progressionsprofile verfügbar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dein Freund hat noch keine Progressionsprofile erstellt',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progressionsprofile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return _buildProfileCard(
                    context, profile, profile.id == activeProfileId);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
      BuildContext context, ProgressionProfileModel profile, bool isActive) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      color: isActive ? Colors.purple[50] : null,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.purple : Colors.grey[300],
          child: Icon(
            Icons.trending_up,
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                profile.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.purple[800] : null,
                ),
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'AKTIV',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(
            profile.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Kopier-Button
            ElevatedButton.icon(
              onPressed: () => _copyProfile(context, profile),
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Kopieren'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _showProfileDetails(context, profile),
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? Colors.purple : Colors.grey[200],
                foregroundColor: isActive ? Colors.white : Colors.black87,
              ),
              child: const Text('Details'),
            ),
          ],
        ),
        onTap: () => _showProfileDetails(context, profile),
      ),
    );
  }

  // Überarbeitete Kopier-Funktion mit verbesserter Dialog-Verwaltung
  void _copyProfile(
      BuildContext context, ProgressionProfileModel profile) async {
    final provider = Provider.of<FriendProfileProvider>(context, listen: false);

    // Dialog-Kontext zur späteren Verwendung merken
    BuildContext? dialogContext;

    // Zeige Ladeanzeige mit Barrier
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        dialogContext = context;
        return WillPopScope(
          onWillPop: () async => false,
          child: const AlertDialog(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Profil wird kopiert...'),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Versuche, das Profil zu kopieren
      final success = await provider.copyProfileToOwnCollection(profile);

      // Dialog schließen - hier mit verbesserten Sicherheitschecks
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!).pop();
      }

      // Kurze Verzögerung, um sicherzustellen, dass der Dialog vollständig geschlossen wurde
      await Future.delayed(const Duration(milliseconds: 200));

      // Nur einen neuen Dialog anzeigen, wenn der Kontext noch gültig ist
      if (context.mounted) {
        if (success) {
          // Erfolg
          _showSuccessDialog(context, profile);
        } else {
          // Fehler
          _showErrorDialog(
              context, provider.errorMessage ?? 'Unbekannter Fehler');
        }
      }
    } catch (e) {
      // Exception abfangen, Dialog schließen und Fehlermeldung anzeigen
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!).pop();
      }

      await Future.delayed(const Duration(milliseconds: 200));

      if (context.mounted) {
        _showErrorDialog(context, e.toString());
      }
    }
  }

  // Erfolgs-Dialog anzeigen
  void _showSuccessDialog(
      BuildContext context, ProgressionProfileModel profile) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Erfolgreich kopiert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Das Progressionsprofil "${profile.name}" wurde erfolgreich in deine Sammlung kopiert.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Fehler-Dialog anzeigen
  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Fehler'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Beim Kopieren ist ein Fehler aufgetreten:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(errorMessage),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showProfileDetails(
      BuildContext context, ProgressionProfileModel profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          profile.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          profile.id == profile.id ? 'AKTIV' : 'PROFIL',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile.description,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Kopier-Button im Detail-Bereich
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // Schließe Details
                            _copyProfile(
                                context, profile); // Starte Kopier-Prozess
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('In meine Sammlung kopieren'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Konfiguration
                  const Text(
                    'Konfiguration',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    color: Colors.purple[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          _buildConfigDetailItem(
                            'Wiederholungsbereich',
                            '${profile.config['targetRepsMin'] ?? 0} - ${profile.config['targetRepsMax'] ?? 0} Wdh.',
                            Icons.repeat,
                          ),
                          const SizedBox(height: 12),
                          _buildConfigDetailItem(
                            'RIR-Bereich',
                            '${profile.config['targetRIRMin'] ?? 0} - ${profile.config['targetRIRMax'] ?? 0} RIR',
                            Icons.battery_5_bar,
                          ),
                          const SizedBox(height: 12),
                          _buildConfigDetailItem(
                            'Gewichtssteigerung',
                            '${profile.config['increment'] ?? 0} kg',
                            Icons.fitness_center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Regeln
                  const Text(
                    'Progressionsregeln',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  profile.rules.isEmpty
                      ? Card(
                          elevation: 0,
                          color: Colors.grey[100],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'Keine Regeln definiert',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            for (int i = 0; i < profile.rules.length; i++) ...[
                              _buildRuleCard(profile.rules[i], i + 1),
                              if (i < profile.rules.length - 1)
                                const SizedBox(height: 8),
                            ],
                          ],
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfigDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.purple[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.purple[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRuleCard(rule, int index) {
    final ruleType = rule.type;

    return Card(
      elevation: 0,
      color: ruleType == 'condition' ? Colors.blue[50] : Colors.green[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor:
                      ruleType == 'condition' ? Colors.blue : Colors.green,
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ruleType == 'condition' ? Colors.blue : Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ruleType == 'condition' ? 'BEDINGUNG' : 'ZUWEISUNG',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Bedingungen und Aktionen
            if (ruleType == 'condition' && rule.conditions.isNotEmpty) ...[
              const Text(
                'Wenn:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              for (int i = 0; i < rule.conditions.length; i++) ...[
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      if (i > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            rule.logicalOperator,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          _buildConditionText(rule.conditions[i]),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            if (rule.children.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Dann:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              for (final action in rule.children) ...[
                if (action.type == 'assignment') ...[
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: _getTargetColor(action.target)[0],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getTargetLabel(action.target),
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: _getTargetColor(action.target)[1],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '= ${_renderValueNode(action.value)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _buildConditionText(condition) {
    final leftLabel = _getVariableLabel(condition.left['value']);
    final operatorLabel = _getOperatorLabel(condition.operator);
    final rightLabel = condition.right['type'] == 'variable'
        ? _getVariableLabel(condition.right['value'])
        : condition.right['value'].toString();

    return '$leftLabel $operatorLabel $rightLabel';
  }

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

  String _getTargetLabel(String target) {
    switch (target) {
      case 'kg':
        return 'GEWICHT';
      case 'reps':
        return 'WIEDERHOLUNGEN';
      case 'rir':
        return 'RIR';
      default:
        return target.toUpperCase();
    }
  }

  String _getVariableLabel(String variableId) {
    final labels = {
      'lastKg': 'Letztes Gewicht',
      'lastReps': 'Letzte Wiederholungen',
      'lastRIR': 'Letzter RIR',
      'last1RM': 'Letzter 1RM',
      'previousKg': 'Vorheriges Gewicht',
      'previousReps': 'Vorherige Wiederholungen',
      'previousRIR': 'Vorheriger RIR',
      'previous1RM': 'Vorheriger 1RM',
      'targetRepsMin': 'Ziel Wdh. Min',
      'targetRepsMax': 'Ziel Wdh. Max',
      'targetRIRMin': 'Ziel RIR Min',
      'targetRIRMax': 'Ziel RIR Max',
      'increment': 'Std. Steigerung',
    };

    return labels[variableId] ?? variableId;
  }

  String _getOperatorLabel(String operatorId) {
    final operators = {
      'eq': '=',
      'gt': '>',
      'lt': '<',
      'gte': '>=',
      'lte': '<=',
      'add': '+',
      'subtract': '-',
      'multiply': '*',
    };

    return operators[operatorId] ?? operatorId;
  }

  String _renderValueNode(Map<String, dynamic> node) {
    if (node == null) return '';

    switch (node['type']) {
      case 'variable':
        return _getVariableLabel(node['value']);
      case 'constant':
        return node['value'].toString();
      case 'operation':
        return '${_renderValueNode(node['left'])} ${_getOperatorLabel(node['operator'])} ${_renderValueNode(node['right'])}';
      case 'oneRM':
        return '1RM +${node['percentage']}% (nach Epley-Formel)';
      default:
        return 'Unbekannter Wert';
    }
  }
}
