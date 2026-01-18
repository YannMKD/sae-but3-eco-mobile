class SwipeIconParticle {
  double x, y, vx, vy, opacity, size;
  final bool isLike;
  final double angle;

  SwipeIconParticle({
    required this.x, required this.y, 
    required this.vx, required this.vy,
    required this.size, required this.isLike,
    required this.angle,
    this.opacity = 1.0,
  });
}