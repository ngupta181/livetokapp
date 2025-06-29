import 'package:bubbly/utils/const_res.dart';
import 'package:flutter/material.dart';

class LevelUtils {
  // Base URL for avatar frames
  static String get avatarFrameBaseUrl => ConstRes.itemBaseUrl;
  
  // Level ranges based on LiveTok screenshots
  static const List<LevelRange> levelRanges = [
    LevelRange(1, 9, "level_badge_1", "avatar_frame_1.png", false, null),
    LevelRange(10, 19, "level_badge_10", "avatar_frame_10.png", false, null),
    LevelRange(20, 29, "level_badge_20", "avatar_frame_20.png", false, null),
    LevelRange(30, 39, "level_badge_30", "avatar_frame_30.png", true, "entry_effect_30"),
    LevelRange(40, 49, "level_badge_40", "avatar_frame_40.png", true, "entry_effect_30"),
    LevelRange(50, 50, "level_badge_50", "avatar_frame_50.png", true, "entry_effect_30"),
  ];

  // Get full URL for avatar frame
  static String getAvatarFrameUrl(int level) {
    LevelRange range = getLevelRange(level);
    return avatarFrameBaseUrl + range.frameAsset;
  }

  // Level colors for badges (matching the screenshot)
  static const Map<int, Color> levelColors = {
    1: Color(0xFF8BD982), // Green (level 1-9)
    10: Color(0xFF5DD1D7), // Light Blue (level 10-19)
    20: Color(0xFF5D97D7), // Blue (level 20-29)
    30: Color(0xFFA87DF0), // Purple (level 30-39)
    40: Color(0xFFEE85B5), // Pink (level 40-49)
    50: Color(0xFFFF5F55), // Red (level 50)
  };

  // Points required to reach each level
  static final Map<int, int> levelPointsRequired = {
    1: 0,
    2: 100,
    3: 200,
    4: 300,
    5: 500,
    6: 700,
    7: 1000,
    8: 1300,
    9: 1700,
    10: 2200,
    // Define more levels as needed
    20: 10000,
    30: 30000, 
    40: 60000,
    50: 100000,
  };

  // Calculate current level based on total points
  static int calculateLevel(int totalPoints) {
    if (totalPoints < 0) return 1;
    
    int level = 1;
    for (int i = 50; i >= 1; i--) {
      if (levelPointsRequired.containsKey(i) && totalPoints >= levelPointsRequired[i]!) {
        level = i;
        break;
      }
    }
    return level;
  }

  // Calculate points needed for next level
  static int pointsToNextLevel(int currentLevel, int currentPoints) {
    int nextLevel = currentLevel + 1;
    if (nextLevel > 50) return 0; // Max level reached
    
    // Find the next defined level threshold
    while (!levelPointsRequired.containsKey(nextLevel) && nextLevel <= 50) {
      nextLevel++;
    }
    
    if (!levelPointsRequired.containsKey(nextLevel)) return 0;
    
    return levelPointsRequired[nextLevel]! - currentPoints;
  }

  // Get level range for a specific level
  static LevelRange getLevelRange(int level) {
    for (LevelRange range in levelRanges) {
      if (level >= range.minLevel && level <= range.maxLevel) {
        return range;
      }
    }
    return levelRanges.first; // Default to first range
  }

  // Convert coin amount to level points 
  static int coinsToPoints(int coins) {
    // Example conversion: 1 coin = 5 points
    return coins * 5;
  }
  
  // Get level color for a specific level
  static Color getLevelColor(int level) {
    for (int threshold in levelColors.keys.toList()..sort()) {
      if (level >= threshold && level <= 50) {
        return levelColors[threshold]!;
      }
    }
    return levelColors[1]!; // Default color
  }
  
  // Get level badge emoji for a level
  static String getLevelBadgeEmoji(int level) {
    if (level >= 1 && level <= 9) return '💚';
    if (level >= 10 && level <= 19) return '⭐';
    if (level >= 20 && level <= 29) return '🌙';
    if (level >= 30 && level <= 39) return '💫';
    if (level >= 40 && level <= 49) return '🔥';
    if (level >= 50) return '👑';
    return '💚';
  }
  
  // Format level display (Lv 1-9, etc.)
  static String formatLevelRange(int minLevel, int maxLevel) {
    if (minLevel == maxLevel) return 'Lv $minLevel';
    return 'Lv $minLevel-$maxLevel';
  }

  /// Returns a widget that displays a user's profile image with the appropriate frame based on their level
  static Widget getProfileWithFrame({
    required String userProfileUrl,
    required int level,
    required String initialText,
    double size = 80,
    double frameSize = 110,
    double fontSize = 30,
  }) {
    String frameImageUrl = getAvatarFrameUrl(level);
    bool hasFrame = level >= 1; // Frames start at level 1
    
    // Calculate the optimal profile image size based on the frame
    // For 512x512 frames, the profile image should be approximately 60% of the frame size
    final double profileToFrameRatio = 0.60;
    final double profileSize = frameSize * profileToFrameRatio;
    
    return Container(
      width: frameSize,
      height: frameSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Profile image/placeholder centered in the frame
          Container(
            width: profileSize,
            height: profileSize,
            decoration: BoxDecoration(
              color: getLevelColor(level),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: userProfileUrl.isNotEmpty
                  ? Image.network(
                      userProfileUrl,
                      width: profileSize,
                      height: profileSize,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            initialText,
                            style: TextStyle(
                              fontSize: fontSize * profileToFrameRatio,
                              color: Colors.white,
                              fontFamily: 'SFUIDisplayBold',
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        initialText,
                        style: TextStyle(
                          fontSize: fontSize * profileToFrameRatio,
                          color: Colors.white,
                          fontFamily: 'SFUIDisplayBold',
                        ),
                      ),
                    ),
            ),
          ),
          // Frame image as overlay
          if (hasFrame)
            Positioned.fill(
              child: Image.network(
                frameImageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading frame image: $error');
                  return const SizedBox.shrink();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class LevelRange {
  final int minLevel;
  final int maxLevel;
  final String badgeAsset;
  final String frameAsset;
  final bool hasEntryEffect;
  final String? entryEffectAsset;
  
  const LevelRange(this.minLevel, this.maxLevel, this.badgeAsset, this.frameAsset, 
      this.hasEntryEffect, this.entryEffectAsset);
} 