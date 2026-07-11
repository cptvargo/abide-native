import 'dart:math' as math;
import 'package:flutter/material.dart';

class AtmosphericBackground extends StatefulWidget {
  const AtmosphericBackground({
    super.key,
    required this.baseColor,
    required this.accentColor,
    this.child,
  });

  final Color baseColor;
  final Color accentColor;
  final Widget? child;

  @override
  State<AtmosphericBackground> createState() => _AtmosphericBackgroundState();
}

class _AtmosphericBackgroundState extends State<AtmosphericBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => CustomPaint(
        painter: _AtmoPainter(
          baseColor: widget.baseColor,
          accentColor: widget.accentColor,
          t: _ctrl.value,
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _AtmoPainter extends CustomPainter {
  _AtmoPainter({
    required this.baseColor,
    required this.accentColor,
    required this.t,
  });

  final Color baseColor;
  final Color accentColor;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Base fill
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = baseColor,
    );

    // Slow-breathing radial glow in upper right
    final glowX = size.width * (0.72 + 0.06 * math.sin(t * math.pi));
    final glowY = size.height * (0.18 + 0.04 * math.cos(t * math.pi * 1.3));
    final radius = size.width * (0.55 + 0.08 * math.sin(t * math.pi * 0.7));

    canvas.drawCircle(
      Offset(glowX, glowY),
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accentColor.withOpacity(0.07 + 0.03 * math.sin(t * math.pi)),
            accentColor.withOpacity(0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(glowX, glowY),
          radius: radius,
        )),
    );

    // Second, cooler glow lower left
    final glow2X = size.width * (0.18 + 0.05 * math.cos(t * math.pi * 0.8));
    final glow2Y = size.height * (0.65 + 0.06 * math.sin(t * math.pi * 1.1));
    final radius2 = size.width * (0.40 + 0.06 * math.cos(t * math.pi * 0.9));

    canvas.drawCircle(
      Offset(glow2X, glow2Y),
      radius2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accentColor.withOpacity(0.04),
            accentColor.withOpacity(0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(glow2X, glow2Y),
          radius: radius2,
        )),
    );

    // Grain overlay — dark on light backgrounds, white on dark
    final isLightBg = baseColor.computeLuminance() > 0.5;
    final grainPaint = Paint()
      ..color = (isLightBg ? Colors.black : Colors.white).withOpacity(0.022);
    final rng = math.Random(42);
    for (int i = 0; i < 800; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), grainPaint);
    }
  }

  @override
  bool shouldRepaint(_AtmoPainter old) => old.t != t;
}
