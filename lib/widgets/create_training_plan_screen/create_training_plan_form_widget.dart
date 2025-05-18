// lib/widgets/create_training_plan_screen/create_training_plan_form_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';
import '../../screens/create_training_plan_screen/training_day_editor_screen.dart';

class CreateTrainingPlanFormWidget extends StatefulWidget {
  const CreateTrainingPlanFormWidget({Key? key}) : super(key: key);

  @override
  _CreateTrainingPlanFormWidgetState createState() =>
      _CreateTrainingPlanFormWidgetState();
}

class _CreateTrainingPlanFormWidgetState
    extends State<CreateTrainingPlanFormWidget> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _planNameController = TextEditingController();
  final _scrollController = ScrollController();

  late final AnimationController _animationController;
  late final Animation<double> _dayListAnimation;

  int _activePeriodizationTab = 0;

  @override
  void initState() {
    super.initState();
    _planNameController.addListener(_updatePlanName);

    // Animation für die Trainingstage
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _dayListAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuad,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _planNameController.removeListener(_updatePlanName);
    _planNameController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updatePlanName() {
    Provider.of<CreateTrainingPlanProvider>(context, listen: false)
        .setPlanName(_planNameController.text);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CreateTrainingPlanProvider>(context);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Form(
          key: _formKey,
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              // Header mit Illustration
              _buildHeader(),
              const SizedBox(height: 32),

              // Trainingsplan Name
              _buildPlanNameSection(provider),
              const SizedBox(height: 32),

              // Trainingsfrequenz
              _buildFrequencySection(provider, theme),
              const SizedBox(height: 32),

              // Periodisierung
              _buildPeriodizationSection(provider, theme),
              const SizedBox(height: 32),

              // Trainingstage
              _buildTrainingDaysSection(provider, theme),
              const SizedBox(height: 40),

              // Weiter-Button
              _buildNextButton(provider, theme),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Illustration
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.fitness_center,
              size: 48,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Titel
        const Center(
          child: Text(
            'Erstelle deinen Trainingsplan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),

        // Untertitel
        Center(
          child: Text(
            'Passe deinen Plan an deine Ziele und deinen Zeitplan an',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanNameSection(CreateTrainingPlanProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sektions-Label
        _buildSectionLabel(
          'Name deines Trainingsplans',
          Icons.edit_outlined,
        ),
        const SizedBox(height: 16),

        // Textfeld für Planname
        TextFormField(
          controller: _planNameController,
          decoration: InputDecoration(
            hintText: 'z.B. Ganzkörperplan, Push/Pull/Legs, ...',
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            prefixIcon: Icon(
              Icons.notes_rounded,
              color: Colors.grey[600],
            ),
          ),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Bitte gib einen Namen ein';
            }
            return null;
          },
          onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
      ],
    );
  }

  Widget _buildFrequencySection(
      CreateTrainingPlanProvider provider, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sektions-Label
        _buildSectionLabel(
          'Trainingsfrequenz',
          Icons.calendar_today_rounded,
        ),
        const SizedBox(height: 8),

        // Hinweistext
        Text(
          'An wie vielen Tagen pro Woche möchtest du trainieren?',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),

        // Elegante Frequenzauswahl
        _buildFrequencySelector(provider, theme),
      ],
    );
  }

  Widget _buildFrequencySelector(
      CreateTrainingPlanProvider provider, ThemeData theme) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          final day = index + 1;
          final isSelected = provider.frequency == day;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              provider.setFrequency(day);
            },
            child: Container(
              width: 40,
              height: 40,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[800],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPeriodizationSection(
      CreateTrainingPlanProvider provider, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sektions-Label
        _buildSectionLabel(
          'Periodisierung',
          Icons.cyclone_rounded,
        ),
        const SizedBox(height: 8),

        // Hinweistext
        Text(
          'Teile deinen Plan in Wochen (Mikrozyklen) für fortgeschrittenes Training',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),

        // Tab-Auswahl für Periodisierung (Aktiviert/Deaktiviert)
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              // Standard-Tab
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _activePeriodizationTab = 0;
                      provider.setIsPeriodized(false);
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _activePeriodizationTab == 0
                          ? Colors.black
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Standard',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _activePeriodizationTab == 0
                              ? Colors.white
                              : Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Periodisiert-Tab
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _activePeriodizationTab = 1;
                      provider.setIsPeriodized(true);
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _activePeriodizationTab == 1
                          ? Colors.black
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Periodisiert',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _activePeriodizationTab == 1
                              ? Colors.white
                              : Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Wenn periodisiert, zeige Wochen-Auswahl
        if (provider.isPeriodized)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: provider.isPeriodized ? null : 0,
            padding: EdgeInsets.only(top: provider.isPeriodized ? 20 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mikrozyklus-Label
                const Text(
                  'Mesozyklus-Länge',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),

                // Kurzer Hinweistext
                Text(
                  'Wähle die Anzahl der Wochen für deinen Mesozyklus',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 16),

                // Wochen-Auswahl als eleganter Stepper
                Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      // "-" Button
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: provider.numberOfWeeks > 1
                              ? () {
                                  HapticFeedback.mediumImpact();
                                  provider.setNumberOfWeeks(
                                      provider.numberOfWeeks - 1);
                                }
                              : null,
                          child: Container(
                            width: 56,
                            height: 56,
                            child: Center(
                              child: Icon(
                                Icons.remove,
                                color: provider.numberOfWeeks > 1
                                    ? Colors.black
                                    : Colors.grey[400],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Zentrierter Wert mit schwarzem Hintergrund
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${provider.numberOfWeeks}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  provider.numberOfWeeks == 1
                                      ? 'Woche'
                                      : 'Wochen',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // "+" Button
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: provider.numberOfWeeks < 16
                              ? () {
                                  HapticFeedback.mediumImpact();
                                  provider.setNumberOfWeeks(
                                      provider.numberOfWeeks + 1);
                                }
                              : null,
                          child: Container(
                            width: 56,
                            height: 56,
                            child: Center(
                              child: Icon(
                                Icons.add,
                                color: provider.numberOfWeeks < 16
                                    ? Colors.black
                                    : Colors.grey[400],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTrainingDaysSection(
      CreateTrainingPlanProvider provider, ThemeData theme) {
    return FadeTransition(
      opacity: _dayListAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sektions-Label
          _buildSectionLabel(
            'Trainingstage',
            Icons.event_rounded,
          ),
          const SizedBox(height: 8),

          // Hinweistext
          Text(
            'Du kannst die Namen der Trainingstage anpassen',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),

          // Liste der Trainingstage
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.frequency,
            itemBuilder: (context, index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Tag-Nummer
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Name-Eingabefeld
                      Expanded(
                        child: TextFormField(
                          initialValue: provider.dayNames.length > index
                              ? provider.dayNames[index]
                              : 'Tag ${index + 1}',
                          decoration: InputDecoration(
                            hintText: 'z.B. Oberkörper, Beine, ...',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Colors.black, width: 1.5),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          textCapitalization: TextCapitalization.words,
                          onChanged: (value) =>
                              provider.setDayName(index, value),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey[800],
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton(
      CreateTrainingPlanProvider provider, ThemeData theme) {
    return ElevatedButton(
      key: const Key('next_to_exercises_button'),
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          print("Formular validiert");
          // Entwurfsplan erstellen
          provider.createDraftPlan();
          print("Entwurfsplan erstellt: ${provider.draftPlan != null}");

          // Haptisches Feedback
          HapticFeedback.mediumImpact();

          // Zum Tag-Editor navigieren, dabei den Provider-Wert weitergeben
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider.value(
                value: provider,
                child: const TrainingDayEditorScreen(),
              ),
            ),
          );
        } else {
          print("Validierung fehlgeschlagen");
          // Kurzes Haptisches Feedback für Fehler
          HapticFeedback.vibrate();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        minimumSize: const Size(double.infinity, 56),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Text
          Text(
            provider.isPeriodized
                ? 'Weiter zum Mesozyklus-Editor'
                : 'Weiter zu den Übungen',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),

          // Icon rechts
          Positioned(
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
