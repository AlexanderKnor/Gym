// lib/widgets/create_training_plan_screen/optimized_anatomy_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import 'package:flutter/services.dart' show rootBundle;

/// Optimierter Widget für anatomische Darstellung mit SVG
/// Lädt SVGs asynchron und verhindert Aufhängen der App
class OptimizedAnatomyWidget extends StatefulWidget {
  final String svgPath;
  final List<String> primaryMuscleIds;
  final List<String> secondaryMuscleIds;
  final bool showPrimary;
  final double width;
  final double height;
  final bool useBackView;

  const OptimizedAnatomyWidget({
    Key? key,
    required this.svgPath,
    required this.primaryMuscleIds,
    required this.secondaryMuscleIds,
    this.showPrimary = true,
    this.width = 200,
    this.height = 280,
    this.useBackView = false,
  }) : super(key: key);

  @override
  State<OptimizedAnatomyWidget> createState() => _OptimizedAnatomyWidgetState();
}

class _OptimizedAnatomyWidgetState extends State<OptimizedAnatomyWidget>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _fadeInController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeInAnimation;
  
  // Loading state
  bool _isLoading = true;
  bool _hasError = false;
  String? _modifiedSvgString;
  
  // Colors
  static const Color _void = Color(0xFF000000);
  static const Color _stellar = Color(0xFF18181C);
  static const Color _lunar = Color(0xFF242429);
  static const Color _stardust = Color(0xFFA5A5B0);
  static const Color _proverCore = Color(0xFFFF4500);
  static const Color _proverGlow = Color(0xFFFF6B3D);
  static const Color _proverSoft = Color(0xFFFF8C69);

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.4,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeOut,
    ));
    
    // Precache SVG to prevent hanging
    _precacheSvg();
  }
  
  Future<void> _precacheSvg() async {
    try {
      // Load SVG
      final svgString = await rootBundle.loadString(widget.svgPath);
      
      // First, let's check if the SVG displays correctly without any modifications
      // Then apply minimal modifications
      _modifiedSvgString = _modifySvgForMuscles(svgString);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _fadeInController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }
  
  String _modifySvgForMuscles(String svgString) {
    String modified = svgString;
    
    // Get the muscle IDs to highlight
    final idsToHighlight = widget.showPrimary 
        ? widget.primaryMuscleIds 
        : widget.secondaryMuscleIds;
    
    // Color for highlighting
    final highlightColor = widget.showPrimary 
        ? '#FF4500' // Primary: Orange-red
        : '#FFB366'; // Secondary: Lighter orange
    
    // Direct approach: Add fill attribute directly to all elements with class="st0"
    // This ensures they are white regardless of CSS
    modified = modified.replaceAll(
      'class="st0"',
      'class="st0" fill="#ffffff"',
    );
    
    // For highlighted muscles, override the fill color
    for (final id in idsToHighlight) {
      // Replace the fill for this specific ID
      modified = modified.replaceAll(
        'id="$id" class="st0" fill="#ffffff"',
        'id="$id" class="st0" fill="$highlightColor"',
      );
    }
    
    // Also update the CSS style to reinforce white for st0
    if (modified.contains('.st0 {')) {
      modified = modified.replaceAll(
        '.st0 {\n        fill: #fff;\n      }',
        '.st0 {\n        fill: #ffffff !important;\n      }',
      );
    }
    
    // Add animation for highlighted muscles
    if (idsToHighlight.isNotEmpty && modified.contains('</style>')) {
      final animationRules = '''
      /* Muscle Animation */
      @keyframes pulse {
        0% { opacity: 0.85; }
        50% { opacity: 1.0; }
        100% { opacity: 0.85; }
      }
      ${idsToHighlight.map((id) => '#$id { animation: pulse 2s ease-in-out infinite; }').join('\n      ')}''';
      
      modified = modified.replaceFirst(
        '</style>',
        '\n      $animationRules\n    </style>',
      );
    }
    
    return modified;
  }
  
  @override
  void didUpdateWidget(OptimizedAnatomyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showPrimary != widget.showPrimary ||
        oldWidget.svgPath != widget.svgPath) {
      // Reload SVG when muscle group selection changes
      _isLoading = true;
      _precacheSvg();
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _fadeInController.dispose();
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
          // Loading or error state
          if (_isLoading || _hasError)
            _buildPlaceholder()
          else
            // SVG content with fade in
            FadeTransition(
              opacity: _fadeInAnimation,
              child: _buildSvgContent(),
            ),
          
          // Muscle highlights overlay (no longer needed)
          if (!_isLoading && !_hasError)
            _buildMuscleHighlights(),
        ],
      ),
    );
  }
  
  Widget _buildPlaceholder() {
    if (_hasError) {
      return _buildErrorPlaceholder();
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _stellar.withOpacity(0.3),
            _lunar.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated loading indicator
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(seconds: 1),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Icon(
                    Icons.accessibility_new_rounded,
                    size: 80,
                    color: _stardust.withOpacity(0.3 + (0.3 * value)),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Lade Anatomie...',
              style: TextStyle(
                color: _stardust.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _stellar.withOpacity(0.3),
            _lunar.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.accessibility_new_rounded,
              size: 100,
              color: widget.showPrimary 
                ? _proverCore.withOpacity(0.5)
                : _proverSoft.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _lunar.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    widget.useBackView ? 'Rückansicht' : 'Frontansicht',
                    style: TextStyle(
                      color: _stardust,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.showPrimary 
                      ? 'Primäre Muskelgruppen'
                      : 'Sekundäre Muskelgruppen',
                    style: TextStyle(
                      color: widget.showPrimary ? _proverCore : _proverSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSvgContent() {
    if (_modifiedSvgString == null) {
      return _buildPlaceholder();
    }
    
    // Display SVG without theme interference
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: widget.width,
        height: widget.height,
        color: _stellar.withOpacity(0.6), // Dark background for contrast
        child: SvgPicture.string(
          _modifiedSvgString!,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => _buildPlaceholder(),
        ),
      ),
    );
  }
  
  Widget _buildMuscleHighlights() {
    // No longer needed as highlighting is done in SVG
    return const SizedBox.shrink();
  }
}

/// Simplified muscle painter using overlays (no longer used but kept for reference)
class SimplifiedMusclePainter extends CustomPainter {
  final bool showPrimary;
  final double primaryOpacity;
  final bool useBackView;
  final Color primaryColor;
  final Color secondaryColor;
  
  SimplifiedMusclePainter({
    required this.showPrimary,
    required this.primaryOpacity,
    required this.useBackView,
    required this.primaryColor,
    required this.secondaryColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    if (showPrimary) {
      paint.color = primaryColor.withOpacity(primaryOpacity * 0.3);
      _drawPrimaryHighlights(canvas, size, paint);
    } else {
      paint.color = secondaryColor.withOpacity(0.2);
      _drawSecondaryHighlights(canvas, size, paint);
    }
  }
  
  void _drawPrimaryHighlights(Canvas canvas, Size size, Paint paint) {
    // Draw simple gradient circles at approximate muscle positions
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    if (!useBackView) {
      // Front view - chest area
      canvas.drawCircle(
        Offset(centerX, centerY - 40),
        30,
        paint,
      );
    } else {
      // Back view - back area
      canvas.drawCircle(
        Offset(centerX, centerY - 30),
        35,
        paint,
      );
    }
  }
  
  void _drawSecondaryHighlights(Canvas canvas, Size size, Paint paint) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Draw smaller highlights for secondary muscles
    canvas.drawCircle(
      Offset(centerX - 30, centerY),
      20,
      paint,
    );
    canvas.drawCircle(
      Offset(centerX + 30, centerY),
      20,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant SimplifiedMusclePainter oldDelegate) {
    return oldDelegate.primaryOpacity != primaryOpacity ||
           oldDelegate.showPrimary != showPrimary;
  }
}