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
                    // Space for fixed header
                    SliverToBoxAdapter(
                      child: SizedBox(height: 80),
                    ),

                    // Content with modern spacing and layout
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Trainingsplan Name
                          _buildPlanNameSection(provider),

                          // Trainingsfrequenz
                          _buildFrequencySection(provider, theme),

                          // Periodisierung
                          _buildPeriodizationSection(provider, theme),

                          // Trainingstage
                          _buildTrainingDaysSection(provider, theme),
                          const SizedBox(height: 120),
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _stellar.withOpacity(0.6),
            _nebula.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icon wie im Training Screen
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _stellar.withOpacity(0.8),
                    _stellar.withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _proverCore.withOpacity(0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _void.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: _proverCore.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: _stardust,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PLAN NAME',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _nova,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Eingabefeld
                  TextFormField(
                    controller: _planNameController,
                    decoration: InputDecoration(
                      hintText: 'z.B. Ganzkörperplan, Push/Pull/Legs',
                      filled: true,
                      fillColor: _stellar.withOpacity(0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _proverCore.withOpacity(0.6),
                          width: 1,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      hintStyle: TextStyle(
                        color: _comet,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _stardust,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySection(
      CreateTrainingPlanProvider provider, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _stellar.withOpacity(0.6),
            _nebula.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icon wie im Training Screen
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _stellar.withOpacity(0.8),
                    _stellar.withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _proverCore.withOpacity(0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _void.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: _proverCore.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: _stardust,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRAININGSFREQUENZ',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _nova,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  Row(
                    children: [
                      Text(
                        '${provider.frequency}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _stardust,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Trainingstage',
                        style: TextStyle(
                          fontSize: 12,
                          color: _comet,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  _buildFrequencySelector(provider, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySelector(
      CreateTrainingPlanProvider provider, ThemeData theme) {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final day = index + 1;
          final isSelected = provider.frequency == day;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              provider.setFrequency(day);
            },
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected
                      ? [
                          _stellar.withOpacity(0.8),
                          _stellar.withOpacity(0.4),
                        ]
                      : [
                          _stellar.withOpacity(0.3),
                          _stellar.withOpacity(0.1),
                        ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? _proverCore.withOpacity(0.6)
                      : _lunar.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _void.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: _proverCore.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 0),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: _void.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? _stardust : _comet,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodizationSection(
      CreateTrainingPlanProvider provider, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _stellar.withOpacity(0.6),
            _nebula.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icon wie im Training Screen
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _stellar.withOpacity(0.8),
                    _stellar.withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _proverCore.withOpacity(0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _void.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: _proverCore.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.timeline_rounded,
                  size: 16,
                  color: _stardust,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PERIODISIERUNG',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _nova,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  Row(
                    children: [
                      Text(
                        provider.isPeriodized ? 'Periodisiert' : 'Standard',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _stardust,
                        ),
                      ),
                      if (provider.isPeriodized) ...[
                        const SizedBox(width: 4),
                        Text(
                          '• ${provider.numberOfWeeks} Mikrozyklen',
                          style: TextStyle(
                            fontSize: 12,
                            color: _comet,
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Training Screen Style Button Row
                  Row(
                    children: [
                      // Standard Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _activePeriodizationTab = 0;
                              provider.setIsPeriodized(false);
                            });
                          },
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: _activePeriodizationTab == 0
                                    ? [
                                        _stellar.withOpacity(0.8),
                                        _stellar.withOpacity(0.4),
                                      ]
                                    : [
                                        _stellar.withOpacity(0.3),
                                        _stellar.withOpacity(0.1),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _activePeriodizationTab == 0
                                    ? _proverCore.withOpacity(0.6)
                                    : _lunar.withOpacity(0.3),
                                width: _activePeriodizationTab == 0 ? 2 : 1,
                              ),
                              boxShadow: _activePeriodizationTab == 0
                                  ? [
                                      BoxShadow(
                                        color: _void.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                      BoxShadow(
                                        color: _proverCore.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 0),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: _void.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: Text(
                                'STANDARD',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: _activePeriodizationTab == 0 ? _stardust : _comet,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Periodisiert Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _activePeriodizationTab = 1;
                              provider.setIsPeriodized(true);
                            });
                          },
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: _activePeriodizationTab == 1
                                    ? [
                                        _stellar.withOpacity(0.8),
                                        _stellar.withOpacity(0.4),
                                      ]
                                    : [
                                        _stellar.withOpacity(0.3),
                                        _stellar.withOpacity(0.1),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _activePeriodizationTab == 1
                                    ? _proverCore.withOpacity(0.6)
                                    : _lunar.withOpacity(0.3),
                                width: _activePeriodizationTab == 1 ? 2 : 1,
                              ),
                              boxShadow: _activePeriodizationTab == 1
                                  ? [
                                      BoxShadow(
                                        color: _void.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                      BoxShadow(
                                        color: _proverCore.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 0),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: _void.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: Text(
                                'PERIODISIERT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: _activePeriodizationTab == 1 ? _stardust : _comet,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Mikrozyklus Stepper wenn periodisiert
                  if (provider.isPeriodized) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        // Minus Button
                        GestureDetector(
                          onTap: provider.numberOfWeeks > 1
                              ? () {
                                  HapticFeedback.selectionClick();
                                  provider.setNumberOfWeeks(provider.numberOfWeeks - 1);
                                }
                              : null,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _stellar.withOpacity(0.6),
                                  _stellar.withOpacity(0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _lunar.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.remove_rounded,
                                size: 16,
                                color: provider.numberOfWeeks > 1 ? _stardust : _comet,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Display
                        Expanded(
                          child: Container(
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _stellar.withOpacity(0.8),
                                  _stellar.withOpacity(0.4),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _proverCore.withOpacity(0.6),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${provider.numberOfWeeks} ${provider.numberOfWeeks == 1 ? 'Mikrozyklus' : 'Mikrozyklen'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _stardust,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Plus Button
                        GestureDetector(
                          onTap: provider.numberOfWeeks < 16
                              ? () {
                                  HapticFeedback.selectionClick();
                                  provider.setNumberOfWeeks(provider.numberOfWeeks + 1);
                                }
                              : null,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _stellar.withOpacity(0.6),
                                  _stellar.withOpacity(0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _lunar.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.add_rounded,
                                size: 16,
                                color: provider.numberOfWeeks < 16 ? _stardust : _comet,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingDaysSection(
      CreateTrainingPlanProvider provider, ThemeData theme) {
    return FadeTransition(
      opacity: _dayListAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header wie im Training Screen
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            child: Text(
              'TRAININGSTAGE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _comet,
                letterSpacing: 1.2,
              ),
            ),
          ),
          
          // Liste der Trainingstage im Training Screen Stil
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: provider.frequency,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 600 + (index * 100)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _stellar.withOpacity(0.6),
                              _nebula.withOpacity(0.4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
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
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              // Tag-Nummer im Training Screen Stil
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      _stellar.withOpacity(0.8),
                                      _stellar.withOpacity(0.4),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _proverCore.withOpacity(0.6),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _void.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                    BoxShadow(
                                      color: _proverCore.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: _stardust,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                      initialValue: provider.dayNames.length > index
                                          ? provider.dayNames[index]
                                          : 'Tag ${index + 1}',
                                      decoration: InputDecoration(
                                        hintText: 'z.B. Oberkörper, Beine, ...',
                                        filled: true,
                                        fillColor: _stellar.withOpacity(0.4),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: _proverCore.withOpacity(0.6),
                                            width: 1,
                                          ),
                                        ),
                                        hintStyle: TextStyle(
                                          color: _comet,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: _nova,
                                        letterSpacing: 0.5,
                                      ),
                                      textCapitalization: TextCapitalization.words,
                                      onChanged: (value) => provider.setDayName(index, value),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
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
            blurRadius: 24,
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
              provider.createDraftPlan();
              HapticFeedback.lightImpact();
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
              HapticFeedback.vibrate();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Haupttext
              Text(
                'WEITER ZU DEN ÜBUNGEN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _nova,
                  letterSpacing: 1,
                ),
              ),

              // Modernes Pfeil-Icon rechts
              Positioned(
                right: 20,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _nova.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
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