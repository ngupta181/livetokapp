import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bubbly/modal/pk_battle/battle_type.dart';
import 'package:bubbly/modal/pk_battle/livestream.dart';
import 'package:bubbly/modal/pk_battle/livestream_user_state.dart';
import 'package:bubbly/modal/pk_battle/livestream_type.dart';
import 'package:bubbly/services/pk_battle_service.dart';
import 'package:bubbly/utils/pk_battle_config.dart';
import 'package:bubbly/utils/audio_manager.dart';
import 'package:bubbly/view/live_stream/model/live_stream_view_model.dart';

class PKBattleController extends GetxController {
  final String roomId;
  final PKBattleService _battleService = PKBattleService();
  
  // Observable properties
  final Rx<Livestream?> livestream = Rx<Livestream?>(null);
  final RxList<LivestreamUserState> userStates = <LivestreamUserState>[].obs;
  final RxInt remainingSeconds = 0.obs;
  final RxMap<String, dynamic> battleWinner = <String, dynamic>{}.obs;
  final RxBool isInitiating = false.obs;
  final Rx<BattleType> battleType = BattleType.initiate.obs;
  
  // Timers
  Timer? _battleTimer;
  Timer? _countdownTimer;
  
  // Stream subscriptions
  StreamSubscription? _livestreamSubscription;
  StreamSubscription? _userStatesSubscription;
  
  PKBattleController(this.roomId);

  @override
  void onInit() {
    super.onInit();
    _initializeListeners();
  }

  @override
  void onClose() {
    _battleTimer?.cancel();
    _countdownTimer?.cancel();
    _livestreamSubscription?.cancel();
    _userStatesSubscription?.cancel();
    super.onClose();
  }

  void _initializeListeners() {
    // Listen to livestream changes
    _livestreamSubscription = _battleService.getLivestreamStream(roomId).listen(
      (livestreamData) {
        if (livestreamData != null) {
          livestream.value = livestreamData;
          _handleLivestreamUpdate(livestreamData);
        }
      },
      onError: (error) {
        print("Error listening to livestream: $error");
      },
    );

    // Listen to user states changes
    _userStatesSubscription = _battleService.getUserStatesStream(roomId).listen(
      (states) {
        userStates.value = states;
        _updateBattleProgress();
      },
      onError: (error) {
        print("Error listening to user states: $error");
      },
    );
  }

  void _handleLivestreamUpdate(Livestream livestreamData) {
    print('PKBattleController: Livestream updated - Type: ${livestreamData.type?.value}, BattleType: ${livestreamData.battleType?.value}');
    battleType.value = livestreamData.battleType!;
    switch (livestreamData.battleType) {
      case BattleType.waiting:
        print('PKBattleController: Starting countdown...');
        _startCountdown();
        break;
      case BattleType.running:
        print('PKBattleController: Starting battle timer...');
        _startBattleTimer();
        break;
      case BattleType.ended:
        print('PKBattleController: Battle ended');
        _handleBattleEnd();
        break;
      default:
        print('PKBattleController: Battle type: ${livestreamData.battleType?.value}');
        break;
    }
  }

  void _updateBattleProgress() {
    // Update battle progress based on user states
    // This will be called when gifts are sent during battle
  }

  void _startCountdown() {
    remainingSeconds.value = PKBattleConfig.countdownDurationInSecond;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        timer.cancel();
        startBattleRunning();
      }
    });
  }

  void _startBattleTimer() {
    remainingSeconds.value = PKBattleConfig.battleDurationInSecond;
    _battleTimer?.cancel();
    _battleTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        timer.cancel();
        endBattle();
      }
    });
  }

  void _handleBattleEnd() {
    _battleTimer?.cancel();
    _countdownTimer?.cancel();
    // battleType.value = BattleType.ended; // This is already set by _handleLivestreamUpdate
    
    // Determine winner and show results
    _determineWinner();
  }

  void _determineWinner() {
    if (userStates.length >= 2) {
      final participants = userStates.where((state) => state.isParticipant).toList();
      if (participants.length >= 2) {
        participants.sort((a, b) => b.currentBattleCoin.compareTo(a.currentBattleCoin));
        final winner = participants.first;
        
        battleWinner.value = {
          'userId': winner.userId,
          'coins': winner.currentBattleCoin,
          'type': winner.type.value,
        };
        
        print('Battle winner: ${winner.userId} with ${winner.currentBattleCoin} coins');
      }
    }
  }

  void _playBattleStartSound() {
    try {
      AudioManager().playBattleStartSound();
    } catch (e) {
      print('Error playing battle start sound: $e');
    }
  }

  void _playBattleEndSound() {
    try {
      AudioManager().playBattleEndSound();
    } catch (e) {
      print('Error playing battle end sound: $e');
    }
  }

  Future<void> initiateBattle() async {
    if (isInitiating.value) return;
    
    try {
      isInitiating.value = true;
      
      // Check prerequisites
      if (!_canInitiateBattle()) {
        throw Exception('Cannot initiate battle: prerequisites not met');
      }

      // Ensure livestream document exists before initiating battle
      final existingLivestream = await _battleService.getLivestream(roomId);
      if (existingLivestream == null) {
        // Create a new livestream document if it doesn't exist
        final newLivestream = Livestream(
          roomID: roomId,
          title: 'PK Battle',
          type: LivestreamType.normal,
          battleType: BattleType.initiate,
          watchingCount: 0,
          hostId: roomId, // Directly assign roomId (String) to hostId
        );
        await _battleService.createLivestream(newLivestream);
      }

      // Ensure participant states exist
      await _ensureParticipantStates();
      
      // Create battle in Firebase
      await _battleService.initiateBattle(roomId);
      
      // Play battle start sound
      _playBattleStartSound();
      
    } catch (e) {
      print('Error initiating battle: $e');
      Get.snackbar(
        'Error',
        'Failed to start battle: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isInitiating.value = false;
    }
  }

  bool _canInitiateBattle() {
    // Basic check - battle is not already active
    if (livestream.value?.type == LivestreamType.battle) {
      Get.snackbar(
        'Battle Active',
        'A battle is already in progress',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    return true;
  }

  Future<void> _ensureParticipantStates() async {
    try {
      // Create host state
      final hostState = LivestreamUserState(
        userId: roomId, // Host ID is the roomId
        type: LivestreamUserType.host,
        currentBattleCoin: 0,
        totalBattleCoin: 0,
      );
      
      // Create co-host state (using a placeholder for now)
      final coHostState = LivestreamUserState(
        userId: 'cohost_$roomId', // Co-host ID
        type: LivestreamUserType.co_host,
        currentBattleCoin: 0,
        totalBattleCoin: 0,
      );
      
      // Set user states in Firebase
      await _battleService.setUserState(roomId, hostState);
      await _battleService.setUserState(roomId, coHostState);
      
      print('Participants ensured: Host and Co-host states created');
    } catch (e) {
      print('Error ensuring participant states: $e');
    }
  }

  Future<void> startBattleRunning() async {
    try {
      await _battleService.startBattleRunning(roomId);
      _playBattleStartSound();
    } catch (e) {
      print('Error starting battle running: $e');
    }
  }

  Future<void> endBattle() async {
    try {
      // Determine winner
      _determineWinner();
      
      // Get winner info
      String? winnerId;
      if (battleWinner.isNotEmpty) {
        winnerId = battleWinner['userId']?.toString();
      }
      
      await _battleService.endBattle(roomId, winnerId);
      _playBattleEndSound();
      
      // Reset battle coins for next battle
      await _resetBattleCoins();
      
    } catch (e) {
      print('Error ending battle: $e');
    }
  }

  Future<void> _resetBattleCoins() async {
    try {
      final userIds = userStates.map((state) => state.userId).toList();
      await _battleService.resetBattleCoins(roomId, userIds);
    } catch (e) {
      print('Error resetting battle coins: $e');
    }
  }

  void sendGift(int giftId, int giftValue, String targetUserId) {
    try {
      // Find target user state
      final targetIndex = userStates.indexWhere((state) => state.userId.toString() == targetUserId);
      if (targetIndex != -1) {
        // Update battle coins locally
        userStates[targetIndex] = userStates[targetIndex].copyWith(
          currentBattleCoin: userStates[targetIndex].currentBattleCoin + giftValue,
        );
        
        print('Gift sent: $giftValue coins to user $targetUserId');
      }
    } catch (e) {
      print('Error sending gift: $e');
    }
  }

  void openGiftSheet(BattleView battleViewType) {
    // Placeholder for gift sheet functionality
    print('Opening gift sheet for battle: ${battleViewType.value}');
  }

  // Get battle type as observable
  Rx<BattleType> get battleTypeObs => battleType;

  // Get remaining seconds as observable
  RxInt get remainingSecondsObs => remainingSeconds;

  // Get user states as observable
  RxList<LivestreamUserState> get userStatesObs => userStates;

  // Get battle winner as observable
  RxMap<String, dynamic> get battleWinnerObs => battleWinner;
}


