import 'dart:math' as math;

class Star {
  double x, y;   
  double originX, originY; 
  double homeX; 
  double homeY;
  double size, opacity;
  double angle;   
  double velocityX = 0.0;

  Star(this.originX, this.originY, this.size, this.opacity, this.homeX, this.homeY)
      : x = originX,
        y = originY,
        angle = math.Random().nextDouble() * math.pi * 2;
}