import 'dart:math';
import 'package:flutter/material.dart';

/// A simplified branded loading/buffering animation widget for the PolyCanteen app.
///
/// Features a smaller default size, pulsing concentric rings, a spinning arc,
/// and a center icon to maintain the culinary/academic aesthetic without
/// being overly large or complex.
class AppLoadingAnimation extends StatefulWidget {
  /// Overall diameter of the animation circle (default 65).
  final double size;

  /// Optional custom loading message. If null, no text is shown.
  final String? message;

  const AppLoadingAnimation({
    super.key,
    this.size = 65.0,
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
  static const Color _white = Color(0xFFFFFFFF);

  // ──────────────────────────────────────────────────────────────────────
  // Animation controllers
  // ──────────────────────────────────────────────────────────────────────

  /// Layer 1 – outer ring pulse (scale 1.0 → 1.05 → 1.0, 1.5 s loop)
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  /// Layer 2 – spinning loading arc (one full rotation in 1.0 s)
  late final AnimationController _arcController;

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

    // ── Layer 2: Arc ────────────────────────────────────────────────────
    _arcController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _arcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    // Scale factor relative to a base reference size of 80
    final double scale = size / 80.0;

    final double arcRadius = 38.0 * scale;
    final double bowlSize = 34.0 * scale;

    return SizedBox(
      width: size,
      // Expand height only if a message is provided
      height: widget.message != null ? size + 24.0 * scale : size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Animation circle ──────────────────────────────────────────
          SizedBox(
            width: size,
            height: size,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _pulseAnimation,
                _arcController,
              ]),
              builder: (context, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Layer 1 – Concentric rings (pulsing)
                    Transform.scale(
                      scale: _pulseAnimation.value,
                      child: CustomPaint(
                        size: Size(size, size),
                        painter: _RingPainter(
                          outerRingColor: _deepBlue,
                          middleRingColor: _creamYellow,
                          innerCircleColor: _primaryBlue,
                        ),
                      ),
                    ),

                    // Layer 2 – Spinning loading arc
                    CustomPaint(
                      size: Size(arcRadius * 2 + 8, arcRadius * 2 + 8),
                      painter: _ArcPainter(
                        progress: _arcController.value,
                        arcRadius: arcRadius,
                        arcColor: _orange,
                        strokeWidth: 4.0 * scale,
                      ),
                    ),

                    // Layer 3 – Static center bowl icon
                    Icon(
                      Icons.soup_kitchen,
                      size: bowlSize,
                      color: _white,
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Optional Loading Text ─────────────────────────────────────
          if (widget.message != null) ...[
            SizedBox(height: 8.0 * scale),
            Text(
              widget.message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.0 * scale,
                color: _deepBlue,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// CustomPainter: concentric rings
// ══════════════════════════════════════════════════════════════════════════

class _RingPainter extends CustomPainter {
  final Color outerRingColor;
  final Color middleRingColor;
  final Color innerCircleColor;

  _RingPainter({
    required this.outerRingColor,
    required this.middleRingColor,
    required this.innerCircleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = size.width / 2;

    canvas.drawCircle(center, maxRadius, Paint()..color = outerRingColor);
    canvas.drawCircle(center, maxRadius * 0.82, Paint()..color = middleRingColor);
    canvas.drawCircle(center, maxRadius * 0.68, Paint()..color = innerCircleColor);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => false;
}

// ══════════════════════════════════════════════════════════════════════════
// CustomPainter: spinning loading arc
// ══════════════════════════════════════════════════════════════════════════

class _ArcPainter extends CustomPainter {
  final double progress;
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
      ..strokeCap = StrokeCap.round;

    final double startAngle = progress * 2 * pi - pi / 2;
    const double sweepAngle = 1.5 * pi; // 270°

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
