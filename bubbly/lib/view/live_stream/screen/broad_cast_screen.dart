import 'package:bubbly/modal/user/user.dart';
import 'package:bubbly/view/live_stream/model/broad_cast_screen_view_model.dart';
import 'package:bubbly/view/live_stream/widget/broad_cast_top_bar_area.dart';
import 'package:bubbly/view/live_stream/widget/swipeable_comments.dart';
import 'package:bubbly/view/live_stream/widget/gift_queue_display.dart';
import 'package:bubbly/view/live_stream/widget/level_up_animation.dart';
import 'package:bubbly/view/live_stream/widget/level_up_animation_controller.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class BroadCastScreen extends StatefulWidget {
  final String? agoraToken;
  final String? channelName;
  final User? registrationUser;

  const BroadCastScreen({
    Key? key,
    required this.agoraToken,
    required this.channelName,
    this.registrationUser,
  }) : super(key: key);

  @override
  State<BroadCastScreen> createState() => _BroadCastScreenState();
}

class _BroadCastScreenState extends State<BroadCastScreen> {
  final LevelUpAnimationController _levelUpController =
      LevelUpAnimationController();

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<BroadCastScreenViewModel>.reactive(
      onViewModelReady: (model) {
        return model.init(
            isBroadCast: true,
            agoraToken: widget.agoraToken ?? "",
            channelName: widget.channelName ?? '',
            registrationUser: widget.registrationUser);
      },
      onDispose: (viewModel) {
        viewModel.leave();
      },
      viewModelBuilder: () => BroadCastScreenViewModel(),
      builder: (context, model, child) {
        // Print debug info
        print(
            'BroadCastScreen: Comment list size: ${model.commentList.length}');
        for (var comment in model.commentList) {
          print('Comment: ${comment.commentType}, ${comment.comment}');
        }

        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            model.onEndButtonClick();
          },
          child: Scaffold(
            body: Stack(
              children: [
                // Base layer - video panel
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: model.videoPanel(),
                ),

                // Middle layer - UI controls and comments
                SafeArea(
                  child: Column(
                    children: [
                      BroadCastTopBarArea(model: model),
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
