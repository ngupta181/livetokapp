import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/utils/assert_image.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/my_loading/my_loading.dart';
import 'package:bubbly/view/live_stream/model/broad_cast_screen_view_model.dart';
import 'package:bubbly/view/live_stream/widget/blur_tab.dart';
import 'package:bubbly/view/live_stream/widget/top_viewers_row.dart';
import 'package:bubbly/view/live_stream/widget/pk_battle_controls.dart';
import 'package:bubbly/view/live_stream/widget/members_bottom_sheet.dart';
import 'package:bubbly/view/live_stream/widget/co_host_controls.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BroadCastTopBarArea extends StatelessWidget {
  final BroadCastScreenViewModel model;

  const BroadCastTopBarArea({
    Key? key,
    required this.model,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, MyLoading myLoading, child) {
      return Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 10),
            padding: EdgeInsets.only(top: 10, bottom: 2),
            child: Row(
              children: [
                BlurTab(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.music_note, color: Colors.white, size: 16),
                        SizedBox(width: 5),
                        Text(LKey.live.tr, style: TextStyle(color: ColorRes.colorPink, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                TopViewersRow(
                  viewers: model.commentList,
                  onViewAllTap: () => _showViewersDialog(context),
                ),
                SizedBox(
                  width: 10,
                ),
                // Members button
                InkWell(
                  onTap: () => _showMembersBottomSheet(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Members',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: FontRes.fNSfUiMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Spacer(),
                InkWell(
                  onTap: () {
                    model.onEndButtonClick();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          ColorRes.colorPink,
                          ColorRes.colorTheme,
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      LKey.end.tr.toUpperCase(),
                      style: TextStyle(
                          color: ColorRes.white,
                          fontSize: 14,
                          fontFamily: FontRes.fNSfUiSemiBold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 5,
          ),
          // PK Battle Controls (only for host)
          if (model.isHost) ...[
            PKBattleControls(
              channelName: model.channelName ?? '',
              commentList: model.commentList,
              model: model,
              onCoHostJoined: () {
                // Handle co-host joined event
                print('Co-host joined the live stream');
              },
            ),
          ],
          // Co-Host Controls (only for co-host)
          CoHostControls(model: model),
          SizedBox(
            height: 5,
          ),
        ],
      );
    });
  }

  void _showMembersBottomSheet(BuildContext context) {
    Get.bottomSheet(
      MembersBottomSheet(
        channelName: model.channelName ?? '',
        isHost: model.isHost,
        commentList: model.commentList,
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  void _showViewersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(LKey.viewers.tr),
          content: Container(
            height: 200,
            width: 200,
            child: ListView.builder(
              itemCount: model.liveStreamUser?.joinedUser?.length ?? 0,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                      "${model.liveStreamUser?.joinedUser?[index] ?? ""}"),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(LKey.ok.tr),
            ),
          ],
        );
      },
    );
  }
}

