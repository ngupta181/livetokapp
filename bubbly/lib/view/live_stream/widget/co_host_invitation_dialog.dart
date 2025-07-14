import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/services/co_host_invitation_service.dart';

class CoHostInvitationDialog extends StatelessWidget {
  final String roomId;
  final String hostName;
  final String? hostImage;
  final int invitedUserId;
  final VoidCallback? onAccepted;
  final VoidCallback? onDeclined;

  const CoHostInvitationDialog({
    Key? key,
    required this.roomId,
    required this.hostName,
    this.hostImage,
    required this.invitedUserId,
    this.onAccepted,
    this.onDeclined,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Host avatar
            CircleAvatar(
              radius: 40,
              child: hostImage != null && hostImage!.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: hostImage!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.person, color: Colors.grey[600], size: 40),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.person, color: Colors.grey[600], size: 40),
                        ),
                      ),
                    )
                  : Icon(Icons.person, color: Colors.grey[600], size: 40),
            ),
            
            const SizedBox(height: 16),
            
            // Invitation title
            Text(
              'Co-Host Invitation',
              style: TextStyle(
                fontSize: 20,
                fontFamily: FontRes.fNSfUiBold,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Invitation message
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontFamily: FontRes.fNSfUiMedium,
                ),
                children: [
                  TextSpan(text: hostName),
                  const TextSpan(text: ' has invited you to be a '),
                  TextSpan(
                    text: 'Co-Host',
                    style: TextStyle(
                      color: ColorRes.colorTheme,
                      fontFamily: FontRes.fNSfUiBold,
                    ),
                  ),
                  const TextSpan(text: ' in their live stream!'),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'You will be able to appear on camera and interact with the audience.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: FontRes.fNSfUiRegular,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                // Decline button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      try {
                        final success = await CoHostInvitationService.declineInvitation(
                          roomId: roomId,
                          userId: invitedUserId,
                        );
                        
                        Get.back();
                        
                        if (success) {
                          Get.snackbar(
                            'Invitation Declined',
                            'You have declined the co-host invitation.',
                            backgroundColor: Colors.orange,
                            colorText: Colors.white,
                            duration: Duration(seconds: 2),
                          );
                          
                          if (onDeclined != null) {
                            onDeclined!();
                          }
                        }
                      } catch (e) {
                        print('Error declining invitation: $e');
                        Get.back();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'Decline',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontFamily: FontRes.fNSfUiMedium,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Accept button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final success = await CoHostInvitationService.acceptInvitation(
                          roomId: roomId,
                          userId: invitedUserId,
                        );
                        
                        Get.back();
                        
                        if (success) {
                          Get.snackbar(
                            'Invitation Accepted',
                            'You are now a co-host! Preparing to join...',
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                            duration: Duration(seconds: 3),
                          );
                          
                          if (onAccepted != null) {
                            onAccepted!();
                          }
                        }
                      } catch (e) {
                        print('Error accepting invitation: $e');
                        Get.back();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorRes.colorTheme,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Accept',
                      style: TextStyle(
                        fontFamily: FontRes.fNSfUiBold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Auto-expire notice
            Text(
              'This invitation will expire in 5 minutes',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontFamily: FontRes.fNSfUiRegular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

