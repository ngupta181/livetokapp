import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubbly/modal/pk_battle/livestream.dart';
import 'package:bubbly/modal/pk_battle/livestream_user_state.dart';
import 'package:bubbly/modal/pk_battle/livestream_comment.dart';
import 'package:bubbly/modal/pk_battle/livestream_type.dart';
import 'package:bubbly/modal/pk_battle/battle_type.dart';
import 'package:bubbly/modal/pk_battle/gift.dart';
import 'package:bubbly/utils/pk_battle_config.dart';

class PKBattleService {
  static final PKBattleService _instance = PKBattleService._internal();
  factory PKBattleService() => _instance;
  PKBattleService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _liveStreamsCollection => 
      _firestore.collection(PKBattleConfig.liveStreamsCollection);

  DocumentReference _getLiveStreamDoc(String roomId) => 
      _liveStreamsCollection.doc(roomId);

  CollectionReference _getUserStateCollection(String roomId) => 
      _getLiveStreamDoc(roomId).collection(PKBattleConfig.userStateSubCollection);

  CollectionReference _getCommentsCollection(String roomId) => 
      _getLiveStreamDoc(roomId).collection(PKBattleConfig.commentsSubCollection);

  // Livestream Operations
  Future<void> createLivestream(Livestream livestream) async {
    try {
      await _getLiveStreamDoc(livestream.roomID!).set(livestream.toFireStore());
      log('Livestream created: ${livestream.roomID}');
    } catch (e) {
      log('Error creating livestream: $e');
      rethrow;
    }
  }

  Future<void> updateLivestream(String roomId, Map<String, dynamic> updates) async {
    try {
      await _getLiveStreamDoc(roomId).update(updates);
      log('Livestream updated: $roomId');
    } catch (e) {
      log('Error updating livestream: $e');
      rethrow;
    }
  }

  Future<Livestream?> getLivestream(String roomId) async {
    try {
      final doc = await _getLiveStreamDoc(roomId).get();
      if (doc.exists) {
        return Livestream.fromFireStore(doc as DocumentSnapshot<Map<String, dynamic>>, null);
      }
      return null;
    } catch (e) {
      log('Error getting livestream: $e');
      return null;
    }
  }

  Stream<Livestream?> watchLivestream(String roomId) {
    return _getLiveStreamDoc(roomId)
        .withConverter<Livestream>(
          fromFirestore: (snapshot, _) => Livestream.fromFireStore(snapshot, null),
          toFirestore: (livestream, _) => livestream.toFireStore(),
        )
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  // User State Operations
  Future<void> updateUserState(String roomId, int userId, Map<String, dynamic> updates) async {
    try {
      await _getUserStateCollection(roomId).doc(userId.toString()).update(updates);
      log('User state updated: $roomId/$userId');
    } catch (e) {
      log('Error updating user state: $e');
      rethrow;
    }
  }

  Future<void> setUserState(String roomId, LivestreamUserState userState) async {
    try {
      await _getUserStateCollection(roomId)
          .doc(userState.userId.toString())
          .set(userState.toFireStore());
      log('User state set: $roomId/${userState.userId}');
    } catch (e) {
      log('Error setting user state: $e');
      rethrow;
    }
  }

  Future<LivestreamUserState?> getUserState(String roomId, int userId) async {
    try {
      final doc = await _getUserStateCollection(roomId).doc(userId.toString()).get();
      if (doc.exists) {
        return LivestreamUserState.fromFireStore(doc as DocumentSnapshot<Map<String, dynamic>>, null);
      }
      return null;
    } catch (e) {
      log('Error getting user state: $e');
      return null;
    }
  }

  Stream<List<LivestreamUserState>> watchUserStates(String roomId) {
    return _getUserStateCollection(roomId)
        .withConverter<LivestreamUserState>(
          fromFirestore: (snapshot, _) => LivestreamUserState.fromFireStore(snapshot, null),
          toFirestore: (userState, _) => userState.toFireStore(),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Comment Operations
  Future<void> addComment(String roomId, LivestreamComment comment) async {
    try {
      await _getCommentsCollection(roomId).add(comment.toFireStore());
      log('Comment added: $roomId');
    } catch (e) {
      log('Error adding comment: $e');
      rethrow;
    }
  }

  Stream<List<LivestreamComment>> watchComments(String roomId, {int limit = 50}) {
    return _getCommentsCollection(roomId)
        .withConverter<LivestreamComment>(
          fromFirestore: (snapshot, _) => LivestreamComment.fromFireStore(snapshot, null),
          toFirestore: (comment, _) => comment.toFireStore(),
        )
        .orderBy("createdAt", descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<Livestream?> getLivestreamStream(String roomId) {
    return _getLiveStreamDoc(roomId)
        .withConverter<Livestream>(
          fromFirestore: (snapshot, _) => Livestream.fromFireStore(snapshot, null),
          toFirestore: (livestream, _) => livestream.toFireStore(),
        )
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  Stream<List<LivestreamUserState>> getUserStatesStream(String roomId) {
    return _getUserStateCollection(roomId)
        .withConverter<LivestreamUserState>(
          fromFirestore: (snapshot, _) => LivestreamUserState.fromFireStore(snapshot, null),
          toFirestore: (userState, _) => userState.toFireStore(),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> initiateBattle(String roomId) async {
    try {
      final updates = {
        PKBattleConfig.battleTypeField: BattleType.waiting.value,
        PKBattleConfig.battleCreatedAtField: DateTime.now().millisecondsSinceEpoch,
        PKBattleConfig.battleDurationField: PKBattleConfig.battleDurationInMinutes,
        PKBattleConfig.typeField: LivestreamType.pk_battle.value,
      };

      await updateLivestream(roomId, updates);
      log("Battle initiated: $roomId");
    } catch (e) {
      log("Error initiating battle: $e");
      rethrow;
    }
  }

  Future<void> startBattleRunning(String roomId) async {
    try {
      await updateLivestream(roomId, {
        PKBattleConfig.battleTypeField: BattleType.running.value,
        PKBattleConfig.battleStartedAtField: DateTime.now().millisecondsSinceEpoch,
      });
      log("Battle running: $roomId");
    } catch (e) {
      log("Error starting battle running: $e");
      rethrow;
    }
  }

  Future<void> endBattle(String roomId, String? winnerId) async {
    try {
      final winner = winnerId != null ? {'userId': winnerId} : null;
      await updateLivestream(roomId, {
        PKBattleConfig.battleTypeField: BattleType.ended.value,
        PKBattleConfig.typeField: LivestreamType.normal.value,
        PKBattleConfig.battleWinnerField: winner,
      });
      log("Battle ended: $roomId");
    } catch (e) {
      log("Error ending battle: $e");
      rethrow;
    }
  }

  Future<void> resetBattleState(String roomId) async {
    try {
      await updateLivestream(roomId, {
        PKBattleConfig.battleTypeField: BattleType.initiate.value,
        PKBattleConfig.battleWinnerField: null,
        PKBattleConfig.battleStartedAtField: null,
        PKBattleConfig.battleCreatedAtField: null,
      });
      log("Battle state reset: $roomId");
    } catch (e) {
      log("Error resetting battle state: $e");
      rethrow;
    }
  }

  // Battle-specific Operations
  Future<void> startBattle(String roomId, {int? coHostId}) async {
    try {
      final updates = {
        PKBattleConfig.battleTypeField: BattleType.waiting.value,
        PKBattleConfig.battleCreatedAtField: DateTime.now().millisecondsSinceEpoch,
        PKBattleConfig.battleDurationField: PKBattleConfig.battleDurationInMinutes,
        PKBattleConfig.typeField: LivestreamType.battle.value,
      };

      if (coHostId != null) {
        updates[PKBattleConfig.coHostIdsField] = [coHostId];
      }

      await updateLivestream(roomId, updates);
      log('Battle started: $roomId');
    } catch (e) {
      log('Error starting battle: $e');
      rethrow;
    }
  }

  Future<void> updateBattleType(String roomId, BattleType battleType) async {
    try {
      await updateLivestream(roomId, {
        PKBattleConfig.battleTypeField: battleType.value,
      });
      log('Battle type updated: $roomId -> ${battleType.value}');
    } catch (e) {
      log('Error updating battle type: $e');
      rethrow;
    }
  }

  Future<void> resetBattleCoins(String roomId, List<int> userIds) async {
    try {
      final batch = _firestore.batch();
      
      for (int userId in userIds) {
        final userStateRef = _getUserStateCollection(roomId).doc(userId.toString());
        batch.update(userStateRef, {
          PKBattleConfig.currentBattleCoinField: 0,
        });
      }
      
      await batch.commit();
      log('Battle coins reset: $roomId');
    } catch (e) {
      log('Error resetting battle coins: $e');
      rethrow;
    }
  }

  // Gift Operations
  Future<void> sendGift({
    required String roomId,
    required int senderId,
    required int receiverId,
    required int giftId,
    required int coinValue,
    required GiftType giftType,
    String? comment,
  }) async {
    try {
      final batch = _firestore.batch();

      // Add gift comment
      final giftComment = LivestreamComment(
        comment: comment,
        type: LivestreamCommentType.gift,
        giftId: giftId,
        receiverId: receiverId,
        senderId: senderId,
        roomId: roomId,
      );

      final commentRef = _getCommentsCollection(roomId).doc();
      batch.set(commentRef, giftComment.toFireStore());

      // Update receiver's coins based on gift type
      final receiverStateRef = _getUserStateCollection(roomId).doc(receiverId.toString());
      
      if (giftType == GiftType.battle) {
        batch.update(receiverStateRef, {
          PKBattleConfig.currentBattleCoinField: FieldValue.increment(coinValue),
          PKBattleConfig.totalBattleCoinField: FieldValue.increment(coinValue),
        });
      } else if (giftType == GiftType.livestream) {
        batch.update(receiverStateRef, {
          PKBattleConfig.liveCoinField: FieldValue.increment(coinValue),
        });
      }

      await batch.commit();
      log('Gift sent: $roomId, $senderId -> $receiverId, $coinValue coins');
    } catch (e) {
      log('Error sending gift: $e');
      rethrow;
    }
  }

  // Utility Methods
  Future<void> incrementWatchingCount(String roomId) async {
    try {
      await updateLivestream(roomId, {
        PKBattleConfig.watchingCountField: FieldValue.increment(1),
      });
    } catch (e) {
      log('Error incrementing watching count: $e');
    }
  }

  Future<void> decrementWatchingCount(String roomId) async {
    try {
      await updateLivestream(roomId, {
        PKBattleConfig.watchingCountField: FieldValue.increment(-1),
      });
    } catch (e) {
      log('Error decrementing watching count: $e');
    }
  }

  Future<void> deleteLivestream(String roomId) async {
    try {
      // Delete all subcollections first
      await _deleteCollection(_getUserStateCollection(roomId));
      await _deleteCollection(_getCommentsCollection(roomId));
      
      // Delete the main document
      await _getLiveStreamDoc(roomId).delete();
      log('Livestream deleted: $roomId');
    } catch (e) {
      log('Error deleting livestream: $e');
      rethrow;
    }
  }

  Future<void> _deleteCollection(CollectionReference collection) async {
    final batch = _firestore.batch();
    final snapshots = await collection.get();
    
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  // Battle Winner Calculation
  Future<Map<String, dynamic>> calculateBattleWinner(String roomId) async {
    try {
      final userStates = await _getUserStateCollection(roomId)
          .where('type', whereIn: [PKBattleConfig.userTypeHost, PKBattleConfig.userTypeCoHost])
          .get();

      int maxCoins = 0;
      int? winnerId;
      Map<int, int> userCoins = {};

      for (var doc in userStates.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId'] as int;
        final coins = data[PKBattleConfig.currentBattleCoinField] as int? ?? 0;
        
        userCoins[userId] = coins;
        
        if (coins > maxCoins) {
          maxCoins = coins;
          winnerId = userId;
        }
      }

      return {
        'winnerId': winnerId,
        'maxCoins': maxCoins,
        'userCoins': userCoins,
      };
    } catch (e) {
      log('Error calculating battle winner: $e');
      return {
        'winnerId': null,
        'maxCoins': 0,
        'userCoins': <int, int>{},
      };
    }
  }
}

