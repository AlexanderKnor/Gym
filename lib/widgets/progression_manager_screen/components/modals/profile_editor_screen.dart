import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/progression_manager_screen/progression_manager_provider.dart';

class ProfileEditorScreen extends StatelessWidget {
  const ProfileEditorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);
    final profil = provider.bearbeitetesProfil;

    if (profil == null) {
      return const SizedBox();
    }

    return WillPopScope(
      onWillPop: () async {
        provider.closeProfileEditor();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            profil.id.contains('profile_')
                ? 'Neues Profil erstellen'
                : 'Profil bearbeiten',
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: provider.closeProfileEditor,
          ),
          actions: [
            TextButton.icon(
              onPressed: provider.saveProfile,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Speichern',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoSection(context, provider, profil),
                const SizedBox(height: 24),
                _buildConfigSection(context, provider, profil),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(BuildContext context,
      ProgressionManagerProvider provider, dynamic profil) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Grundinformationen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name
            const Text(
              'Profilname',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: TextEditingController(text: profil.name),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Name des Progressionsprofils',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (value) => provider.updateProfile('name', value),
            ),
            const SizedBox(height: 16),

            // Beschreibung
            const Text(
              'Beschreibung',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: TextEditingController(text: profil.description),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Kurze Beschreibung des Profils',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              minLines: 2,
              maxLines: 3,
              onChanged: (value) =>
                  provider.updateProfile('description', value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSection(BuildContext context,
      ProgressionManagerProvider provider, dynamic profil) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Konfiguration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Diese Standardwerte werden verwendet, um die Progression zu berechnen:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Wiederholungen
            _buildConfigRow(
              context,
              'Wiederholungsbereich',
              [
                _buildConfigField(
                  context,
                  'Min',
                  profil.config['targetRepsMin'].toString(),
                  (value) =>
                      provider.updateProfile('config.targetRepsMin', value),
                ),
                _buildConfigField(
                  context,
                  'Max',
                  profil.config['targetRepsMax'].toString(),
                  (value) =>
                      provider.updateProfile('config.targetRepsMax', value),
                ),
              ],
              Icons.repeat,
            ),
            const SizedBox(height: 16),

            // RIR
            _buildConfigRow(
              context,
              'RIR-Bereich (Reps in Reserve)',
              [
                _buildConfigField(
                  context,
                  'Min',
                  profil.config['targetRIRMin'].toString(),
                  (value) =>
                      provider.updateProfile('config.targetRIRMin', value),
                ),
                _buildConfigField(
                  context,
                  'Max',
                  profil.config['targetRIRMax'].toString(),
                  (value) =>
                      provider.updateProfile('config.targetRIRMax', value),
                ),
              ],
              Icons.battery_5_bar,
            ),
            const SizedBox(height: 16),

            // Gewichtssteigerung
            _buildConfigRow(
              context,
              'Gewichtssteigerung (kg)',
              [
                Expanded(
                  child: _buildConfigField(
                    context,
                    'Wert',
                    profil.config['increment'].toString(),
                    (value) =>
                        provider.updateProfile('config.increment', value),
                    suffix: 'kg',
                  ),
                ),
                const Spacer(),
              ],
              Icons.fitness_center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigRow(
    BuildContext context,
    String label,
    List<Widget> children,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: children,
        ),
      ],
    );
  }

  Widget _buildConfigField(BuildContext context, String label, String value,
      Function(String) onChanged,
      {String suffix = ''}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: TextEditingController(text: value),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
              suffixText: suffix.isNotEmpty ? suffix : null,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
