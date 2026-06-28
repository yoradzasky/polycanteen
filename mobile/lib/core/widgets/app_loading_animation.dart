import 'dart:math';
import 'package:flutter/material.dart';

/// A branded loading/buffering animation widget for the PolyCanteen app.
///
/// Renders a layered animation with concentric rings, orbiting utensils,
/// a center bowl with floating steam wisps, a spinning arc indicator,
/// and animated "Loading..." text — all matching the app's flat-design
/// badge aesthetic.
///
/// Usage:
/// ```dart
/// Center(
///   child: AppLoadingAnimation(
///     size: 160,
///     message: "Memuat menu...",
///   ),
/// )
/// ```
class AppLoadingAnimation extends StatefulWidget {
  /// Overall diameter of the animation circle (default 150).
  final double size;

  /// Optional custom loading message (replaces "Loading").
  final String? message;

  const AppLoadingAnimation({
    super.key,
    this.size = 150.0,
    this.message,
  });

  @override
  State<AppLoadingAnimation> createState() => _AppLoadingAnimationState();
}

class _AppLoadingAnimationState extends State<AppLoadingAnimation>
    with TickerProviderStateMixin {
  // ──────────────────────────────────────────────────────────────────────
  // Brand color palette
  // ──────────────────────────────────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF4A9BC4);
  static const Color _deepBlue = Color(0xFF2B7BA8);
  static const Color _creamYellow = Color(0xFFF5F0D0);
  static const Color _orange = Color(0xFFF5A623);
  static const Color _green = Color(0xFF5CAF50);
  static const Color _white = Color(0xFFFFFFFF);

  // ──────────────────────────────────────────────────────────────────────
  // Animation controllers
  // ──────────────────────────────────────────────────────────────────────

  /// Layer 1 – outer ring pulse (scale 1.0 → 1.05 → 1.0, 1.5 s loop)
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  /// Layer 2 – orbiting utensils (full rotation in 2.5 s)
  late final AnimationController _orbitController;

  /// Layer 3 – steam wisps (1.2 s each, staggered by 200 ms)
  late final AnimationController _steamController;

  /// Layer 4 – spinning loading arc (one full rotation in 1.0 s)
  late final AnimationController _arcController;

  /// Layer 5 – cycling dots timer index (0, 1, 2)
  late final AnimationController _dotsController;
  int _dotCount = 1;

  @override
  void initState() {
    super.initState();

    // ── Layer 1: Pulse ──────────────────────────────────────────────────
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // ── Layer 2: Orbit ──────────────────────────────────────────────────
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // ── Layer 3: Steam ──────────────────────────────────────────────────
    _steamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // ── Layer 4: Arc ────────────────────────────────────────────────────
    _arcController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    // ── Layer 5: Dots ───────────────────────────────────────────────────
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // 3 × 500 ms
    )..repeat();

    _dotsController.addListener(() {
      final newCount = (_dotsController.value * 3).floor() % 3 + 1;
      if (newCount != _dotCount) {
        setState(() => _dotCount = newCount);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _orbitController.dispose();
    _steamController.dispose();
    _arcController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────
  // Build
  // ────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    // Scale factor relative to the reference size of 150
    final double scale = size / 150.0;

    // Derived radii (reference values, scaled later)
    final double orbitRadius = 55.0 * scale;
    final double arcRadius = 72.0 * scale;
    final double bowlSize = 38.0 * scale;
    final double utensilSize = 20.0 * scale;

    final String label = widget.message ?? 'Loading';
    final String dots = '.' * _dotCount;

    return SizedBox(
      width: size,
      // Extra height for the text label below the circle
      height: size + 28.0 * scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Animation circle ──────────────────────────────────────────
          SizedBox(
            width: size,
            height: size,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _pulseAnimation,
                _orbitController,
                _steamController,
                _arcController,
              ]),
              builder: (context, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Layer 1 – Concentric rings (pulsing)
                    _buildConcentricRings(size, scale),

                    // Layer 4 – Spinning loading arc (painted behind utensils)
                    _buildLoadingArc(arcRadius),

                    // Layer 2 – Orbiting utensils
                    _buildOrbitingUtensil(
                      angle: _orbitController.value * 2 * pi,
                      radius: orbitRadius,
                      icon: Icons.restaurant,
                      iconSize: utensilSize,
                    ),
                    _buildOrbitingUtensil(
                      angle: -_orbitController.value * 2 * pi + pi, // counter-clockwise, offset 180°
                      radius: orbitRadius,
                      icon: Icons.restaurant_menu,
                      iconSize: utensilSize,
                      clockwise: false,
                    ),

                    // Layer 3 – Center bowl with steam
                    _buildBowlAndSteam(bowlSize, scale),
                  ],
                );
              },
            ),
          ),

          SizedBox(height: 6.0 * scale),

          // ── Layer 5: Loading text ─────────────────────────────────────
          Text(
            '$label$dots',
            style: TextStyle(
              fontSize: 13.0 * scale,
              color: _deepBlue,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // Layer 1 – Concentric rings with pulse
  // ────────────────────────────────────────────────────────────────────────

  Widget _buildConcentricRings(double size, double scale) {
    return Transform.scale(
      scale: _pulseAnimation.value,
      child: CustomPaint(
        size: Size(size, size),
        painter: _RingAndArcPainter(
          outerRingColor: _deepBlue,
          middleRingColor: _creamYellow,
          innerCircleColor: _primaryBlue,
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // Layer 2 – Orbiting utensil
  // ────────────────────────────────────────────────────────────────────────

  Widget _buildOrbitingUtensil({
    required double angle,
    required double radius,
    required IconData icon,
    required double iconSize,
    bool clockwise = true,
  }) {
    // Position along the orbit circle
    final double dx = cos(angle) * radius;
    final double dy = sin(angle) * radius;

    // Self-rotation: same speed but direction matches orbit
    final double selfAngle =
        clockwise ? _orbitController.value * 2 * pi : -_orbitController.value * 2 * pi;

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: selfAngle,
        child: Icon(
          icon,
          size: iconSize,
          color: _white,
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // Layer 3 – Bowl + steam wisps
  // ────────────────────────────────────────────────────────────────────────

  Widget _buildBowlAndSteam(double bowlSize, double scale) {
    return SizedBox(
      width: bowlSize * 2,
      height: bowlSize * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Steam wisps (behind the bowl, floating upward)
          for (int i = 0; i < 3; i++) _buildSteamWisp(i, scale),

          // Static bowl icon
          Icon(
            Icons.soup_kitchen,
            size: bowlSize,
            color: _white,
          ),
        ],
      ),
    );
  }

  /// A single steam wisp, staggered by [index] × 200 ms within the
  /// 1.2 s steam cycle. Fades in and translates upward by 12 px.
  Widget _buildSteamWisp(int index, double scale) {
    // Stagger offset: 0 ms, 200 ms, 400 ms → fractions of the 1200 ms cycle
    final double staggerFraction = (index * 200) / 1200;
    // Compute progress for this wisp (wrapping around)
    double t = (_steamController.value - staggerFraction) % 1.0;
    if (t < 0) t += 1.0;

    // Opacity: fade in during first half, fade out during second half
    final double opacity = t < 0.5 ? (t / 0.5) : (1.0 - (t - 0.5) / 0.5);
    // Vertical translation: rise 12 px over the cycle
    final double translateY = -12.0 * scale * t;

    // Horizontal spread for the 3 wisps
    final double horizontalOffset = (index - 1) * 6.0 * scale;

    return Transform.translate(
      offset: Offset(horizontalOffset, translateY - 14.0 * scale),
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Text(
          '~',
          style: TextStyle(
            fontSize: 10.0 * scale,
            color: _green,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // Layer 4 – Loading arc
  // ────────────────────────────────────────────────────────────────────────

  Widget _buildLoadingArc(double arcRadius) {
    return CustomPaint(
      size: Size(arcRadius * 2 + 8, arcRadius * 2 + 8),
      painter: _ArcPainter(
        progress: _arcController.value,
        arcRadius: arcRadius,
        arcColor: _orange,
        strokeWidth: 3.5 * (widget.size / 150.0),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// CustomPainter: concentric rings
// ══════════════════════════════════════════════════════════════════════════

/// Draws the 3 concentric circles that form the badge background:
///   1. Deep blue outer ring
///   2. Cream/yellow middle ring
///   3. Primary blue inner filled circle
class _RingAndArcPainter extends CustomPainter {
  final Color outerRingColor;
  final Color middleRingColor;
  final Color innerCircleColor;

  _RingAndArcPainter({
    required this.outerRingColor,
    required this.middleRingColor,
    required this.innerCircleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = size.width / 2;

    // Layer 1a – Deep blue outer circle (full)
    canvas.drawCircle(
      center,
      maxRadius,
      Paint()..color = outerRingColor,
    );

    // Layer 1b – Cream/yellow middle ring
    canvas.drawCircle(
      center,
      maxRadius * 0.85,
      Paint()..color = middleRingColor,
    );

    // Layer 1c – Primary blue inner circle
    canvas.drawCircle(
      center,
      maxRadius * 0.75,
      Paint()..color = innerCircleColor,
    );
  }

  @override
  bool shouldRepaint(covariant _RingAndArcPainter oldDelegate) => false;
}

// ══════════════════════════════════════════════════════════════════════════
// CustomPainter: spinning loading arc
// ══════════════════════════════════════════════════════════════════════════

/// Draws a 270° arc that rotates clockwise, with a rounded stroke cap.
class _ArcPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0 (fraction of full rotation)
  final double arcRadius;
  final Color arcColor;
  final double strokeWidth;

  _ArcPainter({
    required this.progress,
    required this.arcRadius,
    required this.arcColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Paint arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round; // rounded cap on the arc tip

    // Start angle rotates with progress; sweep is fixed at 270° (3π/2)
    final double startAngle = progress * 2 * pi - pi / 2;
    const double sweepAngle = 3 * pi / 2; // 270°

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: arcRadius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
