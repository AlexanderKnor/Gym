import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/progression_manager_screen/progression_manager_provider.dart';

class ProfileSelectorWidget extends StatelessWidget {
  const ProfileSelectorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);
    final currentDemoProfile = provider.aktuellesProfil;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profil für Demo-Übung',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: provider.progressionsProfile.length,
          itemBuilder: (context, index) {
            final profil = provider.progressionsProfile[index];
            final isSelected = currentDemoProfile != null &&
                profil.id == currentDemoProfile.id;

            return InkWell(
              onTap: () => provider.setDemoProfileId(profil.id),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.purple[100] : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.purple[500]! : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      profil.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.purple[800] : Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profil.description,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () => provider.openProfileEditor(null),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Neues Profil'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green[700],
                backgroundColor: Colors.green[50],
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                final aktuellesProfil = provider.aktuellesProfil;
                if (aktuellesProfil != null) {
                  provider.duplicateProfile(aktuellesProfil.id);
                }
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Aktuelles Profil duplizieren'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue[700],
                backgroundColor: Colors.blue[50],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
