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

// Responsive configuration class
class ResponsiveConfig {
  final double screenWidth;
  final double screenHeight;
  final bool isTablet;
  final bool isLandscape;
  final double pixelRatio;

  ResponsiveConfig({
    required this.screenWidth,
    required this.screenHeight,
    required this.isTablet,
    required this.isLandscape,
    required this.pixelRatio,
  });

  // Responsive sizing methods
  double get headerPadding => isTablet ? 24.0 : 16.0;
  double get headerFontSize => isTablet ? 20.0 : 16.0;
  double get iconSize => isTablet ? 28.0 : 20.0;
  double get vsIndicatorSize => isTablet ? 80.0 : 60.0;
  double get progressBarHeight => isTablet ? 12.0 : 8.0;
  double get coinCountPadding => isTablet ? 16.0 : 12.0;
  double get coinCountFontSize => isTablet ? 16.0 : 14.0;
  double get timerFontSize => isTablet ? 24.0 : 20.0;
  double get borderRadius => isTablet ? 30.0 : 25.0;
  
  // Dynamic spacing based on screen size (increased for better alignment)
  double get verticalSpacing => screenHeight * 0.015; // 1.5% of screen height (increased)
  double get horizontalPadding => screenWidth * 0.04; // 4% of screen width
  
  // Video overlay height based on screen size and orientation (reduced for better fit)
  double get videoOverlayHeight {
    if (isLandscape) {
      return screenHeight * 0.25; // 25% of screen height in landscape (reduced)
    } else {
      return screenHeight * 0.20; // 20% of screen height in portrait (reduced)
    }
  }
  
  // Battle header height
  double get battleHeaderHeight => isTablet ? 60.0 : 50.0;
  
  // Responsive margins
  EdgeInsets get containerMargin => EdgeInsets.symmetric(
    horizontal: horizontalPadding,
    vertical: verticalSpacing,
  );
}

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

  // Responsive design helper methods
  ResponsiveConfig _getResponsiveConfig(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isTablet = screenWidth > 600;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    
    return ResponsiveConfig(
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      isTablet: isTablet,
      isLandscape: isLandscape,
      pixelRatio: mediaQuery.devicePixelRatio,
    );
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
    final config = _getResponsiveConfig(context);
    
    if (participants.length < 2) {
      return _buildWaitingForParticipants(config);
    }

    final host = participants.firstWhere((p) => p.isHost, orElse: () => participants.first);
    final coHost = participants.firstWhere((p) => p.isCoHost, orElse: () => participants.last);

    return Column(
      children: [
        // Battle header
        _buildBattleHeader(livestream, config),
        SizedBox(height: config.verticalSpacing),
        
        // Progress bar with integrated coin counts (moved higher)
        _buildProgressBar(host, coHost, config),
        SizedBox(height: config.verticalSpacing),
        
        // Video overlay with VS indicator only
        _buildVideoOverlay(host, coHost, config),
        SizedBox(height: config.verticalSpacing),
        
        // Battle timer below the video overlay
        _buildBattleTimer(livestream, config),
      ],
    );
  }

  Widget _buildBattleHeader(Livestream livestream, ResponsiveConfig config) {
    return Container(
      height: config.battleHeaderHeight,
      padding: EdgeInsets.symmetric(
        horizontal: config.headerPadding,
        vertical: config.headerPadding * 0.6,
      ),
      margin: config.containerMargin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(PKBattleConfig.redTeamColor).withOpacity(0.8),
            Color(PKBattleConfig.blueTeamColor).withOpacity(0.8),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(config.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: config.isTablet ? 12 : 8,
            spreadRadius: config.isTablet ? 3 : 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flash_on,
            color: Colors.white,
            size: config.iconSize,
          ),
          SizedBox(width: config.horizontalPadding * 0.2),
          Flexible(
            child: Text(
              _getBattleStatusText(livestream.battleType),
              style: TextStyle(
                color: Colors.white,
                fontSize: config.headerFontSize,
                fontWeight: FontWeight.bold,
                letterSpacing: config.isTablet ? 2.0 : 1.5,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: config.horizontalPadding * 0.2),
          Icon(
            Icons.flash_on,
            color: Colors.white,
            size: config.iconSize,
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

  Widget _buildProgressBar(LivestreamUserState host, LivestreamUserState coHost, ResponsiveConfig config) {
    return Container(
      margin: config.containerMargin,
      child: BattleProgressBar(
        redCoins: host.currentBattleCoin,
        blueCoins: coHost.currentBattleCoin,
        height: config.progressBarHeight,
      ),
    );
  }

  Widget _buildCoinCounts(LivestreamUserState host, LivestreamUserState coHost, ResponsiveConfig config) {
    return Container(
      margin: config.containerMargin,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Host coin count (left side - red)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: config.coinCountPadding,
              vertical: config.coinCountPadding * 0.5,
            ),
            decoration: BoxDecoration(
              color: Color(PKBattleConfig.redTeamColor),
              borderRadius: BorderRadius.circular(config.borderRadius * 0.6),
              boxShadow: [
                BoxShadow(
                  color: Color(PKBattleConfig.redTeamColor).withOpacity(0.3),
                  blurRadius: config.isTablet ? 6 : 4,
                  spreadRadius: config.isTablet ? 2 : 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monetization_on,
                  color: Colors.white,
                  size: config.isTablet ? 20 : 16,
                ),
                SizedBox(width: config.horizontalPadding * 0.1),
                Text(
                  PKBattleConfig.formatCoins(host.currentBattleCoin),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: config.coinCountFontSize,
                  ),
                ),
              ],
            ),
          ),
          
          // Co-host coin count (right side - blue)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: config.coinCountPadding,
              vertical: config.coinCountPadding * 0.5,
            ),
            decoration: BoxDecoration(
              color: Color(PKBattleConfig.blueTeamColor),
              borderRadius: BorderRadius.circular(config.borderRadius * 0.6),
              boxShadow: [
                BoxShadow(
                  color: Color(PKBattleConfig.blueTeamColor).withOpacity(0.3),
                  blurRadius: config.isTablet ? 6 : 4,
                  spreadRadius: config.isTablet ? 2 : 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monetization_on,
                  color: Colors.white,
                  size: config.isTablet ? 20 : 16,
                ),
                SizedBox(width: config.horizontalPadding * 0.1),
                Text(
                  PKBattleConfig.formatCoins(coHost.currentBattleCoin),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: config.coinCountFontSize,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoOverlay(LivestreamUserState host, LivestreamUserState coHost, ResponsiveConfig config) {
    return Container(
      height: config.videoOverlayHeight,
      margin: config.containerMargin,
      child: Center(
        // Only VS indicator in the center
        child: Container(
          width: config.vsIndicatorSize,
          height: config.vsIndicatorSize,
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
                blurRadius: config.isTablet ? 12 : 8,
                spreadRadius: config.isTablet ? 3 : 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              'VS',
              style: TextStyle(
                color: Colors.white,
                fontSize: config.isTablet ? 20 : 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBattleTimer(Livestream livestream, ResponsiveConfig config) {
    return Container(
      margin: config.containerMargin,
      child: Obx(() {
        return BattleTimer(
          livestream: livestream,
          remainingSeconds: controller.remainingSeconds.value,
          onBattleEnd: () => controller.endBattle(),
        );
      }),
    );
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

  Widget _buildWaitingForParticipants(ResponsiveConfig config) {
    return Container(
      padding: EdgeInsets.all(config.headerPadding),
      margin: config.containerMargin,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(config.borderRadius * 0.6),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: config.isTablet ? 64 : 48,
            color: Colors.grey,
          ),
          SizedBox(height: config.verticalSpacing * 2),
          Text(
            'Waiting for participants...',
            style: TextStyle(
              fontSize: config.headerFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: config.verticalSpacing),
          Text(
            'A co-host needs to join to start the battle',
            style: TextStyle(
              fontSize: config.isTablet ? 16 : 14,
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


