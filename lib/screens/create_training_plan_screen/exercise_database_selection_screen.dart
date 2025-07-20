import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../models/exercise_database/predefined_exercise_model.dart';
import '../../services/exercise_database/exercise_database_service.dart';
import 'custom_exercise_creation_screen.dart';

class ExerciseDatabaseSelectionScreen extends StatefulWidget {
  final Function(PredefinedExercise) onExerciseSelected;

  const ExerciseDatabaseSelectionScreen({
    Key? key,
    required this.onExerciseSelected,
  }) : super(key: key);

  @override
  State<ExerciseDatabaseSelectionScreen> createState() => _ExerciseDatabaseSelectionScreenState();
}

class _ExerciseDatabaseSelectionScreenState extends State<ExerciseDatabaseSelectionScreen>
    with TickerProviderStateMixin {
  final ExerciseDatabaseService _exerciseService = ExerciseDatabaseService.instance;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  
  List<PredefinedExercise> _allExercises = [];
  List<PredefinedExercise> _filteredExercises = [];
  List<String> _muscleGroups = [];
  List<String> _equipment = [];
  
  String? _selectedMuscleGroup;
  String? _selectedEquipment;
  bool _isLoading = true;

  // Cosmic Color System
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

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      final exercises = await _exerciseService.getAllExercises();
      final muscleGroups = await _exerciseService.getAllMuscleGroups();
      final equipment = await _exerciseService.getAllEquipment();

      setState(() {
        _allExercises = exercises;
        _filteredExercises = exercises;
        _muscleGroups = muscleGroups;
        _equipment = equipment;
        _isLoading = false;
      });

      _fadeController.forward();
      _scaleController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackbar('Fehler beim Laden der Übungen: $e');
    }
  }

  void _filterExercises() {
    setState(() {
      _filteredExercises = _allExercises.where((exercise) {
        final matchesSearch = _searchController.text.isEmpty ||
            exercise.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            exercise.primaryMuscleGroup.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            exercise.equipment.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            exercise.secondaryMuscleGroups.any((muscle) => 
                muscle.toLowerCase().contains(_searchController.text.toLowerCase()));
        
        final matchesMuscleGroup = _selectedMuscleGroup == null ||
            exercise.primaryMuscleGroup == _selectedMuscleGroup ||
            exercise.secondaryMuscleGroups.contains(_selectedMuscleGroup);
        
        final matchesEquipment = _selectedEquipment == null ||
            exercise.equipment == _selectedEquipment;
        
        return matchesSearch && matchesMuscleGroup && matchesEquipment;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedMuscleGroup = null;
      _selectedEquipment = null;
      _filteredExercises = _allExercises;
    });
    HapticFeedback.mediumImpact();
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: _nova,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: _stellar,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _proverCore.withOpacity(0.3)),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _void,
      extendBodyBehindAppBar: true,
      floatingActionButton: _isLoading ? null : _buildFloatingActionButton(),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildMainContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              _stellar.withOpacity(0.6),
              _nebula.withOpacity(0.3),
              _void,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _lunar.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: _proverCore.withOpacity(0.1),
              blurRadius: 40,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: _proverCore,
                strokeWidth: 3,
                backgroundColor: _asteroid.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Übungen werden geladen...',
              style: TextStyle(
                color: _stardust,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _void,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      leading: _buildBackButton(),
      title: Text(
        'Übung auswählen',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: _nova,
        ),
      ),
      centerTitle: true,
      actions: [
        if (_selectedMuscleGroup != null || _selectedEquipment != null)
          _buildClearFiltersButton(),
      ],
    );
  }

  Widget _buildBackButton() {
    return Container(
      margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _stellar.withOpacity(0.8),
            _nebula.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _lunar.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _void.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Icon(
              Icons.arrow_back_ios_rounded,
              color: _nova,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClearFiltersButton() {
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _proverCore.withOpacity(0.15),
            _proverGlow.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _proverCore.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _proverCore.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _clearFilters,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.clear_all_rounded,
              color: _proverCore,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_proverCore, _proverGlow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _void.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomExerciseCreationScreen(
                  onExerciseCreated: (customExercise) {
                    Navigator.pop(context);
                    widget.onExerciseSelected(customExercise);
                  },
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: _nova,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Eigene Übung',
                  style: TextStyle(
                    color: _nova,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return FadeTransition(
      opacity: _fadeController,
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
          _buildSearchSection(),
          _buildFiltersSection(),
          const SizedBox(height: 16),
          _buildExercisesList(),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Stack(
        children: [
          // Glow effect background
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _proverCore.withOpacity(0.08),
                  blurRadius: 60,
                  spreadRadius: -15,
                ),
              ],
            ),
          ),
          // Main search container with glassmorphism
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _stellar.withOpacity(0.85),
                  _nebula.withOpacity(0.7),
                  _lunar.withOpacity(0.6),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _lunar.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _void.withOpacity(0.6),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                  spreadRadius: -8,
                ),
                BoxShadow(
                  color: _proverCore.withOpacity(0.05),
                  blurRadius: 80,
                  spreadRadius: -20,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Backdrop blur for glassmorphism
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _stellar.withOpacity(0.9),
                          _nebula.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  // Search field
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _filterExercises(),
                    style: TextStyle(
                      color: _nova,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.3,
                      height: 1.2,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nach Übungen suchen...',
                      hintStyle: TextStyle(
                        color: _stardust.withOpacity(0.8),
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.2,
                      ),
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                _proverCore.withOpacity(0.2),
                                _proverGlow.withOpacity(0.1),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.7, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            color: _proverCore.withOpacity(0.9),
                            size: 22,
                          ),
                        ),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? Container(
                              padding: const EdgeInsets.all(8),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _comet.withOpacity(0.2),
                                      _asteroid.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _comet.withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      _searchController.clear();
                                      _filterExercises();
                                      HapticFeedback.lightImpact();
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.clear_rounded,
                                        color: _comet,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
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

  Widget _buildFiltersSection() {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildFilterChip(
            label: _selectedMuscleGroup ?? 'Muskelgruppe',
            isSelected: _selectedMuscleGroup != null,
            onTap: _showMuscleGroupPicker,
            icon: Icons.fitness_center,
          ),
          const SizedBox(width: 12),
          _buildFilterChip(
            label: _selectedEquipment ?? 'Equipment',
            isSelected: _selectedEquipment != null,
            onTap: _showEquipmentPicker,
            icon: Icons.sports_gymnastics,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  _proverCore.withOpacity(0.2),
                  _proverGlow.withOpacity(0.1),
                ],
              )
            : LinearGradient(
                colors: [
                  _stellar.withOpacity(0.6),
                  _nebula.withOpacity(0.4),
                ],
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? _proverCore.withOpacity(0.4) : _lunar.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: _proverCore.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          BoxShadow(
            color: _void.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? _proverCore : _comet,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? _nova : _stardust,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExercisesList() {
    return Expanded(
      child: _filteredExercises.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 120, top: 8),
              itemCount: _filteredExercises.length,
              itemBuilder: (context, index) {
                return _buildExerciseCard(_filteredExercises[index]);
              },
            ),
    );
  }

  Widget _buildExerciseCard(PredefinedExercise exercise) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _stellar.withOpacity(0.7),
            _nebula.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _lunar.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _void.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: _proverCore.withOpacity(0.02),
            blurRadius: 32,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onExerciseSelected(exercise);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildExerciseIcon(),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildExerciseInfo(exercise),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _comet,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseIcon() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            _proverCore.withOpacity(0.15),
            _proverGlow.withOpacity(0.08),
            _stellar.withOpacity(0.8),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _proverCore.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _proverCore.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.fitness_center_rounded,
          color: _proverCore,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildExerciseInfo(PredefinedExercise exercise) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exercise.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _nova,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _proverCore.withOpacity(0.2),
                    _proverGlow.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _proverCore.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                exercise.primaryMuscleGroup,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _proverCore,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (exercise.secondaryMuscleGroups.isNotEmpty) ...[
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  exercise.secondaryMuscleGroups.join(', '),
                  style: TextStyle(
                    fontSize: 12,
                    color: _stardust,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          exercise.equipment,
          style: TextStyle(
            fontSize: 13,
            color: _comet,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ScaleTransition(
      scale: _scaleController,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    _stellar.withOpacity(0.8),
                    _nebula.withOpacity(0.4),
                    _void,
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _lunar.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _void.withOpacity(0.6),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: _comet,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Keine Übungen gefunden',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _nova,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Versuche andere Suchbegriffe oder\nerstelle eine eigene Übung',
              style: TextStyle(
                color: _stardust,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.2,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showMuscleGroupPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
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
          child: SafeArea(
            child: _buildPickerContent(
              title: 'Muskelgruppe wählen',
              items: ['Alle Muskelgruppen', ..._muscleGroups],
              selectedItem: _selectedMuscleGroup,
              onItemSelected: (item) {
                setState(() {
                  _selectedMuscleGroup = item == 'Alle Muskelgruppen' ? null : item;
                });
                _filterExercises();
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showEquipmentPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
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
          child: SafeArea(
            child: _buildPickerContent(
              title: 'Equipment wählen',
              items: ['Alle Equipment', ..._equipment],
              selectedItem: _selectedEquipment,
              onItemSelected: (item) {
                setState(() {
                  _selectedEquipment = item == 'Alle Equipment' ? null : item;
                });
                _filterExercises();
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickerContent({
    required String title,
    required List<String> items,
    required String? selectedItem,
    required Function(String) onItemSelected,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: _asteroid,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _nova,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = (index == 0 && selectedItem == null) ||
                  item == selectedItem;
              final isAllOption = index == 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            _proverCore.withOpacity(0.15),
                            _proverGlow.withOpacity(0.08),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            _asteroid.withOpacity(0.3),
                            _lunar.withOpacity(0.2),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? _proverCore.withOpacity(0.3)
                        : _asteroid.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onItemSelected(item);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                color: isAllOption
                                    ? _stardust
                                    : isSelected
                                        ? _nova
                                        : _stardust,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontSize: 16,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_rounded,
                              color: _proverCore,
                              size: 20,
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
    );
  }
}