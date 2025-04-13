import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/progression_manager_screen/progression_manager_provider.dart';

class ProfileEditorDialog extends StatelessWidget {
  const ProfileEditorDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);
    final profil = provider.bearbeitetesProfil;

    if (profil == null) {
      return const SizedBox();
    }

    return Stack(
      children: [
        // Abgedunkelter Hintergrund
        GestureDetector(
          onTap: provider.closeProfileEditor,
          child: Container(
            color: Colors.black.withOpacity(0.5),
          ),
        ),

        // Dialog
        Center(
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Profil bearbeiten: ${profil.name}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: provider.closeProfileEditor,
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Profilname
                  const Text(
                    'Profilname',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: TextEditingController(text: profil.name),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Name des Progressionsprofils',
                    ),
                    onChanged: (value) => provider.updateProfile('name', value),
                  ),
                  const SizedBox(height: 16),

                  // Beschreibung
                  const Text(
                    'Beschreibung',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: TextEditingController(text: profil.description),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Kurze Beschreibung des Profils',
                    ),
                    minLines: 2,
                    maxLines: 3,
                    onChanged: (value) =>
                        provider.updateProfile('description', value),
                  ),
                  const SizedBox(height: 16),

                  // Konfiguration
                  const Text(
                    'Standard-Konfiguration',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 5,
                    shrinkWrap: true,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildConfigItem(
                        context,
                        'Min. Wiederholungen',
                        profil.config['targetRepsMin'].toString(),
                        (value) => provider.updateProfile(
                            'config.targetRepsMin', value),
                      ),
                      _buildConfigItem(
                        context,
                        'Max. Wiederholungen',
                        profil.config['targetRepsMax'].toString(),
                        (value) => provider.updateProfile(
                            'config.targetRepsMax', value),
                      ),
                      _buildConfigItem(
                        context,
                        'Min. RIR',
                        profil.config['targetRIRMin'].toString(),
                        (value) => provider.updateProfile(
                            'config.targetRIRMin', value),
                      ),
                      _buildConfigItem(
                        context,
                        'Max. RIR',
                        profil.config['targetRIRMax'].toString(),
                        (value) => provider.updateProfile(
                            'config.targetRIRMax', value),
                      ),
                      _buildConfigItem(
                        context,
                        'Gewichtssteigerung (kg)',
                        profil.config['increment'].toString(),
                        (value) =>
                            provider.updateProfile('config.increment', value),
                        step: 0.5,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: provider.closeProfileEditor,
                        child: const Text('Abbrechen'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: provider.saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                        ),
                        child: const Text('Profil speichern'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigItem(BuildContext context, String label, String value,
      Function(String) onChanged,
      {double step = 1.0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: value),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
