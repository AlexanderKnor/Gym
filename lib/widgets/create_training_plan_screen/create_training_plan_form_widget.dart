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

  // PROVER color system - consistent with other screens
  static const Color _void = Color(0xFF000000);
  static const Color _cosmos = Color(0xFF050507);
  static const Color _nebula = Color(0xFF0F0F12);
  static const Color _stellar = Color(0xFF18181C);
  static const Color _lunar = Color(0xFF242429);
  static const Color _asteroid = Color(0xFF35353C);
  static const Color _comet = Color(0xFF65656F);
  static const Color _stardust = Color(0xFFA5A5B0);
  static const Color _nova = Color(0xFFF5F5F7);

  // Prover signature gradient
  static const Color _proverCore = Color(0xFFFF4500);
  static const Color _proverGlow = Color(0xFFFF6B3D);
  static const Color _proverFlare = Color(0xFFFFA500);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CreateTrainingPlanProvider>(context);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _void,
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              // Scrollable Content
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Content mit Padding für Fixed Button und App Bar
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
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
                          const SizedBox(height: 24),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Fixed Bottom Button
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _void.withOpacity(0.0),
                      _void.withOpacity(0.8),
                      _void,
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
                child: _buildNextButton(provider, theme),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildPlanNameSection(CreateTrainingPlanProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _stellar.withOpacity(0.6),
            _nebula.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _lunar.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _void.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sektions-Label
          _buildSectionLabel(
            'Plan Name',
            Icons.edit_outlined,
          ),
          const SizedBox(height: 16),

          // Textfeld für Planname
          TextFormField(
            controller: _planNameController,
            decoration: InputDecoration(
              hintText: 'z.B. Ganzkörperplan, Push/Pull/Legs, ...',
              filled: true,
              fillColor: _lunar.withOpacity(0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _asteroid.withOpacity(0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _asteroid.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _proverCore, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              prefixIcon: Icon(
                Icons.notes_rounded,
                color: _stardust,
              ),
              hintStyle: TextStyle(
                color: _comet,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _nova,
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
      ),
    );
  }

  Widget _buildFrequencySection(
      CreateTrainingPlanProvider provider, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _stellar.withOpacity(0.6),
            _nebula.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _lunar.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _void.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sektions-Label
          _buildSectionLabel(
            'Trainingsfrequenz',
            Icons.calendar_today_rounded,
          ),
          const SizedBox(height: 12),

          // Hinweistext
          Text(
            'Wie oft pro Woche möchtest du trainieren?',
            style: TextStyle(
              fontSize: 14,
              color: _stardust,
              letterSpacing: 0.3,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),

          // Elegante Frequenzauswahl
          _buildFrequencySelector(provider, theme),
        ],
      ),
    );
  }

  Widget _buildFrequencySelector(
      CreateTrainingPlanProvider provider, ThemeData theme) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _lunar.withOpacity(0.4),
            _asteroid.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _asteroid.withOpacity(0.5),
          width: 1,
        ),
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
              width: 44,
              height: 44,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [_proverCore, _proverGlow],
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _proverCore.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? _nova : _stardust,
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _stellar.withOpacity(0.6),
            _nebula.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _lunar.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _void.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sektions-Label
          _buildSectionLabel(
            'Periodisierung',
            Icons.cyclone_rounded,
          ),
          const SizedBox(height: 12),

          // Hinweistext
          Text(
            'Verwende Mikrozyklen für fortgeschrittenes Training',
            style: TextStyle(
              fontSize: 14,
              color: _stardust,
              letterSpacing: 0.3,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),

          // Tab-Auswahl für Periodisierung (Aktiviert/Deaktiviert)
          Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _lunar.withOpacity(0.4),
                  _asteroid.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _asteroid.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Standard-Tab
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _activePeriodizationTab = 0;
                        provider.setIsPeriodized(false);
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: _activePeriodizationTab == 0
                            ? LinearGradient(
                                colors: [_proverCore, _proverGlow],
                              )
                            : null,
                        color: _activePeriodizationTab == 0 ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _activePeriodizationTab == 0
                            ? [
                                BoxShadow(
                                  color: _proverCore.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Standard',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _activePeriodizationTab == 0
                                ? _nova
                                : _stardust,
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
                      HapticFeedback.lightImpact();
                      setState(() {
                        _activePeriodizationTab = 1;
                        provider.setIsPeriodized(true);
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: _activePeriodizationTab == 1
                            ? LinearGradient(
                                colors: [_proverCore, _proverGlow],
                              )
                            : null,
                        color: _activePeriodizationTab == 1 ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _activePeriodizationTab == 1
                            ? [
                                BoxShadow(
                                  color: _proverCore.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Periodisiert',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _activePeriodizationTab == 1
                                ? _nova
                                : _stardust,
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
              curve: Curves.easeInOutCubic,
              height: provider.isPeriodized ? null : 0,
              padding: EdgeInsets.only(top: provider.isPeriodized ? 24 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mikrozyklus-Label
                  Text(
                    'Anzahl Mikrozyklen',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _nova,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Kurzer Hinweistext
                  Text(
                    'Aus wie vielen Mikrozyklen soll dein Mesozyklus bestehen?',
                    style: TextStyle(
                      fontSize: 14,
                      color: _stardust,
                      letterSpacing: 0.3,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Wochen-Auswahl als eleganter Stepper
                  Container(
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _lunar.withOpacity(0.6),
                          _asteroid.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _asteroid.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // "-" Button
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: provider.numberOfWeeks > 1
                                ? () {
                                    HapticFeedback.mediumImpact();
                                    provider.setNumberOfWeeks(
                                        provider.numberOfWeeks - 1);
                                  }
                                : null,
                            child: Container(
                              width: 60,
                              height: 60,
                              child: Center(
                                child: Icon(
                                  Icons.remove_rounded,
                                  color: provider.numberOfWeeks > 1
                                      ? _nova
                                      : _comet,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Zentrierter Wert mit gradient Hintergrund
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_proverCore, _proverGlow],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: _proverCore.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${provider.numberOfWeeks}',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: _nova,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    provider.numberOfWeeks == 1
                                        ? 'Mikrozyklus'
                                        : 'Mikrozyklen',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _nova,
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
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: provider.numberOfWeeks < 16
                                ? () {
                                    HapticFeedback.mediumImpact();
                                    provider.setNumberOfWeeks(
                                        provider.numberOfWeeks + 1);
                                  }
                                : null,
                            child: Container(
                              width: 60,
                              height: 60,
                              child: Center(
                                child: Icon(
                                  Icons.add_rounded,
                                  color: provider.numberOfWeeks < 16
                                      ? _nova
                                      : _comet,
                                  size: 24,
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
      ),
    );
  }

  Widget _buildTrainingDaysSection(
      CreateTrainingPlanProvider provider, ThemeData theme) {
    return FadeTransition(
      opacity: _dayListAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _stellar.withOpacity(0.6),
              _nebula.withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _lunar.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _void.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sektions-Label
            _buildSectionLabel(
              'Trainingstage',
              Icons.event_rounded,
            ),
            const SizedBox(height: 12),

            // Hinweistext
            Text(
              'Benenne deine Trainingstage nach deinen Vorlieben',
              style: TextStyle(
                fontSize: 14,
                color: _stardust,
                letterSpacing: 0.3,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 14),

            // Liste der Trainingstage
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: provider.frequency,
              itemBuilder: (context, index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.only(
                    bottom: index == provider.frequency - 1 ? 0 : 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _lunar.withOpacity(0.6),
                        _asteroid.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _asteroid.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _void.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Tag-Nummer
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_proverCore, _proverGlow],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _proverCore.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: _nova,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Name-Eingabefeld
                        Expanded(
                          child: TextFormField(
                            initialValue: provider.dayNames.length > index
                                ? provider.dayNames[index]
                                : 'Tag ${index + 1}',
                            decoration: InputDecoration(
                              hintText: 'z.B. Oberkörper, Beine, ...',
                              filled: true,
                              fillColor: _lunar.withOpacity(0.8),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _asteroid.withOpacity(0.5),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _asteroid.withOpacity(0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _proverCore,
                                  width: 2,
                                ),
                              ),
                              hintStyle: TextStyle(
                                color: _comet,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _nova,
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
      ),
    );
  }

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_proverCore, _proverGlow],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: _nova,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _nova,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton(
      CreateTrainingPlanProvider provider, ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_proverCore, _proverGlow],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _proverCore.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('next_to_exercises_button'),
          onTap: () {
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
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Text
              Text(
                'WEITER ZU DEN ÜBUNGEN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _nova,
                  letterSpacing: 1,
                ),
              ),

              // Icon rechts
              Positioned(
                right: 20,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _nova.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: _nova,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
