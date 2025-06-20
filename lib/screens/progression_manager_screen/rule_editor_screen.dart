// lib/screens/progression_manager_screen/rule_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../../../models/progression_manager_screen/progression_variable_model.dart';

/// Ein moderner, intuitiver Editor für Progressionsregeln
class RuleEditorScreen extends StatelessWidget {
  final bool isDialog;

  const RuleEditorScreen({
    Key? key,
    this.isDialog = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);

    // Dialog-Modus
    if (isDialog) {
      return Stack(
        children: [
          // Abgedunkelter Hintergrund mit Blur
          GestureDetector(
            onTap: provider.closeRuleEditor,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(color: Colors.black.withOpacity(0.7)),
            ),
          ),

          // Dialog-Inhalt
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: _charcoal,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  _buildDialogHeader(context, provider),

                  // Content
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                          child: RuleEditorContent(isDialog: true),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Vollbild-Modus mit überarbeiteter Navigation
    return WillPopScope(
      onWillPop: () async {
        provider.closeRuleEditor();
        return false;
      },
      child: Scaffold(
        backgroundColor: _midnight,
        appBar: AppBar(
          backgroundColor: _midnight,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text(
            provider.bearbeiteteRegel != null
                ? 'Regel bearbeiten'
                : 'Neue Regel erstellen',
            style: const TextStyle(
              color: _snow,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          // Zurück-Button statt Kreuz (X)
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _snow, size: 24),
            onPressed: provider.closeRuleEditor,
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: _snow,
            ),
          ),
          // System-UI Style für dunkles Theme
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  16, 8, 16, 120), // Extra padding am Boden
              child: RuleEditorContent(isDialog: false),
            ),
          ),
        ),
        // Speichern-Button am unteren Bildschirmrand mit angepasster Beschriftung
        bottomSheet: Container(
          color: _midnight,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // Haptisches Feedback hinzufügen
                HapticFeedback.mediumImpact();
                await provider.saveRule();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _emberCore,
                foregroundColor: _snow,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                provider.bearbeiteteRegel != null
                    ? 'Regel aktualisieren'
                    : 'Regel hinzufügen',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader(
      BuildContext context, ProgressionManagerProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: _graphite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            provider.bearbeiteteRegel != null
                ? 'Regel bearbeiten'
                : 'Neue Regel erstellen',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _snow,
              letterSpacing: -0.3,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 24, color: _mercury),
            onPressed: provider.closeRuleEditor,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: _mercury,
            ),
          ),
        ],
      ),
    );
  }
}

/// Option für Selektoren
class SelectionOption {
  final String value;
  final String label;
  final IconData? icon;
  final String? description;

  SelectionOption({
    required this.value,
    required this.label,
    this.icon,
    this.description,
  });
}

/// Der eigentliche Inhalt des Regel-Editors
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
        // Regeltyp-Auswahl
        _buildRuleTypeSelector(context, provider),

        // Bedingungen - nur anzeigen wenn Regeltyp "condition" ist
        if (provider.regelTyp == 'condition')
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildConditionsSection(context, provider),
            ],
          ),

        const SizedBox(height: 24),

        // Aktionen - immer anzeigen
        _buildActionsSection(context, provider),

        // Extra Platz am Ende für besseres Scrollen
        const SizedBox(height: 24),

        // Dialog-Aktionen nur im Dialog-Modus
        if (isDialog) _buildDialogActions(context, provider),
      ],
    );
  }

  Widget _buildRuleTypeSelector(
      BuildContext context, ProgressionManagerProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titel
        const Text(
          'Regeltyp',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _snow,
          ),
        ),
        const SizedBox(height: 8),

        // Selektor für Regeltyp
        _buildSelectableButton(
          context: context,
          currentValue: provider.regelTyp,
          title: 'Regeltyp wählen',
          options: [
            SelectionOption(
              value: 'condition',
              label: 'Bedingte Regel (Wenn... Dann...)',
              icon: Icons.rule_folder,
              description:
                  'Diese Regel wird nur angewendet, wenn alle Bedingungen erfüllt sind.',
            ),
            SelectionOption(
              value: 'assignment',
              label: 'Direkte Zuweisung',
              icon: Icons.assignment,
              description:
                  'Diese Regel wird immer angewendet, ohne Bedingungen zu prüfen.',
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              provider.setRegelTyp(value);
            }
          },
        ),

        // Info-Text
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Text(
            provider.regelTyp == 'condition'
                ? 'Diese Regel wird nur angewendet, wenn alle Bedingungen erfüllt sind.'
                : 'Diese Regel wird immer angewendet, ohne Bedingungen zu prüfen.',
            style: TextStyle(
              fontSize: 13,
              color: _mercury,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionsSection(
      BuildContext context, ProgressionManagerProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titel
        const Text(
          'Bedingungen',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _snow,
          ),
        ),
        const SizedBox(height: 4),

        // Untertitel
        Text(
          'Regel wird angewendet, wenn alle folgenden Bedingungen erfüllt sind:',
          style: TextStyle(
            fontSize: 13,
            color: _mercury,
          ),
        ),
        const SizedBox(height: 16),

        // Liste der Bedingungen
        for (int i = 0; i < provider.regelBedingungen.length; i++)
          _buildConditionItem(context, provider, i),

        // Button für zusätzliche Bedingung
        const SizedBox(height: 12),
        _buildAddConditionButton(provider),
      ],
    );
  }

  Widget _buildConditionItem(
      BuildContext context, ProgressionManagerProvider provider, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // AND-Connector (außer für die erste Bedingung)
        if (index > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(child: Divider(color: _steel.withOpacity(0.3))),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _graphite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _steel.withOpacity(0.3)),
                  ),
                  child: Text(
                    'UND',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _mercury,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: _steel.withOpacity(0.3))),
              ],
            ),
          ),

        // Bedingungseingabe-Card
        _buildConditionEditor(context, provider, index),
      ],
    );
  }

  Widget _buildAddConditionButton(ProgressionManagerProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () {
          HapticFeedback.selectionClick();
          provider.addRegelBedingung();
        },
        icon: Icon(Icons.add, size: 18, color: _emberCore),
        label: Text('Weitere Bedingung hinzufügen',
            style: TextStyle(color: _emberCore)),
        style: TextButton.styleFrom(
          backgroundColor: _emberCore.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: _emberCore.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }

  Widget _buildConditionEditor(
      BuildContext context, ProgressionManagerProvider provider, int index) {
    final bedingung = provider.regelBedingungen[index];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: _charcoal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: _steel.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Variable (linke Seite)
            _buildEditorField(
              context,
              'Variable',
              _buildSelectableButton(
                context: context,
                currentValue: bedingung.left['value'],
                title: 'Variable auswählen',
                subtitle:
                    'Wähle eine Variable für die linke Seite der Bedingung',
                options: provider.verfuegbareVariablen.map((variable) {
                  return SelectionOption(
                    value: variable.id,
                    label: provider.getVariableLabel(variable.id),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    provider.updateRegelBedingung(index, 'leftVariable', value);
                  }
                },
              ),
            ),
            const SizedBox(height: 12),

            // Operator
            _buildEditorField(
              context,
              'Operator',
              _buildSelectableButton(
                context: context,
                currentValue: bedingung.operator,
                title: 'Operator auswählen',
                subtitle: 'Wähle einen Vergleichsoperator',
                options: provider.verfuegbareOperatoren
                    .where((op) => op.type == 'comparison')
                    .map((op) {
                  return SelectionOption(
                    value: op.id,
                    label: op.label,
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
            _buildEditorField(
              context,
              'Vergleichswert',
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Typ (Variable oder Konstante) - OHNE Icon für bessere Textdarstellung
                  Expanded(
                    flex: 4,
                    child: _buildSelectableButton(
                      context: context,
                      currentValue: bedingung.right['type'],
                      title: 'Typ des Vergleichswerts',
                      options: [
                        SelectionOption(
                          value: 'constant',
                          label: 'Zahlenwert',
                        ),
                        SelectionOption(
                          value: 'variable',
                          label: 'Variable',
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          provider.updateRegelBedingung(
                              index, 'rightType', value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Wert (Variable oder Konstante)
                  Expanded(
                    flex: 6,
                    child: bedingung.right['type'] == 'variable'
                        ? _buildRightVariableSelector(
                            context, provider, index, bedingung)
                        : _buildNumberButton(
                            value: bedingung.right['value'].toString(),
                            onPressed: () {
                              _showNumberInputDialog(
                                context: context,
                                title: 'Vergleichswert eingeben',
                                initialValue:
                                    bedingung.right['value'].toString(),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                suffix: '',
                                onValueChanged: (value) {
                                  provider.updateRegelBedingung(
                                      index, 'rightValue', value);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            // Löschen-Button (nur wenn mehr als eine Bedingung vorhanden)
            if (provider.regelBedingungen.length > 1) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    provider.removeRegelBedingung(index);
                  },
                  icon: Icon(Icons.delete_outline, size: 18, color: _mercury),
                  label: Text('Bedingung entfernen',
                      style: TextStyle(color: _mercury)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRightVariableSelector(BuildContext context,
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
      return Center(
        child: Text("Wird aktualisiert...",
            style: TextStyle(fontSize: 14, color: _mercury)),
      );
    }

    return _buildSelectableButton(
      context: context,
      currentValue: rightValue,
      title: 'Vergleichsvariable',
      subtitle: 'Wähle eine Variable für die rechte Seite der Bedingung',
      options: relatedVariables.map((variable) {
        return SelectionOption(
          value: variable.id,
          label: provider.getVariableLabel(variable.id),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titel
        Text(
          provider.regelTyp == 'condition'
              ? 'Aktionen (wenn Bedingungen erfüllt)'
              : 'Direkte Wertzuweisungen',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _snow,
          ),
        ),
        const SizedBox(height: 4),

        // Untertitel
        Text(
          provider.regelTyp == 'condition'
              ? 'Diese Werte werden gesetzt, wenn die Bedingungen erfüllt sind:'
              : 'Diese Werte werden immer direkt gesetzt (ohne Bedingungen):',
          style: TextStyle(
            fontSize: 13,
            color: _mercury,
          ),
        ),
        const SizedBox(height: 16),

        // Die drei Action-Sektionen
        _buildParameterSections(context, provider),
      ],
    );
  }

  Widget _buildParameterSections(
      BuildContext context, ProgressionManagerProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gewicht
        _buildParameterCard(
          context,
          'Gewicht',
          () => _buildKgAction(context, provider),
        ),
        const SizedBox(height: 16),

        // Wiederholungen
        _buildParameterCard(
          context,
          'Wiederholungen',
          () => _buildRepsAction(context, provider),
        ),
        const SizedBox(height: 16),

        // RIR
        _buildParameterCard(
          context,
          'RIR (Reps in Reserve)',
          () => _buildRirAction(context, provider),
        ),
      ],
    );
  }

  Widget _buildParameterCard(
      BuildContext context, String title, Widget Function() contentBuilder) {
    return IntrinsicHeight(
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: _charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: _steel.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _graphite,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _snow,
                ),
              ),
            ),

            // Inhalt
            Padding(
              padding: const EdgeInsets.all(16),
              child: contentBuilder(),
            ),
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
        // Berechnungsmethode
        _buildEditorField(
          context,
          'Berechnungsmethode',
          _buildSelectableButton(
            context: context,
            currentValue: provider.kgAktion['type'],
            title: 'Berechnungsmethode wählen',
            options: [
              SelectionOption(
                value: 'direct',
                label: 'Direkter Wert',
                icon: Icons.straighten_rounded,
                description: 'Gewicht direkt anhand einer Basis berechnen',
              ),
              SelectionOption(
                value: 'oneRM',
                label: '1RM-basierte Berechnung',
                icon: Icons.speed_rounded,
                description:
                    'Gewicht anhand des geschätzten 1-Wiederholungs-Maximum berechnen',
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                provider.updateKgAktion('type', value);
              }
            },
          ),
        ),

        // Je nach Typ unterschiedliche Eingabefelder
        if (provider.kgAktion['type'] == 'direct') ...[
          const SizedBox(height: 16),
          _buildEditorField(
            context,
            'Basiswert',
            _buildSelectableButton(
              context: context,
              currentValue: provider.kgAktion['variable'],
              title: 'Basiswert für Gewicht',
              subtitle: 'Wähle den Basiswert für die Gewichtsberechnung',
              options: [
                SelectionOption(
                  value: 'lastKg',
                  label: 'Letztes Gewicht',
                  icon: Icons.history,
                  description: 'Das Gewicht vom letzten Satz',
                ),
                SelectionOption(
                  value: 'previousKg',
                  label: 'Vorheriges Gewicht',
                  icon: Icons.history_toggle_off,
                  description: 'Das Gewicht vom vorletzten Satz',
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  provider.updateKgAktion('variable', value);
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // Operator und Wert
          _buildEditorField(
            context,
            'Berechnung',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Operator Dropdown
                _buildSelectableButton(
                  context: context,
                  currentValue: provider.kgAktion['operator'],
                  title: 'Berechnungsoperation wählen',
                  subtitle: 'Wie soll der Basiswert verändert werden?',
                  options: [
                    SelectionOption(
                      value: 'none',
                      label: 'Wie ist',
                      icon: Icons.drag_handle,
                      description: 'Wert unverändert übernehmen',
                    ),
                    SelectionOption(
                      value: 'add',
                      label: '+ Wert',
                      icon: Icons.add_circle_outline,
                      description: 'Wert zum Basiswert addieren',
                    ),
                    SelectionOption(
                      value: 'subtract',
                      label: '- Wert',
                      icon: Icons.remove_circle_outline,
                      description: 'Wert vom Basiswert subtrahieren',
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      provider.updateKgAktion('operator', value);
                    }
                  },
                ),

                // Wertauswahl (nur wenn ein Operator gewählt ist)
                if (provider.kgAktion['operator'] != 'none') ...[
                  const SizedBox(height: 16),

                  // Optionen für die Wertquelle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WERTQUELLE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _mercury,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Fester Wert Option
                      _buildSelectableRadioOption(
                        context: context,
                        label: 'Fester Wert',
                        value: 'constant',
                        groupValue: provider.kgAktion['valueType'],
                        onChanged: (value) =>
                            provider.updateKgAktion('valueType', value),
                      ),

                      // Eingabefeld für festen Wert
                      if (provider.kgAktion['valueType'] == 'constant') ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildNumberButton(
                                value: provider.kgAktion['value'].toString(),
                                suffix: 'kg',
                                onPressed: () {
                                  _showNumberInputDialog(
                                    context: context,
                                    title: 'Gewichtswert eingeben',
                                    initialValue:
                                        provider.kgAktion['value'].toString(),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    suffix: 'kg',
                                    onValueChanged: (value) {
                                      provider.updateKgAktion('value', value);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Standard-Steigerung Option
                      _buildSelectableRadioOption(
                        context: context,
                        label: 'Standard-Steigerung',
                        value: 'config',
                        groupValue: provider.kgAktion['valueType'],
                        onChanged: (value) =>
                            provider.updateKgAktion('valueType', value),
                      ),

                      // Anzeige des Standardwerts
                      if (provider.kgAktion['valueType'] == 'config') ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _graphite,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${provider.progressionsConfig['increment']} kg',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _snow,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ] else if (provider.kgAktion['type'] == 'oneRM') ...[
          const SizedBox(height: 16),
          // 1RM-Quelle
          _buildEditorField(
            context,
            '1RM Quelle',
            _buildSelectableButton(
              context: context,
              currentValue: provider.kgAktion['source'] ?? 'last',
              title: '1RM Quelle wählen',
              subtitle:
                  'Welcher Satz soll als Basis für die 1RM-Berechnung dienen?',
              options: [
                SelectionOption(
                  value: 'last',
                  label: 'Aktueller/Letzter Satz',
                  icon: Icons.history,
                  description: 'Das 1RM vom aktuellen/letzten Satz',
                ),
                SelectionOption(
                  value: 'previous',
                  label: 'Vorheriger Satz',
                  icon: Icons.history_toggle_off,
                  description: 'Das 1RM vom vorletzten Satz',
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  provider.updateKgAktion('source', value);
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // 1RM Steigerung
          _buildEditorField(
            context,
            '1RM Steigerung',
            _buildNumberButton(
              value: provider.kgAktion['rmPercentage'].toString(),
              suffix: '%',
              onPressed: () {
                _showNumberInputDialog(
                  context: context,
                  title: '1RM Prozentsatz eingeben',
                  initialValue: provider.kgAktion['rmPercentage'].toString(),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  suffix: '%',
                  onValueChanged: (value) {
                    provider.updateKgAktion('rmPercentage', value);
                  },
                );
              },
            ),
          ),

          // Info-Text für 1RM
          const SizedBox(height: 8),
          Text(
            'Basiert auf Epley-Formel und den Zielwerten für Wiederholungen und RIR',
            style: TextStyle(
              fontSize: 12,
              color: _mercury,
              fontStyle: FontStyle.italic,
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
        // Basiswert
        _buildEditorField(
          context,
          'Basiswert',
          _buildSelectableButton(
            context: context,
            currentValue: provider.repsAktion['variable'],
            title: 'Basiswert für Wiederholungen',
            subtitle: 'Wähle den Basiswert für die Berechnung',
            options: [
              SelectionOption(
                value: 'lastReps',
                label: 'Letzte Wiederh.',
                icon: Icons.history,
                description: 'Wiederholungen vom letzten Satz',
              ),
              SelectionOption(
                value: 'previousReps',
                label: 'Vorherige Wiederh.',
                icon: Icons.history_toggle_off,
                description: 'Wiederholungen vom vorletzten Satz',
              ),
              SelectionOption(
                value: 'targetRepsMin',
                label: 'Min. Wiederh.',
                icon: Icons.arrow_downward,
                description:
                    'Minimaler Wiederholungswert aus der Konfiguration',
              ),
              SelectionOption(
                value: 'targetRepsMax',
                label: 'Max. Wiederh.',
                icon: Icons.arrow_upward,
                description:
                    'Maximaler Wiederholungswert aus der Konfiguration',
              ),
              SelectionOption(
                value: 'constant',
                label: 'Konstante',
                icon: Icons.lock,
                description: 'Ein fester Wiederholungswert',
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                provider.updateRepsAktion('variable', value);
              }
            },
          ),
        ),
        const SizedBox(height: 16),

        // Operator und Wert
        _buildEditorField(
          context,
          'Berechnung',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Operator Dropdown
              _buildSelectableButton(
                context: context,
                currentValue: provider.repsAktion['operator'],
                title: 'Berechnungsoperation wählen',
                subtitle: 'Wie soll der Basiswert verändert werden?',
                options: [
                  SelectionOption(
                    value: 'none',
                    label: 'Wie ist',
                    icon: Icons.drag_handle,
                    description: 'Wert unverändert übernehmen',
                  ),
                  SelectionOption(
                    value: 'add',
                    label: '+ Wert',
                    icon: Icons.add_circle_outline,
                    description: 'Wert zum Basiswert addieren',
                  ),
                  SelectionOption(
                    value: 'subtract',
                    label: '- Wert',
                    icon: Icons.remove_circle_outline,
                    description: 'Wert vom Basiswert subtrahieren',
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    provider.updateRepsAktion('operator', value);
                  }
                },
              ),

              // Wert (nur wenn ein Operator gewählt ist)
              if (provider.repsAktion['operator'] != 'none') ...[
                const SizedBox(height: 12),
                _buildNumberButton(
                  value: provider.repsAktion['value'].toString(),
                  onPressed: () {
                    _showNumberInputDialog(
                      context: context,
                      title: 'Wiederholungswert eingeben',
                      initialValue: provider.repsAktion['value'].toString(),
                      keyboardType: TextInputType.number,
                      onValueChanged: (value) {
                        provider.updateRepsAktion('value', value);
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRirAction(
      BuildContext context, ProgressionManagerProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basiswert
        _buildEditorField(
          context,
          'Basiswert',
          _buildSelectableButton(
            context: context,
            currentValue: provider.rirAktion['variable'],
            title: 'Basiswert für RIR',
            subtitle: 'Wähle den Basiswert für die Berechnung',
            options: [
              SelectionOption(
                value: 'lastRIR',
                label: 'Letzter RIR',
                icon: Icons.history,
                description: 'RIR vom letzten Satz',
              ),
              SelectionOption(
                value: 'previousRIR',
                label: 'Vorheriger RIR',
                icon: Icons.history_toggle_off,
                description: 'RIR vom vorletzten Satz',
              ),
              SelectionOption(
                value: 'targetRIRMin',
                label: 'Min. RIR',
                icon: Icons.arrow_downward,
                description: 'Minimaler RIR-Wert aus der Konfiguration',
              ),
              SelectionOption(
                value: 'targetRIRMax',
                label: 'Max. RIR',
                icon: Icons.arrow_upward,
                description: 'Maximaler RIR-Wert aus der Konfiguration',
              ),
              SelectionOption(
                value: 'constant',
                label: 'Konstante',
                icon: Icons.lock,
                description: 'Ein fester RIR-Wert',
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                provider.updateRirAktion('variable', value);
              }
            },
          ),
        ),
        const SizedBox(height: 16),

        // Operator und Wert
        _buildEditorField(
          context,
          'Berechnung',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Operator Dropdown
              _buildSelectableButton(
                context: context,
                currentValue: provider.rirAktion['operator'],
                title: 'Berechnungsoperation wählen',
                subtitle: 'Wie soll der Basiswert verändert werden?',
                options: [
                  SelectionOption(
                    value: 'none',
                    label: 'Wie ist',
                    icon: Icons.drag_handle,
                    description: 'Wert unverändert übernehmen',
                  ),
                  SelectionOption(
                    value: 'add',
                    label: '+ Wert',
                    icon: Icons.add_circle_outline,
                    description: 'Wert zum Basiswert addieren',
                  ),
                  SelectionOption(
                    value: 'subtract',
                    label: '- Wert',
                    icon: Icons.remove_circle_outline,
                    description: 'Wert vom Basiswert subtrahieren',
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    provider.updateRirAktion('operator', value);
                  }
                },
              ),

              // Wert (nur wenn ein Operator gewählt ist)
              if (provider.rirAktion['operator'] != 'none') ...[
                const SizedBox(height: 12),
                _buildNumberButton(
                  value: provider.rirAktion['value'].toString(),
                  onPressed: () {
                    _showNumberInputDialog(
                      context: context,
                      title: 'RIR-Wert eingeben',
                      initialValue: provider.rirAktion['value'].toString(),
                      keyboardType: TextInputType.number,
                      onValueChanged: (value) {
                        provider.updateRirAktion('value', value);
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Hilfsmethode: Editierfeld mit Label
  Widget _buildEditorField(BuildContext context, String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _mercury,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  // Hilfsmethode: Selektierbarer Button mit Bottom Sheet
  Widget _buildSelectableButton({
    required BuildContext context,
    required String currentValue,
    required String title,
    String? subtitle,
    required List<SelectionOption> options,
    required void Function(String?) onChanged,
  }) {
    // Finde die aktuell ausgewählte Option
    final selectedOption = options.firstWhere(
      (option) => option.value == currentValue,
      orElse: () => options.first,
    );

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        _showOptionsBottomSheet(
          context: context,
          title: title,
          subtitle: subtitle,
          currentValue: currentValue,
          options: options,
          onOptionSelected: onChanged,
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _graphite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _steel.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            if (selectedOption.icon != null) ...[
              Icon(
                selectedOption.icon,
                size: 18,
                color: _mercury,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                selectedOption.label,
                style: const TextStyle(
                  fontSize: 14,
                  color: _snow,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: _mercury,
            ),
          ],
        ),
      ),
    );
  }

  // Hilfsmethode: Bottom Sheet für Optionsauswahl
  void _showOptionsBottomSheet({
    required BuildContext context,
    required String title,
    String? subtitle,
    required String currentValue,
    required List<SelectionOption> options,
    required void Function(String?) onOptionSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: _charcoal,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ziehgriff
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _steel,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Titel
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _snow,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: _mercury,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                Divider(height: 16, color: _steel.withOpacity(0.3)),

                // Optionen-Liste
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = option.value == currentValue;

                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onOptionSelected(option.value);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              if (option.icon != null) ...[
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _emberCore
                                        : _graphite,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    option.icon,
                                    size: 20,
                                    color: isSelected
                                        ? _snow
                                        : _mercury,
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option.label,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: _snow,
                                      ),
                                    ),
                                    if (option.description != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        option.description!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _mercury,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: _emberCore,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // NEUE METHODE: Button für Zahleneingabe
  Widget _buildNumberButton({
    required String value,
    required VoidCallback onPressed,
    String suffix = '',
  }) {
    // Format-Überprüfung: Ist es eine Dezimalzahl?
    final double? doubleValue = double.tryParse(value);
    String displayValue = value;

    // Wenn es eine ganze Zahl ist, entferne die Dezimalstellen für die Anzeige
    if (doubleValue != null && doubleValue == doubleValue.toInt().toDouble()) {
      displayValue = doubleValue.toInt().toString();
    }

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _graphite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _steel.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              suffix.isNotEmpty ? '$displayValue $suffix' : displayValue,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _snow,
              ),
            ),
            Icon(
              Icons.edit_outlined,
              size: 16,
              color: _mercury,
            ),
          ],
        ),
      ),
    );
  }

  // NEUE METHODE: Dialog für Zahleneingabe
  void _showNumberInputDialog({
    required BuildContext context,
    required String title,
    required String initialValue,
    required TextInputType keyboardType,
    String suffix = '',
    required Function(String) onValueChanged,
  }) {
    final TextEditingController controller =
        TextEditingController(text: initialValue);

    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: _charcoal,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog Header
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _graphite,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: _mercury,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: _snow,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Input Field
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _snow,
                  ),
                  decoration: InputDecoration(
                    suffixText: suffix,
                    suffixStyle: TextStyle(color: _mercury),
                    filled: true,
                    fillColor: _graphite,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _emberCore,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.red[400]!,
                        width: 1,
                      ),
                    ),
                  ),
                  onSubmitted: (_) {
                    _applyInputValue(
                        dialogContext, controller.text, onValueChanged);
                  },
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          foregroundColor: _mercury,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Abbrechen',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Confirm button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _applyInputValue(
                              dialogContext, controller.text, onValueChanged);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _emberCore,
                          foregroundColor: _snow,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Bestätigen',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // NEUE METHODE: Wert aus Dialog anwenden
  void _applyInputValue(BuildContext dialogContext, String text,
      Function(String) onValueChanged) {
    // Komma zu Punkt konvertieren für korrekte Verarbeitung
    final String normalizedText = text.replaceAll(',', '.');

    // Wert parsen je nach Typ (Integer oder Double)
    bool isValid = false;

    if (double.tryParse(normalizedText) != null) {
      isValid = true;
    }

    if (isValid) {
      // Wert anwenden und Dialog schließen
      onValueChanged(normalizedText);
      Navigator.pop(dialogContext);

      // Haptisches Feedback
      HapticFeedback.selectionClick();
    } else {
      // Bei ungültiger Eingabe eine Benachrichtigung anzeigen
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: const Text('Bitte gib einen gültigen Wert ein'),
          backgroundColor: _charcoal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Hilfsmethode: Selektierbare Radio-Option
  Widget _buildSelectableRadioOption({
    required BuildContext context,
    required String label,
    required String value,
    required String groupValue,
    required void Function(String?) onChanged,
  }) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(value);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            // Moderner Radio Button
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? _emberCore
                      : _steel,
                  width: 2,
                ),
              ),
              child: Center(
                child: isSelected
                    ? Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _emberCore,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: _snow,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog-Aktionen (nur im Dialog-Modus)
  Widget _buildDialogActions(
      BuildContext context, ProgressionManagerProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Abbrechen-Button
          OutlinedButton(
            onPressed: provider.closeRuleEditor,
            style: OutlinedButton.styleFrom(
              foregroundColor: _mercury,
              side: BorderSide(color: _steel),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('Abbrechen'),
          ),
          const SizedBox(width: 12),

          // Speichern-Button
          ElevatedButton(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              await provider.saveRule();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _emberCore,
              foregroundColor: _snow,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              provider.bearbeiteteRegel != null
                  ? 'Aktualisieren'
                  : 'Hinzufügen',
            ),
          ),
        ],
      ),
    );
  }

  // Hilfsmethode zum Finden verwandter Variablen
  List<ProgressionVariableModel> _getRelatedVariables(
      ProgressionManagerProvider provider, String leftVariableId) {
    final relatedIds = <String>[];

    // Variablen nach Typen gruppieren
    final repetitionVariables = [
      'lastReps',
      'previousReps',
      'targetRepsMin',
      'targetRepsMax'
    ];
    final rirVariables = [
      'lastRIR',
      'previousRIR',
      'targetRIRMin',
      'targetRIRMax'
    ];
    final weightVariables = ['lastKg', 'previousKg', 'increment'];
    final rmVariables = ['last1RM', 'previous1RM'];

    // Logische Zuordnung basierend auf dem Variablentyp
    if (repetitionVariables.contains(leftVariableId)) {
      relatedIds.addAll(repetitionVariables);
    } else if (rirVariables.contains(leftVariableId)) {
      relatedIds.addAll(rirVariables);
    } else if (weightVariables.contains(leftVariableId)) {
      relatedIds.addAll(weightVariables);
    } else if (rmVariables.contains(leftVariableId)) {
      relatedIds.addAll(rmVariables);
    }

    // Die ausgewählte Variable selbst entfernen
    relatedIds.remove(leftVariableId);

    // Falls keine passenden Variablen gefunden wurden, mindestens eine Standardvariable hinzufügen
    if (relatedIds.isEmpty) {
      if (leftVariableId.startsWith('last')) {
        relatedIds.add('previous' + leftVariableId.substring(4));
      } else if (leftVariableId.startsWith('previous')) {
        relatedIds.add('last' + leftVariableId.substring(8));
      } else if (leftVariableId.startsWith('targetReps')) {
        relatedIds.addAll(['lastReps', 'previousReps']);
      } else if (leftVariableId.startsWith('targetRIR')) {
        relatedIds.addAll(['lastRIR', 'previousRIR']);
      } else {
        relatedIds.add('targetRepsMax');
      }
    }

    return provider.verfuegbareVariablen
        .where((v) => relatedIds.contains(v.id))
        .toList();
  }
}

// Color constants matching profile_detail_screen.dart
const Color _midnight = Color(0xFF000000);
const Color _charcoal = Color(0xFF1C1C1E);
const Color _graphite = Color(0xFF2C2C2E);
const Color _steel = Color(0xFF48484A);
const Color _mercury = Color(0xFF8E8E93);
const Color _silver = Color(0xFFAEAEB2);
const Color _snow = Color(0xFFFFFFFF);
const Color _emberCore = Color(0xFFFF4500);