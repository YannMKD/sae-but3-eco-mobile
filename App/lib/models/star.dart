import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class Star {
  double x, y;   
  double originX, originY; 
  double homeX; 
  double homeY;
  double size, opacity;
  double angle;   
  double velocityX = 0.0;
  Color color;
  bool isNew;
  DateTime? birthTime;

  Star(this.originX, this.originY, this.size, this.opacity, this.homeX, this.homeY, {this.color = Colors.white, this.isNew = false})
      : x = originX,
        y = originY,
        angle = math.Random().nextDouble() * math.pi * 2;
}