import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../../services/progression_manager_screen/one_rm_calculator_service.dart';

class SetTableWidget extends StatelessWidget {
  const SetTableWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Satz')),
          DataColumn(label: Text('Kg')),
          DataColumn(label: Text('Wiederholungen')),
          DataColumn(label: Text('RIR')),
          DataColumn(label: Text('1RM (kg)')),
          DataColumn(label: Text('Status')),
        ],
        rows: provider.saetze.map((satz) {
          final istAktiv = satz.id == provider.aktiverSatz &&
              !provider.trainingAbgeschlossen;
          final istAbgeschlossen = satz.abgeschlossen;

          // Empfehlung berechnen wenn es ein aktiver Satz ist
          final empfehlung =
              istAktiv ? provider.berechneProgression(satz) : null;

          // 1RM berechnen
          final aktueller1RM = OneRMCalculatorService.calculate1RM(
              satz.kg, satz.wiederholungen, satz.rir);

          return DataRow(
            color: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
                if (istAktiv) return Colors.blue[50];
                if (istAbgeschlossen) return Colors.green[50];
                return null;
              },
            ),
            cells: [
              // Satznummer
              DataCell(
                Text(
                  '${satz.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              // Gewicht
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 70,
                      child: TextField(
                        controller:
                            TextEditingController(text: satz.kg.toString()),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          suffixText: 'kg',
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        enabled: istAktiv,
                        style: TextStyle(
                          color: !istAktiv ? Colors.grey : Colors.black,
                        ),
                        onChanged: (value) {
                          provider.handleChange(satz.id, 'kg', value);
                        },
                      ),
                    ),
                    if (istAktiv && empfehlung != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '→ ${empfehlung['kg']}kg',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.purple[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Wiederholungen
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 70,
                      child: TextField(
                        controller: TextEditingController(
                            text: satz.wiederholungen.toString()),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        enabled: istAktiv,
                        style: TextStyle(
                          color: !istAktiv ? Colors.grey : Colors.black,
                        ),
                        onChanged: (value) {
                          provider.handleChange(
                              satz.id, 'wiederholungen', value);
                        },
                      ),
                    ),
                    if (istAktiv && empfehlung != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '→ ${empfehlung['wiederholungen']}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.purple[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // RIR
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 70,
                      child: TextField(
                        controller:
                            TextEditingController(text: satz.rir.toString()),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        enabled: istAktiv,
                        style: TextStyle(
                          color: !istAktiv ? Colors.grey : Colors.black,
                        ),
                        onChanged: (value) {
                          provider.handleChange(satz.id, 'rir', value);
                        },
                      ),
                    ),
                    if (istAktiv && empfehlung != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '→ ${empfehlung['rir']}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.purple[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 1RM
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aktueller1RM > 0 ? aktueller1RM.toStringAsFixed(1) : '-',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (istAktiv &&
                        empfehlung != null &&
                        aktueller1RM > 0 &&
                        empfehlung['neuer1RM'] > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '→ ${empfehlung['neuer1RM'].toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.purple[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '(+${((empfehlung['neuer1RM'] / aktueller1RM - 1) * 100).toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Status
              DataCell(
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: istAbgeschlossen
                        ? Colors.green[100]
                        : istAktiv
                            ? Colors.blue[100]
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    istAbgeschlossen
                        ? '✓ Abgeschlossen'
                        : istAktiv
                            ? 'Aktiv'
                            : 'Warten',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: istAbgeschlossen
                          ? Colors.green[800]
                          : istAktiv
                              ? Colors.blue[800]
                              : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
