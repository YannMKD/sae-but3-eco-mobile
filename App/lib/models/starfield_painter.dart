import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:trackstar/models/star.dart';

class StarFieldPainter extends CustomPainter {
  final Offset? touchPosition;
  final List<Star> stars;
  final String mode;

  StarFieldPainter(this.touchPosition, this.stars, this.mode);

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = mode == "light" ? Colors.black : Colors.white;
    final paint = Paint()..strokeCap = StrokeCap.round;

    for (var star in stars) {
      double targetX = star.originX;
      double targetY = star.originY;

      if (touchPosition != null) {
        double dx = star.x - touchPosition!.dx;
        double dy = star.y - touchPosition!.dy;
        double dist = math.sqrt(dx * dx + dy * dy);
        if (dist < 100) {
          double force = (100 - dist) * 0.5;
          targetX += math.cos(math.atan2(dy, dx)) * force;
          targetY += math.sin(math.atan2(dy, dx)) * force;
        }
      }

      double oldX = star.x;
      star.x += (targetX - star.x) * 0.8;
      star.y += (targetY - star.y) * 0.8;

      double speed = (star.x - oldX).abs();
      paint.color = baseColor.withOpacity(star.opacity);

      if (speed > 15.0) { 
        paint.strokeWidth = star.size * 1.2;
        canvas.drawLine(
          Offset(star.x, star.y),
          Offset(star.x - (star.x - oldX) * 1.5, star.y),
          paint,
        );
      } else {
        canvas.drawCircle(Offset(star.x, star.y), star.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}