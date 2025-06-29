import 'package:bubbly/custom_view/image_place_holder.dart';
import 'package:bubbly/modal/live_stream/live_stream.dart';
import 'package:bubbly/utils/assert_image.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/level_utils.dart';
import 'package:flutter/material.dart';

class LiveStreamCommentItem extends StatelessWidget {
  final LiveStreamComment comment;

  const LiveStreamCommentItem({Key? key, required this.comment})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LevelUtils.getProfileWithFrame(
            userProfileUrl: "${ConstRes.itemBaseUrl}${comment.userImage}",
            level: comment.userLevel ?? 1,
            initialText: comment.fullName?.substring(0, 1).toUpperCase() ?? 'N',
            frameSize: 45,
            fontSize: 14,
          ),
          SizedBox(
            width: 5,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.fullName ?? '',
                      style: TextStyle(
                          color: ColorRes.white,
                          fontFamily: FontRes.fNSfUiMedium,
                          fontSize: 12),
                    ),
                    Visibility(
                      visible: comment.isVerify ?? false,
                      child: Image.asset(
                        icVerify,
                        height: 12,
                        width: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 2,
                ),
                comment.commentType == 'msg'
                    ? Text(
                        comment.comment ?? '',
                        style: TextStyle(
                            color: ColorRes.white,
                            fontFamily: FontRes.fNSfUiRegular,
                            fontSize: 12),
                      )
                    : Image.network(
                        comment.comment ?? '',
                        height: 30,
                        width: 30,
                      )
              ],
            ),
          )
        ],
      ),
    );
  }
} 