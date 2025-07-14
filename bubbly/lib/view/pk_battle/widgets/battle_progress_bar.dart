import 'package:flutter/material.dart';
import 'package:bubbly/utils/pk_battle_config.dart';
import 'package:bubbly/utils/colors.dart';

class BattleProgressBar extends StatefulWidget {
  final int redCoins;
  final int blueCoins;
  final double? width;
  final double? height;
  final EdgeInsets? margin;

  const BattleProgressBar({
    Key? key,
    required this.redCoins,
    required this.blueCoins,
    this.width,
    this.height,
    this.margin,
  }) : super(key: key);

  @override
  State<BattleProgressBar> createState() => _BattleProgressBarState();
}

class _BattleProgressBarState extends State<BattleProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: PKBattleConfig.progressBarAnimationDuration),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.5, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(BattleProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.redCoins != widget.redCoins || oldWidget.blueCoins != widget.blueCoins) {
      _updateProgress();
    }
  }

  void _updateProgress() {
    double total = (widget.redCoins + widget.blueCoins).toDouble();
    double newProgress = total > 0 ? widget.redCoins / total : 0.5;
    
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: newProgress,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    
    _animationController.forward(from: 0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final progressBarWidth = widget.width ?? screenWidth * PKBattleConfig.battleProgressBarWidth;
    final progressBarHeight = widget.height ?? PKBattleConfig.battleProgressBarHeight;

    return Container(
      margin: widget.margin ?? const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          // Coin counts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCoinDisplay(
                widget.redCoins,
                Color(PKBattleConfig.redTeamColor),
                true,
              ),
              _buildCoinDisplay(
                widget.blueCoins,
                Color(PKBattleConfig.blueTeamColor),
                false,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          SizedBox(
            width: progressBarWidth,
            height: progressBarHeight,
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Background
                    Container(
                      width: progressBarWidth,
                      height: progressBarHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(progressBarHeight / 2),
                        color: Colors.grey.shade300,
                      ),
                    ),
                    // Red progress
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: progressBarWidth * _progressAnimation.value,
                        height: progressBarHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(progressBarHeight / 2),
                          color: Color(PKBattleConfig.progressBarRedColor),
                        ),
                      ),
                    ),
                    // Blue progress
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: progressBarWidth * (1 - _progressAnimation.value),
                        height: progressBarHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(progressBarHeight / 2),
                          color: Color(PKBattleConfig.progressBarBlueColor),
                        ),
                      ),
                    ),
                    // Crown indicator
                    Positioned(
                      left: (progressBarWidth * _progressAnimation.value) - 15,
                      top: -8,
                      child: _buildCrownIcon(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinDisplay(int coins, Color color, bool isLeft) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLeft) ...[
            Text(
              PKBattleConfig.formatCoins(coins),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Icon(
            Icons.monetization_on,
            color: color,
            size: 16,
          ),
          if (isLeft) ...[
            const SizedBox(width: 4),
            Text(
              PKBattleConfig.formatCoins(coins),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCrownIcon() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.emoji_events,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

