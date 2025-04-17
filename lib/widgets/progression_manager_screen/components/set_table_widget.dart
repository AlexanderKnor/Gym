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
          final sollEmpfehlungAnzeigen =
              provider.sollEmpfehlungAnzeigen(satz.id);

          // 1RM für aktuelle Werte berechnen
          final aktueller1RM = OneRMCalculatorService.calculate1RM(
              satz.kg, satz.wiederholungen, satz.rir);

          // 1RM für empfohlene Werte berechnen, wenn vorhanden und die Empfehlung angezeigt werden soll
          double? empfohlener1RM;
          if (istAktiv &&
              sollEmpfehlungAnzeigen &&
              satz.empfehlungBerechnet &&
              satz.empfKg != null &&
              satz.empfWiederholungen != null &&
              satz.empfRir != null) {
            empfohlener1RM = OneRMCalculatorService.calculate1RM(
                satz.empfKg!, satz.empfWiederholungen!, satz.empfRir!);
          }

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
                    if (sollEmpfehlungAnzeigen &&
                        istAktiv &&
                        satz.empfKg != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '→ ${satz.empfKg}kg',
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
                    if (sollEmpfehlungAnzeigen &&
                        istAktiv &&
                        satz.empfWiederholungen != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '→ ${satz.empfWiederholungen}',
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
                    if (sollEmpfehlungAnzeigen &&
                        istAktiv &&
                        satz.empfRir != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '→ ${satz.empfRir}',
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

              // 1RM - mit einheitlicher Anzeigelogik für den empfohlenen 1RM
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aktueller1RM > 0 ? aktueller1RM.toStringAsFixed(1) : '-',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (sollEmpfehlungAnzeigen &&
                        empfohlener1RM != null &&
                        aktueller1RM > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '→ ${empfohlener1RM.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.purple[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 2),
                          if ((empfohlener1RM - aktueller1RM).abs() > 0.1)
                            Text(
                              '(${empfohlener1RM > aktueller1RM ? '+' : ''}${((empfohlener1RM / aktueller1RM - 1) * 100).toStringAsFixed(1)}%)',
                              style: TextStyle(
                                fontSize: 10,
                                color: empfohlener1RM > aktueller1RM
                                    ? Colors.green[600]
                                    : Colors.red[600],
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
