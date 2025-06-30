import 'package:flutter/material.dart';
import 'package:bubbly/modal/live_stream/live_stream.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/level_utils.dart';
import 'package:get/get.dart';

class ViewersDialog extends StatelessWidget {
  final List<LiveStreamComment> viewers;
  final Function(LiveStreamComment)? onFollowTap;
  final int? hostUserId;

  const ViewersDialog({
    Key? key,
    required this.viewers,
    this.onFollowTap,
    this.hostUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Filter unique viewers by userId and exclude host
    final Map<int?, LiveStreamComment> uniqueViewers = {};
    for (var viewer in viewers) {
      if (viewer.userId != null && viewer.userId != hostUserId) {
        uniqueViewers[viewer.userId] = viewer;
      }
    }
    
    // Convert to list and sort by level (highest to lowest)
    final List<LiveStreamComment> uniqueViewersList = uniqueViewers.values.toList();
    uniqueViewersList.sort((a, b) => (b.userLevel ?? 1).compareTo(a.userLevel ?? 1));

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Viewers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: FontRes.fNSfUiSemiBold,
                    ),
                  ),
                ),
              ),
              
              // Viewers List
              Expanded(
                child: uniqueViewersList.isEmpty 
                  ? Center(child: Text('No viewers yet'))
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      itemCount: uniqueViewersList.length,
                      itemBuilder: (context, index) {
                        final viewer = uniqueViewersList[index];
                        return ViewerListItem(
                          viewer: viewer,
                          onFollowTap: onFollowTap != null 
                            ? () => onFollowTap!(viewer)
                            : null,
                        );
                      },
                    ),
              ),
            ],
          ),
          
          // Close button in top-right corner
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.black87,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ViewerListItem extends StatelessWidget {
  final LiveStreamComment viewer;
  final VoidCallback? onFollowTap;

  const ViewerListItem({
    Key? key,
    required this.viewer,
    this.onFollowTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int userLevel = viewer.userLevel ?? 1;
    final Color levelColor = LevelUtils.getLevelColor(userLevel);
    final String levelBadge = LevelUtils.getLevelBadgeEmoji(userLevel);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Level badge instead of rank
          Container(
            width: 40,
            height: 40,
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: levelColor.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: levelColor,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  levelBadge,
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Lv.$userLevel',
                  style: TextStyle(
                    color: levelColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
            
          // User avatar with level frame
          LevelUtils.getProfileWithFrame(
            userProfileUrl: "${ConstRes.itemBaseUrl}${viewer.userImage}",
            level: userLevel,
            initialText: viewer.fullName?.substring(0, 1).toUpperCase() ?? 'U',
            frameSize: 50,
            fontSize: 16,
          ),
          
          SizedBox(width: 12),
          
          // User details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      viewer.fullName ?? 'User',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (viewer.isVerify == true)
                      Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                Text(
                  '@${viewer.userName ?? ''}',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Follow button
          if (onFollowTap != null)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ColorRes.colorTheme, ColorRes.colorPink],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onFollowTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 