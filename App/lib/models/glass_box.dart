import 'dart:ui';
import 'package:flutter/material.dart';

class GlassBox extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final String mode;
  final BorderRadius borderRadius;
  final double padding;

  const GlassBox({
    super.key, 
    required this.child, 
    this.width, 
    this.height,
    required this.mode,
    required this.borderRadius,
    required this.padding
  });

 @override
  Widget build(BuildContext context) {
    final isLight = mode == "light";

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: isLight 
              ? Colors.black.withOpacity(0.12) 
              : Colors.white.withOpacity(0.18),
          width: 1.2,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.4, 1.0], 
          colors: [
            isLight 
                ? Colors.white.withOpacity(0.5)
                : Colors.white.withOpacity(0.12),
            isLight 
                ? Colors.white.withOpacity(0.25) 
                : Colors.white.withOpacity(0.06),
            isLight 
                ? Colors.white.withOpacity(0.35) 
                : Colors.white.withOpacity(0.08),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isLight ? 0.05 : 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: child,
        ),
      ),
    );
  }
}