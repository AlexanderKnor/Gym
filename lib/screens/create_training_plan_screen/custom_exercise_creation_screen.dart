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
    extends State<CustomExerciseCreationScreen> {
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
  void dispose() {
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
      backgroundColor: const Color(0xFF000000),
      extendBodyBehindAppBar: true,
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
          'Eigene Übung erstellen',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: Color(0xFFFFFFFF),
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFFFF4500),
                    ),
                  )
                : Container(
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
                        onTap: _createExercise,
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Text(
                            'ERSTELLEN',
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
            bottom: 32,
          ),
          children: [
            // Exercise Name
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF48484A).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Übungsname',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF4500),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'z.B. Meine spezielle Übung',
                        hintStyle: const TextStyle(
                          color: Color(0xFF8E8E93),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                  ],
                ),
              ),
            ),

            // Primary Muscle Group
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF48484A).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Primäre Muskelgruppe',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF4500),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showPrimaryMuscleGroupPicker(),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedPrimaryMuscle.isEmpty
                                        ? 'Wähle die primäre Muskelgruppe'
                                        : _selectedPrimaryMuscle,
                                    style: TextStyle(
                                      color: _selectedPrimaryMuscle.isEmpty
                                          ? const Color(0xFF8E8E93)
                                          : const Color(0xFFFFFFFF),
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: Color(0xFFFF4500),
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Secondary Muscle Groups
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF48484A).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sekundäre Muskelgruppen (optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF4500),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedSecondaryMuscles.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedSecondaryMuscles.map((muscle) {
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedSecondaryMuscles.remove(muscle);
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        muscle,
                                        style: const TextStyle(
                                          color: Color(0xFFFFFFFF),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.close_rounded,
                                        size: 14,
                                        color: Color(0xFF8E8E93),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showSecondaryMuscleGroupPicker,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.add_circle_outline,
                                  color: Color(0xFFFF4500),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Sekundäre Muskelgruppe',
                                    style: const TextStyle(
                                      color: Color(0xFFFF4500),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Equipment
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF48484A).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Equipment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF4500),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showEquipmentPicker(),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedEquipment.isEmpty
                                        ? 'Equipment auswählen'
                                        : _selectedEquipment,
                                    style: TextStyle(
                                      color: _selectedEquipment.isEmpty
                                          ? const Color(0xFF8E8E93)
                                          : const Color(0xFFFFFFFF),
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: Color(0xFFFF4500),
                                  size: 24,
                                ),
                              ],
                            ),
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
      ),
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
