import 'package:flutter/material.dart';
import 'package:bubbly/modal/pk_battle/livestream.dart';
import 'package:bubbly/modal/pk_battle/battle_type.dart';
import 'package:bubbly/utils/pk_battle_config.dart';

class BattleTimer extends StatefulWidget {
  final Livestream livestream;
  final int remainingSeconds;
  final VoidCallback? onBattleEnd;

  const BattleTimer({
    Key? key,
    required this.livestream,
    required this.remainingSeconds,
    this.onBattleEnd,
  }) : super(key: key);

  @override
  State<BattleTimer> createState() => _BattleTimerState();
}

class _BattleTimerState extends State<BattleTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.red,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(BattleTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.remainingSeconds <= 10 && widget.remainingSeconds > 0) {
      _animationController.repeat(reverse: true);
    } else {
      _animationController.stop();
      _animationController.reset();
    }

    if (widget.remainingSeconds <= 0 && oldWidget.remainingSeconds > 0) {
      widget.onBattleEnd?.call();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.livestream.battleType == BattleType.initiate) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          if (widget.livestream.isBattleWaiting) _buildCountdownView(),
          if (widget.livestream.isBattleRunning) _buildBattleTimer(),
          if (widget.livestream.isBattleEnded) _buildBattleEndView(),
        ],
      ),
    );
  }

  Widget _buildCountdownView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Text(
            'BATTLE STARTING IN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.remainingSeconds <= 10 ? _scaleAnimation.value : 1.0,
                child: Text(
                  widget.remainingSeconds.toString(),
                  style: TextStyle(
                    color: widget.remainingSeconds <= 10 
                        ? _colorAnimation.value 
                        : Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBattleTimer() {
    final isLastTenSeconds = widget.remainingSeconds <= 10;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isLastTenSeconds 
            ? Colors.red.withOpacity(0.8) 
            : Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: isLastTenSeconds 
            ? Border.all(color: Colors.red, width: 2)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: Colors.white,
            size: isLastTenSeconds ? 24 : 20,
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isLastTenSeconds ? _scaleAnimation.value : 1.0,
                child: Text(
                  PKBattleConfig.formatTime(widget.remainingSeconds),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isLastTenSeconds ? 20 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBattleEndView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber, Colors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 8),
          const Text(
            'BATTLE ENDED',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Results in ${PKBattleConfig.battleEndMainViewInSecond}s',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

