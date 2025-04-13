import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../../models/progression_manager_screen/training_set_model.dart';
import '../../../services/progression_manager_screen/one_rm_calculator_service.dart';

class SetCardWidget extends StatelessWidget {
  final TrainingSetModel satz;

  const SetCardWidget({
    Key? key,
    required this.satz,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);
    final istAktiv =
        satz.id == provider.aktiverSatz && !provider.trainingAbgeschlossen;
    final istAbgeschlossen = satz.abgeschlossen;

    // Berechne 1RM
    final einRM = satz.kg > 0 && satz.wiederholungen > 0
        ? OneRMCalculatorService.calculate1RM(
            satz.kg, satz.wiederholungen, satz.rir)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 1,
        color: istAktiv
            ? Colors.blue[50]
            : istAbgeschlossen
                ? Colors.green[50]
                : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: istAktiv
                              ? Colors.blue
                              : istAbgeschlossen
                                  ? Colors.green
                                  : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${satz.id}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        istAktiv
                            ? 'Aktueller Satz'
                            : istAbgeschlossen
                                ? 'Satz abgeschlossen'
                                : 'Satz ${satz.id}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: istAktiv
                              ? Colors.blue
                              : istAbgeschlossen
                                  ? Colors.green[700]
                                  : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (einRM > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '1RM: ${einRM.toStringAsFixed(1)} kg',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Eingabefelder oder Werte, je nach Status
              _buildSetValuesRow(context, provider, istAktiv),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetValuesRow(BuildContext context,
      ProgressionManagerProvider provider, bool istAktiv) {
    return Row(
      children: [
        // Gewicht
        Expanded(
          child: _buildInputField(
            context,
            'Gewicht',
            satz.kg.toString(),
            'kg',
            istAktiv,
            (value) => provider.handleChange(satz.id, 'kg', value),
            'kg', // Typ hinzugefügt
          ),
        ),
        const SizedBox(width: 8),

        // Wiederholungen
        Expanded(
          child: _buildInputField(
            context,
            'Wdh.',
            satz.wiederholungen.toString(),
            '',
            istAktiv,
            (value) => provider.handleChange(satz.id, 'wiederholungen', value),
            'wiederholungen', // Typ hinzugefügt
          ),
        ),
        const SizedBox(width: 8),

        // RIR
        Expanded(
          child: _buildInputField(
            context,
            'RIR',
            satz.rir.toString(),
            '',
            istAktiv,
            (value) => provider.handleChange(satz.id, 'rir', value),
            'rir', // Typ hinzugefügt
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(
    BuildContext context,
    String label,
    String value,
    String suffix,
    bool isEnabled,
    Function(String) onChanged,
    String feldTyp, // 'kg', 'wiederholungen', oder 'rir'
  ) {
    final provider = Provider.of<ProgressionManagerProvider>(context);
    final istAktiv =
        satz.id == provider.aktiverSatz && !provider.trainingAbgeschlossen;
    final sollEmpfehlungAnzeigen = provider.sollEmpfehlungAnzeigen(satz.id);

    // Den richtigen Empfehlungswert basierend auf dem Feldtyp auswählen
    String? empfehlungWert;
    if (sollEmpfehlungAnzeigen && istAktiv) {
      switch (feldTyp) {
        case 'kg':
          empfehlungWert = satz.empfKg?.toString();
          break;
        case 'wiederholungen':
          empfehlungWert = satz.empfWiederholungen?.toString();
          break;
        case 'rir':
          empfehlungWert = satz.empfRir?.toString();
          break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: value),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            suffixText: suffix,
            isDense: true,
            enabled: isEnabled,
          ),
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isEnabled ? Colors.black : Colors.grey[600],
          ),
        ),
        if (istAktiv && sollEmpfehlungAnzeigen && empfehlungWert != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.arrow_upward,
                size: 12,
                color: Colors.purple[700],
              ),
              const SizedBox(width: 2),
              Text(
                suffix.isNotEmpty ? '$empfehlungWert $suffix' : empfehlungWert,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
