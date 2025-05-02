// lib/screens/strength_calculator_screen/strength_calculator_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/strength_calculator_screen/strength_calculator_form_widget.dart';

class StrengthCalculatorScreen extends StatefulWidget {
  // Callback-Funktion, die aufgerufen wird, wenn die Werte angewendet werden sollen
  final Function(double, int, int) onApplyValues;

  const StrengthCalculatorScreen({
    Key? key,
    required this.onApplyValues,
  }) : super(key: key);

  @override
  State<StrengthCalculatorScreen> createState() =>
      _StrengthCalculatorScreenState();
}

class _StrengthCalculatorScreenState extends State<StrengthCalculatorScreen> {
  @override
  void initState() {
    super.initState();

    // Set system UI overlay style to match the aesthetic
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    // Reset system UI to default when leaving
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Kraftrechner',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: Colors.black,
          ),
        ),
        // Close button on the left side
        leading: IconButton(
          icon: const Icon(Icons.close, size: 22, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 20,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: StrengthCalculatorFormWidget(
              onApplyValues: widget.onApplyValues,
            ),
          ),
        ),
      ),
    );
  }
}
