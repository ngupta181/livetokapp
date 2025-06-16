import 'package:bubbly/modal/live_stream/live_stream.dart';
import 'package:bubbly/view/live_stream/model/broad_cast_screen_view_model.dart';
import 'package:bubbly/view/live_stream/widget/audience_top_bar.dart';
import 'package:bubbly/view/live_stream/widget/swipeable_comments.dart';
import 'package:bubbly/view/live_stream/widget/gift_display.dart';
import 'package:bubbly/view/live_stream/widget/gift_animation_controller.dart';
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
  final GiftAnimationController _giftAnimationController =
      GiftAnimationController();

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

                // Top layer - gift animations (must be last in stack to show on top)
                GiftDisplay(
                  commentList: model.commentList,
                  settingData: model.settingData,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
