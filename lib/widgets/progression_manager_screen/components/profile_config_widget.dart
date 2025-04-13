import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/progression_manager_screen/progression_manager_provider.dart';

class ProfileConfigWidget extends StatelessWidget {
  const ProfileConfigWidget({Key? key}) : super(key: key);

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
        Text(
          'Konfiguration: ${profil.name}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
              provider.progressionsConfig['targetRepsMin'].toString(),
              (value) => provider.handleConfigChange('targetRepsMin', value),
            ),
            _buildConfigItem(
              context,
              'Max. Wiederholungen',
              provider.progressionsConfig['targetRepsMax'].toString(),
              (value) => provider.handleConfigChange('targetRepsMax', value),
            ),
            _buildConfigItem(
              context,
              'Min. RIR',
              provider.progressionsConfig['targetRIRMin'].toString(),
              (value) => provider.handleConfigChange('targetRIRMin', value),
            ),
            _buildConfigItem(
              context,
              'Max. RIR',
              provider.progressionsConfig['targetRIRMax'].toString(),
              (value) => provider.handleConfigChange('targetRIRMax', value),
            ),
            _buildConfigItem(
              context,
              'Gewichtssteigerung (kg)',
              provider.progressionsConfig['increment'].toString(),
              (value) => provider.handleConfigChange('increment', value),
              step: 0.5,
            ),
          ],
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
