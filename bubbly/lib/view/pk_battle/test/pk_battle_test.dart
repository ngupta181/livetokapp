import 'package:flutter_test/flutter_test.dart';
import 'package:bubbly/modal/pk_battle/livestream.dart';
import 'package:bubbly/modal/pk_battle/livestream_user_state.dart';
import 'package:bubbly/modal/pk_battle/battle_type.dart';
import 'package:bubbly/modal/pk_battle/gift.dart';
import 'package:bubbly/modal/user/user.dart';
import 'package:bubbly/utils/pk_battle_config.dart';
import 'package:bubbly/services/pk_battle_service.dart';

void main() {
  group('PK Battle Models Tests', () {
    test('Livestream model should create correctly', () {
      final livestream = Livestream(
        id: 'test_id',
        hostId: 'host_123',
        coHostId: 'cohost_456',
        battleType: BattleType.initiate,
        battleCreatedAt: DateTime.now().millisecondsSinceEpoch,
        isActive: true,
      );

      expect(livestream.id, 'test_id');
      expect(livestream.hostId, 'host_123');
      expect(livestream.coHostId, 'cohost_456');
      expect(livestream.battleType, BattleType.initiate);
      expect(livestream.isActive, true);
      expect(livestream.isBattleMode, false); // initiate is not battle mode
    });

    test('Livestream should detect battle mode correctly', () {
      final waitingLivestream = Livestream(
        id: 'test_id',
        battleType: BattleType.waiting,
      );
      expect(waitingLivestream.isBattleMode, true);

      final runningLivestream = Livestream(
        id: 'test_id',
        battleType: BattleType.running,
      );
      expect(runningLivestream.isBattleMode, true);

      final endedLivestream = Livestream(
        id: 'test_id',
        battleType: BattleType.end,
      );
      expect(endedLivestream.isBattleMode, true);

      final initiateLivestream = Livestream(
        id: 'test_id',
        battleType: BattleType.initiate,
      );
      expect(initiateLivestream.isBattleMode, false);
    });

    test('LivestreamUserState should create correctly', () {
      final user = UserData(
        userId: 'user_123',
        userName: 'TestUser',
        image: 'https://example.com/avatar.jpg',
        isVerified: true,
      );

      final userState = LivestreamUserState(
        userId: 'user_123',
        user: user,
        isHost: true,
        isCoHost: false,
        isMuted: false,
        isVideoOn: true,
        currentBattleCoin: 100,
      );

      expect(userState.userId, 'user_123');
      expect(userState.isHost, true);
      expect(userState.isCoHost, false);
      expect(userState.isParticipant, true); // host is participant
      expect(userState.currentBattleCoin, 100);
    });

    test('Gift model should create correctly', () {
      final gift = Gift(
        id: 'gift_1',
        name: 'Rose',
        image: 'https://example.com/rose.png',
        coinPrice: 10,
        isActive: true,
      );

      expect(gift.id, 'gift_1');
      expect(gift.name, 'Rose');
      expect(gift.coinPrice, 10);
      expect(gift.isActive, true);
    });
  });

  group('PK Battle Config Tests', () {
    test('Config constants should be valid', () {
      expect(PKBattleConfig.battleDurationInSecond, greaterThan(0));
      expect(PKBattleConfig.battleStartInSecond, greaterThan(0));
      expect(PKBattleConfig.battleEndMainViewInSecond, greaterThan(0));
      expect(PKBattleConfig.giftDialogDismissTime, greaterThan(0));
    });

    test('formatTime should work correctly', () {
      expect(PKBattleConfig.formatTime(65), '01:05');
      expect(PKBattleConfig.formatTime(30), '00:30');
      expect(PKBattleConfig.formatTime(0), '00:00');
      expect(PKBattleConfig.formatTime(3661), '61:01'); // Over 60 minutes
    });

    test('formatCoins should work correctly', () {
      expect(PKBattleConfig.formatCoins(999), '999');
      expect(PKBattleConfig.formatCoins(1000), '1K');
      expect(PKBattleConfig.formatCoins(1500), '1.5K');
      expect(PKBattleConfig.formatCoins(1000000), '1M');
      expect(PKBattleConfig.formatCoins(1500000), '1.5M');
    });
  });

  group('Battle Type Tests', () {
    test('BattleType enum should have correct values', () {
      expect(BattleType.initiate.value, 'INITIATE');
      expect(BattleType.waiting.value, 'WAITING');
      expect(BattleType.running.value, 'RUNNING');
      expect(BattleType.end.value, 'END');
    });

    test('BattleView enum should have correct values', () {
      expect(BattleView.red.value, 'red');
      expect(BattleView.blue.value, 'blue');
    });

    test('GiftType enum should have correct values', () {
      expect(GiftType.normal.value, 'normal');
      expect(GiftType.battle.value, 'battle');
    });
  });

  group('PKBattleService Tests', () {
    late PKBattleService service;

    setUp(() {
      service = PKBattleService();
    });

    test('Service should initialize correctly', () {
      expect(service, isNotNull);
    });

    // Note: These would be integration tests that require Firebase setup
    // For now, just testing that methods exist and don't throw immediately
    test('Service methods should exist', () {
      expect(() => service.initiateBattle('test_room'), returnsNormally);
      expect(() => service.startBattleRunning('test_room'), returnsNormally);
      expect(() => service.endBattle('test_room', {}), returnsNormally);
    });
  });
}

// Helper function to create test user data
UserData createTestUser({
  required String userId,
  String? userName,
  String? image,
  bool isVerified = false,
}) {
  return UserData(
    userId: userId,
    userName: userName ?? 'TestUser_$userId',
    image: image,
    isVerified: isVerified,
  );
}

// Helper function to create test livestream
Livestream createTestLivestream({
  required String id,
  String? hostId,
  String? coHostId,
  BattleType? battleType,
  bool isActive = true,
}) {
  return Livestream(
    id: id,
    hostId: hostId,
    coHostId: coHostId,
    battleType: battleType ?? BattleType.initiate,
    isActive: isActive,
  );
}

// Helper function to create test user state
LivestreamUserState createTestUserState({
  required String userId,
  UserData? user,
  bool isHost = false,
  bool isCoHost = false,
  bool isMuted = false,
  bool isVideoOn = true,
  int currentBattleCoin = 0,
}) {
  return LivestreamUserState(
    userId: userId,
    user: user ?? createTestUser(userId: userId),
    isHost: isHost,
    isCoHost: isCoHost,
    isMuted: isMuted,
    isVideoOn: isVideoOn,
    currentBattleCoin: currentBattleCoin,
  );
}

