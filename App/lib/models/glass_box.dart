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
    if (mode == "light") {
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
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
              
              Container(
                padding: EdgeInsets.all(padding), 
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.14),
                    width: 1,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color.fromARGB(255, 208, 208, 208).withValues(alpha: 0.3),
                      const Color.fromARGB(255, 208, 208, 208).withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: child, 
              ),
            ],
          ),
        ),
      );
    } else {
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
                    color: const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.1),
                  ),
                ),
              ),
              
              Container(
                padding: EdgeInsets.all(padding), 
                width: width, 
                height: height,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: const Color.fromARGB(255, 138, 138, 138).withValues(alpha: 0.8),
                    width: 1,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color.fromARGB(255, 208, 208, 208).withValues(alpha: 0.08),
                      const Color.fromARGB(255, 208, 208, 208).withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: child, 
              ),
            ],
          ),
        ),
      );
    }
  }
}