import 'dart:ui';

import 'package:bubbly/custom_view/image_place_holder.dart';
import 'package:bubbly/modal/live_stream/live_stream.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/level_utils.dart';
import 'package:flutter/material.dart';

class LiveStreamChatList extends StatelessWidget {
  final List<LiveStreamComment> commentList;
  final BuildContext pageContext;

  const LiveStreamChatList({
    Key? key,
    required this.commentList,
    required this.pageContext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double tempSize = MediaQuery.of(pageContext).viewInsets.bottom == 0
        ? 0
        : MediaQuery.of(pageContext).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(left: 10),
      height: (tempSize == 0)
          ? (MediaQuery.of(context).size.height - 270) / 2
          : (MediaQuery.of(context).size.height - 270) - tempSize - 50,
      width: MediaQuery.of(context).size.width,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red, Colors.transparent, Colors.transparent],
            stops: [0.0, 0.3, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstOut,
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: commentList.length,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          reverse: true,
          itemBuilder: (context, index) {
            final comment = commentList[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with frame based on user level
                  LevelUtils.getProfileWithFrame(
                    userProfileUrl: "${ConstRes.itemBaseUrl}${comment.userImage}",
                    level: comment.userLevel ?? 1,
                    initialText: comment.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                    frameSize: 35,
                    fontSize: 14,
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 1.5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comment.fullName ?? '',
                            style: TextStyle(
                                color: ColorRes.white,
                                fontSize: 13,
                                fontFamily: FontRes.fNSfUiMedium)),
                        SizedBox(height: 2),
                        comment.commentType == "msg"
                            ? Text(comment.comment ?? '',
                                style: TextStyle(
                                    color: ColorRes.greyShade100, fontSize: 12))
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaY: 15, sigmaX: 15),
                                  child: Container(
                                    height: 55,
                                    width: 55,
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: ColorRes.colorPrimaryDark
                                          .withOpacity(0.33),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        ConstRes.getImageUrl(comment.comment),
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container();
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
