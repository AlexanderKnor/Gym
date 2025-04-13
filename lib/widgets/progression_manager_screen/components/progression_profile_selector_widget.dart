import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/progression_manager_screen/progression_manager_provider.dart';

class ProgressionProfileSelectorWidget extends StatelessWidget {
  const ProgressionProfileSelectorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progressionsprofile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),

        // Profile als ListView
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.progressionsProfile.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey[300]),
            itemBuilder: (context, index) {
              final profil = provider.progressionsProfile[index];
              final isSelected =
                  profil.id == provider.aktivesProgressionsProfil;
              final isStandardProfile = _isStandardProfile(profil.id);

              return ListTile(
                onTap: () => provider.wechsleProgressionsProfil(profil.id),
                selected: isSelected,
                selectedTileColor: Colors.purple[50],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                dense: true,
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? Colors.purple : Colors.grey,
                ),
                title: Text(
                  profil.name,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.purple[800] : Colors.black,
                  ),
                ),
                subtitle: Text(
                  profil.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                trailing: isStandardProfile
                    ? null // Keine Lösch-Option für Standard-Profile
                    : IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: () => _confirmDeleteProfile(
                            context, provider, profil.id, profil.name),
                        color: Colors.red[700],
                      ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Profile-Management Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => provider.openProfileEditor(null),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Neues Profil'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green[700],
                  side: BorderSide(color: Colors.green[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  final aktivesProfilId = provider.aktivesProgressionsProfil;
                  provider.duplicateProfile(aktivesProfilId);
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Duplizieren'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  side: BorderSide(color: Colors.blue[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Überprüft, ob es ein Standard-Profil ist
  bool _isStandardProfile(String profileId) {
    return profileId == 'double-progression' ||
        profileId == 'linear-periodization' ||
        profileId == 'rir-based' ||
        profileId == 'set-consistency';
  }

  // Bestätigungsdialog zum Löschen des Profils
  void _confirmDeleteProfile(
      BuildContext context,
      ProgressionManagerProvider provider,
      String profileId,
      String profileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil löschen'),
        content:
            Text('Möchtest du das Profil "$profileName" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteProfile(profileId);
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
