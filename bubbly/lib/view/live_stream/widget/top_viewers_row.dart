import 'package:flutter/material.dart';
import 'package:bubbly/modal/live_stream/live_stream.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/level_utils.dart';

class TopViewersRow extends StatelessWidget {
  final List<LiveStreamComment> viewers;
  final VoidCallback onViewAllTap;

  const TopViewersRow({
    Key? key,
    required this.viewers,
    required this.onViewAllTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Filter unique viewers by userId
    final Map<int?, LiveStreamComment> uniqueViewers = {};
    for (var viewer in viewers) {
      if (viewer.userId != null) {
        uniqueViewers[viewer.userId] = viewer;
      }
    }
    
    // Convert to list and sort by level (highest to lowest)
    final List<LiveStreamComment> allViewers = uniqueViewers.values.toList();
    allViewers.sort((a, b) => (b.userLevel ?? 1).compareTo(a.userLevel ?? 1));
    
    // Get top 3 viewers by level
    final List<LiveStreamComment> topViewers = allViewers.take(3).toList();

    return InkWell(
      onTap: onViewAllTap,
      child: Container(
        height: 40,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Display top viewers
            for (int i = 0; i < topViewers.length; i++)
              Padding(
                padding: EdgeInsets.only(right: i < topViewers.length - 1 ? -10 : 0),
                child: _buildViewerAvatar(topViewers[i]),
              ),
            
            // Show count if there are more viewers
            if (uniqueViewers.length > 1)
              Container(
                margin: EdgeInsets.only(left: 5),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '+${uniqueViewers.length - 3}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewerAvatar(LiveStreamComment viewer) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: LevelUtils.getProfileWithFrame(
        userProfileUrl: "${ConstRes.itemBaseUrl}${viewer.userImage}",
        level: viewer.userLevel ?? 1,
        initialText: viewer.fullName?.substring(0, 1).toUpperCase() ?? 'U',
        frameSize: 40,
        fontSize: 14,
      ),
    );
  }
} 