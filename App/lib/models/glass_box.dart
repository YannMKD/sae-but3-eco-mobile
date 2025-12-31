import 'dart:ui';
import 'package:flutter/material.dart';

class GlassBox extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const GlassBox({
    super.key, 
    required this.child, 
    required this.width, 
    required this.height,
    required this.borderRadius
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: width,
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  color: Colors.white.withOpacity(0.2), 
                ),
              ),
            ),
            
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.black.withOpacity(0.14), 
                  width: 1,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color.fromARGB(255, 208, 208, 208).withOpacity(0.3),
                    const Color.fromARGB(255, 208, 208, 208).withOpacity(0.05),
                  ],
                ),
              ),
            ),
            
            Center(child: child),
          ],
        ),
      ),
    );
  }
}