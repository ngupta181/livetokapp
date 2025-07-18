import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/firebase_res.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:bubbly/view/live_stream/model/broad_cast_screen_view_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class CoHostControls extends StatefulWidget {
  final BroadCastScreenViewModel model;

  const CoHostControls({
    Key? key,
    required this.model,
  }) : super(key: key);

  @override
  State<CoHostControls> createState() => _CoHostControlsState();
}

class _CoHostControlsState extends State<CoHostControls> {
  StreamSubscription<QuerySnapshot>? _notificationStream;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SessionManager _pref = SessionManager();

  @override
  void initState() {
    super.initState();
    if (widget.model.isCoHost) {
      _listenForRemovalNotifications();
    }
  }

  @override
  void dispose() {
    _notificationStream?.cancel();
    super.dispose();
  }

  void _listenForRemovalNotifications() async {
    await _pref.initPref();
    final currentUser = _pref.getUser();
    
    _notificationStream = _db
        .collection(FirebaseRes.liveStreamUser)
        .doc(widget.model.channelName)
        .collection('co_host_notifications')
        .where('userId', isEqualTo: currentUser?.data?.userId)
        .where('type', isEqualTo: 'removed')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.added) {
          _handleRemovalNotification(doc.doc.data() as Map<String, dynamic>);
          // Delete the notification after processing
          doc.doc.reference.delete();
        }
      }
    });
  }

  void _handleRemovalNotification(Map<String, dynamic> notification) {
    // Show notification to user
    Get.snackbar(
      'Removed as Co-Host',
      notification['message'] ?? 'You have been removed as co-host by the host',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: Duration(seconds: 5),
    );

    // Automatically leave co-host mode without confirmation
    _performLeaveCoHost();
  }

  @override
  Widget build(BuildContext context) {
    // Only show for co-hosts
    if (!widget.model.isCoHost) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute/Unmute button
          _buildControlButton(
            icon: widget.model.isMic ? Icons.mic : Icons.mic_off,
            label: widget.model.isMic ? 'Mute' : 'Unmute',
            onTap: () => _toggleMicrophone(),
            color: widget.model.isMic ? ColorRes.colorTheme : Colors.red,
          ),
          
          // Camera toggle button
          _buildControlButton(
            icon: Icons.cameraswitch,
            label: 'Flip Camera',
            onTap: () => _flipCamera(),
            color: ColorRes.colorTheme,
          ),
          
          // Leave co-host button
          _buildControlButton(
            icon: Icons.exit_to_app,
            label: 'Leave Co-Host',
            onTap: () => _leaveCoHost(),
            color: Colors.red,
          ),
        ],
      ),
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
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
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
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontFamily: FontRes.fNSfUiMedium,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleMicrophone() {
    try {
      widget.model.agoraEngine.muteLocalAudioStream(!widget.model.isMic);
      widget.model.isMic = !widget.model.isMic;
      widget.model.notifyListeners();
      
      Get.snackbar(
        widget.model.isMic ? 'Microphone On' : 'Microphone Off',
        widget.model.isMic ? 'Your microphone is now unmuted' : 'Your microphone is now muted',
        backgroundColor: widget.model.isMic ? Colors.green : Colors.orange,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      print('Error toggling microphone: $e');
    }
  }

  void _flipCamera() {
    try {
      widget.model.agoraEngine.switchCamera();
      
      Get.snackbar(
        'Camera Switched',
        'Camera view has been flipped',
        backgroundColor: ColorRes.colorTheme,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      print('Error flipping camera: $e');
    }
  }

  void _leaveCoHost() {
    Get.dialog(
      AlertDialog(
        title: Text('Leave Co-Host'),
        content: Text('Are you sure you want to stop being a co-host? You will return to audience mode.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _performLeaveCoHost();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performLeaveCoHost() async {
    try {
      // Leave current channel as broadcaster
      await widget.model.agoraEngine.leaveChannel();
      
      // Update local state
      widget.model.isCoHost = false;
      widget.model.isHost = false;
      
      // Rejoin as audience
      await widget.model.agoraEngine.setClientRole(role: ClientRoleType.clientRoleAudience);
      await widget.model.agoraEngine.disableVideo();
      
      // Join the channel again as audience
      await widget.model.agoraEngine.joinChannel(
        token: widget.model.agoraToken,
        channelId: widget.model.channelName,
        uid: 0, // Use 0 for auto-assigned UID
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleAudience,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );
      
      widget.model.notifyListeners();
      
      Get.snackbar(
        'Left Co-Host',
        'You are now viewing as audience',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
      
    } catch (e) {
      print('Error leaving co-host: $e');
      Get.snackbar(
        'Error',
        'Failed to leave co-host mode. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    }
  }
}

