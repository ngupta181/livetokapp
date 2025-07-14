import 'package:flutter/material.dart';
import 'package:bubbly/modal/pk_battle/battle_type.dart';
import 'package:bubbly/modal/pk_battle/livestream_user_state.dart';
import 'package:bubbly/utils/pk_battle_config.dart';

class BattleGiftButtons extends StatefulWidget {
  final List<LivestreamUserState> participants;
  final Function(BattleView battleView) onGiftTap;
  final bool isEnabled;

  const BattleGiftButtons({
    Key? key,
    required this.participants,
    required this.onGiftTap,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  State<BattleGiftButtons> createState() => _BattleGiftButtonsState();
}

class _BattleGiftButtonsState extends State<BattleGiftButtons>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isEnabled) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BattleGiftButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEnabled && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isEnabled && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.participants.length < 2) {
      return const SizedBox.shrink();
    }

    final host = widget.participants.firstWhere(
      (p) => p.isHost,
      orElse: () => widget.participants.first,
    );
    final coHost = widget.participants.firstWhere(
      (p) => p.isCoHost,
      orElse: () => widget.participants.last,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _buildGiftButton(
              battleView: BattleView.red,
              user: host,
              color: Color(PKBattleConfig.redTeamColor),
              isLeft: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildGiftButton(
              battleView: BattleView.blue,
              user: coHost,
              color: Color(PKBattleConfig.blueTeamColor),
              isLeft: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftButton({
    required BattleView battleView,
    required LivestreamUserState user,
    required Color color,
    required bool isLeft,
  }) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isEnabled ? _pulseAnimation.value : 1.0,
          child: GestureDetector(
            onTap: widget.isEnabled ? () => widget.onGiftTap(battleView) : null,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isEnabled
                      ? [color, color.withOpacity(0.7)]
                      : [Colors.grey, Colors.grey.withOpacity(0.7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: widget.isEnabled
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isLeft) ...[
                    _buildUserAvatar(user),
                    const SizedBox(width: 8),
                  ],
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.card_giftcard,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'GIFT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (isLeft) ...[
                    const SizedBox(width: 8),
                    _buildUserAvatar(user),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserAvatar(LivestreamUserState user) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        image: user.user?.image != null
            ? DecorationImage(
                image: NetworkImage(user.user!.image!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: user.user?.image == null
          ? Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            )
          : null,
    );
  }
}

class GiftAnimationWidget extends StatefulWidget {
  final String giftImage;
  final String userName;
  final int coinValue;
  final Color teamColor;

  const GiftAnimationWidget({
    Key? key,
    required this.giftImage,
    required this.userName,
    required this.coinValue,
    required this.teamColor,
  }) : super(key: key);

  @override
  State<GiftAnimationWidget> createState() => _GiftAnimationWidgetState();
}

class _GiftAnimationWidgetState extends State<GiftAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    await _slideController.forward();
    await Future.delayed(Duration(seconds: PKBattleConfig.giftDialogDismissTime));
    await _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_slideAnimation, _fadeAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _slideAnimation.value.dx * MediaQuery.of(context).size.width,
            _slideAnimation.value.dy * 100,
          ),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.teamColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: widget.teamColor.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: widget.giftImage.isNotEmpty
                        ? Image.network(
                            widget.giftImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.card_giftcard),
                          )
                        : const Icon(Icons.card_giftcard),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${PKBattleConfig.formatCoins(widget.coinValue)} coins',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

