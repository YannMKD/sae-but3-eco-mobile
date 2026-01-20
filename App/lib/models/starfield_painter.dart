import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:trackstar/models/star.dart';

class StarFieldPainter extends CustomPainter {
  final List<Star> stars;
  final String mode;

  StarFieldPainter(this.stars, this.mode);

  @override
  void paint(Canvas canvas, Size size) {
    final isLight = mode == "light";
    final paint = Paint()..strokeCap = StrokeCap.round;

    for (var star in stars) {
      double opacity = star.isNew ? 1.0 : 0.8;
      double currentSize = star.isNew ? star.size * 2.0 : star.size;

      if (isLight) {
        paint.color = star.color == Colors.white 
            ? Colors.black.withOpacity(0.85) 
            : star.color.withOpacity(1.0);
      } else {
        paint.color = star.color.withOpacity(opacity);
        paint.maskFilter = star.isNew ? null : const MaskFilter.blur(BlurStyle.normal, 0.5);
      }

      canvas.drawCircle(Offset(star.x, star.y), currentSize, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

