import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubbly/modal/user/user.dart';
import 'package:bubbly/utils/firebase_res.dart';
import 'package:bubbly/utils/session_manager.dart';

class CoHostInvitationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final SessionManager _sessionManager = SessionManager();

  // Send co-host invitation
  static Future<bool> sendInvitation({
    required String roomId,
    required UserData invitedUser,
    required int hostUserId,
  }) async {
    try {
      await _sessionManager.initPref();
      final currentUser = _sessionManager.getUser();
      
      if (currentUser == null) {
        throw Exception('Host user not found');
      }

      // Create invitation document
      final invitationData = {
        'roomId': roomId,
        'hostUserId': hostUserId,
        'hostName': currentUser.data?.fullName ?? currentUser.data?.userName ?? 'Host',
        'hostImage': currentUser.data?.userProfile ?? '',
        'invitedUserId': invitedUser.userId,
        'invitedUserName': invitedUser.userName,
        'invitedUserFullName': invitedUser.fullName,
        'invitedUserImage': invitedUser.userProfile,
        'status': 'pending', // pending, accepted, declined, expired
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(Duration(minutes: 5)).millisecondsSinceEpoch,
        'type': 'co_host_invitation',
      };

      // Store invitation in user's personal invitations collection
      await _firestore
          .collection('users')
          .doc(invitedUser.userId.toString())
          .collection('invitations')
          .doc('${roomId}_cohost')
          .set(invitationData);

      // Also store in the livestream's invitations subcollection for host tracking
      await _firestore
          .collection(FirebaseRes.liveStreamUser)
          .doc(roomId)
          .collection('co_host_invitations')
          .doc(invitedUser.userId.toString())
          .set(invitationData);

      print('Co-host invitation sent successfully to user ${invitedUser.userId}');
      return true;
    } catch (e) {
      print('Error sending co-host invitation: $e');
      return false;
    }
  }

  // Listen for invitations for current user
  static Stream<QuerySnapshot> listenForInvitations(int userId) {
    return _firestore
        .collection('users')
        .doc(userId.toString())
        .collection('invitations')
        .where('status', isEqualTo: 'pending')
        .where('type', isEqualTo: 'co_host_invitation')
        .snapshots();
  }

  // Accept invitation
  static Future<bool> acceptInvitation({
    required String roomId,
    required int userId,
  }) async {
    try {
      // Update invitation status
      await _firestore
          .collection('users')
          .doc(userId.toString())
          .collection('invitations')
          .doc('${roomId}_cohost')
          .update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Update in livestream collection as well
      await _firestore
          .collection(FirebaseRes.liveStreamUser)
          .doc(roomId)
          .collection('co_host_invitations')
          .doc(userId.toString())
          .update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Add user to co-hosts collection
      await _sessionManager.initPref();
      final currentUser = _sessionManager.getUser();
      
      if (currentUser != null) {
        await _firestore
            .collection(FirebaseRes.liveStreamUser)
            .doc(roomId)
            .collection('co_hosts')
            .doc(userId.toString())
            .set({
          'userId': userId,
          'userName': currentUser.data?.userName,
          'fullName': currentUser.data?.fullName,
          'userImage': currentUser.data?.userProfile,
          'joinedAt': FieldValue.serverTimestamp(),
          'status': 'active',
        });
      }

      print('Co-host invitation accepted for room $roomId');
      return true;
    } catch (e) {
      print('Error accepting co-host invitation: $e');
      return false;
    }
  }

  // Decline invitation
  static Future<bool> declineInvitation({
    required String roomId,
    required int userId,
  }) async {
    try {
      // Update invitation status
      await _firestore
          .collection('users')
          .doc(userId.toString())
          .collection('invitations')
          .doc('${roomId}_cohost')
          .update({
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
      });

      // Update in livestream collection as well
      await _firestore
          .collection(FirebaseRes.liveStreamUser)
          .doc(roomId)
          .collection('co_host_invitations')
          .doc(userId.toString())
          .update({
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
      });

      print('Co-host invitation declined for room $roomId');
      return true;
    } catch (e) {
      print('Error declining co-host invitation: $e');
      return false;
    }
  }

  // Remove co-host
  static Future<bool> removeCoHost({
    required String roomId,
    required int userId,
  }) async {
    try {
      // Remove from co-hosts collection
      await _firestore
          .collection(FirebaseRes.liveStreamUser)
          .doc(roomId)
          .collection('co_hosts')
          .doc(userId.toString())
          .delete();

      // Update invitation status
      await _firestore
          .collection(FirebaseRes.liveStreamUser)
          .doc(roomId)
          .collection('co_host_invitations')
          .doc(userId.toString())
          .update({
        'status': 'removed',
        'removedAt': FieldValue.serverTimestamp(),
      });

      print('Co-host removed from room $roomId');
      return true;
    } catch (e) {
      print('Error removing co-host: $e');
      return false;
    }
  }

  // Listen for co-host status in a room (for host to track)
  static Stream<QuerySnapshot> listenForCoHosts(String roomId) {
    return _firestore
        .collection(FirebaseRes.liveStreamUser)
        .doc(roomId)
        .collection('co_hosts')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // Clean up expired invitations
  static Future<void> cleanupExpiredInvitations() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // This would typically be run as a cloud function
      // For now, we'll just mark them as expired when checking
      print('Cleanup expired invitations (implement as cloud function)');
    } catch (e) {
      print('Error cleaning up expired invitations: $e');
    }
  }
}

