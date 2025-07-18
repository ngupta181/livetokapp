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
    // Filter unique viewers by userId and handle null safety
    final Map<int?, LiveStreamComment> uniqueViewers = {};
    for (var viewer in viewers) {
      if (viewer.userId != null && viewer.userId! > 0) {
        uniqueViewers[viewer.userId] = viewer;
      }
    }
    
    // Convert to list and sort by level (highest to lowest)
    final List<LiveStreamComment> allViewers = uniqueViewers.values.toList();
    allViewers.sort((a, b) => (b.userLevel ?? 1).compareTo(a.userLevel ?? 1));
    
    // Get top 3 viewers by level
    final List<LiveStreamComment> topViewers = allViewers.take(3).toList();
    final int totalViewers = uniqueViewers.length;

    // Return empty container if no viewers
    if (topViewers.isEmpty) {
      return SizedBox(height: 40);
    }

    return InkWell(
      onTap: onViewAllTap,
      child: Container(
        height: 40,
        constraints: BoxConstraints(maxWidth: 200), // Prevent overflow
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display top viewers with proper spacing
              ...List.generate(topViewers.length, (index) {
                return Container(
                  margin: EdgeInsets.only(
                    right: index < topViewers.length - 1 ? 5 : 0, // Positive margin instead of negative padding
                  ),
                  child: Transform.translate(
                    offset: Offset(index * -8.0, 0), // Overlap effect with transform
                    child: _buildViewerAvatar(topViewers[index], index),
                  ),
                );
              }),
              
              // Show count if there are more than 3 viewers
              if (totalViewers > 3)
                Container(
                  margin: EdgeInsets.only(left: totalViewers > 1 ? 8 : 5),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  constraints: BoxConstraints(minWidth: 24, minHeight: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    '+${totalViewers - 3}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewerAvatar(LiveStreamComment viewer, int index) {
    return Container(
      key: ValueKey('viewer_${viewer.userId}_$index'), // Unique key to prevent duplicate key errors
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: LevelUtils.getProfileWithFrame(
          userProfileUrl: "${ConstRes.itemBaseUrl}${viewer.userImage ?? ''}",
          level: viewer.userLevel ?? 1,
          initialText: (viewer.fullName?.isNotEmpty == true) 
              ? viewer.fullName!.substring(0, 1).toUpperCase() 
              : 'U',
          frameSize: 32,
          fontSize: 12,
        ),
      ),
    );
  }
} 