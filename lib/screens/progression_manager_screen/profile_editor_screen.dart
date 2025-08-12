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

  @override
  void initState() {
    super.initState();
    
    // Wenn eine initialProfileAction gegeben ist, führe sie SOFORT aus
    if (widget.initialProfileAction != null) {
      // WICHTIG: Zuerst das alte Profil löschen, DANN die neue Aktion ausführen
      final provider = Provider.of<ProgressionManagerProvider>(context, listen: false);
      provider.profileProvider.clearEditedProfile(); // Neue Methode die wir erstellen müssen
      
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
    // Wenn noch nicht initialisiert, zeige Loading (OHNE das Profil zu lesen)
    if (!_initialized) {
      final provider = Provider.of<ProgressionManagerProvider>(context);
      return _buildLoadingScreen(context, provider);
    }

    final provider = Provider.of<ProgressionManagerProvider>(context);
    final profil = provider.bearbeitetesProfil;

    // Jetzt erst das Profil prüfen, nachdem die Initialisierung abgeschlossen ist
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
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
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
          onTap: () {
            provider.closeProfileEditor();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
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
        // Explizit zurück navigieren nach Provider-Update
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        return false; // Verhindert doppelte Navigation
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

  // Aktualisiert die Controller nur wenn nötig (verhindert Cursor-Sprünge)
  void _updateControllersIfNeeded(dynamic profil) {
    if (profil == null) return;
    
    // Prüfe und aktualisiere nur wenn sich Werte geändert haben
    if (_nameController.text != profil.name) {
      _nameController.text = profil.name;
    }
    if (_descriptionController.text != profil.description) {
      _descriptionController.text = profil.description;
    }
    
    final repsMin = (profil.config['targetRepsMin'] ?? 8).toInt().toString();
    if (_repsMinController.text != repsMin) {
      _repsMinController.text = repsMin;
    }
    
    final repsMax = (profil.config['targetRepsMax'] ?? 12).toInt().toString();
    if (_repsMaxController.text != repsMax) {
      _repsMaxController.text = repsMax;
    }
    
    final rirMin = (profil.config['targetRIRMin'] ?? 1).toInt().toString();
    if (_rirMinController.text != rirMin) {
      _rirMinController.text = rirMin;
    }
    
    final rirMax = (profil.config['targetRIRMax'] ?? 3).toInt().toString();
    if (_rirMaxController.text != rirMax) {
      _rirMaxController.text = rirMax;
    }
    
    final increment = (profil.config['increment'] ?? 2.5).toString();
    if (_incrementController.text != increment) {
      _incrementController.text = increment;
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize controllers with empty values first - will be updated in didUpdateWidget
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _repsMinController = TextEditingController();
    _repsMaxController = TextEditingController();
    _rirMinController = TextEditingController();
    _rirMaxController = TextEditingController();
    _incrementController = TextEditingController();
    
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
    
    // Update controllers will be done in build() when profile changes
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
    
    // Aktualisiere Controller, wenn sich das Profil geändert hat
    _updateControllersIfNeeded(widget.profil);
    
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
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
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
    return Consumer<ProgressionManagerProvider>(
      builder: (context, prov, child) {
        final isLoading = prov.profileProvider.isSaving;
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isLoading 
                ? [_comet, _mercury] 
                : [_proverCore, _proverGlow],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (isLoading ? _comet : _proverCore).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: isLoading ? null : () => _handleSave(context, provider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    if (isLoading) 
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(_nova),
                        ),
                      )
                    else
                      const Icon(Icons.check, color: _nova, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      isLoading ? 'SPEICHERN...' : 'SPEICHERN',
                      style: const TextStyle(
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
      },
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
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
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
            child: Consumer<ProgressionManagerProvider>(
              builder: (context, prov, child) {
                final isLoading = prov.profileProvider.isSaving;
                
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLoading 
                        ? [_comet, _mercury] 
                        : [_proverCore, _proverGlow],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (isLoading ? _comet : _proverCore).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: isLoading ? null : () => _handleSave(context, provider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isLoading) 
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(_nova),
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                            if (isLoading) const SizedBox(width: 8),
                            Text(
                              isLoading ? 'SPEICHERN...' : 'SPEICHERN',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _nova,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
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

  void _handleSave(BuildContext context, ProgressionManagerProvider provider) async {
    HapticFeedback.mediumImpact();
    
    // Save profile reference BEFORE closing editor
    final currentProfile = provider.bearbeitetesProfil;
    if (currentProfile == null) return;
    
    // Check if this is a new profile before saving  
    final bool isNewProfile = currentProfile.id.contains('profile_') || 
                              currentProfile.id.contains('-copy-');
    final String profileId = currentProfile.id;
    
    if (isNewProfile) {
      // Start smooth transition while saving in background
      _startSmoothTransitionAndSave(context, provider, currentProfile);
    } else {
      // For existing profiles, save normally
      final result = await provider.saveProfile();
      
      if (context.mounted && result['success'] == true) {
        // Update UI controllers with the latest saved values
        _updateControllersFromProfile();
      } else if (context.mounted) {
        // Close on failure
        provider.closeProfileEditor();
        Navigator.of(context).pop();
      }
    }
  }
  
  void _startSmoothTransitionAndSave(BuildContext context, ProgressionManagerProvider provider, dynamic currentProfile) async {
    // SOFORTIGE ANIMATION: Editor schließen und sofort navigieren, parallel speichern!
    
    // 1. Editor UI sofort schließen für butterweiche Animation
    provider.closeProfileEditor();
    
    // 2. Sofortige Navigation mit temporärem Profil - kein Warten!
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        SmoothPageRoute(
          builder: (context) => _ProfileDetailWithSaving(
            profile: currentProfile,
            initialTab: 0,
            onSaveComplete: () async {
              // Speichere das spezifische Profil parallel zur Animation
              // Verwende die Kopie, da Editor bereits geschlossen wurde
              final result = await provider.saveProfileDirectly(currentProfile);
              if (result['success'] == true) {
                await provider.refreshProfiles();
                // NICHT setDemoProfileId für Editor-Tab!
                // Editor-Tab nutzt ausschließlich widget.profile
              }
              return result;
            },
          ),
        ),
      );
    }
  }

  void _updateControllersFromProfile() {
    // Vereinfachte Methode - verwendet die neue _updateControllersIfNeeded
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
    
    // Starte parallele Speicherung nach kurzer Verzögerung für butterweiche Animation
    Future.delayed(const Duration(milliseconds: 200), () async {
      try {
        final result = await widget.onSaveComplete();
        if (mounted) {
          setState(() {
            _isSaving = false;
            _saveSuccess = result['success'] == true;
          });
          
          // Kurzes Feedback bei erfolgreichem Speichern
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
        // Hauptinhalt - ProfileDetailScreen
        ProfileDetailScreen(
          profile: widget.profile,
          initialTab: widget.initialTab,
        ),
        
        // Subtiler Save-Indicator oben rechts
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
                    : [Color(0xFFFF4500).withOpacity(0.9), Color(0xFFFF6B3D).withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (_saveSuccess ? Colors.green : Color(0xFFFF4500)).withOpacity(0.3),
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