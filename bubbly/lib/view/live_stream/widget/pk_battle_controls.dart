import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bubbly/modal/pk_battle/battle_type.dart';
import 'package:bubbly/modal/live_stream/live_stream.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:bubbly/view/pk_battle/controllers/pk_battle_controller.dart';
import 'package:bubbly/view/live_stream/widget/co_host_invitation_sheet.dart';
import 'package:bubbly/services/co_host_invitation_service.dart';
import 'package:bubbly/view/live_stream/model/broad_cast_screen_view_model.dart';

class PKBattleControls extends StatelessWidget {
  final String channelName;
  final VoidCallback? onCoHostJoined;
  final List<LiveStreamComment> commentList;
  final bool isHost;
  final int? remoteUserId;
  final BroadCastScreenViewModel model;

  const PKBattleControls({
    Key? key,
    required this.channelName,
    this.onCoHostJoined,
    required this.commentList,
    this.isHost = true,
    this.remoteUserId,
    required this.model,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isHost) return SizedBox.shrink();

    return GetBuilder<PKBattleController>(
      init: PKBattleController(channelName),
      builder: (controller) {
        // Debug information
        print('PKBattleControls: coHostID = ${model.coHostID}');
        print('PKBattleControls: battleType = ${controller.battleType}');
        print('PKBattleControls: isCoHost = ${model.isCoHost}');
        
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
                  // Always show invite co-host button
                  _buildControlButton(
                    icon: Icons.person_add,
                    label: 'Invite Co-host',
                    onTap: () => _showCoHostInvitationSheet(context),
                    color: ColorRes.colorTheme,
                  ),
                  
                  // Always show PK Battle button for host - simplified logic
                  if (controller.battleType == BattleType.waiting) ...[
                    _buildControlButton(
                      icon: Icons.timer,
                      label: 'Battle Starting...',
                      onTap: null,
                      color: Colors.orange,
                    ),
                  ] else if (controller.battleType == BattleType.running) ...[
                    _buildControlButton(
                      icon: Icons.stop,
                      label: 'End Battle',
                      onTap: () => _endPKBattle(controller),
                      color: Colors.red,
                    ),
                  ] else ...[
                    // Default: Always show Start PK Battle button when not in waiting/running state
                    _buildControlButton(
                      icon: Icons.sports_mma,
                      label: 'Start PK Battle',
                      onTap: () => _startPKBattle(controller),
                      color: Colors.red,
                    ),
                  ],
                  
                  // Show remove co-host button only when co-host is present
                  if (model.coHostID != null) ...[
                    _buildControlButton(
                      icon: Icons.person_remove,
                      label: 'Remove Co-host',
                      onTap: () => model.removeCoHost(),
                      color: Colors.red,
                    ),
                  ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: onTap != null ? color : color.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontFamily: FontRes.fNSfUiSemiBold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCoHostInvitationSheet(BuildContext context) {
    Get.bottomSheet(
      CoHostInvitationSheet(
        roomId: channelName,
        commentList: commentList,
        onInviteUser: (user) async {
          // Handle co-host invitation using the service
          print('Sending co-host invitation to: ${user.userId}');
          
          try {
            final sessionManager = SessionManager();
            await sessionManager.initPref();
            final currentUser = sessionManager.getUser();
            
            if (currentUser?.data?.userId != null) {
              final success = await CoHostInvitationService.sendInvitation(
                roomId: channelName,
                invitedUser: user,
                hostUserId: currentUser!.data!.userId!,
              );
              
              if (success) {
                Get.snackbar(
                  'Invitation Sent',
                  'Co-host invitation sent to ${user.fullName ?? user.userName}',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  duration: Duration(seconds: 3),
                );
                
                if (onCoHostJoined != null) {
                  onCoHostJoined!();
                }
              } else {
                Get.snackbar(
                  'Error',
                  'Failed to send invitation. Please try again.',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  duration: Duration(seconds: 3),
                );
              }
            } else {
              Get.snackbar(
                'Error',
                'Unable to send invitation. Please check your login status.',
                backgroundColor: Colors.red,
                colorText: Colors.white,
                duration: Duration(seconds: 3),
              );
            }
          } catch (e) {
            print('Error sending invitation: $e');
            Get.snackbar(
              'Error',
              'An error occurred while sending the invitation.',
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: Duration(seconds: 3),
            );
          }
        },
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  void _startPKBattle(PKBattleController controller) {
    Get.dialog(
      AlertDialog(
        title: Text('Start PK Battle'),
        content: Text('Are you ready to start the PK Battle with your co-host?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.initiateBattle();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Start Battle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _endPKBattle(PKBattleController controller) {
    Get.dialog(
      AlertDialog(
        title: Text('End PK Battle'),
        content: Text('Are you sure you want to end the PK Battle?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.endBattle();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('End Battle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }


}

