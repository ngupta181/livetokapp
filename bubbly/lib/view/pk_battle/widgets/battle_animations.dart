import 'package:flutter/material.dart';
import 'package:bubbly/utils/pk_battle_config.dart';

class BattleAnimations {
  // Particle animation for battle start
  static Widget createBattleStartParticles(BuildContext context) {
    return BattleParticleAnimation(
      particleCount: 50,
      colors: [
        Color(PKBattleConfig.redTeamColor),
        Color(PKBattleConfig.blueTeamColor),
        Colors.amber,
        Colors.white,
      ],
      duration: const Duration(seconds: 3),
    );
  }

  // Confetti animation for winner
  static Widget createWinnerConfetti(BuildContext context, Color teamColor) {
    return ConfettiAnimation(
      particleCount: 100,
      primaryColor: teamColor,
      duration: const Duration(seconds: 5),
    );
  }

  // Pulse animation for countdown
  static Widget createCountdownPulse(Widget child) {
    return PulseAnimation(
      child: child,
      duration: const Duration(milliseconds: 1000),
    );
  }

  // Shake animation for low time warning
  static Widget createShakeAnimation(Widget child) {
    return ShakeAnimation(
      child: child,
      duration: const Duration(milliseconds: 500),
    );
  }
}

class BattleParticleAnimation extends StatefulWidget {
  final int particleCount;
  final List<Color> colors;
  final Duration duration;

  const BattleParticleAnimation({
    Key? key,
    required this.particleCount,
    required this.colors,
    required this.duration,
  }) : super(key: key);

  @override
  State<BattleParticleAnimation> createState() => _BattleParticleAnimationState();
}

class _BattleParticleAnimationState extends State<BattleParticleAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _particles = List.generate(widget.particleCount, (index) {
      return Particle(
        color: widget.colors[index % widget.colors.length],
        size: 2.0 + (index % 4),
        startX: (index % 10) * 0.1,
        startY: 0.5 + ((index % 5) * 0.1 - 0.2),
        velocityX: (index % 3 - 1) * 0.5,
        velocityY: -0.5 - (index % 3) * 0.3,
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(_particles, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class ConfettiAnimation extends StatefulWidget {
  final int particleCount;
  final Color primaryColor;
  final Duration duration;

  const ConfettiAnimation({
    Key? key,
    required this.particleCount,
    required this.primaryColor,
    required this.duration,
  }) : super(key: key);

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<ConfettiParticle> _confetti;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _confetti = List.generate(widget.particleCount, (index) {
      return ConfettiParticle(
        color: index % 2 == 0 ? widget.primaryColor : Colors.amber,
        size: 3.0 + (index % 3),
        startX: (index % 20) * 0.05,
        startY: -0.1,
        velocityX: (index % 5 - 2) * 0.3,
        velocityY: 0.5 + (index % 3) * 0.2,
        rotation: (index % 360) * 3.14159 / 180,
        rotationSpeed: (index % 5 - 2) * 0.1,
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ConfettiPainter(_confetti, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const PulseAnimation({
    Key? key,
    required this.child,
    required this.duration,
  }) : super(key: key);

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShakeAnimation({
    Key? key,
    required this.child,
    required this.duration,
  }) : super(key: key);

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticIn),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: widget.child,
        );
      },
    );
  }
}

// Particle classes
class Particle {
  final Color color;
  final double size;
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;

  Particle({
    required this.color,
    required this.size,
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
  });
}

class ConfettiParticle {
  final Color color;
  final double size;
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double rotation;
  final double rotationSpeed;

  ConfettiParticle({
    required this.color,
    required this.size,
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
  });
}

// Custom painters
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(1.0 - progress)
        ..style = PaintingStyle.fill;

      final x = (particle.startX + particle.velocityX * progress) * size.width;
      final y = (particle.startY + particle.velocityY * progress) * size.height;

      canvas.drawCircle(
        Offset(x, y),
        particle.size * (1.0 - progress * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> confetti;
  final double progress;

  ConfettiPainter(this.confetti, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in confetti) {
      final paint = Paint()
        ..color = particle.color.withOpacity(1.0 - progress)
        ..style = PaintingStyle.fill;

      final x = (particle.startX + particle.velocityX * progress) * size.width;
      final y = (particle.startY + particle.velocityY * progress) * size.height;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + particle.rotationSpeed * progress * 10);

      // Draw rectangle confetti
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 2,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

