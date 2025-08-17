// lib/widgets/create_training_plan_screen/anatomy_svg_widget.dart

import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart'; // Temporär deaktiviert

/// Widget für die anatomische SVG-Darstellung mit Muskelgruppen-Highlighting
/// HINWEIS: Temporär als Placeholder implementiert bis SVG-Support aktiviert ist
class AnatomySvgWidget extends StatefulWidget {
  final String svgPath;
  final List<String> primaryMuscleIds;
  final List<String> secondaryMuscleIds;
  final bool showPrimary;
  final double width;
  final double height;

  const AnatomySvgWidget({
    Key? key,
    required this.svgPath,
    required this.primaryMuscleIds,
    required this.secondaryMuscleIds,
    this.showPrimary = true,
    this.width = 200,
    this.height = 280,
  }) : super(key: key);

  @override
  State<AnatomySvgWidget> createState() => _AnatomySvgWidgetState();
}

class _AnatomySvgWidgetState extends State<AnatomySvgWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  // Colors
  static const Color _emberCore = Color(0xFFFF4500);
  static const Color _emberBright = Color(0xFFFF6B35);
  static const Color _emberSoft = Color(0xFFFF8C69);
  static const Color _steel = Color(0xFF48484A);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Placeholder implementation until SVG support is enabled
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: _steel.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomPaint(
              size: Size(widget.width, widget.height),
              painter: MuscleHighlightPainter(
                primaryIds: widget.showPrimary ? widget.primaryMuscleIds : [],
                secondaryIds: widget.secondaryMuscleIds,
                primaryOpacity: _pulseAnimation.value,
                svgPath: widget.svgPath,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for muscle highlighting
class MuscleHighlightPainter extends CustomPainter {
  final List<String> primaryIds;
  final List<String> secondaryIds;
  final double primaryOpacity;
  final String svgPath;
  
  // Colors
  static const Color _emberCore = Color(0xFFFF4500);
  static const Color _emberSoft = Color(0xFFFF8C69);
  
  MuscleHighlightPainter({
    required this.primaryIds,
    required this.secondaryIds,
    required this.primaryOpacity,
    required this.svgPath,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Create gradient effect for primary muscles
    if (primaryIds.isNotEmpty) {
      final primaryPaint = Paint()
        ..color = _emberCore.withOpacity(primaryOpacity * 0.7)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      // Draw primary muscle highlight areas
      // Note: In a real implementation, you'd parse the SVG paths
      // and draw them based on the IDs. For now, we'll simulate with circles
      _drawMuscleHighlights(canvas, size, primaryIds, primaryPaint);
    }
    
    // Create gradient effect for secondary muscles
    if (secondaryIds.isNotEmpty) {
      final secondaryPaint = Paint()
        ..color = _emberSoft.withOpacity(0.4)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      
      _drawMuscleHighlights(canvas, size, secondaryIds, secondaryPaint);
    }
  }
  
  void _drawMuscleHighlights(Canvas canvas, Size size, List<String> ids, Paint paint) {
    // Simulated muscle positions based on common anatomy
    // In production, these would be extracted from the actual SVG paths
    final musclePositions = _getMusclePositions(size, svgPath);
    
    for (final id in ids) {
      if (musclePositions.containsKey(id)) {
        final position = musclePositions[id]!;
        
        // Draw gradient circle for muscle highlight
        final gradient = RadialGradient(
          colors: [
            paint.color,
            paint.color.withOpacity(0),
          ],
        );
        
        final rect = Rect.fromCircle(
          center: position,
          radius: 25,
        );
        
        final gradientPaint = Paint()
          ..shader = gradient.createShader(rect)
          ..maskFilter = paint.maskFilter;
        
        canvas.drawCircle(position, 25, gradientPaint);
      }
    }
  }
  
  Map<String, Offset> _getMusclePositions(Size size, String svgPath) {
    // Approximate positions for muscle groups
    // These would be calculated from actual SVG path data in production
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    return {
      // Chest positions
      '_x37_1': Offset(centerX - 20, centerY - 60),
      '_x37_0': Offset(centerX + 20, centerY - 60),
      
      // Biceps positions  
      '_x36_3': Offset(centerX - 45, centerY - 30),
      '_x36_2': Offset(centerX + 45, centerY - 30),
      
      // Quads positions
      '_x36_1': Offset(centerX - 20, centerY + 40),
      '_x36_4': Offset(centerX + 20, centerY + 40),
      
      // Back positions
      '_x35_2': Offset(centerX - 15, centerY - 50),
      '_x35_0': Offset(centerX + 15, centerY - 50),
      
      // Glutes positions
      '_x35_1': Offset(centerX - 15, centerY + 10),
      '_x35_3': Offset(centerX + 15, centerY + 10),
      
      // Add more positions as needed...
    };
  }
  
  @override
  bool shouldRepaint(covariant MuscleHighlightPainter oldDelegate) {
    return oldDelegate.primaryOpacity != primaryOpacity ||
           oldDelegate.primaryIds != primaryIds ||
           oldDelegate.secondaryIds != secondaryIds;
  }
}