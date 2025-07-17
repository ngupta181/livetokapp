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
  CollectionReference get _liveStreamUserCollection => 
      _firestore.collection('liveStreamUser');

  DocumentReference _getLiveStreamUserDoc(String userId) => 
      _liveStreamUserCollection.doc(userId);

  CollectionReference _getPkBattleCollection(String userId) => 
      _getLiveStreamUserDoc(userId).collection('Pk_battle');

  DocumentReference _getPkBattleDoc(String userId) => 
      _getPkBattleCollection(userId).doc('battle_data'); // Assuming a single battle document per user

  // Livestream Operations (now under Pk_battle sub-collection)
  Future<void> createLivestream(Livestream livestream) async {
    try {
      await _getPkBattleDoc(livestream.hostId ?? '').set(livestream.toFireStore());
      log('Livestream created: ${livestream.roomID}');
    } catch (e) {
      log('Error creating livestream: $e');
      rethrow;
    }
  }

  Future<void> updateLivestream(String userId, Map<String, dynamic> updates) async {
    try {
      await _getPkBattleDoc(userId).update(updates);
      log('Livestream updated for user: $userId');
    } catch (e) {
      log('Error updating livestream: $e');
      rethrow;
    }
  }

  Future<Livestream?> getLivestream(String userId) async {
    try {
      final doc = await _getPkBattleDoc(userId).get();
      if (doc.exists) {
        return Livestream.fromFireStore(doc as DocumentSnapshot<Map<String, dynamic>>, null);
      }
      return null;
    } catch (e) {
      log('Error getting livestream: $e');
      return null;
    }
  }

  Stream<Livestream?> watchLivestream(String userId) {
    return _getPkBattleDoc(userId)
        .withConverter<Livestream>(
          fromFirestore: (snapshot, _) => Livestream.fromFireStore(snapshot, null),
          toFirestore: (livestream, _) => livestream.toFireStore(),
        )
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  // User State Operations (now under user document)
  Future<void> updateUserState(String userId, String userStateId, Map<String, dynamic> updates) async {
    try {
      await _getLiveStreamUserDoc(userId).collection(PKBattleConfig.userStateSubCollection).doc(userStateId).update(updates);
      log('User state updated: $userId/$userStateId');
    } catch (e) {
      log('Error updating user state: $e');
      rethrow;
    }
  }

  Future<void> setUserState(String userId, LivestreamUserState userState) async {
    try {
      await _getLiveStreamUserDoc(userId)
          .collection(PKBattleConfig.userStateSubCollection)
          .doc(userState.userId)
          .set(userState.toFireStore());
      log('User state set: $userId/${userState.userId}');
    } catch (e) {
      log('Error setting user state: $e');
      rethrow;
    }
  }

  Future<LivestreamUserState?> getUserState(String userId, String userStateId) async {
    try {
      final doc = await _getLiveStreamUserDoc(userId).collection(PKBattleConfig.userStateSubCollection).doc(userStateId).get();
      if (doc.exists) {
        return LivestreamUserState.fromFireStore(doc as DocumentSnapshot<Map<String, dynamic>>, null);
      }
      return null;
    } catch (e) {
      log('Error getting user state: $e');
      return null;
    }
  }

  Stream<List<LivestreamUserState>> watchUserStates(String userId) {
    return _getLiveStreamUserDoc(userId)
        .collection(PKBattleConfig.userStateSubCollection)
        .withConverter<LivestreamUserState>(
          fromFirestore: (snapshot, _) => LivestreamUserState.fromFireStore(snapshot, null),
          toFirestore: (userState, _) => userState.toFireStore(),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Comment Operations (now under user document)
  Future<void> addComment(String userId, LivestreamComment comment) async {
    try {
      await _getLiveStreamUserDoc(userId).collection(PKBattleConfig.commentsSubCollection).add(comment.toFireStore());
      log('Comment added: $userId');
    } catch (e) {
      log('Error adding comment: $e');
      rethrow;
    }
  }

  Stream<List<LivestreamComment>> watchComments(String userId, {int limit = 50}) {
    return _getLiveStreamUserDoc(userId)
        .collection(PKBattleConfig.commentsSubCollection)
        .withConverter<LivestreamComment>(
          fromFirestore: (snapshot, _) => LivestreamComment.fromFireStore(snapshot, null),
          toFirestore: (comment, _) => comment.toFireStore(),
        )
        .orderBy("createdAt", descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<Livestream?> getLivestreamStream(String userId) {
    return _getPkBattleDoc(userId)
        .withConverter<Livestream>(
          fromFirestore: (snapshot, _) => Livestream.fromFireStore(snapshot, null),
          toFirestore: (livestream, _) => livestream.toFireStore(),
        )
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  Stream<List<LivestreamUserState>> getUserStatesStream(String userId) {
    return _getLiveStreamUserDoc(userId)
        .collection(PKBattleConfig.userStateSubCollection)
        .withConverter<LivestreamUserState>(
          fromFirestore: (snapshot, _) => LivestreamUserState.fromFireStore(snapshot, null),
          toFirestore: (userState, _) => userState.toFireStore(),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> initiateBattle(String userId) async {
    try {
      final updates = {
        PKBattleConfig.battleTypeField: BattleType.waiting.value,
        PKBattleConfig.battleCreatedAtField: DateTime.now().millisecondsSinceEpoch,
        PKBattleConfig.battleDurationField: PKBattleConfig.battleDurationInMinutes,
        PKBattleConfig.typeField: LivestreamType.pk_battle.value,
        'title': 'PK Battle',
      };

      await updateLivestream(userId, updates);
      log("Battle initiated for user: $userId");
    } catch (e) {
      log("Error initiating battle: $e");
      rethrow;
    }
  }

  Future<void> startBattleRunning(String userId) async {
    try {
      await updateLivestream(userId, {
        PKBattleConfig.battleTypeField: BattleType.running.value,
        PKBattleConfig.battleStartedAtField: DateTime.now().millisecondsSinceEpoch,
      });
      log("Battle running for user: $userId");
    } catch (e) {
      log("Error starting battle running: $e");
      rethrow;
    }
  }

  Future<void> endBattle(String userId, String? winnerId) async {
    try {
      final winner = winnerId != null ? {'userId': winnerId} : null;
      await updateLivestream(userId, {
        PKBattleConfig.battleTypeField: BattleType.ended.value,
        PKBattleConfig.typeField: LivestreamType.normal.value,
        PKBattleConfig.battleWinnerField: winner,
      });
      log("Battle ended for user: $userId");
    } catch (e) {
      log("Error ending battle: $e");
      rethrow;
    }
  }

  Future<void> resetBattleState(String userId) async {
    try {
      await updateLivestream(userId, {
        PKBattleConfig.battleTypeField: BattleType.initiate.value,
        PKBattleConfig.battleWinnerField: null,
        PKBattleConfig.battleStartedAtField: null,
        PKBattleConfig.battleCreatedAtField: null,
      });
      log("Battle state reset for user: $userId");
    } catch (e) {
      log("Error resetting battle state: $e");
      rethrow;
    }
  }

  // Battle-specific Operations
  Future<void> startBattle(String userId, {String? coHostId}) async {
    try {
      final updates = {
        PKBattleConfig.battleTypeField: BattleType.waiting.value,
        PKBattleConfig.battleCreatedAtField: DateTime.now().millisecondsSinceEpoch,
        PKBattleConfig.battleDurationField: PKBattleConfig.battleDurationInMinutes,
        PKBattleConfig.typeField: LivestreamType.pk_battle.value,
        'title': 'PK Battle',
      };

      if (coHostId != null) {
        updates[PKBattleConfig.coHostIdsField] = [coHostId];
      }

      await updateLivestream(userId, updates);
      log('Battle started for user: $userId');
    } catch (e) {
      log('Error starting battle: $e');
      rethrow;
    }
  }

  Future<void> updateBattleType(String userId, BattleType battleType) async {
    try {
      await updateLivestream(userId, {
        PKBattleConfig.battleTypeField: battleType.value,
      });
      log('Battle type updated: $userId -> ${battleType.value}');
    } catch (e) {
      log('Error updating battle type: $e');
      rethrow;
    }
  }

  Future<void> resetBattleCoins(String userId, List<String> userIds) async {
    try {
      final batch = _firestore.batch();
      
      for (String userStateId in userIds) {
        final userStateRef = _getLiveStreamUserDoc(userId).collection(PKBattleConfig.userStateSubCollection).doc(userStateId);
        batch.update(userStateRef, {
          PKBattleConfig.currentBattleCoinField: 0,
        });
      }
      
      await batch.commit();
      log('Battle coins reset for user: $userId');
    } catch (e) {
      log('Error resetting battle coins: $e');
      rethrow;
    }
  }

  // Gift Operations
  Future<void> sendGift({
    required String userId,
    required String senderId,
    required String receiverId,
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
        roomId: userId,
      );

      final commentRef = _getLiveStreamUserDoc(userId).collection(PKBattleConfig.commentsSubCollection).doc();
      batch.set(commentRef, giftComment.toFireStore());

      // Update receiver's coins based on gift type
      final receiverStateRef = _getLiveStreamUserDoc(userId).collection(PKBattleConfig.userStateSubCollection).doc(receiverId);
      
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
      log('Gift sent: $userId, $senderId -> $receiverId, $coinValue coins');
    } catch (e) {
      log('Error sending gift: $e');
      rethrow;
    }
  }

  // Utility Methods
  Future<void> incrementWatchingCount(String userId) async {
    try {
      await updateLivestream(userId, {
        PKBattleConfig.watchingCountField: FieldValue.increment(1),
      });
    } catch (e) {
      log('Error incrementing watching count: $e');
    }
  }

  Future<void> decrementWatchingCount(String userId) async {
    try {
      await updateLivestream(userId, {
        PKBattleConfig.watchingCountField: FieldValue.increment(-1),
      });
    } catch (e) {
      log('Error decrementing watching count: $e');
    }
  }

  Future<void> deleteLivestream(String userId) async {
    try {
      // Delete all subcollections first
      await _deleteCollection(_getLiveStreamUserDoc(userId).collection(PKBattleConfig.userStateSubCollection));
      await _deleteCollection(_getLiveStreamUserDoc(userId).collection(PKBattleConfig.commentsSubCollection));
      await _deleteCollection(_getPkBattleCollection(userId));
      
      // Delete the main document
      await _getLiveStreamUserDoc(userId).delete();
      log('Livestream deleted for user: $userId');
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
  Future<Map<String, dynamic>> calculateBattleWinner(String userId) async {
    try {
      final userStates = await _getLiveStreamUserDoc(userId)
          .collection(PKBattleConfig.userStateSubCollection)
          .where('type', whereIn: [PKBattleConfig.userTypeHost, PKBattleConfig.userTypeCoHost])
          .get();

      int maxCoins = 0;
      String? winnerId;
      Map<String, int> userCoins = {};

      for (var doc in userStates.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userStateId = data['userId'] as String;
        final coins = data[PKBattleConfig.currentBattleCoinField] as int? ?? 0;
        
        userCoins[userStateId] = coins;
        
        if (coins > maxCoins) {
          maxCoins = coins;
          winnerId = userStateId;
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
        'userCoins': <String, int>{},
      };
    }
  }
}


