import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/exercise_database/predefined_exercise_model.dart';

class CustomExerciseCreationScreen extends StatefulWidget {
  final Function(PredefinedExercise) onExerciseCreated;

  const CustomExerciseCreationScreen({
    Key? key,
    required this.onExerciseCreated,
  }) : super(key: key);

  @override
  State<CustomExerciseCreationScreen> createState() =>
      _CustomExerciseCreationScreenState();
}

class _CustomExerciseCreationScreenState
    extends State<CustomExerciseCreationScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _heroController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _heroScaleAnimation;
  
  // Sophisticated color system - matching modern screens
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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedPrimaryMuscle = '';
  List<String> _selectedSecondaryMuscles = [];
  String _selectedEquipment = '';

  bool _isSaving = false;

  final List<String> _availableMuscleGroups = [
    'Brust',
    'Rücken',
    'Schultern',
    'Bizeps',
    'Trizeps',
    'Quadrizeps',
    'Beinbeuger',
    'Gesäß',
    'Waden',
    'Rumpf',
    'Bauch',
    'Nacken',
    'Unterarme',
    'Hintere Schulter',
    'Vordere Schulter'
  ];

  final List<String> _availableEquipment = [
    'Langhantel',
    'Kurzhantel',
    'Kabelzug',
    'Maschine',
    'Körpergewicht',
    'Hex-Stange',
    'SZ-Stange'
  ];

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _heroController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    );

    _heroScaleAnimation = CurvedAnimation(
      parent: _heroController,
      curve: const Cubic(0.175, 0.885, 0.32, 1.275),
    );

    _fadeController.forward();
    _heroController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _heroController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _createExercise() async {
    if (_formKey.currentState!.validate() &&
        _selectedPrimaryMuscle.isNotEmpty &&
        _selectedEquipment.isNotEmpty &&
        !_isSaving) {
      setState(() {
        _isSaving = true;
      });

      final customExercise = PredefinedExercise(
        id: DateTime.now().millisecondsSinceEpoch,
        name: _nameController.text.trim(),
        primaryMuscleGroup: _selectedPrimaryMuscle,
        secondaryMuscleGroups: _selectedSecondaryMuscles,
        equipment: _selectedEquipment,
      );

      await Future.delayed(const Duration(milliseconds: 300));

      HapticFeedback.mediumImpact();

      // Call the callback first, then pop
      widget.onExerciseCreated(customExercise);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _void,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            bottom: false,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                  // Space for fixed header
                  SliverToBoxAdapter(
                    child: SizedBox(height: 60),
                  ),
                  
                  // Title section - elegant and minimal
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Eigene Übung',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: _nova,
                              letterSpacing: -1,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Erstelle deine individuelle Übung',
                            style: TextStyle(
                              fontSize: 14,
                              color: _stardust,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Form sections
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildModernSection(
                          'GRUNDDATEN',
                          Icons.edit_rounded,
                          [
                            _buildModernFormField(
                              'Übungsname',
                              Icons.fitness_center,
                              child: TextFormField(
                                controller: _nameController,
                                style: TextStyle(
                                  color: _nova,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'z.B. Meine spezielle Übung',
                                  hintStyle: TextStyle(
                                    color: _comet,
                                  ),
                                  filled: true,
                                  fillColor: _stellar.withOpacity(0.6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Bitte gib einen Übungsnamen ein';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        _buildModernSection(
                          'MUSKELGRUPPEN',
                          Icons.accessibility_new_rounded,
                          [
                            _buildModernFormField(
                              'Primäre Muskelgruppe',
                              Icons.radio_button_checked,
                              child: _buildModernSelector(
                                _selectedPrimaryMuscle.isEmpty
                                    ? 'Wähle die primäre Muskelgruppe'
                                    : _selectedPrimaryMuscle,
                                _selectedPrimaryMuscle.isEmpty,
                                () => _showModernPrimaryMuscleGroupPicker(),
                              ),
                            ),
                            _buildModernFormField(
                              'Sekundäre Muskelgruppen',
                              Icons.group_work_rounded,
                              child: Column(
                                children: [
                                  if (_selectedSecondaryMuscles.isNotEmpty) ...[
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _selectedSecondaryMuscles.map((muscle) {
                                        return _buildMuscleTag(muscle);
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  _buildAddSecondaryMuscleButton(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        _buildModernSection(
                          'EQUIPMENT',
                          Icons.hardware_rounded,
                          [
                            _buildModernFormField(
                              'Benötigtes Equipment',
                              Icons.build_rounded,
                              child: _buildModernSelector(
                                _selectedEquipment.isEmpty
                                    ? 'Equipment auswählen'
                                    : _selectedEquipment,
                                _selectedEquipment.isEmpty,
                                () => _showModernEquipmentPicker(),
                              ),
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
          
          // Fixed header with logo and actions
          SafeArea(
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _void,
                    _void.withOpacity(0.95),
                    _void.withOpacity(0.8),
                    _void.withOpacity(0),
                  ],
                  stops: const [0.0, 0.6, 0.8, 1.0],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _stellar.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _lunar.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: _nova,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'EIGENE ÜBUNG',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _nova,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  _isSaving
                    ? Container(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _proverCore,
                        ),
                      )
                    : GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _createExercise();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_proverCore, _proverGlow],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: _proverCore.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'ERSTELLEN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _nova,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSection(
    String title,
    IconData icon,
    List<Widget> children, {
    bool optional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: _proverCore,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _proverCore,
                  letterSpacing: 1.2,
                ),
              ),
              if (optional) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _comet.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _comet.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'OPTIONAL',
                    style: TextStyle(
                      fontSize: 9,
                      color: _comet,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        ...children.map((child) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: child,
        )),
        ],
      );
  }

  Widget _buildModernFormField(String label, IconData icon, {required Widget child}) {
    return Container(
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
        ),
        boxShadow: [
          BoxShadow(
            color: _void.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
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
                      colors: [
                        _stellar.withOpacity(0.8),
                        _stellar.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _lunar.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 16,
                      color: _stardust,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _nova,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildModernSelector(String text, bool isEmpty, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _stellar.withOpacity(0.8),
              _stellar.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _lunar.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: isEmpty ? _comet : _nova,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                color: _proverCore,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMuscleTag(String muscle) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _stellar.withOpacity(0.8),
            _stellar.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _lunar.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedSecondaryMuscles.remove(muscle);
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  muscle,
                  style: TextStyle(
                    color: _nova,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: _comet,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddSecondaryMuscleButton() {
    return GestureDetector(
      onTap: _showModernSecondaryMuscleGroupPicker,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _stellar.withOpacity(0.6),
              _stellar.withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _proverCore.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.add_circle_outline_rounded,
              color: _proverCore,
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              'Sekundäre Muskelgruppe hinzufügen',
              style: TextStyle(
                color: _proverCore,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModernPrimaryMuscleGroupPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_stellar, _nebula],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: _lunar.withOpacity(0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _lunar,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_proverCore, _proverGlow],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.radio_button_checked,
                      color: _nova,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'PRIMÄRE MUSKELGRUPPE',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: _nova,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, size: 22, color: _stardust),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: _availableMuscleGroups.map((muscle) {
                    final isSelected = _selectedPrimaryMuscle == muscle;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isSelected 
                            ? [_proverCore.withOpacity(0.2), _proverGlow.withOpacity(0.1)]
                            : [_stellar.withOpacity(0.6), _stellar.withOpacity(0.4)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _proverCore.withOpacity(0.5) : _lunar.withOpacity(0.3),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _selectedPrimaryMuscle = muscle;
                              _selectedSecondaryMuscles.remove(muscle);
                            });
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    muscle,
                                    style: TextStyle(
                                      color: isSelected ? _proverCore : _nova,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: _proverCore,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showModernSecondaryMuscleGroupPicker() {
    final availableSecondaryMuscles = _availableMuscleGroups
        .where((muscle) =>
            muscle != _selectedPrimaryMuscle &&
            !_selectedSecondaryMuscles.contains(muscle))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_stellar, _nebula],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: _lunar.withOpacity(0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _lunar,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_proverCore, _proverGlow],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.group_work_rounded,
                      color: _nova,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'SEKUNDÄRE MUSKELGRUPPE',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: _nova,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, size: 22, color: _stardust),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: availableSecondaryMuscles.isEmpty
                    ? Center(
                        child: Text(
                          'Alle verfügbaren Muskelgruppen\nsind bereits ausgewählt',
                          style: TextStyle(
                            color: _comet,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView(
                        children: availableSecondaryMuscles.map((muscle) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_stellar.withOpacity(0.6), _stellar.withOpacity(0.4)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _lunar.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    _selectedSecondaryMuscles.add(muscle);
                                  });
                                  Navigator.pop(context);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Text(
                                    muscle,
                                    style: TextStyle(
                                      color: _nova,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showModernEquipmentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_stellar, _nebula],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: _lunar.withOpacity(0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _lunar,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_proverCore, _proverGlow],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.build_rounded,
                      color: _nova,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'EQUIPMENT AUSWÄHLEN',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: _nova,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, size: 22, color: _stardust),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: _availableEquipment.map((equipment) {
                    final isSelected = _selectedEquipment == equipment;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isSelected 
                            ? [_proverCore.withOpacity(0.2), _proverGlow.withOpacity(0.1)]
                            : [_stellar.withOpacity(0.6), _stellar.withOpacity(0.4)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _proverCore.withOpacity(0.5) : _lunar.withOpacity(0.3),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _selectedEquipment = equipment;
                            });
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    equipment,
                                    style: TextStyle(
                                      color: isSelected ? _proverCore : _nova,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: _proverCore,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrimaryMuscleGroupPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF48484A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Primäre Muskelgruppe wählen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFFFFF),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: _availableMuscleGroups.map((muscle) {
                    return ListTile(
                      title: Text(
                        muscle,
                        style: TextStyle(
                          color: _selectedPrimaryMuscle == muscle
                              ? const Color(0xFFFF4500)
                              : const Color(0xFFFFFFFF),
                          fontWeight: _selectedPrimaryMuscle == muscle
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      trailing: _selectedPrimaryMuscle == muscle
                          ? const Icon(
                              Icons.check,
                              color: Color(0xFFFF4500),
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedPrimaryMuscle = muscle;
                          _selectedSecondaryMuscles.remove(muscle);
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSecondaryMuscleGroupPicker() {
    final availableSecondaryMuscles = _availableMuscleGroups
        .where((muscle) =>
            muscle != _selectedPrimaryMuscle &&
            !_selectedSecondaryMuscles.contains(muscle))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF48484A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sekundäre Muskelgruppe hinzufügen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFFFFF),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: availableSecondaryMuscles.isEmpty
                    ? const Center(
                        child: Text(
                          'Alle verfügbaren Muskelgruppen\nsind bereits ausgewählt',
                          style: TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView(
                        children: availableSecondaryMuscles.map((muscle) {
                          return ListTile(
                            title: Text(
                              muscle,
                              style: const TextStyle(
                                color: Color(0xFFFFFFFF),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedSecondaryMuscles.add(muscle);
                              });
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEquipmentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF48484A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Equipment wählen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFFFFF),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: _availableEquipment.map((equipment) {
                    return ListTile(
                      title: Text(
                        equipment,
                        style: TextStyle(
                          color: _selectedEquipment == equipment
                              ? const Color(0xFFFF4500)
                              : const Color(0xFFFFFFFF),
                          fontWeight: _selectedEquipment == equipment
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      trailing: _selectedEquipment == equipment
                          ? const Icon(
                              Icons.check,
                              color: Color(0xFFFF4500),
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedEquipment = equipment;
                        });
                        Navigator.pop(context);
                        HapticFeedback.lightImpact();
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
