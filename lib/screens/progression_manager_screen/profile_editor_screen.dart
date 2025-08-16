import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../utils/smooth_page_route.dart';
import 'profile_detail_screen.dart';

class ProfileEditorScreen extends StatefulWidget {
  final bool isDialog;
  final VoidCallback? initialProfileAction;

  const ProfileEditorScreen({
    Key? key,
    this.isDialog = false,
    this.initialProfileAction,
  }) : super(key: key);

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  bool _initialized = false;
  
  // Ultra-premium dark color scheme
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

  @override
  void initState() {
    super.initState();
    
    if (widget.initialProfileAction != null) {
      final provider = Provider.of<ProgressionManagerProvider>(context, listen: false);
      provider.profileProvider.clearEditedProfile();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.initialProfileAction!();
          setState(() {
            _initialized = true;
          });
        }
      });
    } else {
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      final provider = Provider.of<ProgressionManagerProvider>(context);
      return _buildLoadingScreen(context, provider);
    }

    final provider = Provider.of<ProgressionManagerProvider>(context);
    final profil = provider.bearbeitetesProfil;

    if (profil == null) {
      return _buildLoadingScreen(context, provider);
    }

    if (widget.isDialog) {
      return _buildDialogMode(context, provider, profil);
    }

    return _buildScreenMode(context, provider, profil);
  }

  Widget _buildLoadingScreen(BuildContext context, ProgressionManagerProvider provider) {
    return Scaffold(
      backgroundColor: _void,
      body: Container(
        decoration: const BoxDecoration(
          color: _void,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: _stardust, size: 24),
                      onPressed: () {
                        provider.closeProfileEditor();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_proverCore),
                    strokeWidth: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogMode(BuildContext context, ProgressionManagerProvider provider, dynamic profil) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            provider.closeProfileEditor();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: _void.withOpacity(0.7),
            ),
          ),
        ),
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
            margin: const EdgeInsets.all(24),
            child: ProfileEditorContent(
              profil: profil,
              isDialog: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScreenMode(BuildContext context, ProgressionManagerProvider provider, dynamic profil) {
    return WillPopScope(
      onWillPop: () async {
        provider.closeProfileEditor();
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: _void,
        body: ProfileEditorContent(
          profil: profil,
          isDialog: false,
        ),
      ),
    );
  }
}

class ProfileEditorContent extends StatefulWidget {
  final dynamic profil;
  final bool isDialog;

  const ProfileEditorContent({
    Key? key,
    required this.profil,
    required this.isDialog,
  }) : super(key: key);

  @override
  State<ProfileEditorContent> createState() => _ProfileEditorContentState();
}

class _ProfileEditorContentState extends State<ProfileEditorContent> 
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Profile values
  int _repsMin = 8;
  int _repsMax = 12;
  int _rirMin = 1;
  int _rirMax = 3;
  double _increment = 2.5;

  // Ultra-premium dark color scheme
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

  void _updateControllersIfNeeded(dynamic profil) {
    if (profil == null) return;
    
    if (_nameController.text != profil.name) {
      _nameController.text = profil.name;
    }
    if (_descriptionController.text != profil.description) {
      _descriptionController.text = profil.description;
    }
    
    setState(() {
      _repsMin = (profil.config['targetRepsMin'] ?? 8).toInt();
      _repsMax = (profil.config['targetRepsMax'] ?? 12).toInt();
      _rirMin = (profil.config['targetRIRMin'] ?? 1).toInt();
      _rirMax = (profil.config['targetRIRMax'] ?? 3).toInt();
      _increment = (profil.config['increment'] ?? 2.5).toDouble();
    });
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);
    
    _updateControllersIfNeeded(widget.profil);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: _void,
          borderRadius: widget.isDialog ? BorderRadius.circular(24) : BorderRadius.zero,
        ),
        child: Column(
          children: [
            _buildHeader(context, provider),
            Expanded(
              child: _buildContent(context, provider),
            ),
            _buildFooter(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ProgressionManagerProvider provider) {
    final isNewProfile = widget.profil.id.contains('profile_');
    
    return Container(
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
          if (!widget.isDialog) ...[
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                provider.closeProfileEditor();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
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
                child: const Center(
                  child: Icon(
                    Icons.arrow_back_ios_rounded,
                    color: _nova,
                    size: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          
          Expanded(
            child: Text(
              isNewProfile ? 'NEUES PROFIL' : 'PROFIL BEARBEITEN',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _nova,
                letterSpacing: 1.5,
              ),
            ),
          ),
          
          if (!widget.isDialog) _buildSaveButton(context, provider),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, ProgressionManagerProvider provider) {
    return Consumer<ProgressionManagerProvider>(
      builder: (context, prov, child) {
        final isLoading = prov.profileProvider.isSaving;
        
        return GestureDetector(
          onTap: isLoading ? null : () => _handleSave(context, provider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLoading 
                  ? [_asteroid.withOpacity(0.6), _asteroid.withOpacity(0.4)] 
                  : [_proverCore.withOpacity(0.9), _proverGlow.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                if (!isLoading)
                  BoxShadow(
                    color: _proverCore.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading) 
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(_nova),
                    ),
                  )
                else
                  const Icon(Icons.check_rounded, color: _nova, size: 16),
                const SizedBox(width: 6),
                Text(
                  isLoading ? 'SPEICHERN...' : 'SPEICHERN',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _nova,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ProgressionManagerProvider provider) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          
          // Basic Info Section
          _buildSectionHeader('GRUNDINFORMATIONEN', Icons.badge_outlined),
          const SizedBox(height: 20),
          
          _buildTextField(
            controller: _nameController,
            label: 'Profilname',
            hint: 'z.B. Anfänger, Fortgeschritten',
            onChanged: (value) => provider.updateProfile('name', value),
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _descriptionController,
            label: 'Beschreibung',
            hint: 'Kurze Beschreibung des Profils',
            maxLines: 3,
            onChanged: (value) => provider.updateProfile('description', value),
          ),
          
          const SizedBox(height: 32),
          
          // Training Parameters Section
          _buildSectionHeader('TRAININGSPARAMETER', Icons.fitness_center),
          const SizedBox(height: 20),
          
          _buildParameterCard(
            'Wiederholungen',
            Icons.repeat_rounded,
            _buildModernRangeControl(
              minValue: _repsMin,
              maxValue: _repsMax,
              onMinChanged: (value) {
                setState(() => _repsMin = value);
                provider.updateProfile('config.targetRepsMin', value);
              },
              onMaxChanged: (value) {
                setState(() => _repsMax = value);
                provider.updateProfile('config.targetRepsMax', value);
              },
              context: context,
              min: 1,
              max: 30,
              label: 'WDHL',
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildParameterCard(
            'RIR-Bereich',
            Icons.speed_rounded,
            _buildModernRangeControl(
              minValue: _rirMin,
              maxValue: _rirMax,
              onMinChanged: (value) {
                setState(() => _rirMin = value);
                provider.updateProfile('config.targetRIRMin', value);
              },
              onMaxChanged: (value) {
                setState(() => _rirMax = value);
                provider.updateProfile('config.targetRIRMax', value);
              },
              context: context,
              min: 0,
              max: 10,
              label: 'RIR',
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildParameterCard(
            'Gewichtssteigerung',
            Icons.trending_up_rounded,
            _buildIncrementControl(context, provider),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
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
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Function(String) onChanged,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _stellar.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _lunar.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _comet,
                letterSpacing: 0.5,
              ),
            ),
          ),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _nova,
              letterSpacing: -0.2,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: _asteroid,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              border: InputBorder.none,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildParameterCard(String label, IconData icon, Widget control) {
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _stellar.withOpacity(0.8),
                    _stellar.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _lunar.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 20,
                  color: _stardust,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _nova,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 16),
            control,
          ],
        ),
      ),
    );
  }

  Widget _buildModernRangeControl({
    required int minValue,
    required int maxValue,
    required Function(int) onMinChanged,
    required Function(int) onMaxChanged,
    required BuildContext context,
    required int min,
    required int max,
    required String label,
  }) {
    return Container(
      height: 50,
      width: 140,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showRangePicker(
            context: context,
            currentMin: minValue,
            currentMax: maxValue,
            min: min,
            max: max,
            onMinChanged: onMinChanged,
            onMaxChanged: onMaxChanged,
            label: label,
          ),
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$minValue',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _nova,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  width: 16,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _proverCore.withOpacity(0.4),
                        _proverCore.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              Text(
                '$maxValue',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _nova,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncrementControl(BuildContext context, ProgressionManagerProvider provider) {
    return Container(
      height: 50,
      width: 100,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showIncrementPicker(context, provider),
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _increment.toStringAsFixed(_increment == _increment.roundToDouble() ? 0 : 1),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _nova,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'kg',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _stardust,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRangePicker({
    required BuildContext context,
    required int currentMin,
    required int currentMax,
    required int min,
    required int max,
    required Function(int) onMinChanged,
    required Function(int) onMaxChanged,
    required String label,
  }) {
    HapticFeedback.mediumImpact();
    
    int tempMin = currentMin;
    int tempMax = currentMax;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: _nebula,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: _lunar.withOpacity(0.3), width: 1),
                  left: BorderSide(color: _lunar.withOpacity(0.3), width: 1),
                  right: BorderSide(color: _lunar.withOpacity(0.3), width: 1),
                ),
              ),
              padding: const EdgeInsets.all(24),
              height: 480,
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _asteroid.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    label.toUpperCase() + '-BEREICH',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _stardust,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Range display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: _stellar.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _lunar.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Text(
                              'MIN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _proverCore.withOpacity(0.7),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$tempMin',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: _nova,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Container(
                            width: 24,
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _proverCore.withOpacity(0.3),
                                  _proverCore.withOpacity(0.6),
                                  _proverCore.withOpacity(0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              'MAX',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _proverCore.withOpacity(0.7),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$tempMax',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: _nova,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Wheels
                  Expanded(
                    child: Row(
                      children: [
                        // MIN Wheel
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  _stellar.withOpacity(0.2),
                                  _stellar.withOpacity(0.4),
                                  _stellar.withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _lunar.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: ListWheelScrollView(
                              itemExtent: 50,
                              physics: const FixedExtentScrollPhysics(),
                              controller: FixedExtentScrollController(
                                initialItem: tempMin - min,
                              ),
                              diameterRatio: 1.5,
                              perspective: 0.003,
                              onSelectedItemChanged: (index) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  tempMin = min + index;
                                  if (tempMin > tempMax) {
                                    tempMax = tempMin;
                                  }
                                });
                              },
                              children: List.generate(
                                max - min + 1,
                                (index) {
                                  final value = min + index;
                                  final isSelected = value == tempMin;
                                  return Center(
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 200),
                                      style: TextStyle(
                                        fontSize: isSelected ? 24 : 16,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                        color: isSelected ? _nova : _asteroid,
                                      ),
                                      child: Text('$value'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // MAX Wheel
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  _stellar.withOpacity(0.2),
                                  _stellar.withOpacity(0.4),
                                  _stellar.withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _lunar.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: ListWheelScrollView(
                              itemExtent: 50,
                              physics: const FixedExtentScrollPhysics(),
                              controller: FixedExtentScrollController(
                                initialItem: tempMax - min,
                              ),
                              diameterRatio: 1.5,
                              perspective: 0.003,
                              onSelectedItemChanged: (index) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  tempMax = min + index;
                                  if (tempMax < tempMin) {
                                    tempMin = tempMax;
                                  }
                                });
                              },
                              children: List.generate(
                                max - min + 1,
                                (index) {
                                  final value = min + index;
                                  final isSelected = value == tempMax;
                                  return Center(
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 200),
                                      style: TextStyle(
                                        fontSize: isSelected ? 24 : 16,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                        color: isSelected ? _nova : _asteroid,
                                      ),
                                      child: Text('$value'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Confirm button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onMinChanged(tempMin);
                      onMaxChanged(tempMax);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_proverCore.withOpacity(0.9), _proverGlow.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _proverCore.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'ÜBERNEHMEN',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _nova,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showIncrementPicker(BuildContext context, ProgressionManagerProvider provider) {
    HapticFeedback.mediumImpact();
    
    final increments = [0.25, 0.5, 1.0, 1.25, 2.0, 2.5, 5.0, 7.5, 10.0];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        double tempValue = _increment;
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: _nebula,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: _lunar.withOpacity(0.3), width: 1),
                  left: BorderSide(color: _lunar.withOpacity(0.3), width: 1),
                  right: BorderSide(color: _lunar.withOpacity(0.3), width: 1),
                ),
              ),
              padding: const EdgeInsets.all(24),
              height: 420,
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _asteroid.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  const Text(
                    'GEWICHTSSTEIGERUNG',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _stardust,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Current value display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(
                      color: _stellar.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _lunar.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tempValue.toStringAsFixed(tempValue == tempValue.roundToDouble() ? 0 : 2),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: _nova,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'kg',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: _proverCore.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Wheel
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _stellar.withOpacity(0.2),
                            _stellar.withOpacity(0.4),
                            _stellar.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _lunar.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: ListWheelScrollView(
                        itemExtent: 50,
                        physics: const FixedExtentScrollPhysics(),
                        controller: FixedExtentScrollController(
                          initialItem: increments.indexOf(_increment),
                        ),
                        diameterRatio: 1.5,
                        perspective: 0.003,
                        onSelectedItemChanged: (index) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            tempValue = increments[index];
                          });
                        },
                        children: increments.map((increment) {
                          final isSelected = increment == tempValue;
                          return Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: isSelected ? 24 : 16,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                color: isSelected ? _nova : _asteroid,
                              ),
                              child: Text(
                                '${increment.toStringAsFixed(increment == increment.roundToDouble() ? 0 : 2)} kg',
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Confirm button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _increment = tempValue;
                      });
                      provider.updateProfile('config.increment', tempValue);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_proverCore.withOpacity(0.9), _proverGlow.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _proverCore.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'ÜBERNEHMEN',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _nova,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context, ProgressionManagerProvider provider) {
    if (!widget.isDialog) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: _lunar.withOpacity(0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                provider.closeProfileEditor();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _lunar.withOpacity(0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'ABBRECHEN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _stardust,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Consumer<ProgressionManagerProvider>(
              builder: (context, prov, child) {
                final isLoading = prov.profileProvider.isSaving;
                
                return GestureDetector(
                  onTap: isLoading ? null : () => _handleSave(context, provider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isLoading 
                          ? [_asteroid.withOpacity(0.6), _asteroid.withOpacity(0.4)] 
                          : [_proverCore.withOpacity(0.9), _proverGlow.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        if (!isLoading)
                          BoxShadow(
                            color: _proverCore.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLoading) 
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(_nova),
                              ),
                            ),
                          if (isLoading) const SizedBox(width: 8),
                          Text(
                            isLoading ? 'SPEICHERN...' : 'SPEICHERN',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _nova,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
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

  void _handleSave(BuildContext context, ProgressionManagerProvider provider) async {
    HapticFeedback.mediumImpact();
    
    final currentProfile = provider.bearbeitetesProfil;
    if (currentProfile == null) return;
    
    final bool isNewProfile = currentProfile.id.contains('profile_') || 
                              currentProfile.id.contains('-copy-');
    
    if (isNewProfile) {
      _startSmoothTransitionAndSave(context, provider, currentProfile);
    } else {
      final result = await provider.saveProfile();
      
      if (context.mounted && result['success'] == true) {
        _updateControllersFromProfile();
      } else if (context.mounted) {
        provider.closeProfileEditor();
        Navigator.of(context).pop();
      }
    }
  }
  
  void _startSmoothTransitionAndSave(BuildContext context, ProgressionManagerProvider provider, dynamic currentProfile) async {
    provider.closeProfileEditor();
    
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        SmoothPageRoute(
          builder: (context) => _ProfileDetailWithSaving(
            profile: currentProfile,
            initialTab: 0,
            onSaveComplete: () async {
              final result = await provider.saveProfileDirectly(currentProfile);
              if (result['success'] == true) {
                await provider.refreshProfiles();
              }
              return result;
            },
          ),
        ),
      );
    }
  }

  void _updateControllersFromProfile() {
    final provider = Provider.of<ProgressionManagerProvider>(context, listen: false);
    final profil = provider.bearbeitetesProfil ?? widget.profil;
    _updateControllersIfNeeded(profil);
  }
}

// Wrapper-Widget für ProfileDetailScreen mit paralleler Speicherung
class _ProfileDetailWithSaving extends StatefulWidget {
  final dynamic profile;
  final int initialTab;
  final Future<Map<String, dynamic>> Function() onSaveComplete;

  const _ProfileDetailWithSaving({
    required this.profile,
    required this.initialTab,
    required this.onSaveComplete,
  });

  @override
  State<_ProfileDetailWithSaving> createState() => _ProfileDetailWithSavingState();
}

class _ProfileDetailWithSavingState extends State<_ProfileDetailWithSaving> {
  bool _isSaving = true;
  bool _saveSuccess = false;

  @override
  void initState() {
    super.initState();
    
    Future.delayed(const Duration(milliseconds: 200), () async {
      try {
        final result = await widget.onSaveComplete();
        if (mounted) {
          setState(() {
            _isSaving = false;
            _saveSuccess = result['success'] == true;
          });
          
          if (_saveSuccess) {
            await Future.delayed(const Duration(milliseconds: 800));
            if (mounted) {
              setState(() {
                _saveSuccess = false;
              });
            }
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSaving = false;
            _saveSuccess = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ProfileDetailScreen(
          profile: widget.profile,
          initialTab: widget.initialTab,
        ),
        
        if (_isSaving || _saveSuccess)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            right: 16,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _saveSuccess 
                    ? [Colors.green.withOpacity(0.9), Colors.green.withOpacity(0.7)]
                    : [const Color(0xFFFF4500).withOpacity(0.9), const Color(0xFFFF6B3D).withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (_saveSuccess ? Colors.green : const Color(0xFFFF4500)).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSaving)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    const Icon(Icons.check_circle, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    _isSaving ? 'Speichern...' : 'Gespeichert',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}