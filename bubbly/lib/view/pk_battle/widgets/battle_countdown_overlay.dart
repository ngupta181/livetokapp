import 'package:flutter/material.dart';
import 'package:bubbly/modal/pk_battle/livestream.dart';
import 'package:bubbly/modal/pk_battle/battle_type.dart';
import 'package:bubbly/utils/pk_battle_config.dart';

class BattleCountdownOverlay extends StatefulWidget {
  final Livestream livestream;
  final VoidCallback? onCountdownComplete;

  const BattleCountdownOverlay({
    Key? key,
    required this.livestream,
    this.onCountdownComplete,
  }) : super(key: key);

  @override
  State<BattleCountdownOverlay> createState() => _BattleCountdownOverlayState();
}

class _BattleCountdownOverlayState extends State<BattleCountdownOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  int _countdownValue = PKBattleConfig.battleStartInSecond;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _startCountdown();
  }

  void _startCountdown() {
    _fadeController.forward();
    _rotationController.repeat();
    
    if (widget.livestream.battleCreatedAt != null) {
      final battleStartTime = DateTime.fromMillisecondsSinceEpoch(
        widget.livestream.battleCreatedAt!,
      );
      final battleEndTime = battleStartTime.add(
        Duration(seconds: PKBattleConfig.battleStartInSecond),
      );

      // Update countdown every second
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 1));
        
        if (!mounted) return false;
        
        final now = DateTime.now();
        final remaining = battleEndTime.difference(now).inSeconds;
        
        setState(() {
          _countdownValue = remaining.clamp(0, PKBattleConfig.battleStartInSecond);
        });

        if (_countdownValue > 0) {
          _scaleController.forward().then((_) {
            _scaleController.reverse();
          });
        }

        if (_countdownValue <= 0) {
          widget.onCountdownComplete?.call();
          return false;
        }
        
        return true;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.livestream.battleType != BattleType.waiting) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.8),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildVSIcon(),
                  const SizedBox(height: 40),
                  _buildBattleStartingText(),
                  const SizedBox(height: 30),
                  _buildCountdownNumber(),
                  const SizedBox(height: 40),
                  _buildLoadingIndicator(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVSIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(PKBattleConfig.redTeamColor),
            Color(PKBattleConfig.blueTeamColor),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'VS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildBattleStartingText() {
    return Column(
      children: [
        const Text(
          'BATTLE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'STARTING IN',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownNumber() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getCountdownColor(),
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getCountdownColor().withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _countdownValue.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2 * 3.14159,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: CustomPaint(
              painter: LoadingPainter(),
            ),
          ),
        );
      },
    );
  }

  Color _getCountdownColor() {
    if (_countdownValue <= 3) {
      return Colors.red;
    } else if (_countdownValue <= 5) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}

class LoadingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      3.14159, // Half circle
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

