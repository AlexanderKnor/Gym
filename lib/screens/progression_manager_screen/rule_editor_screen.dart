import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../../../models/progression_manager_screen/progression_variable_model.dart';

/// Ein universeller Editor für Progressionsregeln, der sowohl als eigenständiger Screen
/// als auch als Dialog verwendet werden kann.
class RuleEditorScreen extends StatelessWidget {
  /// Bestimmt, ob die Komponente als Dialog oder als Screen dargestellt wird
  final bool isDialog;

  const RuleEditorScreen({
    Key? key,
    this.isDialog = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);

    // Dialog-Modus: Im Stack mit abgedunkeltem Hintergrund
    if (isDialog) {
      return Stack(
        children: [
          // Abgedunkelter Hintergrund
          GestureDetector(
            onTap: provider.closeRuleEditor,
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),

          // Dialog-Inhalt
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
                  child: RuleEditorContent(isDialog: true),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Screen-Modus: Als vollständiger Screen mit AppBar
    return WillPopScope(
      onWillPop: () async {
        provider.closeRuleEditor();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            provider.bearbeiteteRegel != null
                ? 'Regel bearbeiten'
                : 'Neue Regel erstellen',
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              provider.closeRuleEditor();
              // Entferne Navigator.pop() hier, damit wir auf der gleichen Seite bleiben
            },
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await provider.saveRule();
                // Entferne Navigator.pop() hier, damit wir auf der gleichen Seite bleiben
              },
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
            child: RuleEditorContent(isDialog: false),
          ),
        ),
      ),
    );
  }
}

/// Der eigentliche Inhalt des Regel-Editors, der sowohl im Dialog als auch im Screen verwendet wird
class RuleEditorContent extends StatelessWidget {
  final bool isDialog;

  const RuleEditorContent({
    Key? key,
    required this.isDialog,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nur im Dialog-Modus Header mit Schließen-Button anzeigen
        if (isDialog) ...[
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
        ],

        // Regeltyp-Auswahl
        _buildRuleTypeSelector(context, provider),
        const SizedBox(height: 24),

        // Bedingungen - nur anzeigen wenn Regeltyp "condition" ist
        if (provider.regelTyp == 'condition')
          _buildConditionsSection(context, provider),

        if (provider.regelTyp == 'condition') const SizedBox(height: 24),

        // Aktionen - immer anzeigen
        _buildActionsSection(context, provider),

        // Buttons am Ende - im Dialog-Modus anders als im Screen
        const SizedBox(height: 24),
        if (isDialog)
          _buildDialogButtons(context, provider)
        else
          _buildScreenButtons(context, provider),
      ],
    );
  }

  Widget _buildRuleTypeSelector(
      BuildContext context, ProgressionManagerProvider provider) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Regeltyp',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: provider.regelTyp,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                labelText: 'Art der Regel',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'condition',
                  child: Text('Bedingte Regel (Wenn... Dann...)'),
                ),
                DropdownMenuItem(
                  value: 'assignment',
                  child: Text('Direkte Zuweisung (Setze Werte direkt)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  provider.setRegelTyp(value);
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              provider.regelTyp == 'condition'
                  ? 'Diese Regel wird nur angewendet, wenn alle Bedingungen erfüllt sind.'
                  : 'Diese Regel wird immer angewendet, ohne Bedingungen zu prüfen.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionsSection(
      BuildContext context, ProgressionManagerProvider provider) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.rule, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Bedingungen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Diese Regel wird angewendet, wenn alle folgenden Bedingungen erfüllt sind:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Liste der Bedingungen
            for (int i = 0; i < provider.regelBedingungen.length; i++) ...[
              if (i > 0) ...[
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'UND',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ),
              ],
              _buildConditionEditor(context, provider, i),
            ],

            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                onPressed: provider.addRegelBedingung,
                icon: const Icon(Icons.add),
                label: const Text('Weitere Bedingung (UND)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  side: BorderSide(color: Colors.blue[300]!),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionEditor(
      BuildContext context, ProgressionManagerProvider provider, int index) {
    final bedingung = provider.regelBedingungen[index];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Variable (linke Seite)
          const Text(
            'Variable',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          _buildVariableDropdown(
            context,
            bedingung.left['value'],
            (value) =>
                provider.updateRegelBedingung(index, 'leftVariable', value),
            provider.verfuegbareVariablen,
          ),
          const SizedBox(height: 12),

          // Operator
          const Text(
            'Operator',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: DropdownButtonFormField<String>(
              value: bedingung.operator,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                isDense: true,
              ),
              items: provider.verfuegbareOperatoren
                  .where((op) => op.type == 'comparison')
                  .map((op) {
                return DropdownMenuItem<String>(
                  value: op.id,
                  child: Text(op.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  provider.updateRegelBedingung(index, 'operator', value);
                }
              },
            ),
          ),
          const SizedBox(height: 12),

          // Vergleichswert
          const Text(
            'Vergleichswert',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              // Typ (Variable oder Konstante)
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  value: bedingung.right['type'],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'constant',
                      child: Text('Zahlenwert'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'variable',
                      child: Text('Variable'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      provider.updateRegelBedingung(index, 'rightType', value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Wert (Variable oder Konstante)
              Expanded(
                flex: 5,
                child: bedingung.right['type'] == 'variable'
                    ? _buildRightVariableDropdown(
                        context, provider, index, bedingung)
                    : TextField(
                        controller: TextEditingController(
                          text: bedingung.right['value'].toString(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          provider.updateRegelBedingung(
                              index, 'rightValue', value);
                        },
                      ),
              ),
            ],
          ),

          // Löschen-Button (nur wenn mehr als eine Bedingung vorhanden)
          if (provider.regelBedingungen.length > 1) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => provider.removeRegelBedingung(index),
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Entfernen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  side: BorderSide(color: Colors.red[300]!),
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRightVariableDropdown(BuildContext context,
      ProgressionManagerProvider provider, int index, dynamic bedingung) {
    final relatedVariables =
        _getRelatedVariables(provider, bedingung.left['value']);
    final rightValue = bedingung.right['value'].toString();

    // Überprüfen, ob der aktuelle Wert in den verfügbaren Optionen enthalten ist
    bool containsValue = relatedVariables.any((v) => v.id == rightValue);

    // Falls nicht, automatisch den ersten Wert auswählen
    if (!containsValue && relatedVariables.isNotEmpty) {
      Future.microtask(() {
        provider.updateRegelBedingung(
            index, 'rightValue', relatedVariables.first.id);
      });

      // Temporär einen gültigen Wert zurückgeben, um den Fehler zu vermeiden
      return const Text("Wert wird aktualisiert...");
    }

    return DropdownButtonFormField<String>(
      value: rightValue,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        isDense: true,
      ),
      items: relatedVariables.map((variable) {
        return DropdownMenuItem<String>(
          value: variable.id,
          child: Text(
            provider.getVariableLabel(variable.id),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          provider.updateRegelBedingung(index, 'rightValue', value);
        }
      },
    );
  }

  Widget _buildActionsSection(
      BuildContext context, ProgressionManagerProvider provider) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_fix_high, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  provider.regelTyp == 'condition'
                      ? 'Aktionen (wenn Bedingungen erfüllt)'
                      : 'Direkte Wertzuweisungen',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              provider.regelTyp == 'condition'
                  ? 'Diese Werte werden gesetzt, wenn die Bedingungen erfüllt sind:'
                  : 'Diese Werte werden immer direkt gesetzt (ohne Bedingungen):',
              style: const TextStyle(fontSize: 14),
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
          ],
        ),
      ),
    );
  }

  Widget _buildKgAction(
      BuildContext context, ProgressionManagerProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Überschrift mit Icon
        Row(
          children: [
            Icon(Icons.fitness_center, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 4),
            const Text(
              'Gewicht',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Typ auswählen (Direkter Wert oder 1RM-basiert)
        const Text('Berechnungsmethode:', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: provider.kgAktion['type'],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem<String>(
              value: 'direct',
              child: Text('Direkter Wert'),
            ),
            DropdownMenuItem<String>(
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
        const SizedBox(height: 8),

        // Je nach Typ unterschiedliche Eingabefelder
        if (provider.kgAktion['type'] == 'direct') ...[
          // Basiswert
          const Text('Basiswert:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: provider.kgAktion['variable'],
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem<String>(
                value: 'lastKg',
                child: Text('Letztes Gewicht'),
              ),
              DropdownMenuItem<String>(
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
          const SizedBox(height: 8),

          // Operator und Wert
          const Text('Berechnung:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              // Operator
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: provider.kgAktion['operator'],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'none',
                      child: Text('Wie ist'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'add',
                      child: Text('+ Wert'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'subtract',
                      child: Text('- Wert'),
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

              // Neuer Code: Werttyp- und Wertauswahl mit Radio-Buttons
              if (provider.kgAktion['operator'] != 'none')
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Option für festen Wert
                      Row(
                        children: [
                          Radio<String>(
                            value: 'constant',
                            groupValue: provider.kgAktion['valueType'],
                            onChanged: (value) {
                              if (value != null) {
                                provider.updateKgAktion('valueType', value);
                              }
                            },
                          ),
                          const Text('Fester Wert:'),
                        ],
                      ),
                      if (provider.kgAktion['valueType'] == 'constant')
                        Padding(
                          padding: const EdgeInsets.only(left: 32.0),
                          child: TextField(
                            controller: TextEditingController(
                              text: provider.kgAktion['value'].toString(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              isDense: true,
                              suffixText: 'kg',
                            ),
                            onChanged: (value) {
                              provider.updateKgAktion('value', value);
                            },
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Option für Standardsteigerung
                      Row(
                        children: [
                          Radio<String>(
                            value: 'config',
                            groupValue: provider.kgAktion['valueType'],
                            onChanged: (value) {
                              if (value != null) {
                                provider.updateKgAktion('valueType', value);
                              }
                            },
                          ),
                          const Text('Std. Steigerung:'),
                          const SizedBox(width: 8),
                          if (provider.kgAktion['valueType'] == 'config')
                            Text(
                              '${provider.progressionsConfig['increment']} kg',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ] else if (provider.kgAktion['type'] == 'oneRM') ...[
          // 1RM-basierte Berechnung
          const Text('1RM Steigerung:'),
          const SizedBox(height: 4),
          TextField(
            controller: TextEditingController(
              text: provider.kgAktion['rmPercentage'].toString(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
              suffixText: '%',
            ),
            onChanged: (value) {
              provider.updateKgAktion('rmPercentage', value);
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Basiert auf Epley-Formel und den Zielwerten für Wiederholungen und RIR',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRepsAction(
      BuildContext context, ProgressionManagerProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Überschrift mit Icon
        Row(
          children: [
            Icon(Icons.repeat, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 4),
            const Text(
              'Wiederholungen',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Basiswert
        const Text('Basiswert:', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: provider.repsAktion['variable'],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem<String>(
              value: 'lastReps',
              child: Text('Letzte Wiederh.'),
            ),
            DropdownMenuItem<String>(
              value: 'previousReps',
              child: Text('Vorherige Wiederh.'),
            ),
            DropdownMenuItem<String>(
              value: 'targetRepsMin',
              child: Text('Min. Wiederh.'),
            ),
            DropdownMenuItem<String>(
              value: 'targetRepsMax',
              child: Text('Max. Wiederh.'),
            ),
            DropdownMenuItem<String>(
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
        const SizedBox(height: 8),

        // Operator und Wert
        const Text('Berechnung:', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            // Operator
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: provider.repsAktion['operator'],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem<String>(
                    value: 'none',
                    child: Text('Wie ist'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'add',
                    child: Text('+ Wert'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'subtract',
                    child: Text('- Wert'),
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

            // Wert
            Expanded(
              flex: 1,
              child: provider.repsAktion['operator'] != 'none'
                  ? TextField(
                      controller: TextEditingController(
                        text: provider.repsAktion['value'].toString(),
                      ),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        provider.updateRepsAktion('value', value);
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRirAction(
      BuildContext context, ProgressionManagerProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Überschrift mit Icon
        Row(
          children: [
            Icon(Icons.battery_5_bar, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 4),
            const Text(
              'RIR (Reps in Reserve)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Basiswert
        const Text('Basiswert:', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: provider.rirAktion['variable'],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem<String>(
              value: 'lastRIR',
              child: Text('Letzter RIR'),
            ),
            DropdownMenuItem<String>(
              value: 'previousRIR',
              child: Text('Vorheriger RIR'),
            ),
            DropdownMenuItem<String>(
              value: 'targetRIRMin',
              child: Text('Min. RIR'),
            ),
            DropdownMenuItem<String>(
              value: 'targetRIRMax',
              child: Text('Max. RIR'),
            ),
            DropdownMenuItem<String>(
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
        const SizedBox(height: 8),

        // Operator und Wert
        const Text('Berechnung:', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            // Operator
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: provider.rirAktion['operator'],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem<String>(
                    value: 'none',
                    child: Text('Wie ist'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'add',
                    child: Text('+ Wert'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'subtract',
                    child: Text('- Wert'),
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

            // Wert
            Expanded(
              flex: 1,
              child: provider.rirAktion['operator'] != 'none'
                  ? TextField(
                      controller: TextEditingController(
                        text: provider.rirAktion['value'].toString(),
                      ),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        provider.updateRirAktion('value', value);
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVariableDropdown(
    BuildContext context,
    String value,
    Function(String) onChanged,
    List<ProgressionVariableModel> variables,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        isDense: true,
      ),
      items: variables.map((variable) {
        return DropdownMenuItem<String>(
          value: variable.id,
          child: Text(
            Provider.of<ProgressionManagerProvider>(context)
                .getVariableLabel(variable.id),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }

  // Buttons für Dialog-Modus
  Widget _buildDialogButtons(
      BuildContext context, ProgressionManagerProvider provider) {
    return Row(
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
    );
  }

  // Buttons für Screen-Modus - optional, da bereits in der AppBar vorhanden
  Widget _buildScreenButtons(
      BuildContext context, ProgressionManagerProvider provider) {
    // Im Screen-Modus werden die Hauptbuttons in der AppBar angezeigt
    // Zusätzliche Aktionen können hier hinzugefügt werden, falls nötig
    return const SizedBox.shrink();
  }

  // Hilfsmethode zum Finden verwandter Variablen für die rechte Seite einer Bedingung
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
    } else if (leftVariableId.startsWith('target')) {
      // Bei Zielvariablen andere Zielvariablen hinzufügen
      provider.verfuegbareVariablen
          .where((v) => v.id.startsWith('target') && v.id != leftVariableId)
          .forEach((v) => relatedIds.add(v.id));
    }

    // Falls keine passenden Variablen gefunden wurden, mindestens eine Standardvariable hinzufügen
    if (relatedIds.isEmpty) {
      relatedIds.add('targetRepsMax');
    }

    return provider.verfuegbareVariablen
        .where((v) => relatedIds.contains(v.id))
        .toList();
  }
}
