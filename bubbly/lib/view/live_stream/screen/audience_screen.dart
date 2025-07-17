import 'package:bubbly/modal/live_stream/live_stream.dart';
import 'package:bubbly/view/live_stream/model/broad_cast_screen_view_model.dart';
import 'package:bubbly/view/live_stream/widget/audience_top_bar.dart';
import 'package:bubbly/view/live_stream/widget/swipeable_comments.dart';
import 'package:bubbly/view/live_stream/widget/gift_queue_display.dart';
import 'package:bubbly/view/live_stream/widget/level_up_animation.dart';
import 'package:bubbly/view/live_stream/widget/level_up_animation_controller.dart';
import 'package:bubbly/view/pk_battle/screens/battle_view.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class AudienceScreen extends StatefulWidget {
  final String? agoraToken;
  final String? channelName;
  final LiveStreamUser user;

  const AudienceScreen({
    Key? key,
    this.agoraToken,
    this.channelName,
    required this.user,
  }) : super(key: key);

  @override
  State<AudienceScreen> createState() => _AudienceScreenState();
}

class _AudienceScreenState extends State<AudienceScreen> {
  final LevelUpAnimationController _levelUpController =
      LevelUpAnimationController();

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<BroadCastScreenViewModel>.reactive(
      onViewModelReady: (model) {
        model.init(
          isBroadCast: false,
          agoraToken: widget.agoraToken ?? '',
          channelName: widget.channelName ?? '',
        );
      },
      viewModelBuilder: () => BroadCastScreenViewModel(),
      builder: (context, model, child) {
        // Print debug info
        print('AudienceScreen: Comment list size: ${model.commentList.length}');
        for (var comment in model.commentList) {
          print('Comment: ${comment.commentType}, ${comment.comment}');
        }

        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: Colors.black, // Black background to match host UI
            body: Stack(
              children: [
                // Base layer - video panel
                model.videoPanel(),

                // Middle layer - UI controls and comments
                SafeArea(
                  child: Column(
                    children: [
                      AudienceTopBar(model: model, user: widget.user),
                      Spacer(),
                      SwipeableComments(
                        model: model,
                        commentList: model.commentList,
                        pageContext: context,
                      ),
                    ],
                  ),
                ),

                // Gift animations (using new system)
                GiftQueueDisplay(
                  commentList: model.commentList,
                  settingData: model.settingData,
                  isGiftSheetOpen: model.isGiftSheetOpen,
                  isGiftSheetMinimized: model.isGiftSheetMinimized,
                ),
                
                // PK Battle View - shows battle UI when battle is active (responsive positioning for audience)
                if (model.channelName != null)
                  Builder(
                    builder: (context) {
                      final mediaQuery = MediaQuery.of(context);
                      final screenHeight = mediaQuery.size.height;
                      final screenWidth = mediaQuery.size.width;
                      final isTablet = screenWidth > 600;
                      final isLandscape = mediaQuery.orientation == Orientation.landscape;
                      
                      // Responsive positioning based on screen size and orientation
                      // Adjusted to avoid overlapping with top bar
                      double topPosition;
                      if (isLandscape) {
                        topPosition = screenHeight * 0.20; // 20% from top in landscape
                      } else if (isTablet) {
                        topPosition = screenHeight * 0.22; // 22% from top on tablets
                      } else {
                        topPosition = screenHeight * 0.20; // 20% from top on phones (moved lower)
                      }
                      
                      double horizontalMargin = screenWidth * 0.04; // 4% of screen width
                      
                      return Positioned(
                        top: topPosition,
                        left: horizontalMargin,
                        right: horizontalMargin,
                        child: BattleView(
                          roomId: model.channelName!,
                          isAudience: true, // Audience view
                          isHost: false, // Audience is not host
                          isCoHost: model.isCoHost, // Pass co-host status from model
                        ),
                      );
                    },
                  ),
                
                // Level up animation display
                AnimatedBuilder(
                  animation: _levelUpController,
                  builder: (context, _) {
                    if (_levelUpController.showLevelAnimation) {
                      return Center(
                        child: LevelUpAnimation(
                          oldLevel: _levelUpController.oldLevel,
                          newLevel: _levelUpController.newLevel,
                          onAnimationComplete: () {
                            _levelUpController.hideAnimation();
                          },
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
