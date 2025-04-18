import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../widgets/progression_manager_screen/components/progression_profile_selector_widget.dart';
import '../../widgets/progression_manager_screen/components/rule_list_widget.dart';
import '../../screens/progression_manager_screen/rule_editor_screen.dart';
import '../../screens/progression_manager_screen/profile_editor_screen.dart';

class ProgressionManagerDetailScreen extends StatelessWidget {
  final ProgressionManagerProvider provider;

  const ProgressionManagerDetailScreen({
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Provider als Dependency bereitstellen, aber keine neue Instanz erstellen
    return ChangeNotifierProvider.value(
      value: provider,
      child: const ProgressionManagerDetailScreenContent(),
    );
  }
}

class ProgressionManagerDetailScreenContent extends StatelessWidget {
  const ProgressionManagerDetailScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);
    final profil = provider.aktuellesProfil;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detaillierter Progression Manager'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: provider.zeigeRegelEditor || provider.zeigeProfilEditor
          ? _buildEditorScreen(context, provider)
          : _buildDetailScreen(context, provider, profil),
    );
  }

  Widget _buildDetailScreen(BuildContext context,
      ProgressionManagerProvider provider, dynamic profil) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Über den Progression Manager" Card wurde entfernt

          // Profilauswahl
          const Text(
            'Progressionsprofile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const ProgressionProfileSelectorWidget(),
          const SizedBox(height: 24),

          // Profilkonfiguration - nur anzeigen wenn ein Profil ausgewählt ist
          if (profil != null) ...[
            _buildProfileConfigSummary(context, provider, profil),
            const SizedBox(height: 24),

            // Regelliste
            const Text(
              'Progressionsregeln',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const RuleListWidget(),
          ],
        ],
      ),
    );
  }

  Widget _buildEditorScreen(
      BuildContext context, ProgressionManagerProvider provider) {
    if (provider.zeigeRegelEditor) {
      return const RuleEditorScreen();
    } else if (provider.zeigeProfilEditor) {
      return const ProfileEditorScreen();
    }
    return const SizedBox.shrink();
  }

  Widget _buildProfileConfigSummary(BuildContext context,
      ProgressionManagerProvider provider, dynamic profil) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Profilkonfiguration',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                final provider = Provider.of<ProgressionManagerProvider>(
                    context,
                    listen: false);
                provider.openProfileEditor(profil);
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Bearbeiten'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profil.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profil.description,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _buildConfigRow(
                  'Wiederholungen:',
                  '${profil.config['targetRepsMin']} - ${profil.config['targetRepsMax']} Wdh.',
                ),
                const SizedBox(height: 8),
                _buildConfigRow(
                  'RIR-Bereich:',
                  '${profil.config['targetRIRMin']} - ${profil.config['targetRIRMax']} RIR',
                ),
                const SizedBox(height: 8),
                _buildConfigRow(
                  'Steigerung:',
                  '${profil.config['increment']} kg',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
