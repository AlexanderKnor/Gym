import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import 'profile_detail_screen.dart';

class ProfileEditorScreen extends StatelessWidget {
  final bool isDialog;

  // Premium color scheme
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

  const ProfileEditorScreen({
    Key? key,
    this.isDialog = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);
    final profil = provider.bearbeitetesProfil;

    if (profil == null) {
      Future.delayed(const Duration(seconds: 3), () {
        if (context.mounted && provider.bearbeitetesProfil == null) {
          provider.closeProfileEditor();
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      });

      return _buildLoadingScreen(context, provider);
    }

    if (isDialog) {
      return _buildDialogMode(context, provider, profil);
    }

    return _buildScreenMode(context, provider, profil);
  }

  Widget _buildLoadingScreen(BuildContext context, ProgressionManagerProvider provider) {
    return Scaffold(
      backgroundColor: _void,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_cosmos, _nebula],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: _stardust, size: 24),
                      onPressed: () {
                        provider.closeProfileEditor();
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'PROFIL WIRD GELADEN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _comet,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Loading indicator
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(_proverCore),
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Einen Moment bitte...',
                        style: TextStyle(
                          fontSize: 14,
                          color: _comet,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
        // Backdrop
        GestureDetector(
          onTap: provider.closeProfileEditor,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: _void.withOpacity(0.5),
            ),
          ),
        ),
        // Dialog content
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
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
        return false;
      },
      child: Scaffold(
        backgroundColor: _void,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_cosmos, _nebula],
            ),
          ),
          child: SafeArea(
            child: ProfileEditorContent(
              profil: profil,
              isDialog: false,
            ),
          ),
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
  late TextEditingController _repsMinController;
  late TextEditingController _repsMaxController;
  late TextEditingController _rirMinController;
  late TextEditingController _rirMaxController;
  late TextEditingController _incrementController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Premium color scheme - matched to existing screens
  static const Color _midnight = Color(0xFF000000);
  static const Color _charcoal = Color(0xFF1C1C1E);
  static const Color _graphite = Color(0xFF2C2C2E);
  static const Color _steel = Color(0xFF48484A);
  static const Color _mercury = Color(0xFF8E8E93);
  static const Color _silver = Color(0xFFAEAEB2);
  static const Color _snow = Color(0xFFFFFFFF);
  static const Color _emberCore = Color(0xFFFF4500);
  
  // Keep existing aliases for compatibility
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
  static const Color _proverFlare = Color(0xFFFFA500);

  // Helper method to get current profile for initialization (works during initState)
  dynamic _getCurrentProfileForInit() {
    // During initState, we don't have context access for Provider.of, so we check widget.profil first
    // If it's the edited profile from provider, it should have the latest data
    return widget.profil;
  }

  @override
  void initState() {
    super.initState();
    // Initialize controllers with fresh profile data
    final currentProfile = _getCurrentProfileForInit();
    _nameController = TextEditingController(text: currentProfile.name);
    _descriptionController = TextEditingController(text: currentProfile.description);
    _repsMinController = TextEditingController(text: (currentProfile.config['targetRepsMin'] ?? 8).toInt().toString());
    _repsMaxController = TextEditingController(text: (currentProfile.config['targetRepsMax'] ?? 12).toInt().toString());
    _rirMinController = TextEditingController(text: (currentProfile.config['targetRIRMin'] ?? 1).toInt().toString());
    _rirMaxController = TextEditingController(text: (currentProfile.config['targetRIRMax'] ?? 3).toInt().toString());
    _incrementController = TextEditingController(text: (currentProfile.config['increment'] ?? 2.5).toString());
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));
    
    _animationController.forward();
    
    // Update controllers with fresh data after initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateControllersFromProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _repsMinController.dispose();
    _repsMaxController.dispose();
    _rirMinController.dispose();
    _rirMaxController.dispose();
    _incrementController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _stellar.withOpacity(0.9),
                    _nebula.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _lunar.withOpacity(0.3),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    _buildHeader(context, provider),
                    Expanded(
                      child: _buildContent(context, provider),
                    ),
                    if (widget.isDialog) _buildDialogActions(context, provider),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ProgressionManagerProvider provider) {
    final isNewProfile = widget.profil.id.contains('profile_');
    
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _stellar.withOpacity(0.8),
            _stellar.withOpacity(0.4),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: _lunar.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Close button
          if (!widget.isDialog) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _lunar.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: _stardust, size: 20),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  provider.closeProfileEditor();
                },
              ),
            ),
            const SizedBox(width: 16),
          ],
          
          // Title
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNewProfile ? 'NEUES PROFIL' : 'PROFIL BEARBEITEN',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _nova,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          
          // Save button for screen mode
          if (!widget.isDialog) _buildSaveButton(context, provider),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, ProgressionManagerProvider provider) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_proverCore, _proverGlow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleSave(context, provider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: const [
                Icon(Icons.check, color: _nova, size: 18),
                SizedBox(width: 8),
                Text(
                  'SPEICHERN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _nova,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProgressionManagerProvider provider) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildInputSection(
            icon: Icons.badge_outlined,
            title: 'GRUNDINFORMATIONEN',
            children: [
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
                hint: 'Beschreibe das Profil in wenigen Worten',
                maxLines: 3,
                onChanged: (value) => provider.updateProfile('description', value),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInputSection(
            icon: Icons.fitness_center,
            title: 'TRAININGSPARAMETER',
            children: [
              _buildRangeInput(
                label: 'Wiederholungsbereich',
                icon: Icons.repeat,
                minController: _repsMinController,
                maxController: _repsMaxController,
                onMinChanged: (value) => provider.updateProfile(
                  'config.targetRepsMin', 
                  int.tryParse(value) ?? 8
                ),
                onMaxChanged: (value) => provider.updateProfile(
                  'config.targetRepsMax', 
                  int.tryParse(value) ?? 12
                ),
              ),
              const SizedBox(height: 20),
              _buildRangeInput(
                label: 'RIR-Bereich (Reps in Reserve)',
                icon: Icons.speed,
                minController: _rirMinController,
                maxController: _rirMaxController,
                onMinChanged: (value) => provider.updateProfile(
                  'config.targetRIRMin', 
                  int.tryParse(value) ?? 1
                ),
                onMaxChanged: (value) => provider.updateProfile(
                  'config.targetRIRMax', 
                  int.tryParse(value) ?? 3
                ),
              ),
              const SizedBox(height: 20),
              _buildNumberInput(
                label: 'Gewichtssteigerung',
                icon: Icons.trending_up,
                controller: _incrementController,
                suffix: 'kg',
                onChanged: (value) => provider.updateProfile(
                  'config.increment', 
                  double.tryParse(value) ?? 2.5
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _stellar.withOpacity(0.4),
            _nebula.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _lunar.withOpacity(0.2),
          width: 1,
        ),
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
                    colors: [_proverCore.withOpacity(0.2), _proverGlow.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _proverCore.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: _proverCore, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _comet,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Function(String) onChanged,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _stardust,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _void.withOpacity(0.4),
                _cosmos.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _lunar.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _void.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
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
                color: _silver.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              filled: true,
              fillColor: _graphite.withOpacity(0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _steel.withOpacity(0.3),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _steel.withOpacity(0.3),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _emberCore,
                  width: 2,
                ),
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildRangeInput({
    required String label,
    required IconData icon,
    required TextEditingController minController,
    required TextEditingController maxController,
    required Function(String) onMinChanged,
    required Function(String) onMaxChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _proverCore, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _stardust,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                controller: minController,
                label: 'MIN',
                onChanged: onMinChanged,
              ),
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Container(
                height: 2,
                width: 16,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _proverCore.withOpacity(0.3),
                      _proverCore.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            Expanded(
              child: _buildNumberField(
                controller: maxController,
                label: 'MAX',
                onChanged: onMaxChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required Function(String) onChanged,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _emberCore.withOpacity(0.8),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _nova,
            letterSpacing: -0.5,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: _graphite.withOpacity(0.6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _steel.withOpacity(0.3),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _steel.withOpacity(0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _emberCore,
                width: 2,
              ),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildNumberInput({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String suffix,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _proverCore, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _stardust,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _nova,
                  letterSpacing: -0.5,
                ),
                decoration: InputDecoration(
                  suffixText: suffix,
                  suffixStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _emberCore.withOpacity(0.8),
                    letterSpacing: 0.5,
                  ),
                  filled: true,
                  fillColor: _graphite.withOpacity(0.6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _steel.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _steel.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _emberCore,
                      width: 2,
                    ),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDialogActions(BuildContext context, ProgressionManagerProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _stellar.withOpacity(0.4),
            _stellar.withOpacity(0.8),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: _lunar.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _lunar.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    provider.closeProfileEditor();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: const Text(
                      'ABBRECHEN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _stardust,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_proverCore, _proverGlow],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _proverCore.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _handleSave(context, provider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: const Text(
                      'SPEICHERN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _nova,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSave(BuildContext context, ProgressionManagerProvider provider) async {
    HapticFeedback.mediumImpact();
    
    final result = await provider.saveProfile();

    if (context.mounted) {
      final bool isSuccess = result['success'] == true;
      final String? profileId = result['profileId'];
      final bool isNewProfile = result['isNewProfile'] ?? false;

      if (isSuccess) {
        // Force refresh of profile data to ensure UI shows latest values
        await provider.refreshProfiles();
        
        // For existing profiles, update the current edited profile with fresh data
        if (!isNewProfile && profileId != null) {
          final updatedProfile = provider.profileProvider.getProfileById(profileId);
          if (updatedProfile != null) {
            // Update the provider's current edited profile
            provider.openProfileEditor(updatedProfile);
          }
        }
        
        // Update UI controllers with the latest saved values
        _updateControllersFromProfile();
        
        // Show brief success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 18),
                SizedBox(width: 12),
                Text('Profil erfolgreich gespeichert'),
              ],
            ),
            backgroundColor: _stellar,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(milliseconds: 1500),
          ),
        );
        
        // For existing profiles, keep the editor open with updated data
        // Only close for new profiles that should navigate to detail view
        if (isNewProfile) {
          provider.closeProfileEditor();
        }
      } else {
        // Close on failure
        provider.closeProfileEditor();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          if (isSuccess && isNewProfile && profileId != null) {
            // For new profiles, navigate to ProfileDetailScreen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                final updatedProfile = provider.profileProvider
                    .getProfileById(profileId);
                if (updatedProfile != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProfileDetailScreen(
                        profile: updatedProfile,
                        initialTab: 0,
                      ),
                    ),
                  );
                }
              }
            });
          }
          // For existing profiles, the editor closes automatically via state management
        }
      });
    }
  }

  void _updateControllersFromProfile() {
    // Get the fresh profile data from provider instead of widget.profil
    final provider = Provider.of<ProgressionManagerProvider>(context, listen: false);
    
    // First try to get the most up-to-date profile from the profileProvider by ID
    final profileId = (provider.bearbeitetesProfil ?? widget.profil).id;
    final freshProfile = provider.profileProvider.getProfileById(profileId) ?? 
                        provider.bearbeitetesProfil ?? 
                        widget.profil;
    
    // Update controllers with the fresh profile values to sync UI
    _nameController.text = freshProfile.name ?? '';
    _descriptionController.text = freshProfile.description ?? '';
    
    // Format integers properly (no .0 suffix)
    final repsMin = freshProfile.config['targetRepsMin'];
    final repsMax = freshProfile.config['targetRepsMax'];
    final rirMin = freshProfile.config['targetRIRMin'];
    final rirMax = freshProfile.config['targetRIRMax'];
    final increment = freshProfile.config['increment'];
    
    _repsMinController.text = repsMin is num ? repsMin.toInt().toString() : '8';
    _repsMaxController.text = repsMax is num ? repsMax.toInt().toString() : '12';
    _rirMinController.text = rirMin is num ? rirMin.toInt().toString() : '1';
    _rirMaxController.text = rirMax is num ? rirMax.toInt().toString() : '3';
    _incrementController.text = increment is num ? increment.toString() : '2.5';
  }
}