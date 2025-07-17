import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bubbly/modal/pk_battle/livestream.dart';
import 'package:bubbly/modal/pk_battle/livestream_user_state.dart';
import 'package:bubbly/modal/pk_battle/battle_type.dart' as BattleTypes;
import 'package:bubbly/view/pk_battle/widgets/battle_progress_bar.dart';
import 'package:bubbly/view/pk_battle/widgets/battle_timer.dart';
import 'package:bubbly/view/pk_battle/widgets/battle_countdown_overlay.dart';
import 'package:bubbly/view/pk_battle/widgets/battle_user_view.dart';
import 'package:bubbly/view/pk_battle/widgets/battle_gift_buttons.dart';
import 'package:bubbly/view/pk_battle/controllers/pk_battle_controller.dart';
import 'package:bubbly/utils/pk_battle_config.dart';

class BattleView extends StatefulWidget {
  final bool isAudience;
  final bool isHost;
  final bool isCoHost;
  final EdgeInsets? margin;
  final String roomId;

  const BattleView({
    Key? key,
    this.isAudience = false,
    this.isHost = false,
    this.isCoHost = false,
    this.margin,
    required this.roomId,
  }) : super(key: key);

  @override
  State<BattleView> createState() => _BattleViewState();
}

class _BattleViewState extends State<BattleView> {
  late PKBattleController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(PKBattleController(widget.roomId));
  }

  @override
  void dispose() {
    Get.delete<PKBattleController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final livestream = controller.livestream.value;
      final userStates = controller.userStates;
      
      // Enhanced debug logging
      print('BattleView: roomId = ${widget.roomId}');
      print('BattleView: isHost = ${widget.isHost}');
      print('BattleView: isCoHost = ${widget.isCoHost}');
      print('BattleView: isAudience = ${widget.isAudience}');
      print('BattleView: livestream = $livestream');
      print('BattleView: livestream?.isBattleMode = ${livestream?.isBattleMode}');
      print('BattleView: livestream?.battleType = ${livestream?.battleType}');
      print('BattleView: userStates.length = ${userStates.length}');
      
      if (livestream == null || !livestream.isBattleMode) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: widget.margin,
        child: Stack(
          children: [
            _buildMainBattleView(livestream, userStates),
            if (livestream.battleType == BattleTypes.BattleType.waiting) _buildCountdownOverlay(livestream),
          ],
        ),
      );
    });
  }

  Widget _buildMainBattleView(Livestream livestream, List<LivestreamUserState> userStates) {
    final participants = userStates.where((state) => state.isParticipant).toList();
    
    if (participants.length < 2) {
      return _buildWaitingForParticipants();
    }

    final host = participants.firstWhere((p) => p.isHost, orElse: () => participants.first);
    final coHost = participants.firstWhere((p) => p.isCoHost, orElse: () => participants.last);

    return Column(
      children: [
        // Battle header
        _buildBattleHeader(livestream),
        const SizedBox(height: 4),
        
        // Progress bar with integrated coin counts (moved higher)
        _buildProgressBar(host, coHost),
        const SizedBox(height: 4),
        
        // Video overlay with VS indicator only
        _buildVideoOverlay(host, coHost),
        const SizedBox(height: 4),
        
        // Battle timer below the video overlay
        _buildBattleTimer(livestream),
      ],
    );
  }

  Widget _buildBattleHeader(Livestream livestream) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(PKBattleConfig.redTeamColor).withOpacity(0.8),
            Color(PKBattleConfig.blueTeamColor).withOpacity(0.8),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.flash_on,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            _getBattleStatusText(livestream.battleType),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.flash_on,
            color: Colors.white,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsView(LivestreamUserState host, LivestreamUserState coHost) {
    return Obx(() {
      final winnerData = controller.battleWinner;
      final hostIsWinner = winnerData['winnerId'] == host.userId;
      final coHostIsWinner = winnerData['winnerId'] == coHost.userId;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BattleUserView(
            userState: host,
            isWinner: hostIsWinner,
            isLeft: true,
            onTap: () => _onUserTap(host),
          ),
          _buildVSIndicator(),
          BattleUserView(
            userState: coHost,
            isWinner: coHostIsWinner,
            isLeft: false,
            onTap: () => _onUserTap(coHost),
          ),
        ],
      );
    });
  }

  Widget _buildVSIndicator() {
    return Container(
      width: 60,
      height: 60,
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
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'VS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(LivestreamUserState host, LivestreamUserState coHost) {
    return BattleProgressBar(
      redCoins: host.currentBattleCoin,
      blueCoins: coHost.currentBattleCoin,
    );
  }

  Widget _buildCoinCounts(LivestreamUserState host, LivestreamUserState coHost) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Host coin count (left side - red)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(PKBattleConfig.redTeamColor),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Color(PKBattleConfig.redTeamColor).withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                PKBattleConfig.formatCoins(host.currentBattleCoin),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        
        // Co-host coin count (right side - blue)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(PKBattleConfig.blueTeamColor),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Color(PKBattleConfig.blueTeamColor).withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                PKBattleConfig.formatCoins(coHost.currentBattleCoin),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoOverlay(LivestreamUserState host, LivestreamUserState coHost) {
    return Container(
      height: 300, // Reduced height since we only have VS indicator
      child: Center(
        // Only VS indicator in the center
        child: Container(
          width: 60,
          height: 300,
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
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'VS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBattleTimer(Livestream livestream) {
    return Obx(() {
      return BattleTimer(
        livestream: livestream,
        remainingSeconds: controller.remainingSeconds.value,
        onBattleEnd: () => controller.endBattle(),
      );
    });
  }

  Widget _buildGiftButtons(List<LivestreamUserState> participants) {
    return Obx(() {
      final livestream = controller.livestream.value;
      final isEnabled = livestream?.isBattleRunning == true;

      return BattleGiftButtons(
        participants: participants,
        onGiftTap: (battleView) => _onGiftTap(battleView),
        isEnabled: isEnabled,
      );
    });
  }

  Widget _buildCountdownOverlay(Livestream livestream) {
    return BattleCountdownOverlay(
      livestream: livestream,
      onCountdownComplete: () => controller.startBattleRunning(),
    );
  }

  Widget _buildWaitingForParticipants() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.people_outline,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Waiting for participants...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'A co-host needs to join to start the battle',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getBattleStatusText(BattleTypes.BattleType? battleType) {
    switch (battleType) {
      case BattleTypes.BattleType.waiting:
        return 'BATTLE STARTING';
      case BattleTypes.BattleType.running:
        return 'BATTLE IN PROGRESS';
      case BattleTypes.BattleType.end:
        return 'BATTLE ENDED';
      default:
        return 'PK BATTLE';
    }
  }

  void _onUserTap(LivestreamUserState userState) {
    // Handle user tap - could show user profile or other actions
    print('User tapped: ${userState.user?.userName}');
  }

  void _onGiftTap(BattleTypes.BattleView battleViewType) {
    controller.openGiftSheet(battleViewType);
  }
}


