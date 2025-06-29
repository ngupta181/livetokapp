import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/modal/user/user.dart';
import 'package:bubbly/modal/user/user_level.dart';
import 'package:bubbly/utils/app_res.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/level_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bubbly/utils/const_res.dart';

class LevelScreen extends StatefulWidget {
  final User? userData;

  const LevelScreen({Key? key, this.userData}) : super(key: key);

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  UserLevelData? levelData;
  bool isLoading = true;
  ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    fetchLevelData();
  }

  Future<void> fetchLevelData() async {
    try {
      // If we already have user data from the arguments, use it
      if (widget.userData != null && widget.userData?.data != null) {
        setState(() {
          // We already have the user data, so we can just set isLoading to false
          isLoading = false;
        });
        return;
      }
      
      // Otherwise, fetch level data from the API
      final response = await apiService.getUserLevel();
      setState(() {
        levelData = response.data;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching level data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
        ),
        title: const Text(
          'Level',
          style: TextStyle(
            color: Colors.black,
            fontFamily: FontRes.fNSfUiBold,
            fontSize: 18,
          ),
        ),
        // actions: [
        //   TextButton(
        //     onPressed: () {
        //       // Navigate to settings or show settings dialog
        //     },
        //     child: const Text(
        //       'Settings',
        //       style: TextStyle(
        //         color: Colors.black,
        //         fontFamily: FontRes.fNSfUiRegular,
        //       ),
        //     ),
        //   ),
        // ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserProfile(),
                  _buildLevelInfo(),
                  _buildLevelMedalsSection(),
                  _buildAvatarDecorationsSection(),
                  _buildEntryEffectsSection(),
                  _buildLevelNotesSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserProfile() {
    final user = widget.userData?.data;
    int level = user?.userLevel ?? 1;
    String userProfileUrl = '${ConstRes.itemBaseUrl}${user?.userProfile ?? ''}';
    String initial = user?.fullName?.substring(0, 1).toUpperCase() ?? 'N';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            // Use the improved LevelUtils.getProfileWithFrame method
            LevelUtils.getProfileWithFrame(
              userProfileUrl: userProfileUrl,
              level: level,
              initialText: initial,
              size: 90, // Not used in the new implementation
              frameSize: 140, // Larger size for the level screen
              fontSize: 45,
            ),
            
            // Level badge below the profile
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: LevelUtils.getLevelColor(level),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    LevelUtils.getLevelBadgeEmoji(level),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Lv $level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: FontRes.fNSfUiBold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How to level up',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: FontRes.fNSfUiBold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'LiveTok Levels rewards you for sending Live gifts to your favorite creators. Increase your level by spending coins and sending gifts. The higher your level, the more benefits you\'ll unlock.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontFamily: FontRes.fNSfUiRegular,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelMedalsSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Level Medal',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: FontRes.fNSfUiBold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.0,
            children: [
              _buildLevelBadge(1, 9, '💚', Colors.green),
              _buildLevelBadge(10, 19, '⭐', Colors.cyan),
              _buildLevelBadge(20, 29, '🌙', Colors.blue),
              _buildLevelBadge(30, 39, '💫', Colors.purple),
              _buildLevelBadge(40, 49, '🔥', Colors.pink),
              _buildLevelBadge(50, 50, '👑', Colors.red),
              // Add empty containers for remaining grid spaces
              // const SizedBox(),
              // const SizedBox(),
              // const SizedBox(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(int minLevel, int maxLevel, String emoji, Color color) {
    final int userLevel = widget.userData?.data?.userLevel ?? 1;
    bool isUnlocked = userLevel >= minLevel;
    
    return SizedBox(
      height: 90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LevelUtils.formatLevelRange(minLevel, maxLevel),
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: FontRes.fNSfUiRegular,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                isUnlocked ? Icons.lock_open : Icons.lock,
                size: 12,
                color: isUnlocked ? Colors.green : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarDecorationsSection() {
    final int userLevel = widget.userData?.data?.userLevel ?? 1;
    
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Avatar Decoration',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: FontRes.fNSfUiBold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.9,
            children: [
              _buildAvatarFrame(1, 9),
              _buildAvatarFrame(10, 19),
              _buildAvatarFrame(20, 29),
              _buildAvatarFrame(30, 39),
              _buildAvatarFrame(40, 49),
              _buildAvatarFrame(50, 50),
              // Add empty containers for remaining grid spaces
              // const SizedBox(),
              // const SizedBox(),
              // const SizedBox(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFrame(int minLevel, int maxLevel) {
    final int userLevel = widget.userData?.data?.userLevel ?? 1;
    bool isUnlocked = userLevel >= minLevel;
    String initial = widget.userData?.data?.fullName?.substring(0, 1).toUpperCase() ?? 'N';
    String userProfileUrl = '${ConstRes.itemBaseUrl}${widget.userData?.data?.userProfile ?? ''}';
    
    return SizedBox(
      height: 115,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Use the improved getProfileWithFrame method with appropriate sizing
          Opacity(
            opacity: isUnlocked ? 1.0 : 0.5, // Dim locked frames
            child: LevelUtils.getProfileWithFrame(
              userProfileUrl: userProfileUrl,
              level: minLevel, // Use the minimum level for this frame
              initialText: initial,
              frameSize: 80, // Smaller size for the grid display
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LevelUtils.formatLevelRange(minLevel, maxLevel),
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: FontRes.fNSfUiRegular,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                isUnlocked ? Icons.lock_open : Icons.lock,
                size: 12,
                color: isUnlocked ? Colors.green : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEntryEffectsSection() {
    final int userLevel = widget.userData?.data?.userLevel ?? 1;
    final bool hasEntryEffect = userLevel >= 30;
    String username = widget.userData?.data?.userName ?? 'username';
    
    // Use static values instead of dynamic ones
    const String staticEmoji = "💫"; // Star emoji for level 30
    const int staticLevel = 30;
    final Color staticColor = Colors.purple; // Purple color for level 30
    
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Entry Effect',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: FontRes.fNSfUiBold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('${ConstRes.itemBaseUrl}entry_effect.png'),
                fit: BoxFit.cover,
              ),
              // borderRadius: BorderRadius.circular(10),
              // border: Border.all(
              //   color: hasEntryEffect ? Colors.amber : Colors.grey.shade300,
              //   width: 1,
              // ),
            ),
            child: Stack(
              children: [
                // Main content
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Level badge with emoji - static content
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: staticColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              staticEmoji,
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              "$staticLevel",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Username joined text
                      Text(
                        "@$username joined",
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: FontRes.fNSfUiMedium,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Lv 30-50',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: FontRes.fNSfUiRegular,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                hasEntryEffect ? Icons.lock_open : Icons.lock,
                size: 14,
                color: hasEntryEffect ? Colors.green : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelNotesSection() {
    final int userLevel = widget.userData?.data?.userLevel ?? 1;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Notes',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: FontRes.fNSfUiBold,
            ),
          ),
          SizedBox(height: 16),
          _LevelNote(
            index: 1,
            text: 'All Coins spent on LiveTok will contribute to your Level.',
          ),
          SizedBox(height: 16),
          _LevelNote(
            index: 2,
            text: 'When you stop sending gifts for 14 days, the avatar decoration and entry effect will be unavailable. You can reactivate them by sending a gift in any Live.',
          ),
          SizedBox(height: 16),
          _LevelNote(
            index: 3,
            text: 'If gifts sent to a host were returned, your Level progress will be reduced accordingly. You can still send the returned Coins to re-level up.',
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _LevelNote extends StatelessWidget {
  final int index;
  final String text;

  const _LevelNote({
    Key? key,
    required this.index,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$index. ',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: FontRes.fNSfUiMedium,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: FontRes.fNSfUiRegular,
            ),
          ),
        ),
      ],
    );
  }
} 