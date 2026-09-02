import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';

class Particle {
  double x, y;
  double vx, vy;
  Color color;
  double size;
  double life;
  double maxLife;
  double rotation;
  double rotationSpeed;
  BucketType type;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.maxLife,
    required this.rotation,
    required this.rotationSpeed,
    required this.type,
  }) : life = maxLife;

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    
    // Apply gravity/physics based on type
    if (type == BucketType.enjoy) {
      vy += 400 * dt; // Gravity for confetti
      vx *= 0.95; // drag
    } else if (type == BucketType.dailyExpenses) {
      vy -= 100 * dt; // Bubbles float up faster
      x += math.sin(life * 10) * 1.5; // Wobble
    } else if (type == BucketType.smile) {
      vy -= 300 * dt; // Stars shoot up
      x += math.sin(life * 5) * 2;
    } else if (type == BucketType.heal) {
      vy -= 500 * dt; // Sparks shoot up fast
      vy *= 0.9; // Drag
      vx *= 0.9;
    }

    rotation += rotationSpeed * dt;
    life -= dt;
  }
}

class BucketParticleEmitter extends StatefulWidget {
  const BucketParticleEmitter({super.key});

  @override
  BucketParticleEmitterState createState() => BucketParticleEmitterState();
}

class BucketParticleEmitterState extends State<BucketParticleEmitter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final _random = math.Random();
  DateTime _lastTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateParticles);
  }

  void _updateParticles() {
    if (_particles.isEmpty) {
      if (_controller.isAnimating) _controller.stop();
      return;
    }

    final now = DateTime.now();
    final dt = now.difference(_lastTime).inMilliseconds / 1000.0;
    _lastTime = now;

    // Prevent huge jumps if thread is paused
    if (dt > 0.1) return; 

    setState(() {
      for (var p in _particles) {
        p.update(dt);
      }
      _particles.removeWhere((p) => p.life <= 0);
    });
  }

  void emit(Offset position, BucketType type) {
    _lastTime = DateTime.now();
    final newParticles = <Particle>[];

    int count = 0;
    if (type == BucketType.dailyExpenses) count = 25; // Bubbles
    if (type == BucketType.enjoy) count = 60; // Confetti
    if (type == BucketType.smile) count = 30; // Stars
    if (type == BucketType.heal) count = 50; // Sparks

    final colors = {
      BucketType.dailyExpenses: [Colors.blue.shade300, Colors.blue.shade200, Colors.cyan.shade200, Colors.white],
      BucketType.enjoy: [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange],
      BucketType.smile: [Colors.yellow.shade400, Colors.yellow.shade300, Colors.green.shade300, Colors.green.shade400],
      BucketType.heal: [Colors.pinkAccent, Colors.pink, Colors.orangeAccent, Colors.yellowAccent, Colors.white],
    };

    final palette = colors[type]!;

    for (int i = 0; i < count; i++) {
      double vx = 0;
      double vy = 0;
      
      if (type == BucketType.enjoy) {
        vx = (_random.nextDouble() - 0.5) * 600;
        vy = -_random.nextDouble() * 600 - 200;
      } else if (type == BucketType.dailyExpenses) {
        vx = (_random.nextDouble() - 0.5) * 200;
        vy = -_random.nextDouble() * 300 - 100;
      } else if (type == BucketType.smile) {
        vx = (_random.nextDouble() - 0.5) * 400;
        vy = -_random.nextDouble() * 500 - 200;
      } else if (type == BucketType.heal) {
        vx = (_random.nextDouble() - 0.5) * 300;
        vy = -_random.nextDouble() * 900 - 300;
      }

      newParticles.add(Particle(
        x: position.dx,
        y: position.dy,
        vx: vx,
        vy: vy,
        color: palette[_random.nextInt(palette.length)],
        size: _random.nextDouble() * 10 + 6,
        maxLife: _random.nextDouble() * 1.5 + 0.8,
        rotation: _random.nextDouble() * math.pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 15,
        type: type,
      ));
    }

    setState(() {
      _particles.addAll(newParticles);
    });

    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _ParticlePainter(_particles),
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      double alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
        
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      
      if (p.type == BucketType.dailyExpenses) {
        // Bubbles: Hollow circles
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = p.size * 0.3;
        canvas.drawCircle(Offset.zero, p.size, paint);
        
        // Inner highlight for bubble
        final highlightPaint = Paint()
          ..color = Colors.white.withValues(alpha: alpha * 0.5)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(-p.size * 0.3, -p.size * 0.3), p.size * 0.2, highlightPaint);
      } else if (p.type == BucketType.enjoy) {
        // Confetti: Rectangles
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.8), paint);
      } else if (p.type == BucketType.smile) {
        // Stars
        _drawStar(canvas, Offset.zero, 5, p.size, p.size * 0.4, paint);
      } else if (p.type == BucketType.heal) {
        // Sparks: Lines
        paint.style = PaintingStyle.stroke;
        paint.strokeCap = StrokeCap.round;
        paint.strokeWidth = p.size * 0.4;
        canvas.drawLine(Offset.zero, Offset(0, p.size * 2), paint);
      }
      
      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, Offset center, int points, double outerRadius, double innerRadius, Paint paint) {
    final path = Path();
    final step = math.pi / points;
    double angle = -math.pi / 2;
    
    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final point = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
      angle += step;
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
