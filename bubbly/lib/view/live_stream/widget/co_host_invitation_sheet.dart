import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bubbly/modal/user/user.dart';
import 'package:bubbly/modal/live_stream/live_stream.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/font_res.dart';

class CoHostInvitationSheet extends StatelessWidget {
  final String roomId;
  final Function(UserData) onInviteUser;
  final List<LiveStreamComment> commentList;

  const CoHostInvitationSheet({
    Key? key,
    required this.roomId,
    required this.onInviteUser,
    required this.commentList,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract unique users from comment list
    final Map<int, LiveStreamComment> uniqueUsers = {};
    for (var comment in commentList) {
      if (comment.userId != null && comment.commentType != 'host') {
        uniqueUsers[comment.userId!] = comment;
      }
    }
    
    final List<LiveStreamComment> audienceUsers = uniqueUsers.values.toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Invite Co-Host',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: audienceUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No viewers yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontFamily: FontRes.fNSfUiMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Viewers will appear here when they join your live stream',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: audienceUsers.length,
                    itemBuilder: (context, index) {
                      final comment = audienceUsers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 20,
                          child: comment.userImage != null && comment.userImage!.isNotEmpty
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: comment.userImage!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[300],
                                      child: Icon(Icons.person, color: Colors.grey[600]),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[300],
                                      child: Icon(Icons.person, color: Colors.grey[600]),
                                    ),
                                  ),
                                )
                              : Icon(Icons.person, color: Colors.grey[600]),
                        ),
                        title: Text(
                          comment.fullName ?? comment.userName ?? 'User ${comment.userId}',
                          style: const TextStyle(
                            fontFamily: FontRes.fNSfUiSemiBold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Online',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            // Create UserData from comment
                            final user = UserData(
                              userId: comment.userId,
                              userName: comment.userName,
                              fullName: comment.fullName,
                              userProfile: comment.userImage,
                              isVerify: comment.isVerify == true ? 1 : 0,
                            );
                            onInviteUser(user);
                            Get.back();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorRes.colorTheme,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Invite',
                            style: TextStyle(
                              fontFamily: FontRes.fNSfUiMedium,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

