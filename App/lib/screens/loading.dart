import 'dart:math' as math;
import 'package:flutter/material.dart';

class Loading extends StatefulWidget {
  final double size;
  final Color color;

  const Loading({super.key, this.size = 50, required this.color});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double wRatio = MediaQuery.of(context).size.width / 392.7;
    
    final double responsiveSize = widget.size * wRatio;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(responsiveSize, responsiveSize),
          painter: _OrbitPainter(
            progress: _controller.value,
            color: widget.color,
            wRatio: wRatio, 
          ),
        );
      },
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double wRatio; 

  _OrbitPainter({required this.progress, required this.color, required this.wRatio});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final orbitPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * wRatio; 
    canvas.drawCircle(center, radius, orbitPaint);

    final signalPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3 * wRatio
      ..shader = SweepGradient(
        colors: [Colors.transparent, color],
        stops: const [0.7, 1.0],
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * math.pi,
      false,
      signalPaint,
    );

    final headPaint = Paint()..color = color;
    final headAngle = progress * 2 * math.pi;
    final headOffset = Offset(
      center.dx + radius * math.cos(headAngle),
      center.dy + radius * math.sin(headAngle),
    );
    canvas.drawCircle(headOffset, 4 * wRatio, headPaint);
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) => true;
}