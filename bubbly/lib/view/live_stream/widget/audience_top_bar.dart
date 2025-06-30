import 'package:bubbly/custom_view/image_place_holder.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/modal/live_stream/live_stream.dart';
import 'package:bubbly/utils/assert_image.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/level_utils.dart';
import 'package:bubbly/utils/my_loading/my_loading.dart';
import 'package:bubbly/view/live_stream/model/broad_cast_screen_view_model.dart';
import 'package:bubbly/view/live_stream/widget/blur_tab.dart';
import 'package:bubbly/view/live_stream/widget/top_viewers_row.dart';
import 'package:bubbly/view/live_stream/widget/viewers_dialog.dart';
import 'package:bubbly/view/report/report_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AudienceTopBar extends StatelessWidget {
  final BroadCastScreenViewModel model;
  final LiveStreamUser user;

  const AudienceTopBar({Key? key, required this.model, required this.user})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          BlurTab(
            height: 65,
            radius: 15,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      model.onUserTap(context);
                    },
                    child: LevelUtils.getProfileWithFrame(
                      userProfileUrl: "${ConstRes.itemBaseUrl}${user.userImage}",
                      level: user.userLevel ?? 1,
                      initialText: user.fullName?.substring(0, 1).toUpperCase() ?? 'N',
                      frameSize: 65,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        model.onUserTap(context);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user.fullName ?? '',
                                style: TextStyle(
                                    color: ColorRes.white,
                                    fontFamily: FontRes.fNSfUiMedium),
                              ),
                              Visibility(
                                visible: user.isVerified ?? false,
                                child: Image.asset(
                                  icVerify,
                                  height: 15,
                                  width: 15,
                                ),
                              )
                            ],
                          ),
                          SizedBox(
                            height: 2,
                          ),
                          Text(
                            "${user.followers ?? 0} ${LKey.followers.tr}",
                            style: TextStyle(
                                color: ColorRes.white.withOpacity(0.5),
                                fontFamily: FontRes.fNSfUiMedium),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Follow button
                  InkWell(
                    onTap: () {
                      model.followUser(user.userId ?? -1);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [ColorRes.colorTheme, ColorRes.colorPink],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => ReportScreen(2, "${user.userId}"),
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                      );
                    },
                    child: Image.asset(
                      icMenu,
                      height: 20,
                      width: 20,
                      color: ColorRes.white,
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 5,
          ),
          BlurTab(
            height: 40,
            child: Row(
              children: [
                SizedBox(
                  width: 10,
                ),
                Image.asset(
                    Provider.of<MyLoading>(context, listen: true).isDark
                        ? icLogo
                        : icLogoLight,
                    height: 20),
                Text(
                  ' LIVE',
                  style: TextStyle(
                      fontFamily: FontRes.fNSfUiSemiBold,
                      fontSize: 16,
                      color: ColorRes.white),
                ),
                Spacer(),
                // Top viewers row
                InkWell(
                  onTap: () {
                    _showViewersDialog(context);
                  },
                  child: model.commentList.isNotEmpty
                      ? TopViewersRow(
                          viewers: model.commentList,
                          onViewAllTap: () => _showViewersDialog(context),
                        )
                      : Row(
                          children: [
                            Text(
                              "${NumberFormat.compact(locale: 'en').format(double.parse('${model.liveStreamUser?.watchingCount ?? '0'}'))} Viewers",
                              style: TextStyle(
                                  fontFamily: FontRes.fNSfUiRegular,
                                  fontSize: 15,
                                  color: ColorRes.white),
                            ),
                          ],
                        ),
                ),
                Spacer(),
                InkWell(
                  onTap: model.audienceExit,
                  child: Row(
                    children: [
                      Image.asset(
                        exit,
                        height: 20,
                        width: 20,
                        color: ColorRes.white,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        "Exit",
                        style: TextStyle(
                            fontSize: 15,
                            color: ColorRes.white,
                            fontFamily: FontRes.fNSfUiMedium),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showViewersDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ViewersDialog(
        viewers: model.commentList,
        onFollowTap: (viewer) {
          model.followUser(viewer.userId ?? -1);
          Navigator.pop(context);
        },
        hostUserId: model.liveStreamUser?.userId,
      ),
    );
  }
}
