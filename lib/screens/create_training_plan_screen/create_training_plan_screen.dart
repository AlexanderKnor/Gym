// lib/screens/create_training_plan_screen/create_training_plan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';
import '../../widgets/create_training_plan_screen/create_training_plan_form_widget.dart';

class CreateTrainingPlanScreen extends StatelessWidget {
  const CreateTrainingPlanScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Provider in der main.dart erstellen und hier nur referenzieren
    final createProvider =
        Provider.of<CreateTrainingPlanProvider>(context, listen: false);

    // Zurücksetzen für einen sauberen Start - nach dem Build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      createProvider.reset();
    });

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // _void
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
                const Color(0xFF000000), // _void
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
            color: const Color(0xFF18181C).withOpacity(0.8), // _stellar
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF35353C).withOpacity(0.5), // _asteroid
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(12),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Color(0xFFF5F5F7), // _nova
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF18181C), // _stellar
                Color(0xFF0F0F12), // _nebula
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFF4500).withOpacity(0.3), // _proverCore
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4500).withOpacity(0.1), // _proverCore
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFF4500), Color(0xFFFF6B3D)], // _proverCore, _proverGlow
            ).createShader(bounds),
            child: const Text(
              'NEUER PLAN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF5F5F7), // _nova
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: const CreateTrainingPlanFormWidget(),
    );
  }
}
