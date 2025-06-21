// lib/screens/progression_manager_screen/rule_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../../../models/progression_manager_screen/progression_variable_model.dart';

/// Ein moderner, intuitiver Editor für Progressionsregeln mit sequenziellem Workflow
class RuleEditorScreen extends StatefulWidget {
  final bool isDialog;

  const RuleEditorScreen({
    Key? key,
    this.isDialog = false,
  }) : super(key: key);

  @override
  State<RuleEditorScreen> createState() => _RuleEditorScreenState();
}

class _RuleEditorScreenState extends State<RuleEditorScreen> {

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);

    // Dialog-Modus
    if (widget.isDialog) {
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
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: RuleEditorContent(isDialog: false),
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

/// Der eigentliche Inhalt des Regel-Editors mit sequenziellem Workflow
class RuleEditorContent extends StatefulWidget {
  final bool isDialog;

  const RuleEditorContent({
    Key? key,
    required this.isDialog,
  }) : super(key: key);

  @override
  State<RuleEditorContent> createState() => _RuleEditorContentState();
}

class _RuleEditorContentState extends State<RuleEditorContent> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;
  

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      final provider = Provider.of<ProgressionManagerProvider>(context, listen: false);
      
      // Debug print
      print('_nextStep called: currentStep=$_currentStep, regelTyp=${provider.regelTyp}');
      
      // Skip conditions step for direct assignment
      if (_currentStep == 0 && provider.regelTyp == 'assignment') {
        print('Skipping to step 2 (actions)');
        _currentStep = 2; // Skip to actions step
      } else {
        print('Normal progression to step ${_currentStep + 1}');
        _currentStep++;
      }
      
      setState(() {});
      
      // Use a slight delay to ensure setState completes first
      Future.delayed(const Duration(milliseconds: 50), () {
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      setState(() {});
      
      // Use a slight delay to ensure setState completes first
      Future.delayed(const Duration(milliseconds: 50), () {
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _goToStep(int step) {
    _currentStep = step;
    setState(() {});
    
    // Use a slight delay to ensure setState completes first
    Future.delayed(const Duration(milliseconds: 50), () {
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress Indicator
        _buildProgressIndicator(),
        const SizedBox(height: 24),

        // Step Pages
        SizedBox(
          height: 500, // Fixed height for consistent layout
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Disable swipe
            children: [
              _buildRuleTypeStep(provider),
              _buildConditionsStep(provider),
              _buildActionsStep(provider),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Navigation buttons
        _buildNavigationButtons(provider),

        // Dialog-Aktionen nur im Dialog-Modus
        if (widget.isDialog) _buildDialogActions(context, provider),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          for (int i = 0; i < _totalSteps; i++) ...[
            _buildStepIndicator(i),
            if (i < _totalSteps - 1) _buildStepConnector(i),
          ],
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step) {
    final isActive = step <= _currentStep;
    final isCurrent = step == _currentStep;
    
    final stepTitles = ['Typ', 'Regeln', 'Aktionen'];

    return Expanded(
      child: GestureDetector(
        onTap: () => _goToStep(step),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? _emberCore : _graphite,
                border: Border.all(
                  color: isCurrent ? _emberCore : _steel,
                  width: isCurrent ? 2 : 1,
                ),
              ),
              child: Center(
                child: isActive
                    ? Icon(
                        step < _currentStep ? Icons.check : Icons.circle,
                        color: _snow,
                        size: 16,
                      )
                    : Text(
                        '${step + 1}',
                        style: TextStyle(
                          color: _mercury,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stepTitles[step],
              style: TextStyle(
                color: isActive ? _snow : _mercury,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepConnector(int step) {
    final isCompleted = step < _currentStep;
    
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: isCompleted ? _emberCore : _steel,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildRuleTypeStep(ProgressionManagerProvider provider) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Regeltyp auswählen',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _snow,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bestimme, wie deine Regel funktionieren soll',
            style: TextStyle(
              fontSize: 15,
              color: _mercury,
            ),
          ),
          const SizedBox(height: 32),

          // Regel-Typ Optionen
          _buildRuleTypeOption(
            context: context,
            title: 'Bedingte Regel',
            subtitle: 'Wenn... Dann...',
            description: 'Diese Regel wird nur angewendet, wenn bestimmte Bedingungen erfüllt sind.',
            icon: Icons.rule_folder_rounded,
            value: 'condition',
            currentValue: provider.regelTyp,
            onTap: () {
              provider.setRegelTyp('condition');
              HapticFeedback.selectionClick();
            },
          ),
          const SizedBox(height: 16),
          _buildRuleTypeOption(
            context: context,
            title: 'Direkte Zuweisung',
            subtitle: 'Immer anwenden',
            description: 'Diese Regel wird immer angewendet, ohne Bedingungen zu prüfen.',
            icon: Icons.assignment_rounded,
            value: 'assignment',
            currentValue: provider.regelTyp,
            onTap: () {
              provider.setRegelTyp('assignment');
              HapticFeedback.selectionClick();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRuleTypeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required String value,
    required String currentValue,
    required VoidCallback onTap,
  }) {
    final isSelected = value == currentValue;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(
                  colors: [
                    _emberCore.withOpacity(0.15),
                    _emberCore.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    _midnight,
                    _charcoal.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _emberCore : _steel.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected 
              ? [
                  BoxShadow(
                    color: _emberCore.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? _emberCore : _graphite,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? _snow : _mercury,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? _emberCore : _snow,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? _emberCore.withOpacity(0.8) : _mercury,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: _mercury,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // Selection indicator
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _emberCore,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: _snow,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionsStep(ProgressionManagerProvider provider) {
    // Skip conditions step for direct assignment
    if (provider.regelTyp == 'assignment') {
      return Center(
        child: Text(
          'Wird übersprungen...',
          style: TextStyle(
            color: _mercury,
            fontSize: 16,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header mit integrierter Vorschau
        Text(
          'Regeln festlegen',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _snow,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        // Integrierte Vorschau
        _buildConditionsPreviewRichText(provider),
        const SizedBox(height: 24),

        // Scrollable conditions editor
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Conditions list
                for (int i = 0; i < provider.regelBedingungen.length; i++) ...[
                  if (i > 0) _buildConditionConnector(),
                  _buildConditionCard(provider, i),
                ],

                const SizedBox(height: 16),
                _buildAddConditionButton(provider),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildCompactConditionsText(ProgressionManagerProvider provider) {
    if (provider.regelBedingungen.isEmpty) {
      return Text(
        'WENN: Noch keine Bedingungen definiert',
        style: TextStyle(
          fontSize: 13,
          color: _mercury,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 13,
          color: _snow,
          height: 1.3,
        ),
        children: [
          TextSpan(
            text: 'WENN ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _emberCore,
            ),
          ),
          for (int i = 0; i < provider.regelBedingungen.length; i++) ...[
            if (i > 0) TextSpan(
              text: ' UND ',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _emberCore,
              ),
            ),
            TextSpan(
              text: _getCompactConditionText(provider, i),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: _snow,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConditionsDetailedView(ProgressionManagerProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < provider.regelBedingungen.length; i++) ...[
          _buildConditionPreviewItem(provider, i),
          if (i < provider.regelBedingungen.length - 1) _buildConditionAnd(),
        ],
      ],
    );
  }


  Widget _buildCompactActionsText(ProgressionManagerProvider provider, List<String> actions) {
    if (actions.isEmpty) {
      return Text(
        'DANN: Noch keine Aktionen konfiguriert',
        style: TextStyle(
          fontSize: 13,
          color: _mercury,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 13,
          color: _snow,
          height: 1.3,
        ),
        children: [
          TextSpan(
            text: 'DANN ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _emberCore,
            ),
          ),
          TextSpan(
            text: actions.join(', '),
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: _snow,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsDetailedView(ProgressionManagerProvider provider, List<String> actions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: _midnight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _steel.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              actions[i],
              style: const TextStyle(
                fontSize: 14,
                color: _snow,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactConditionsPreview(ProgressionManagerProvider provider) {
    if (provider.regelBedingungen.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _steel.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _steel.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          'WENN: Noch keine Bedingungen definiert',
          style: TextStyle(
            fontSize: 13,
            color: _mercury,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _emberCore.withOpacity(0.06),
            _emberCore.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _emberCore.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            color: _snow,
            height: 1.3,
          ),
          children: [
            TextSpan(
              text: 'WENN ',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _emberCore,
              ),
            ),
            for (int i = 0; i < provider.regelBedingungen.length; i++) ...[
              if (i > 0) TextSpan(
                text: ' UND ',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _emberCore,
                ),
              ),
              TextSpan(
                text: _getCompactConditionText(provider, i),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: _snow,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactActionsPreview(ProgressionManagerProvider provider) {
    final actions = <String>[];
    
    // Collect configured actions
    if (provider.kgAktion['type'] != null && provider.kgAktion['type'].isNotEmpty) {
      actions.add(_getKgActionPreview(provider));
    }
    if (provider.repsAktion['operator'] != null && provider.repsAktion['operator'] != 'none') {
      actions.add(_getRepsActionPreview(provider));
    }
    if (provider.rirAktion['operator'] != null && provider.rirAktion['operator'] != 'none') {
      actions.add(_getRirActionPreview(provider));
    }

    if (actions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _steel.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _steel.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          'DANN: Noch keine Aktionen konfiguriert',
          style: TextStyle(
            fontSize: 13,
            color: _mercury,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _emberCore.withOpacity(0.06),
            _emberCore.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _emberCore.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            color: _snow,
            height: 1.3,
          ),
          children: [
            TextSpan(
              text: 'DANN ',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _emberCore,
              ),
            ),
            TextSpan(
              text: actions.join(', '),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: _snow,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCompactConditionText(ProgressionManagerProvider provider, int index) {
    final bedingung = provider.regelBedingungen[index];
    final variable = _getImprovedVariableLabel(provider, bedingung.left['value']);
    final operator = _getOperatorLabel(bedingung.operator);
    final value = _getValueDisplayText(provider, bedingung);
    
    return '$variable $operator $value';
  }

  Widget _buildConditionsPreview(ProgressionManagerProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _emberCore.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.visibility_rounded,
                  size: 16,
                  color: _emberCore,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'REGEL VORSCHAU',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _emberCore,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildConditionsPreviewWidget(provider),
        ],
      ),
    );
  }

  Widget _buildConditionsPreviewWidget(ProgressionManagerProvider provider) {
    if (provider.regelBedingungen.isEmpty) {
      return Text(
        'Noch keine Bedingungen definiert',
        style: TextStyle(
          fontSize: 14,
          color: _mercury,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Build structured condition display
        for (int i = 0; i < provider.regelBedingungen.length; i++) ...[
          if (i == 0) _buildConditionStart(),
          _buildConditionPreviewItem(provider, i),
          if (i < provider.regelBedingungen.length - 1) _buildConditionAnd(),
        ],
      ],
    );
  }

  Widget _buildConditionStart() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'WENN',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _emberCore,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildConditionPreviewItem(ProgressionManagerProvider provider, int index) {
    final bedingung = provider.regelBedingungen[index];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _midnight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _steel.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              color: _snow,
              height: 1.3,
            ),
            children: [
              TextSpan(
                text: _getImprovedVariableLabel(provider, bedingung.left['value']),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _snow,
                ),
              ),
              TextSpan(
                text: ' ${_getOperatorLabel(bedingung.operator)} ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _emberCore,
                ),
              ),
              TextSpan(
                text: _getValueDisplayText(provider, bedingung),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _snow,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConditionAnd() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _emberCore.withOpacity(0.8),
                  _emberCore,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'UND',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _snow,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionConnector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _emberCore.withOpacity(0.1),
                    _emberCore.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _emberCore.withOpacity(0.8),
                  _emberCore,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _steel.withOpacity(0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _emberCore.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.link_rounded,
                  size: 14,
                  color: _snow,
                ),
                const SizedBox(width: 6),
                Text(
                  'UND',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _snow,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _emberCore.withOpacity(0.6),
                    _emberCore.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionCard(ProgressionManagerProvider provider, int index) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _midnight,
            _charcoal.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _steel.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Condition title
          Row(
            children: [
              Text(
                'Bedingung ${index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _snow,
                ),
              ),
              const Spacer(),
              if (provider.regelBedingungen.length > 1)
                IconButton(
                  onPressed: () {
                    provider.removeRegelBedingung(index);
                    HapticFeedback.selectionClick();
                  },
                  icon: const Icon(Icons.close, color: _mercury, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: _graphite,
                    foregroundColor: _mercury,
                    minimumSize: const Size(32, 32),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Condition builder steps
          _buildConditionBuilder(provider, index),
        ],
      ),
    );
  }

  Widget _buildConditionBuilder(ProgressionManagerProvider provider, int index) {
    final bedingung = provider.regelBedingungen[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intuitive condition display
        _buildConditionPreview(provider, index, bedingung),
        
        const SizedBox(height: 20),
        
        // Interactive condition editor
        _buildConditionEditor(provider, index, bedingung),
      ],
    );
  }

  Widget _buildConditionPreview(ProgressionManagerProvider provider, int index, dynamic bedingung) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _emberCore.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.visibility_rounded,
                  size: 16,
                  color: _emberCore,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'BEDINGUNG VORSCHAU',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _emberCore,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                color: _snow,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: 'WENN ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _emberCore,
                  ),
                ),
                TextSpan(
                  text: _getImprovedVariableLabel(provider, bedingung.left['value']),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _snow,
                  ),
                ),
                TextSpan(
                  text: ' ${_getOperatorLabel(bedingung.operator)} ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _emberCore,
                  ),
                ),
                TextSpan(
                  text: _getValueDisplayText(provider, bedingung),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _snow,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionEditor(ProgressionManagerProvider provider, int index, dynamic bedingung) {
    return Column(
      children: [
        // Variable selection
        _buildEditorField(
          title: 'Variable',
          description: 'Was soll überprüft werden?',
          icon: Icons.data_object_rounded,
          child: _buildVariableSelector(provider, index, bedingung),
        ),
        
        const SizedBox(height: 20),
        
        // Operator selection  
        _buildEditorField(
          title: 'Vergleich',
          description: 'Wie soll verglichen werden?',
          icon: Icons.compare_arrows_rounded,
          child: _buildOperatorSelector(provider, index, bedingung),
        ),
        
        const SizedBox(height: 20),
        
        // Value selection
        _buildEditorField(
          title: 'Wert',
          description: 'Womit soll verglichen werden?',
          icon: Icons.tune_rounded,
          child: _buildValueSelector(provider, index, bedingung),
        ),
      ],
    );
  }

  Widget _buildEditorField({
    required String title,
    required String description,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: _emberCore,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _emberCore,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: _mercury,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildConditionStep({
    required int stepNumber,
    required String title,
    required String description,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _emberCore,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(
                    color: _snow,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _snow,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: _mercury,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildVariableSelector(ProgressionManagerProvider provider, int index, dynamic bedingung) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showGroupedVariableBottomSheet(
          context: context,
          title: 'Variable auswählen',
          currentValue: bedingung.left['value'],
          provider: provider,
          onOptionSelected: (value) {
            if (value != null) {
              provider.updateRegelBedingung(index, 'leftVariable', value);
            }
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _steel.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getVariableIcon(bedingung.left['value']),
              size: 18,
              color: _mercury,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getImprovedVariableLabel(provider, bedingung.left['value']),
                style: const TextStyle(
                  fontSize: 14,
                  color: _snow,
                  fontWeight: FontWeight.w500,
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

  Widget _buildOperatorSelector(ProgressionManagerProvider provider, int index, dynamic bedingung) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showOperatorBottomSheet(
          context: context,
          title: 'Vergleich auswählen',
          currentValue: bedingung.operator,
          provider: provider,
          onOptionSelected: (value) {
            if (value != null) {
              provider.updateRegelBedingung(index, 'operator', value);
            }
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _steel.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getOperatorIcon(bedingung.operator),
              size: 18,
              color: _mercury,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getOperatorLabel(bedingung.operator),
                style: const TextStyle(
                  fontSize: 14,
                  color: _snow,
                  fontWeight: FontWeight.w500,
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

  Widget _buildValueSelector(ProgressionManagerProvider provider, int index, dynamic bedingung) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type selector with improved layout
        Container(
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                child: _buildValueTypeButton(
                  label: 'Fester Wert',
                  icon: Icons.pin_rounded,
                  isSelected: bedingung.right['type'] == 'constant',
                  onTap: () {
                    provider.updateRegelBedingung(index, 'rightType', 'constant');
                    HapticFeedback.selectionClick();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildValueTypeButton(
                  label: 'Variable',
                  icon: Icons.data_object_rounded,
                  isSelected: bedingung.right['type'] == 'variable',
                  onTap: () {
                    provider.updateRegelBedingung(index, 'rightType', 'variable');
                    HapticFeedback.selectionClick();
                  },
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Value input with improved layout
        Container(
          width: double.infinity,
          child: bedingung.right['type'] == 'variable'
              ? _buildRightVariableSelector(provider, index, bedingung)
              : _buildNumberInput(
                  value: bedingung.right['value'].toString(),
                  onChanged: (value) {
                    provider.updateRegelBedingung(index, 'rightValue', value);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildValueTypeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    _emberCore.withOpacity(0.2),
                    _emberCore.withOpacity(0.1),
                  ],
                )
              : null,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _emberCore : _steel.withOpacity(0.4),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? _emberCore : _mercury,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? _emberCore : _snow,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightVariableSelector(ProgressionManagerProvider provider, int index, dynamic bedingung) {
    final relatedVariables = _getRelatedVariables(provider, bedingung.left['value']);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showGroupedVariableBottomSheet(
          context: context,
          title: 'Variable',
          currentValue: bedingung.right['value'].toString(),
          provider: provider,
          variableFilter: relatedVariables.map((v) => v.id).toList(),
          onOptionSelected: (value) {
            if (value != null) {
              provider.updateRegelBedingung(index, 'rightValue', value);
            }
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _steel.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getVariableIcon(bedingung.right['value'].toString()),
              size: 18,
              color: _mercury,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getImprovedVariableLabel(provider, bedingung.right['value'].toString()),
                style: const TextStyle(
                  fontSize: 14,
                  color: _snow,
                  fontWeight: FontWeight.w500,
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

  Widget _buildNumberInput({
    required String value,
    required Function(String) onChanged,
  }) {
    return GestureDetector(
      onTap: () {
        _showNumberInputDialog(
          context: context,
          title: 'Wert eingeben',
          initialValue: value,
          onValueChanged: onChanged,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _steel.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _snow,
              ),
            ),
            const Icon(
              Icons.edit_rounded,
              size: 16,
              color: _mercury,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddConditionButton(ProgressionManagerProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          provider.addRegelBedingung();
          HapticFeedback.selectionClick();
        },
        icon: Icon(Icons.add_circle_outline, size: 20, color: _emberCore),
        label: Text(
          'Weitere Bedingung hinzufügen',
          style: TextStyle(color: _emberCore),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _emberCore,
          side: BorderSide(color: _emberCore.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildActionsStep(ProgressionManagerProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildActionsHeader(provider),
        const SizedBox(height: 24),

        // Scrollable action cards
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Interactive action cards
                _buildModernActionCard(
                  title: 'Gewicht',
                  subtitle: 'Neues Arbeitsgewicht bestimmen',
                  builder: () => _buildKgAction(provider),
                  provider: provider,
                ),
                const SizedBox(height: 20),
                _buildModernActionCard(
                  title: 'Wiederholungen',
                  subtitle: 'Ziel-Wiederholungen festlegen',
                  builder: () => _buildRepsAction(provider),
                  provider: provider,
                ),
                const SizedBox(height: 20),
                _buildModernActionCard(
                  title: 'RIR',
                  subtitle: 'Reps in Reserve definieren',
                  builder: () => _buildRirAction(provider),
                  provider: provider,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsHeader(ProgressionManagerProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          provider.regelTyp == 'condition'
              ? 'Aktionen festlegen'
              : 'Werte zuweisen',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _snow,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        // Integrierte Aktions-Vorschau
        _buildActionsPreviewRichText(provider),
      ],
    );
  }

  Widget _buildActionsPreview(ProgressionManagerProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _emberCore.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.preview_rounded,
                  size: 16,
                  color: _emberCore,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AKTIONS VORSCHAU',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _emberCore,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionPreviewText(provider),
        ],
      ),
    );
  }

  Widget _buildActionPreviewText(ProgressionManagerProvider provider) {
    final actions = <String>[];
    
    // Collect configured actions
    if (provider.kgAktion['type'] != null && provider.kgAktion['type'].isNotEmpty) {
      actions.add(_getKgActionPreview(provider));
    }
    if (provider.repsAktion['operator'] != null && provider.repsAktion['operator'] != 'none') {
      actions.add(_getRepsActionPreview(provider));
    }
    if (provider.rirAktion['operator'] != null && provider.rirAktion['operator'] != 'none') {
      actions.add(_getRirActionPreview(provider));
    }

    if (actions.isEmpty) {
      return Text(
        'Noch keine Aktionen konfiguriert',
        style: TextStyle(
          fontSize: 14,
          color: _mercury,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 15,
          color: _snow,
          height: 1.4,
        ),
        children: [
          TextSpan(
            text: 'DANN ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _emberCore,
            ),
          ),
          TextSpan(
            text: actions.join(', '),
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: _snow,
            ),
          ),
        ],
      ),
    );
  }

  String _getKgActionPreview(ProgressionManagerProvider provider) {
    if (provider.kgAktion['type'] == 'oneRM') {
      return 'Gewicht auf ${provider.kgAktion['rmPercentage']}% vom 1RM setzen';
    } else if (provider.kgAktion['operator'] == 'add') {
      return 'Gewicht um ${provider.kgAktion['value']}kg erhöhen';
    } else if (provider.kgAktion['operator'] == 'subtract') {
      return 'Gewicht um ${provider.kgAktion['value']}kg verringern';
    } else {
      return 'Gewicht beibehalten';
    }
  }

  String _getRepsActionPreview(ProgressionManagerProvider provider) {
    if (provider.repsAktion['operator'] == 'add') {
      return 'Wdhl um ${provider.repsAktion['value']} erhöhen';
    } else if (provider.repsAktion['operator'] == 'subtract') {
      return 'Wdhl um ${provider.repsAktion['value']} verringern';
    } else {
      return 'Wdhl beibehalten';
    }
  }

  String _getRirActionPreview(ProgressionManagerProvider provider) {
    if (provider.rirAktion['operator'] == 'add') {
      return 'RIR um ${provider.rirAktion['value']} erhöhen';
    } else if (provider.rirAktion['operator'] == 'subtract') {
      return 'RIR um ${provider.rirAktion['value']} verringern';
    } else {
      return 'RIR beibehalten';
    }
  }

  Widget _buildModernActionCard({
    required String title,
    required String subtitle,
    required Widget Function() builder,
    required ProgressionManagerProvider provider,
  }) {
    final isExpanded = _getActionCardExpanded(title);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _midnight,
            _charcoal.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _steel.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with toggle
          GestureDetector(
            onTap: () => _toggleActionCard(title),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _emberCore.withOpacity(0.1),
                    _emberCore.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: isExpanded 
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      )
                    : BorderRadius.circular(16),
                border: isExpanded
                    ? Border(
                        bottom: BorderSide(
                          color: _emberCore.withOpacity(0.2),
                          width: 1,
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _snow,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: _mercury,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Status indicator
                  _buildActionStatus(title, provider),
                  const SizedBox(width: 12),
                  
                  // Expand/collapse button
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _emberCore,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable content
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: isExpanded ? null : 0,
            child: isExpanded
                ? Container(
                    padding: const EdgeInsets.all(20),
                    child: builder(),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionStatus(String title, ProgressionManagerProvider provider) {
    bool isConfigured = false;
    
    switch (title) {
      case 'Gewicht':
        isConfigured = provider.kgAktion['type'] != null && provider.kgAktion['type'].isNotEmpty;
        break;
      case 'Wiederholungen':
        isConfigured = provider.repsAktion['operator'] != null && provider.repsAktion['operator'] != 'none';
        break;
      case 'RIR':
        isConfigured = provider.rirAktion['operator'] != null && provider.rirAktion['operator'] != 'none';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isConfigured ? _emberCore.withOpacity(0.2) : _steel.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConfigured ? _emberCore.withOpacity(0.5) : _steel.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isConfigured ? _emberCore : _mercury,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isConfigured ? 'Aktiv' : 'Inaktiv',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isConfigured ? _emberCore : _mercury,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // State management for expanded cards
  final Map<String, bool> _expandedCards = {
    'Gewicht': true,
    'Wiederholungen': false,
    'RIR': false,
  };

  bool _getActionCardExpanded(String title) {
    return _expandedCards[title] ?? false;
  }

  void _toggleActionCard(String title) {
    setState(() {
      _expandedCards[title] = !(_expandedCards[title] ?? false);
    });
    HapticFeedback.selectionClick();
  }

  Widget _buildActionCategory({
    required String title,
    required IconData icon,
    required Widget Function() builder,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _midnight,
            _charcoal.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _steel.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _emberCore.withOpacity(0.1),
                  _emberCore.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: _emberCore.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: _emberCore, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _snow,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: builder(),
          ),
        ],
      ),
    );
  }

  Widget _buildKgAction(ProgressionManagerProvider provider) {
    // Simplified weight action for better UX
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildActionField(
          title: 'Berechnungsart',
          child: _buildSelectableButton(
            context: context,
            currentValue: provider.kgAktion['type'],
            title: 'Berechnungsart',
            options: [
              SelectionOption(
                value: 'direct',
                label: 'Direkt berechnen',
                icon: Icons.straighten_rounded,
                description: 'Gewicht direkt vom letzten Satz übernehmen und anpassen',
              ),
              SelectionOption(
                value: 'oneRM',
                label: '1RM-basiert kalkulieren',
                icon: Icons.speed_rounded,
                description: 'Arbeitsgewicht automatisch aus 1RM-Prozentsatz berechnen',
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                provider.updateKgAktion('type', value);
              }
            },
          ),
        ),
        
        if (provider.kgAktion['type'] == 'direct') ...[
          const SizedBox(height: 16),
          _buildDirectWeightAction(provider),
        ] else if (provider.kgAktion['type'] == 'oneRM') ...[
          const SizedBox(height: 16),
          _buildOneRMWeightAction(provider),
        ],
      ],
    );
  }

  Widget _buildDirectWeightAction(ProgressionManagerProvider provider) {
    return Column(
      children: [
        _buildActionField(
          title: 'Basis',
          child: _buildSelectableButton(
            context: context,
            currentValue: provider.kgAktion['variable'],
            title: 'Basis-Gewicht',
            options: [
              SelectionOption(
                value: 'lastKg',
                label: 'Letztes Gewicht',
                icon: Icons.history_rounded,
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
        _buildActionField(
          title: 'Änderung',
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildSelectableButton(
                  context: context,
                  currentValue: provider.kgAktion['operator'],
                  title: 'Operation',
                  options: [
                    SelectionOption(
                      value: 'add',
                      label: '+ kg',
                      icon: Icons.add_rounded,
                    ),
                    SelectionOption(
                      value: 'subtract',
                      label: '- kg',
                      icon: Icons.remove_rounded,
                    ),
                    SelectionOption(
                      value: 'none',
                      label: 'Gleich',
                      icon: Icons.drag_handle_rounded,
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      provider.updateKgAktion('operator', value);
                    }
                  },
                ),
              ),
              if (provider.kgAktion['operator'] != 'none') ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _buildNumberInput(
                    value: provider.kgAktion['value'].toString(),
                    onChanged: (value) {
                      provider.updateKgAktion('value', value);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOneRMWeightAction(ProgressionManagerProvider provider) {
    return Column(
      children: [
        _buildActionField(
          title: 'Prozentsatz vom 1RM',
          child: _buildNumberInput(
            value: '${provider.kgAktion['rmPercentage']}%',
            onChanged: (value) {
              final numValue = double.tryParse(value.replaceAll('%', ''));
              if (numValue != null) {
                provider.updateKgAktion('rmPercentage', numValue);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRepsAction(ProgressionManagerProvider provider) {
    return Column(
      children: [
        _buildActionField(
          title: 'Basis',
          child: _buildSelectableButton(
            context: context,
            currentValue: provider.repsAktion['variable'],
            title: 'Basis-Wiederholungen',
            options: [
              SelectionOption(
                value: 'lastReps',
                label: 'Letzte Wiederh.',
                icon: Icons.history_rounded,
              ),
              SelectionOption(
                value: 'targetRepsMin',
                label: 'Min. Ziel',
                icon: Icons.arrow_downward_rounded,
              ),
              SelectionOption(
                value: 'targetRepsMax',
                label: 'Max. Ziel',
                icon: Icons.arrow_upward_rounded,
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
        _buildActionField(
          title: 'Änderung',
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildSelectableButton(
                  context: context,
                  currentValue: provider.repsAktion['operator'],
                  title: 'Operation',
                  options: [
                    SelectionOption(
                      value: 'add',
                      label: '+',
                      icon: Icons.add_rounded,
                    ),
                    SelectionOption(
                      value: 'subtract',
                      label: '-',
                      icon: Icons.remove_rounded,
                    ),
                    SelectionOption(
                      value: 'none',
                      label: 'Gleich',
                      icon: Icons.drag_handle_rounded,
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      provider.updateRepsAktion('operator', value);
                    }
                  },
                ),
              ),
              if (provider.repsAktion['operator'] != 'none') ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _buildNumberInput(
                    value: provider.repsAktion['value'].toString(),
                    onChanged: (value) {
                      provider.updateRepsAktion('value', value);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRirAction(ProgressionManagerProvider provider) {
    return Column(
      children: [
        _buildActionField(
          title: 'Basis',
          child: _buildSelectableButton(
            context: context,
            currentValue: provider.rirAktion['variable'],
            title: 'Basis-RIR',
            options: [
              SelectionOption(
                value: 'lastRIR',
                label: 'Letzter RIR',
                icon: Icons.history_rounded,
              ),
              SelectionOption(
                value: 'targetRIRMin',
                label: 'Min. Ziel',
                icon: Icons.arrow_downward_rounded,
              ),
              SelectionOption(
                value: 'targetRIRMax',
                label: 'Max. Ziel',
                icon: Icons.arrow_upward_rounded,
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
        _buildActionField(
          title: 'Änderung',
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildSelectableButton(
                  context: context,
                  currentValue: provider.rirAktion['operator'],
                  title: 'Operation',
                  options: [
                    SelectionOption(
                      value: 'add',
                      label: '+',
                      icon: Icons.add_rounded,
                    ),
                    SelectionOption(
                      value: 'subtract',
                      label: '-',
                      icon: Icons.remove_rounded,
                    ),
                    SelectionOption(
                      value: 'none',
                      label: 'Gleich',
                      icon: Icons.drag_handle_rounded,
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      provider.updateRirAktion('operator', value);
                    }
                  },
                ),
              ),
              if (provider.rirAktion['operator'] != 'none') ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _buildNumberInput(
                    value: provider.rirAktion['value'].toString(),
                    onChanged: (value) {
                      provider.updateRirAktion('value', value);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionField({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _mercury,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildNavigationButtons(ProgressionManagerProvider provider) {
    final canGoNext = _canProceedToNextStep(provider);

    return Row(
      children: [
        // Previous button
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Zurück'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _mercury,
                side: BorderSide(color: _steel),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        
        if (_currentStep > 0) const SizedBox(width: 12),

        // Next/Complete button
        Expanded(
          flex: _currentStep > 0 ? 1 : 1,
          child: ElevatedButton.icon(
            onPressed: canGoNext 
                ? (_currentStep < _totalSteps - 1 
                    ? _nextStep 
                    : () async {
                        // Save rule when on last step
                        final provider = Provider.of<ProgressionManagerProvider>(context, listen: false);
                        HapticFeedback.mediumImpact();
                        await provider.saveRule();
                      }) 
                : null,
            icon: Icon(
              _currentStep < _totalSteps - 1 
                  ? Icons.arrow_forward_rounded 
                  : Icons.check_rounded,
              size: 18,
            ),
            label: Text(
              _currentStep < _totalSteps - 1 ? 'Weiter' : 'Regel speichern',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: canGoNext ? _emberCore : _graphite,
              foregroundColor: canGoNext ? _snow : _mercury,
              disabledBackgroundColor: _graphite,
              disabledForegroundColor: _mercury,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _canProceedToNextStep(ProgressionManagerProvider provider) {
    switch (_currentStep) {
      case 0: // Rule type step
        return provider.regelTyp.isNotEmpty;
      case 1: // Conditions step
        if (provider.regelTyp == 'assignment') return true;
        return provider.regelBedingungen.isNotEmpty;
      case 2: // Actions step
        return true; // Always allow completing actions step
      default:
        return false;
    }
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
                borderRadius: BorderRadius.circular(8),
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
                borderRadius: BorderRadius.circular(8),
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

  // Helper method for selectable buttons
  Widget _buildSelectableButton({
    required BuildContext context,
    required String currentValue,
    required String title,
    required List<SelectionOption> options,
    required void Function(String?) onChanged,
  }) {
    final selectedOption = options.firstWhere(
      (option) => option.value == currentValue,
      orElse: () => options.first,
    );

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showOptionsBottomSheet(
          context: context,
          title: title,
          currentValue: currentValue,
          options: options,
          onOptionSelected: onChanged,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _steel.withOpacity(0.4),
            width: 1,
          ),
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
                  fontWeight: FontWeight.w500,
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

  // Bottom sheet for option selection
  void _showOptionsBottomSheet({
    required BuildContext context,
    required String title,
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
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            decoration: BoxDecoration(
              color: _charcoal,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _steel,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _snow,
                    ),
                  ),
                ),

                // Options
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = option.value == currentValue;

                      return ListTile(
                        leading: option.icon != null
                            ? Icon(
                                option.icon,
                                color: isSelected ? _emberCore : _mercury,
                              )
                            : null,
                        title: Text(
                          option.label,
                          style: TextStyle(
                            color: isSelected ? _emberCore : _snow,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        subtitle: option.description != null
                            ? Text(
                                option.description!,
                                style: TextStyle(color: _mercury, fontSize: 12),
                              )
                            : null,
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: _emberCore)
                            : null,
                        onTap: () {
                          onOptionSelected(option.value);
                          Navigator.pop(context);
                        },
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

  // Number input dialog
  void _showNumberInputDialog({
    required BuildContext context,
    required String title,
    required String initialValue,
    required Function(String) onValueChanged,
  }) {
    final controller = TextEditingController(text: initialValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _charcoal,
        title: Text(title, style: const TextStyle(color: _snow)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: const TextStyle(color: _snow),
          decoration: InputDecoration(
            filled: false,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _steel.withOpacity(0.4),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _steel.withOpacity(0.4),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _emberCore,
                width: 2,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen', style: TextStyle(color: _mercury)),
          ),
          ElevatedButton(
            onPressed: () {
              onValueChanged(controller.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _emberCore),
            child: const Text('OK', style: TextStyle(color: _snow)),
          ),
        ],
      ),
    );
  }

  // Helper methods for operator display
  String _getOperatorLabel(String operatorId) {
    switch (operatorId) {
      case 'gt':
        return 'größer als';
      case 'gte':
        return 'größer oder gleich';
      case 'lt':
        return 'kleiner als';
      case 'lte':
        return 'kleiner oder gleich';
      case 'eq':
        return 'gleich';
      default:
        return operatorId;
    }
  }

  String _getValueDisplayText(ProgressionManagerProvider provider, dynamic bedingung) {
    if (bedingung.right['type'] == 'variable') {
      return _getImprovedVariableLabel(provider, bedingung.right['value'].toString());
    } else {
      return bedingung.right['value'].toString();
    }
  }

  // Operator bottom sheet
  void _showOperatorBottomSheet({
    required BuildContext context,
    required String title,
    required String currentValue,
    required ProgressionManagerProvider provider,
    required void Function(String?) onOptionSelected,
  }) {
    final operatorOptions = [
      {'id': 'gt', 'label': 'größer als', 'symbol': '>', 'description': 'Wert muss größer sein'},
      {'id': 'gte', 'label': 'größer oder gleich', 'symbol': '≥', 'description': 'Wert muss größer oder gleich sein'},
      {'id': 'lt', 'label': 'kleiner als', 'symbol': '<', 'description': 'Wert muss kleiner sein'},
      {'id': 'lte', 'label': 'kleiner oder gleich', 'symbol': '≤', 'description': 'Wert muss kleiner oder gleich sein'},
      {'id': 'eq', 'label': 'gleich', 'symbol': '=', 'description': 'Wert muss exakt gleich sein'},
    ];

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
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            decoration: BoxDecoration(
              color: _charcoal,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _steel,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _snow,
                    ),
                  ),
                ),

                // Operators
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: operatorOptions.length,
                    itemBuilder: (context, index) {
                      final operator = operatorOptions[index];
                      final isSelected = operator['id'] == currentValue;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    _emberCore.withOpacity(0.1),
                                    _emberCore.withOpacity(0.05),
                                  ],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: _emberCore)
                              : null,
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(
                                color: isSelected ? _emberCore : _steel.withOpacity(0.4),
                                width: isSelected ? 2 : 1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                operator['symbol']!,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? _snow : _mercury,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            operator['label']!,
                            style: TextStyle(
                              color: isSelected ? _emberCore : _snow,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            operator['description']!,
                            style: TextStyle(
                              color: _mercury,
                              fontSize: 12,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: _emberCore, size: 20)
                              : null,
                          onTap: () {
                            onOptionSelected(operator['id']);
                            Navigator.pop(context);
                          },
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

  // Helper methods for icons
  IconData _getVariableIcon(String variableId) {
    if (variableId.contains('Reps')) return Icons.repeat_rounded;
    if (variableId.contains('RIR')) return Icons.speed_rounded;
    if (variableId.contains('Kg')) return Icons.fitness_center_rounded;
    if (variableId.contains('RM')) return Icons.trending_up_rounded;
    return Icons.data_object_rounded;
  }

  IconData _getOperatorIcon(String operatorId) {
    switch (operatorId) {
      case 'gt': return Icons.keyboard_double_arrow_up_rounded;
      case 'lt': return Icons.keyboard_double_arrow_down_rounded;
      case 'gte': return Icons.keyboard_arrow_up_rounded;
      case 'lte': return Icons.keyboard_arrow_down_rounded;
      case 'eq': return Icons.drag_handle_rounded;
      default: return Icons.compare_arrows_rounded;
    }
  }

  // Helper method to get improved variable labels
  String _getImprovedVariableLabel(ProgressionManagerProvider provider, String variableId) {
    switch (variableId) {
      case 'lastKg':
        return 'Gewicht (letzter Satz)';
      case 'lastReps':
        return 'Wdhl (letzter Satz)';
      case 'lastRIR':
        return 'RIR (letzter Satz)';
      case 'last1RM':
        return '1RM (letzter Satz)';
      case 'previousKg':
        return 'Gewicht (gleicher Satz, letzte Einheit)';
      case 'previousReps':
        return 'Wdhl (gleicher Satz, letzte Einheit)';
      case 'previousRIR':
        return 'RIR (gleicher Satz, letzte Einheit)';
      case 'previous1RM':
        return '1RM (gleicher Satz, letzte Einheit)';
      case 'targetRepsMin':
        return 'Ziel Min. Wdhl';
      case 'targetRepsMax':
        return 'Ziel Max. Wdhl';
      case 'targetRIRMin':
        return 'Ziel Min. RIR';
      case 'targetRIRMax':
        return 'Ziel Max. RIR';
      case 'increment':
        return 'Standard Steigerung';
      default:
        return provider.getVariableLabel(variableId);
    }
  }

  // Grouped variable bottom sheet
  void _showGroupedVariableBottomSheet({
    required BuildContext context,
    required String title,
    required String currentValue,
    required ProgressionManagerProvider provider,
    List<String>? variableFilter,
    required void Function(String?) onOptionSelected,
  }) {
    // Group variables by category
    final variableGroups = <String, List<Map<String, dynamic>>>{
      'Letzter Satz': [],
      'Gleicher Satz, letzte Einheit': [],
      'Zielwerte': [],
      'Sonstiges': [],
    };

    final availableVariables = variableFilter != null
        ? provider.verfuegbareVariablen.where((v) => variableFilter.contains(v.id)).toList()
        : provider.verfuegbareVariablen;

    for (final variable in availableVariables) {
      final variableData = {
        'id': variable.id,
        'label': _getImprovedVariableLabel(provider, variable.id),
        'icon': _getVariableIcon(variable.id),
        'description': _getVariableDescription(variable.id),
      };

      if (variable.id.startsWith('last')) {
        variableGroups['Letzter Satz']!.add(variableData);
      } else if (variable.id.startsWith('previous')) {
        variableGroups['Gleicher Satz, letzte Einheit']!.add(variableData);
      } else if (variable.id.startsWith('target')) {
        variableGroups['Zielwerte']!.add(variableData);
      } else {
        variableGroups['Sonstiges']!.add(variableData);
      }
    }

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
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: _charcoal,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _steel,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _snow,
                    ),
                  ),
                ),

                // Grouped variables
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final entry in variableGroups.entries)
                        if (entry.value.isNotEmpty) ...[
                          _buildVariableGroupHeader(entry.key),
                          ...entry.value.map((variable) => _buildVariableOption(
                                variable: variable,
                                currentValue: currentValue,
                                onOptionSelected: onOptionSelected,
                              )),
                          const SizedBox(height: 16),
                        ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVariableGroupHeader(String groupName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _emberCore.withOpacity(0.8),
                  _emberCore,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              groupName.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _snow,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _emberCore.withOpacity(0.5),
                    _emberCore.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariableOption({
    required Map<String, dynamic> variable,
    required String currentValue,
    required void Function(String?) onOptionSelected,
  }) {
    final isSelected = variable['id'] == currentValue;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  _emberCore.withOpacity(0.1),
                  _emberCore.withOpacity(0.05),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: _emberCore)
            : null,
      ),
      child: ListTile(
        leading: Icon(
          variable['icon'],
          color: isSelected ? _emberCore : _mercury,
          size: 22,
        ),
        title: Text(
          variable['label'],
          style: TextStyle(
            color: isSelected ? _emberCore : _snow,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 15,
          ),
        ),
        subtitle: variable['description'] != null
            ? Text(
                variable['description'],
                style: TextStyle(
                  color: _mercury,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: isSelected
            ? Icon(Icons.check_circle, color: _emberCore, size: 20)
            : null,
        onTap: () {
          onOptionSelected(variable['id']);
          Navigator.pop(context);
        },
      ),
    );
  }

  String _getVariableDescription(String variableId) {
    switch (variableId) {
      case 'lastKg':
        return 'Gewicht vom unmittelbar vorhergehenden Satz dieser Einheit';
      case 'lastReps':
        return 'Wdhl vom unmittelbar vorhergehenden Satz dieser Einheit';
      case 'lastRIR':
        return 'RIR vom unmittelbar vorhergehenden Satz dieser Einheit';
      case 'last1RM':
        return '1RM basierend auf dem unmittelbar vorhergehenden Satz';
      case 'previousKg':
        return 'Gewicht vom gleichen Satz der letzten Einheit';
      case 'previousReps':
        return 'Wdhl vom gleichen Satz der letzten Einheit';
      case 'previousRIR':
        return 'RIR vom gleichen Satz der letzten Einheit';
      case 'previous1RM':
        return '1RM vom gleichen Satz der letzten Einheit';
      case 'targetRepsMin':
        return 'Mindestanzahl der geplanten Wdhl';
      case 'targetRepsMax':
        return 'Höchstanzahl der geplanten Wdhl';
      case 'targetRIRMin':
        return 'Mindest-RIR Zielwert';
      case 'targetRIRMax':
        return 'Höchst-RIR Zielwert';
      case 'increment':
        return 'Standard Gewichtssteigerung für diese Übung';
      default:
        return '';
    }
  }

  // Helper method to get related variables
  List<ProgressionVariableModel> _getRelatedVariables(
      ProgressionManagerProvider provider, String leftVariableId) {
    final relatedIds = <String>[];

    // Variable groupings
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

    // Logic for related variables
    if (repetitionVariables.contains(leftVariableId)) {
      relatedIds.addAll(repetitionVariables);
    } else if (rirVariables.contains(leftVariableId)) {
      relatedIds.addAll(rirVariables);
    } else if (weightVariables.contains(leftVariableId)) {
      relatedIds.addAll(weightVariables);
    } else if (rmVariables.contains(leftVariableId)) {
      relatedIds.addAll(rmVariables);
    }

    // Remove the selected variable itself
    relatedIds.remove(leftVariableId);

    // Default fallback
    if (relatedIds.isEmpty) {
      relatedIds.add('targetRepsMax');
    }

    return provider.verfuegbareVariablen
        .where((v) => relatedIds.contains(v.id))
        .toList();
  }

  String _buildConditionsPreviewText(ProgressionManagerProvider provider) {
    if (provider.regelBedingungen.isEmpty) {
      return 'Noch keine Bedingungen definiert';
    }

    final List<String> conditionTexts = [];
    
    for (int i = 0; i < provider.regelBedingungen.length; i++) {
      final condition = provider.regelBedingungen[i];
      
      // Linke Variable
      final leftLabel = provider.getVariableLabel(condition.left['value']);
      
      // Operator
      final operatorLabel = provider.getOperatorLabel(condition.operator);
      
      // Rechte Seite
      String rightLabel;
      if (condition.right['type'] == 'variable') {
        rightLabel = provider.getVariableLabel(condition.right['value']);
      } else {
        rightLabel = condition.right['value'].toString();
      }
      
      conditionTexts.add('$leftLabel $operatorLabel $rightLabel');
    }
    
    // Alle Bedingungen vollständig anzeigen
    if (conditionTexts.length == 1) {
      return 'WENN ${conditionTexts.first}';
    } else {
      return 'WENN ${conditionTexts.join(' UND ')}';
    }
  }

  String _buildActionsPreviewText(ProgressionManagerProvider provider) {
    final List<String> actionTexts = [];
    
    // Gewicht-Aktion
    if (provider.kgAktion['type'] == 'oneRM') {
      final source = provider.kgAktion['source'] ?? 'last';
      final sourceText = source == 'previous' ? 'vorherigen' : 'aktuellen';
      actionTexts.add('1RM vom $sourceText Satz +${provider.kgAktion['rmPercentage']}%');
    } else if (provider.kgAktion['operator'] != 'none') {
      final variable = provider.getVariableLabel(provider.kgAktion['variable']);
      final operator = provider.getOperatorLabel(provider.kgAktion['operator']);
      final value = provider.kgAktion['value'];
      actionTexts.add('$variable $operator ${value}kg');
    } else {
      final variable = provider.getVariableLabel(provider.kgAktion['variable']);
      actionTexts.add(variable);
    }
    
    // Wiederholungs-Aktion
    if (provider.repsAktion['operator'] != 'none') {
      final variable = provider.getVariableLabel(provider.repsAktion['variable']);
      final operator = provider.getOperatorLabel(provider.repsAktion['operator']);
      final value = provider.repsAktion['value'];
      actionTexts.add('$variable $operator $value');
    } else {
      final variable = provider.getVariableLabel(provider.repsAktion['variable']);
      actionTexts.add(variable);
    }
    
    // RIR-Aktion
    if (provider.rirAktion['operator'] != 'none') {
      final variable = provider.getVariableLabel(provider.rirAktion['variable']);
      final operator = provider.getOperatorLabel(provider.rirAktion['operator']);
      final value = provider.rirAktion['value'];
      actionTexts.add('$variable $operator $value');
    } else {
      final variable = provider.getVariableLabel(provider.rirAktion['variable']);
      actionTexts.add(variable);
    }
    
    // Alle Aktionen anzeigen
    return 'DANN ${actionTexts.join(', ')}';
  }

  Widget _buildConditionsPreviewRichText(ProgressionManagerProvider provider) {
    final text = _buildConditionsPreviewText(provider);
    
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 13,
          color: _silver,
          height: 1.3,
        ),
        children: _highlightKeywords(text),
      ),
    );
  }

  Widget _buildActionsPreviewRichText(ProgressionManagerProvider provider) {
    final text = _buildActionsPreviewText(provider);
    
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 13,
          color: _silver,
          height: 1.3,
        ),
        children: _highlightKeywords(text),
      ),
    );
  }

  List<TextSpan> _highlightKeywords(String text) {
    final keywords = ['WENN', 'UND', 'DANN'];
    final spans = <TextSpan>[];
    
    // Finde alle Keyword-Positionen
    final positions = <MapEntry<int, String>>[];
    for (final keyword in keywords) {
      int index = 0;
      while ((index = text.indexOf(keyword, index)) != -1) {
        positions.add(MapEntry(index, keyword));
        index += keyword.length;
      }
    }
    
    // Sortiere nach Position
    positions.sort((a, b) => a.key.compareTo(b.key));
    
    int lastIndex = 0;
    
    for (final entry in positions) {
      final index = entry.key;
      final keyword = entry.value;
      
      // Text vor dem Keyword
      if (index > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, index),
        ));
      }
      
      // Das Keyword in Orange
      spans.add(TextSpan(
        text: keyword,
        style: TextStyle(
          color: _emberCore,
          fontWeight: FontWeight.w600,
        ),
      ));
      
      lastIndex = index + keyword.length;
    }
    
    // Restlicher Text nach dem letzten Keyword
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
      ));
    }
    
    return spans;
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

// Color constants
const Color _midnight = Color(0xFF000000);
const Color _charcoal = Color(0xFF1C1C1E);
const Color _graphite = Color(0xFF2C2C2E);
const Color _steel = Color(0xFF48484A);
const Color _mercury = Color(0xFF8E8E93);
const Color _silver = Color(0xFFAEAEB2);
const Color _snow = Color(0xFFFFFFFF);
const Color _emberCore = Color(0xFFFF4500);
const Color _cardBackground = Color(0xFF15151A);
const Color _cardBorder = Color(0xFF2A2A30);
const Color _successGreen = Color(0xFF34C759);