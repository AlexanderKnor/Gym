// lib/screens/create_training_plan_screen/create_plan_wizard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';
import '../../utils/smooth_page_route.dart';
import 'training_day_editor_screen.dart';

class CreatePlanWizardScreen extends StatefulWidget {
  const CreatePlanWizardScreen({Key? key}) : super(key: key);

  @override
  State<CreatePlanWizardScreen> createState() => _CreatePlanWizardScreenState();
}

class _CreatePlanWizardScreenState extends State<CreatePlanWizardScreen> 
    with TickerProviderStateMixin {
  
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;

  late AnimationController _progressAnimationController;
  late AnimationController _stepAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Premium color scheme - exact match with app
  static const Color _void = Color(0xFF000000);
  static const Color _cosmos = Color(0xFF050507);
  static const Color _nebula = Color(0xFF0F0F12);
  static const Color _stellar = Color(0xFF18181C);
  static const Color _lunar = Color(0xFF242429);
  static const Color _asteroid = Color(0xFF35353C);
  static const Color _comet = Color(0xFF65656F);
  static const Color _stardust = Color(0xFFA5A5B0);
  static const Color _nova = Color(0xFFF5F5F7);
  static const Color _proverCore = Color(0xFFFF4500);
  static const Color _proverGlow = Color(0xFFFF6B3D);
  static const Color _graphite = Color(0xFF2C2C2E);
  static const Color _emberCore = Color(0xFFFF4500);

  @override
  void initState() {
    super.initState();
    
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _stepAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _progressAnimation = CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeOutCubic,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _stepAnimationController,
      curve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _stepAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _progressAnimationController.forward();
    _stepAnimationController.forward();

    // Reset provider for clean start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CreateTrainingPlanProvider>(context, listen: false).reset();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimationController.dispose();
    _stepAnimationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      // Tastatur schließen vor dem Wechsel zum nächsten Schritt
      FocusScope.of(context).unfocus();
      
      HapticFeedback.lightImpact();
      setState(() {
        _currentStep++;
      });
      _stepAnimationController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      _updateProgress();
      _stepAnimationController.forward();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      // Tastatur schließen vor dem Wechsel zum vorherigen Schritt
      FocusScope.of(context).unfocus();
      
      HapticFeedback.lightImpact();
      setState(() {
        _currentStep--;
      });
      _stepAnimationController.reset();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      _updateProgress();
      _stepAnimationController.forward();
    }
  }

  void _updateProgress() {
    _progressAnimationController.reset();
    _progressAnimationController.forward();
  }

  bool _canProceed() {
    final provider = Provider.of<CreateTrainingPlanProvider>(context, listen: false);
    
    switch (_currentStep) {
      case 0: // Plan Basics
        return provider.planName.isNotEmpty;
      case 1: // Training Setup
        return provider.frequency >= 3 && provider.frequency <= 6;
      case 2: // Advanced Settings
        return true; // Always can proceed
      case 3: // Training Days
        // Prüfe ob alle Tag-Namen ausgefüllt sind (nicht leer)
        return provider.dayNames.every((name) => name.trim().isNotEmpty);
      case 4: // Summary
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _void,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_cosmos, _nebula, _void],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildProgressIndicator(),
                
                // Main content with keyboard handling
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _PlanBasicsStep(
                        fadeAnimation: _fadeAnimation,
                        slideAnimation: _slideAnimation,
                      ),
                      _TrainingSetupStep(
                        fadeAnimation: _fadeAnimation,
                        slideAnimation: _slideAnimation,
                      ),
                      _AdvancedSettingsStep(
                        fadeAnimation: _fadeAnimation,
                        slideAnimation: _slideAnimation,
                      ),
                      _TrainingDaysStep(
                        fadeAnimation: _fadeAnimation,
                        slideAnimation: _slideAnimation,
                      ),
                      _SummaryStep(
                        fadeAnimation: _fadeAnimation,
                        slideAnimation: _slideAnimation,
                      ),
                    ],
                  ),
                ),

                _buildBottomNavigation(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_stellar.withOpacity(0.8), _nebula.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _asteroid.withOpacity(0.5)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.arrow_back_ios_rounded,
                    color: _nova,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Title with gradient
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_stellar, _nebula],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _proverCore.withOpacity(0.3),
              ),
            ),
            child: const Text(
              'NEUER PLAN',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _nova,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Step indicators with premium design
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_totalSteps, (index) {
              final isActive = index <= _currentStep;
              final isCurrent = index == _currentStep;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isCurrent ? 36 : 28,
                height: isCurrent ? 36 : 28,
                decoration: BoxDecoration(
                  gradient: isActive 
                    ? LinearGradient(colors: [_proverCore, _proverGlow])
                    : null,
                  color: isActive ? null : _asteroid.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(18),
                  border: isCurrent 
                    ? Border.all(color: _nova.withOpacity(0.4), width: 2)
                    : null,
                  boxShadow: isActive ? [
                    BoxShadow(
                      color: _proverCore.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive ? _nova : _comet,
                      fontWeight: FontWeight.w700,
                      fontSize: isCurrent ? 15 : 13,
                    ),
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 16),
          
          // Animated progress bar
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Container(
                height: 6,
                decoration: BoxDecoration(
                  color: _asteroid.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: ((_currentStep + _progressAnimation.value) / _totalSteps),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_proverCore, _proverGlow],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Previous button
          if (_currentStep > 0)
            Expanded(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_stellar.withOpacity(0.8), _nebula.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _asteroid.withOpacity(0.5)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _previousStep,
                    borderRadius: BorderRadius.circular(16),
                    child: const Center(
                      child: Text(
                        'ZURÜCK',
                        style: TextStyle(
                          color: _stardust,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            const Expanded(child: SizedBox()),
          
          if (_currentStep > 0) const SizedBox(width: 16),
          
          // Next/Create button
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: Consumer<CreateTrainingPlanProvider>(
              builder: (context, provider, child) {
                final canProceed = _canProceed();
                final isLastStep = _currentStep == _totalSteps - 1;
                
                return Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: canProceed 
                      ? LinearGradient(colors: [_proverCore, _proverGlow])
                      : LinearGradient(colors: [_asteroid.withOpacity(0.6), _asteroid.withOpacity(0.8)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: canProceed ? [
                      BoxShadow(
                        color: _proverCore.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: canProceed 
                        ? (isLastStep ? _createPlan : _nextStep)
                        : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: Text(
                          isLastStep ? 'PLAN ERSTELLEN' : 'WEITER',
                          style: TextStyle(
                            color: canProceed ? _nova : _comet,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createPlan() async {
    final provider = Provider.of<CreateTrainingPlanProvider>(context, listen: false);
    
    HapticFeedback.mediumImpact();
    
    // Erstelle den Draft Plan, falls noch nicht vorhanden
    if (provider.draftPlan == null) {
      provider.generateDraftPlan();
    }
    
    // Speichere Plan-Referenz vor dem Speichern (da savePlan() reset() aufruft)
    final planToEdit = provider.draftPlan!;
    final planName = provider.planName;
    
    // Save plan to database
    final success = await provider.savePlan();
    
    if (context.mounted) {
      if (success) {
        // Lade Plan zurück in Provider für Bearbeitung
        provider.loadExistingPlanForEditing(planToEdit);
        
        // Navigate to exercise editor instead of going back
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider.value(
              value: provider,
              child: const TrainingDayEditorScreen(),
            ),
          ),
        );
      } else {
        // Show error feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Fehler beim Erstellen des Plans!'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// Premium Input Widget matching app design
class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isRequired;
  final int maxLines;
  final IconData icon;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;

  const _PremiumTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.isRequired = false,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  }) : super(key: key);

  static const Color _stellar = Color(0xFF18181C);
  static const Color _nebula = Color(0xFF0F0F12);
  static const Color _lunar = Color(0xFF242429);
  static const Color _stardust = Color(0xFFA5A5B0);
  static const Color _nova = Color(0xFFF5F5F7);
  static const Color _proverCore = Color(0xFFFF4500);
  static const Color _graphite = Color(0xFF2C2C2E);
  static const Color _comet = Color(0xFF65656F);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with icon
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_proverCore.withOpacity(0.2), _proverCore.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _proverCore.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: _proverCore, size: 14),
            ),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _stardust,
                letterSpacing: 1,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _proverCore,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Premium text field
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(
            color: _nova,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: _comet.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: _graphite.withOpacity(0.6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _proverCore.withOpacity(0.6),
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.all(maxLines > 1 ? 16 : 20),
          ),
        ),
      ],
    );
  }
}

// Step 1: Plan Basics
class _PlanBasicsStep extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const _PlanBasicsStep({
    Key? key,
    required this.fadeAnimation,
    required this.slideAnimation,
  }) : super(key: key);

  @override
  State<_PlanBasicsStep> createState() => __PlanBasicsStepState();
}

class __PlanBasicsStepState extends State<_PlanBasicsStep> 
    with AutomaticKeepAliveClientMixin {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateName() {
    Provider.of<CreateTrainingPlanProvider>(context, listen: false)
        .setPlanName(_nameController.text);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return AnimatedBuilder(
      animation: widget.fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: widget.fadeAnimation,
          child: SlideTransition(
            position: widget.slideAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step title with premium styling
                  const Text(
                    'Plan Grundlagen',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFF5F5F7),
                      letterSpacing: -1,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Gib deinem Trainingsplan einen Namen und eine Beschreibung',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFA5A5B0),
                      height: 1.5,
                      letterSpacing: -0.2,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Plan Name
                  _PremiumTextField(
                    controller: _nameController,
                    label: 'Plan Name',
                    hint: 'z.B. Push Pull Legs',
                    icon: Icons.fitness_center,
                    isRequired: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Plan Description  
                  _PremiumTextField(
                    controller: _descriptionController,
                    label: 'Beschreibung',
                    hint: 'Kurze Beschreibung des Plans...',
                    icon: Icons.description,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Step 2: Training Setup
class _TrainingSetupStep extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const _TrainingSetupStep({
    Key? key,
    required this.fadeAnimation,
    required this.slideAnimation,
  }) : super(key: key);

  @override
  State<_TrainingSetupStep> createState() => __TrainingSetupStepState();
}

class __TrainingSetupStepState extends State<_TrainingSetupStep>
    with AutomaticKeepAliveClientMixin {
  final _gymController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _gymController.addListener(_updateGym);
  }

  @override
  void dispose() {
    _gymController.dispose();
    super.dispose();
  }

  void _updateGym() {
    Provider.of<CreateTrainingPlanProvider>(context, listen: false)
        .setGym(_gymController.text);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return AnimatedBuilder(
      animation: widget.fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: widget.fadeAnimation,
          child: SlideTransition(
            position: widget.slideAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Consumer<CreateTrainingPlanProvider>(
                builder: (context, provider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Training Setup',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFF5F5F7),
                          letterSpacing: -1,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      const Text(
                        'Wähle dein Fitnessstudio und deine wöchentliche Trainingsfrequenz',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFFA5A5B0),
                          height: 1.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Gym Name
                      _PremiumTextField(
                        controller: _gymController,
                        label: 'Fitnessstudio',
                        hint: 'z.B. McFit, Clever Fit...',
                        icon: Icons.location_on,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Frequency Selection
                      _buildFrequencySection(provider),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFrequencySection(CreateTrainingPlanProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFFF4500).withOpacity(0.2), const Color(0xFFFF4500).withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFFF4500).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.calendar_today, color: Color(0xFFFF4500), size: 14),
            ),
            const SizedBox(width: 8),
            const Text(
              'TRAININGSFREQUENZ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFA5A5B0),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Frequency options
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [3, 4, 5, 6].map((freq) {
            final isSelected = provider.frequency == freq;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                provider.setFrequency(freq);
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: isSelected
                    ? const LinearGradient(colors: [Color(0xFFFF4500), Color(0xFFFF6B3D)])
                    : LinearGradient(colors: [const Color(0xFF2C2C2E).withOpacity(0.6), const Color(0xFF18181C).withOpacity(0.6)]),
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected 
                    ? Border.all(color: const Color(0xFFF5F5F7).withOpacity(0.3), width: 2)
                    : Border.all(color: const Color(0xFF35353C).withOpacity(0.5), width: 1),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: const Color(0xFFFF4500).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ] : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$freq',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? const Color(0xFFF5F5F7) : const Color(0xFFA5A5B0),
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      freq == 1 ? 'TAG' : 'TAGE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? const Color(0xFFF5F5F7).withOpacity(0.8) : const Color(0xFF65656F),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Step 3: Advanced Settings
class _AdvancedSettingsStep extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const _AdvancedSettingsStep({
    Key? key,
    required this.fadeAnimation,
    required this.slideAnimation,
  }) : super(key: key);

  @override
  State<_AdvancedSettingsStep> createState() => __AdvancedSettingsStepState();
}

class __AdvancedSettingsStepState extends State<_AdvancedSettingsStep>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return AnimatedBuilder(
      animation: widget.fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: widget.fadeAnimation,
          child: SlideTransition(
            position: widget.slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Consumer<CreateTrainingPlanProvider>(
                builder: (context, provider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Erweiterte Einstellungen',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFF5F5F7),
                          letterSpacing: -1,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      const Text(
                        'Aktiviere Periodisierung für fortgeschrittene Trainingszyklen',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFFA5A5B0),
                          height: 1.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Periodization Toggle
                      _buildPeriodizationToggle(provider),
                      
                      if (provider.isPeriodized) ...[
                        const SizedBox(height: 32),
                        _buildWeeksSelection(provider),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodizationToggle(CreateTrainingPlanProvider provider) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        provider.setPeriodization(!provider.isPeriodized);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF18181C).withOpacity(0.4), const Color(0xFF0F0F12).withOpacity(0.4)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: provider.isPeriodized 
              ? const Color(0xFFFF4500).withOpacity(0.5)
              : const Color(0xFF242429).withOpacity(0.2),
            width: provider.isPeriodized ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: provider.isPeriodized
                    ? [const Color(0xFFFF4500), const Color(0xFFFF6B3D)]
                    : [const Color(0xFF35353C), const Color(0xFF242429)],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: provider.isPeriodized 
                    ? const Color(0xFFF5F5F7).withOpacity(0.3)
                    : const Color(0xFF65656F).withOpacity(0.3),
                ),
              ),
              child: Icon(
                provider.isPeriodized ? Icons.check : Icons.close,
                color: provider.isPeriodized 
                  ? const Color(0xFFF5F5F7)
                  : const Color(0xFF65656F),
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Periodisierung aktivieren',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: provider.isPeriodized 
                        ? const Color(0xFFF5F5F7)
                        : const Color(0xFFA5A5B0),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Für strukturierte Trainingszyklen mit verschiedenen Phasen',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF65656F),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeksSelection(CreateTrainingPlanProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFFF4500).withOpacity(0.2), const Color(0xFFFF4500).withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFFF4500).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.event, color: Color(0xFFFF4500), size: 14),
            ),
            const SizedBox(width: 8),
            const Text(
              'ANZAHL WOCHEN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFA5A5B0),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Week options
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [4, 6, 8, 12].map((weeks) {
            final isSelected = provider.numberOfWeeks == weeks;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                provider.setNumberOfWeeks(weeks);
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: isSelected
                    ? const LinearGradient(colors: [Color(0xFFFF4500), Color(0xFFFF6B3D)])
                    : LinearGradient(colors: [const Color(0xFF2C2C2E).withOpacity(0.6), const Color(0xFF18181C).withOpacity(0.6)]),
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected 
                    ? Border.all(color: const Color(0xFFF5F5F7).withOpacity(0.3), width: 2)
                    : Border.all(color: const Color(0xFF35353C).withOpacity(0.5), width: 1),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: const Color(0xFFFF4500).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ] : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$weeks',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? const Color(0xFFF5F5F7) : const Color(0xFFA5A5B0),
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'WOCHEN',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF65656F),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Step 4: Training Days
class _TrainingDaysStep extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const _TrainingDaysStep({
    Key? key,
    required this.fadeAnimation,
    required this.slideAnimation,
  }) : super(key: key);

  @override
  State<_TrainingDaysStep> createState() => __TrainingDaysStepState();
}

class __TrainingDaysStepState extends State<_TrainingDaysStep>
    with AutomaticKeepAliveClientMixin {
  
  List<TextEditingController> _controllers = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final provider = Provider.of<CreateTrainingPlanProvider>(context, listen: false);
    _controllers = List.generate(provider.frequency, (index) {
      final controller = TextEditingController(text: provider.dayNames[index]);
      controller.addListener(() {
        provider.setDayName(index, controller.text);
      });
      return controller;
    });
  }

  void _updateControllers() {
    final provider = Provider.of<CreateTrainingPlanProvider>(context, listen: false);
    
    // Wenn sich die Frequenz geändert hat, Controller neu initialisieren
    if (_controllers.length != provider.frequency) {
      _disposeControllers();
      _initializeControllers();
      return;
    }

    // Controller-Texte aktualisieren, wenn sich dayNames geändert haben
    for (int i = 0; i < _controllers.length; i++) {
      if (_controllers[i].text != provider.dayNames[i]) {
        _controllers[i].text = provider.dayNames[i];
      }
    }
  }

  void _disposeControllers() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return AnimatedBuilder(
      animation: widget.fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: widget.fadeAnimation,
          child: SlideTransition(
            position: widget.slideAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Consumer<CreateTrainingPlanProvider>(
                builder: (context, provider, child) {
                  // Controller aktualisieren
                  _updateControllers();
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trainingstage',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFF5F5F7),
                          letterSpacing: -1,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      const Text(
                        'Benenne deine Trainingstage (z.B. Push, Pull, Legs)',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFFA5A5B0),
                          height: 1.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Day name inputs mit persistenten Controllern
                      ...List.generate(provider.frequency, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _PremiumTextField(
                            controller: index < _controllers.length ? _controllers[index] : TextEditingController(),
                            label: 'Tag ${index + 1}',
                            hint: 'z.B. Push, Pull, Legs...',
                            icon: Icons.fitness_center,
                            // onChanged wird nicht mehr benötigt, da Controller-Listener verwendet werden
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// Step 5: Summary
class _SummaryStep extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const _SummaryStep({
    Key? key,
    required this.fadeAnimation,
    required this.slideAnimation,
  }) : super(key: key);

  @override
  State<_SummaryStep> createState() => __SummaryStepState();
}

class __SummaryStepState extends State<_SummaryStep>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return AnimatedBuilder(
      animation: widget.fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: widget.fadeAnimation,
          child: SlideTransition(
            position: widget.slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Consumer<CreateTrainingPlanProvider>(
                builder: (context, provider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Zusammenfassung',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFF5F5F7),
                          letterSpacing: -1,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      const Text(
                        'Überprüfe deine Eingaben bevor du den Plan erstellst',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFFA5A5B0),
                          height: 1.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Summary sections
                      _buildSummarySection(
                        icon: Icons.fitness_center,
                        title: 'Plan Details',
                        children: [
                          _buildSummaryItem('Name', provider.planName),
                          if (provider.gym.isNotEmpty)
                            _buildSummaryItem('Fitnessstudio', provider.gym),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      _buildSummarySection(
                        icon: Icons.calendar_today,
                        title: 'Training Setup',
                        children: [
                          _buildSummaryItem('Frequenz', '${provider.frequency} Tage/Woche'),
                          if (provider.isPeriodized)
                            _buildSummaryItem('Periodisierung', '${provider.numberOfWeeks} Wochen'),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      _buildSummarySection(
                        icon: Icons.list,
                        title: 'Trainingstage',
                        children: provider.dayNames.asMap().entries.map((entry) {
                          return _buildSummaryItem('Tag ${entry.key + 1}', entry.value);
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummarySection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF18181C).withOpacity(0.4), const Color(0xFF0F0F12).withOpacity(0.4)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF242429).withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFFF4500).withOpacity(0.2), const Color(0xFFFF6B3D).withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF4500).withOpacity(0.3)),
                ),
                child: Icon(icon, color: const Color(0xFFFF4500), size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF65656F),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF65656F),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFF5F5F7),
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}