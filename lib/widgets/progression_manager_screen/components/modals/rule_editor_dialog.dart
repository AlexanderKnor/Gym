import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../../../models/progression_manager_screen/progression_variable_model.dart';

class RuleEditorDialog extends StatelessWidget {
  const RuleEditorDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);

    return Stack(
      children: [
        // Abgedunkelter Hintergrund
        GestureDetector(
          onTap: provider.closeRuleEditor,
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
              constraints: const BoxConstraints(maxWidth: 800),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          provider.bearbeiteteRegel != null
                              ? 'Regel bearbeiten'
                              : 'Neue Regel hinzufügen',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: provider.closeRuleEditor,
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Regel-Typ
                    const Text(
                      'Regel-Typ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: provider.regelTyp,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'condition',
                          child: Text('Bedingte Regel (Wenn... Dann...)'),
                        ),
                        DropdownMenuItem(
                          value: 'assignment',
                          child: Text('Direkte Zuweisung (ohne Bedingung)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          provider.setRegelTyp(value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Bedingungen - nur anzeigen, wenn Regeltyp "condition" ist
                    if (provider.regelTyp == 'condition') ...[
                      const Text(
                        'Bedingungen (mit UND verknüpft)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // Bedingungen-Liste
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.regelBedingungen.length,
                        itemBuilder: (context, index) {
                          final bedingung = provider.regelBedingungen[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (index > 0) ...[
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.purple[100],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'UND',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple[800],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],

                                  // Bedingungseditor
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Linke Variable
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('Variable',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            DropdownButtonFormField<String>(
                                              value: bedingung.left['value'],
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 8),
                                                isDense: true,
                                              ),
                                              items: provider
                                                  .verfuegbareVariablen
                                                  .map((variable) {
                                                return DropdownMenuItem(
                                                  value: variable.id,
                                                  child: Text(variable.label),
                                                );
                                              }).toList(),
                                              onChanged: (value) {
                                                if (value != null) {
                                                  provider.updateRegelBedingung(
                                                      index,
                                                      'leftVariable',
                                                      value);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Operator
                                      SizedBox(
                                        width: 80,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('Operator',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            DropdownButtonFormField<String>(
                                              value: bedingung.operator,
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 8),
                                                isDense: true,
                                              ),
                                              items: provider
                                                  .verfuegbareOperatoren
                                                  .where((op) =>
                                                      op.type == 'comparison')
                                                  .map((op) {
                                                return DropdownMenuItem(
                                                  value: op.id,
                                                  child: Text(op.label),
                                                );
                                              }).toList(),
                                              onChanged: (value) {
                                                if (value != null) {
                                                  provider.updateRegelBedingung(
                                                      index, 'operator', value);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Rechte Seite
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('Wert',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                // Typ (Variable oder Konstante)
                                                SizedBox(
                                                  width: 120,
                                                  child:
                                                      DropdownButtonFormField<
                                                          String>(
                                                    value:
                                                        bedingung.right['type'],
                                                    decoration:
                                                        const InputDecoration(
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .horizontal(
                                                          left: Radius.circular(
                                                              4),
                                                          right: Radius.zero,
                                                        ),
                                                      ),
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 8),
                                                      isDense: true,
                                                    ),
                                                    items: const [
                                                      DropdownMenuItem(
                                                        value: 'constant',
                                                        child:
                                                            Text('Konstante'),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 'variable',
                                                        child: Text('Variable'),
                                                      ),
                                                    ],
                                                    onChanged: (value) {
                                                      if (value != null) {
                                                        provider
                                                            .updateRegelBedingung(
                                                                index,
                                                                'rightType',
                                                                value);
                                                      }
                                                    },
                                                  ),
                                                ),

                                                // Wert (Variable oder Konstante)
                                                Expanded(
                                                  child: bedingung
                                                              .right['type'] ==
                                                          'variable'
                                                      ? DropdownButtonFormField<
                                                          String>(
                                                          value: bedingung
                                                              .right['value']
                                                              .toString(),
                                                          decoration:
                                                              const InputDecoration(
                                                            border:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .horizontal(
                                                                left:
                                                                    Radius.zero,
                                                                right: Radius
                                                                    .circular(
                                                                        4),
                                                              ),
                                                            ),
                                                            contentPadding:
                                                                EdgeInsets
                                                                    .symmetric(
                                                                        horizontal:
                                                                            8,
                                                                        vertical:
                                                                            8),
                                                            isDense: true,
                                                          ),
                                                          items: _getRelatedVariables(
                                                                  provider,
                                                                  bedingung
                                                                          .left[
                                                                      'value'])
                                                              .map((variable) {
                                                            return DropdownMenuItem(
                                                              value:
                                                                  variable.id,
                                                              child: Text(
                                                                  variable
                                                                      .label),
                                                            );
                                                          }).toList(),
                                                          onChanged: (value) {
                                                            if (value != null) {
                                                              provider
                                                                  .updateRegelBedingung(
                                                                      index,
                                                                      'rightValue',
                                                                      value);
                                                            }
                                                          },
                                                        )
                                                      : TextField(
                                                          controller:
                                                              TextEditingController(
                                                            text: bedingung
                                                                .right['value']
                                                                .toString(),
                                                          ),
                                                          keyboardType:
                                                              const TextInputType
                                                                  .numberWithOptions(
                                                                  decimal:
                                                                      true),
                                                          decoration:
                                                              const InputDecoration(
                                                            border:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .horizontal(
                                                                left:
                                                                    Radius.zero,
                                                                right: Radius
                                                                    .circular(
                                                                        4),
                                                              ),
                                                            ),
                                                            contentPadding:
                                                                EdgeInsets
                                                                    .symmetric(
                                                                        horizontal:
                                                                            8,
                                                                        vertical:
                                                                            8),
                                                            isDense: true,
                                                          ),
                                                          onChanged: (value) {
                                                            provider
                                                                .updateRegelBedingung(
                                                                    index,
                                                                    'rightValue',
                                                                    value);
                                                          },
                                                        ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Löschen-Button für Bedingungen
                                  if (provider.regelBedingungen.length > 1) ...[
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () => provider
                                            .removeRegelBedingung(index),
                                        icon:
                                            const Icon(Icons.delete, size: 16),
                                        label:
                                            const Text('Bedingung entfernen'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Button zum Hinzufügen einer Bedingung
                      OutlinedButton.icon(
                        onPressed: provider.addRegelBedingung,
                        icon: const Icon(Icons.add),
                        label: const Text('Weitere Bedingung hinzufügen (UND)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple[700],
                          side: BorderSide(color: Colors.purple[300]!),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Aktionen
                    Text(
                      provider.regelTyp == 'condition'
                          ? 'Wenn die Bedingung erfüllt ist, setze:'
                          : 'Folgende Werte werden direkt gesetzt (ohne Bedingung):',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Gewicht
                    _buildKgAction(context, provider),
                    const SizedBox(height: 16),

                    // Wiederholungen
                    _buildRepsAction(context, provider),
                    const SizedBox(height: 16),

                    // RIR
                    _buildRirAction(context, provider),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: provider.closeRuleEditor,
                          child: const Text('Abbrechen'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: provider.saveRule,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                          ),
                          child: Text(
                            provider.bearbeiteteRegel != null
                                ? 'Regel aktualisieren'
                                : 'Regel hinzufügen',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<ProgressionVariableModel> _getRelatedVariables(
      ProgressionManagerProvider provider, String leftVariableId) {
    final relatedIds = <String>[];

    if (leftVariableId == 'lastKg') {
      relatedIds.add('previousKg');
    } else if (leftVariableId == 'lastReps') {
      relatedIds.addAll(['targetRepsMin', 'targetRepsMax', 'previousReps']);
    } else if (leftVariableId == 'lastRIR') {
      relatedIds.addAll(['targetRIRMin', 'targetRIRMax', 'previousRIR']);
    } else if (leftVariableId == 'last1RM') {
      relatedIds.add('previous1RM');
    } else if (leftVariableId == 'previousKg') {
      relatedIds.add('lastKg');
    } else if (leftVariableId == 'previousReps') {
      relatedIds.add('lastReps');
    } else if (leftVariableId == 'previousRIR') {
      relatedIds.add('lastRIR');
    } else if (leftVariableId == 'previous1RM') {
      relatedIds.add('last1RM');
    }

    return provider.verfuegbareVariablen
        .where((v) => relatedIds.contains(v.id))
        .toList();
  }

  Widget _buildKgAction(
      BuildContext context, ProgressionManagerProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Gewicht:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                value: provider.kgAktion['type'],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'direct',
                    child: Text('Direkter Wert'),
                  ),
                  DropdownMenuItem(
                    value: 'oneRM',
                    child: Text('1RM-basierte Berechnung'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    provider.updateKgAktion('type', value);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Je nach Typ unterschiedliche Eingabefelder
        if (provider.kgAktion['type'] == 'direct') ...[
          // Direkter Wert
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Row(
              children: [
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    value: provider.kgAktion['variable'],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'lastKg',
                        child: Text('Letztes Gewicht'),
                      ),
                      DropdownMenuItem(
                        value: 'previousKg',
                        child: Text('Vorheriges Gewicht'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        provider.updateKgAktion('variable', value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: DropdownButtonFormField<String>(
                    value: provider.kgAktion['operator'],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'none',
                        child: Text('-'),
                      ),
                      DropdownMenuItem(
                        value: 'add',
                        child: Text('+'),
                      ),
                      DropdownMenuItem(
                        value: 'subtract',
                        child: Text('-'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        provider.updateKgAktion('operator', value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: TextEditingController(
                      text: provider.kgAktion['value'].toString(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      provider.updateKgAktion('value', value);
                    },
                  ),
                ),
              ],
            ),
          ),
        ] else if (provider.kgAktion['type'] == 'oneRM') ...[
          // 1RM-basierte Berechnung
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Row(
              children: [
                const Text('1RM Steigerung um (%):'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: TextEditingController(
                      text: provider.kgAktion['rmPercentage'].toString(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      provider.updateKgAktion('rmPercentage', value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              'Basiert auf Epley-Formel und Zielwerten für Wiederholungen und RIR',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRepsAction(
      BuildContext context, ProgressionManagerProvider provider) {
    return Row(
      children: [
        const Text('Wiederh. =', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 16),
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String>(
            value: provider.repsAktion['variable'],
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: 'lastReps',
                child: Text('Letzte Wiederh.'),
              ),
              DropdownMenuItem(
                value: 'previousReps',
                child: Text('Vorherige Wiederh.'),
              ),
              DropdownMenuItem(
                value: 'targetRepsMin',
                child: Text('Min. Wiederh.'),
              ),
              DropdownMenuItem(
                value: 'targetRepsMax',
                child: Text('Max. Wiederh.'),
              ),
              DropdownMenuItem(
                value: 'constant',
                child: Text('Konstante'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                provider.updateRepsAktion('variable', value);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: DropdownButtonFormField<String>(
            value: provider.repsAktion['operator'],
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: 'none',
                child: Text('-'),
              ),
              DropdownMenuItem(
                value: 'add',
                child: Text('+'),
              ),
              DropdownMenuItem(
                value: 'subtract',
                child: Text('-'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                provider.updateRepsAktion('operator', value);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: TextField(
            controller: TextEditingController(
              text: provider.repsAktion['value'].toString(),
            ),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            onChanged: (value) {
              provider.updateRepsAktion('value', value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRirAction(
      BuildContext context, ProgressionManagerProvider provider) {
    return Row(
      children: [
        const Text('RIR =', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 16),
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String>(
            value: provider.rirAktion['variable'],
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: 'lastRIR',
                child: Text('Letzter RIR'),
              ),
              DropdownMenuItem(
                value: 'previousRIR',
                child: Text('Vorheriger RIR'),
              ),
              DropdownMenuItem(
                value: 'targetRIRMin',
                child: Text('Min. RIR'),
              ),
              DropdownMenuItem(
                value: 'targetRIRMax',
                child: Text('Max. RIR'),
              ),
              DropdownMenuItem(
                value: 'constant',
                child: Text('Konstante'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                provider.updateRirAktion('variable', value);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: DropdownButtonFormField<String>(
            value: provider.rirAktion['operator'],
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: 'none',
                child: Text('-'),
              ),
              DropdownMenuItem(
                value: 'add',
                child: Text('+'),
              ),
              DropdownMenuItem(
                value: 'subtract',
                child: Text('-'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                provider.updateRirAktion('operator', value);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: TextField(
            controller: TextEditingController(
              text: provider.rirAktion['value'].toString(),
            ),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            onChanged: (value) {
              provider.updateRirAktion('value', value);
            },
          ),
        ),
      ],
    );
  }
}
