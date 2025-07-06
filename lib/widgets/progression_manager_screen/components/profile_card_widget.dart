import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/progression_manager_screen/progression_manager_provider.dart';

class ProfileCardWidget extends StatelessWidget {
  final dynamic profile;
  final VoidCallback onTap;
  final VoidCallback onDemo;
  final bool isStandardProfile;

  const ProfileCardWidget({
    Key? key,
    required this.profile,
    required this.onTap,
    required this.onDemo,
    this.isStandardProfile = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Prüfen, ob es ein Standard-Profil ist
    final bool isSystemProfile = _isStandardProfile(profile.id);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSystemProfile ? Colors.blue[200]! : Colors.purple[200]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profil-Header mit Namen und Typ-Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 24,
                        color: isSystemProfile
                            ? Colors.blue[700]
                            : Colors.purple[700],
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSystemProfile
                                  ? Colors.blue[50]
                                  : Colors.purple[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isSystemProfile
                                  ? 'Standardprofil'
                                  : 'Benutzerdefiniert',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSystemProfile
                                    ? Colors.blue[800]
                                    : Colors.purple[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Löschbutton - nur für benutzerdefinierte Profile anzeigen
                      if (!isSystemProfile)
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Colors.red[700],
                          ),
                          tooltip: 'Löschen',
                          onPressed: () =>
                              _confirmDeleteProfile(context, profile),
                        ),
                      IconButton(
                        onPressed: onTap,
                        icon: const Icon(Icons.edit),
                        tooltip: 'Bearbeiten',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Beschreibung
              Text(
                profile.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // Konfiguration
              Row(
                children: [
                  _buildConfigItem(
                    context,
                    'Wiederholungen',
                    '${_formatInteger(profile.config['targetRepsMin'])}-${_formatInteger(profile.config['targetRepsMax'])}',
                    Icons.repeat,
                  ),
                  _buildConfigItem(
                    context,
                    'RIR',
                    '${_formatInteger(profile.config['targetRIRMin'])}-${_formatInteger(profile.config['targetRIRMax'])}',
                    Icons.battery_5_bar,
                  ),
                  _buildConfigItem(
                    context,
                    'Steigerung',
                    '${_formatNumber(profile.config['increment'])}kg',
                    Icons.fitness_center,
                  ),
                  // Regelanzahl
                  _buildConfigItem(
                    context,
                    'Regeln',
                    '${profile.rules.length}',
                    Icons.rule,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Demo-Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onDemo,
                  icon: const Icon(Icons.science),
                  label: const Text('Demo testen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isSystemProfile ? Colors.blue : Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Hilfsmethode zum Identifizieren von Standard-Profilen
  bool _isStandardProfile(String profileId) {
    return profileId == 'double-progression' ||
        profileId == 'linear-periodization' ||
        profileId == 'rir-based' ||
        profileId == 'set-consistency';
  }

  // Bestätigungsdialog zum Löschen des Profils
  void _confirmDeleteProfile(BuildContext context, dynamic profile) {
    final provider =
        Provider.of<ProgressionManagerProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil löschen'),
        content:
            Text('Möchtest du das Profil "${profile.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await provider.deleteProfile(profile.id);
              // Nach dem Löschen werden die Profile automatisch aktualisiert
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

// Helper functions for number formatting
String _formatInteger(dynamic value) {
  if (value == null) return '0';
  if (value is int) return value.toString();
  if (value is double) return value.toInt().toString();
  return value.toString();
}

String _formatNumber(dynamic value) {
  if (value == null) return '0';
  if (value is int) return value.toString();
  if (value is double) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
  return value.toString();
}
