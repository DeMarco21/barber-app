import 'dart:math' as math;
import 'package:flutter/material.dart';

class ParticlesPainter extends CustomPainter {
  final double animationValue;

  ParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Draw some simple animated dots
    final random = math.Random(42); // Fixed seed for consistent positions

    for (int i = 0; i < 15; i++) {
      final x = size.width * random.nextDouble();
      final y = size.height * random.nextDouble();
      final radius = (1 + random.nextDouble() * 2) * (0.5 + 0.5 * animationValue);
      final opacity = ((0.2 + 0.3 * math.sin(animationValue * 2 * math.pi + i)) * animationValue).clamp(0.0, 1.0);

      paint.color = const Color(0xFFD4AF37).withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
