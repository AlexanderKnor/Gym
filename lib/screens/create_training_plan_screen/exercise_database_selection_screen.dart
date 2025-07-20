import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _ExerciseDatabaseSelectionScreenState extends State<ExerciseDatabaseSelectionScreen> {
  final ExerciseDatabaseService _exerciseService = ExerciseDatabaseService.instance;
  final TextEditingController _searchController = TextEditingController();
  
  List<PredefinedExercise> _allExercises = [];
  List<PredefinedExercise> _filteredExercises = [];
  List<String> _muscleGroups = [];
  List<String> _equipment = [];
  
  String? _selectedMuscleGroup;
  String? _selectedEquipment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Laden der Übungen: $e'),
          backgroundColor: const Color(0xFFFF453A),
        ),
      );
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
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      extendBodyBehindAppBar: true,
      floatingActionButton: _isLoading ? null : Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF4500),
              Color(0xFFFF6B3D),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4500).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomExerciseCreationScreen(
                    onExerciseCreated: (customExercise) {
                      Navigator.pop(context); // Pop the custom exercise creation screen
                      widget.onExerciseSelected(customExercise);
                    },
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_rounded,
                    color: Color(0xFFFFFFFF),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Eigene Übung',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF000000),
                const Color(0xFF000000).withOpacity(0.95),
                const Color(0xFF000000).withOpacity(0.8),
                const Color(0xFF000000).withOpacity(0.4),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 0.6, 0.85, 1.0],
            ),
          ),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF48484A).withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Color(0xFFFFFFFF),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Übung auswählen',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: Color(0xFFFFFFFF),
          ),
        ),
        centerTitle: true,
        actions: [
          if (_selectedMuscleGroup != null || _selectedEquipment != null)
            Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              child: IconButton(
                icon: const Icon(
                  Icons.clear_all_rounded,
                  color: Color(0xFFFF4500),
                ),
                onPressed: _clearFilters,
                tooltip: 'Filter zurücksetzen',
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF4500),
              ),
            )
          : Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
                
                // Search Bar
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF48484A).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _filterExercises(),
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Übung suchen...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF8E8E93),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF8E8E93),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Color(0xFF8E8E93),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _filterExercises();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),

                // Filter Chips
                Container(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Muscle Group Filter
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            _selectedMuscleGroup ?? 'Muskelgruppe',
                            style: TextStyle(
                              color: _selectedMuscleGroup != null
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFF8E8E93),
                            ),
                          ),
                          selected: _selectedMuscleGroup != null,
                          onSelected: (_) => _showMuscleGroupPicker(),
                          backgroundColor: const Color(0xFF1C1C1E),
                          selectedColor: const Color(0xFFFF4500).withOpacity(0.2),
                          side: BorderSide(
                            color: _selectedMuscleGroup != null
                                ? const Color(0xFFFF4500)
                                : const Color(0xFF48484A),
                          ),
                          showCheckmark: false,
                        ),
                      ),

                      // Equipment Filter
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            _selectedEquipment ?? 'Equipment',
                            style: TextStyle(
                              color: _selectedEquipment != null
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFF8E8E93),
                            ),
                          ),
                          selected: _selectedEquipment != null,
                          onSelected: (_) => _showEquipmentPicker(),
                          backgroundColor: const Color(0xFF1C1C1E),
                          selectedColor: const Color(0xFFFF4500).withOpacity(0.2),
                          side: BorderSide(
                            color: _selectedEquipment != null
                                ? const Color(0xFFFF4500)
                                : const Color(0xFF48484A),
                          ),
                          showCheckmark: false,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Exercise List
                Expanded(
                  child: _filteredExercises.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: _filteredExercises.length,
                          itemBuilder: (context, index) {
                            final exercise = _filteredExercises[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C1E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF48484A).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    widget.onExerciseSelected(exercise);
                                    HapticFeedback.lightImpact();
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2C2C2E),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.fitness_center,
                                              color: Color(0xFFFF4500),
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                exercise.name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFFFFFFFF),
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFF4500).withOpacity(0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      exercise.primaryMuscleGroup,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                        color: Color(0xFFFF4500),
                                                      ),
                                                    ),
                                                  ),
                                                  if (exercise.secondaryMuscleGroups.isNotEmpty) ...[
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      exercise.secondaryMuscleGroups.join(', '),
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Color(0xFF8E8E93),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                exercise.equipment,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFFAEAEB2),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          color: Color(0xFF8E8E93),
                                          size: 16,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1E),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off,
              size: 40,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Keine Übungen gefunden',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Versuche andere Suchbegriffe oder\nerstelle eine eigene Übung',
            style: TextStyle(
              color: Color(0xFFAEAEB2),
              fontSize: 15,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showMuscleGroupPicker() {
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
                'Muskelgruppe wählen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFFFFF),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      title: const Text(
                        'Alle Muskelgruppen',
                        style: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedMuscleGroup = null;
                        });
                        _filterExercises();
                        Navigator.pop(context);
                      },
                    ),
                    ..._muscleGroups.map((muscleGroup) {
                      return ListTile(
                        title: Text(
                          muscleGroup,
                          style: TextStyle(
                            color: _selectedMuscleGroup == muscleGroup
                                ? const Color(0xFFFF4500)
                                : const Color(0xFFFFFFFF),
                            fontWeight: _selectedMuscleGroup == muscleGroup
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        trailing: _selectedMuscleGroup == muscleGroup
                            ? const Icon(
                                Icons.check,
                                color: Color(0xFFFF4500),
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedMuscleGroup = muscleGroup;
                          });
                          _filterExercises();
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ],
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
                  children: [
                    ListTile(
                      title: const Text(
                        'Alle Equipment',
                        style: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedEquipment = null;
                        });
                        _filterExercises();
                        Navigator.pop(context);
                      },
                    ),
                    ..._equipment.map((equipment) {
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
                          _filterExercises();
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}