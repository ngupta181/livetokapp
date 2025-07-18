import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/my_loading/my_loading.dart';
import 'package:bubbly/view/live_stream/model/broad_cast_screen_view_model.dart';
import 'package:bubbly/view/live_stream/widget/blur_tab.dart';
import 'package:bubbly/view/live_stream/widget/top_viewers_row.dart';
import 'package:bubbly/view/live_stream/widget/members_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
          // Row 1: Live == Viewers == END (with background)
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 15),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                // Live indicator
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.music_note, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        LKey.live.tr,
                        style: TextStyle(
                          color: ColorRes.colorPink,
                          fontSize: 13,
                          fontFamily: FontRes.fNSfUiMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                // Viewers count
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        '${model.liveStreamUser?.joinedUser?.length ?? 0} ${LKey.viewers.tr}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: FontRes.fNSfUiMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                // END button
                InkWell(
                  onTap: () {
                    model.onEndButtonClick();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          ColorRes.colorPink,
                          ColorRes.colorTheme,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ColorRes.colorPink.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      LKey.end.tr.toUpperCase(),
                      style: TextStyle(
                        color: ColorRes.white,
                        fontSize: 14,
                        fontFamily: FontRes.fNSfUiSemiBold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 8),
          
          // Row 2: Coin collected => TopViewersRow => Flip Camera => Microphone (with background)
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 15),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                // Collection status (coins collected)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.music_note, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        '0 ${LKey.collected.tr}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: FontRes.fNSfUiMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                // Top viewers row with flexible layout
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 150), // Limit width to prevent overflow
                    child: TopViewersRow(
                      viewers: model.commentList ?? [],
                      onViewAllTap: () => _showViewersDialog(context),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // Flip Camera button
                InkWell(
                  onTap: () {
                    model.flipCamera();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: ColorRes.colorTheme.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.flip_camera_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // Microphone button
                InkWell(
                  onTap: () {
                    model.onMuteUnMute();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: !model.isMic 
                          ? ColorRes.colorTheme.withOpacity(0.8)
                          : Colors.red.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      !model.isMic ? Icons.mic : Icons.mic_off,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 8),
          
          // Row 3: Members button (centered with background)
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 15),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Members button
                InkWell(
                  onTap: () => _showMembersBottomSheet(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          LKey.members.tr,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: FontRes.fNSfUiMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 8),
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
        model: model, // Pass the BroadCastScreenViewModel
        onCoHostRemoved: () {
          // Refresh the broadcast screen when co-host is removed
          model.notifyListeners();
        },
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  void _showViewersDialog(BuildContext context) {
    final joinedUsers = model.liveStreamUser?.joinedUser ?? [];
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(LKey.viewers.tr),
          content: Container(
            height: 200,
            width: 200,
            child: joinedUsers.isEmpty
                ? Center(
                    child: Text(
                      'No viewers yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: joinedUsers.length,
                    itemBuilder: (context, index) {
                      final user = joinedUsers[index];
                      return ListTile(
                        title: Text(user?.toString() ?? 'Unknown User'),
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


