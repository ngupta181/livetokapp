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
        print('Error listening to livestream: $error');
      },
    );

    // Listen to user states changes
    _userStatesSubscription = _battleService.getUserStatesStream(roomId).listen(
      (states) {
        userStates.value = states;
        _updateBattleProgress();
      },
      onError: (error) {
        print('Error listening to user states: $error');
      },
    );
  }

  void _handleLivestreamUpdate(Livestream livestreamData) {
    switch (livestreamData.battleType) {
      case BattleType.waiting:
        _startCountdown();
        break;
      case BattleType.running:
        _startBattleTimer();
        break;
      case BattleType.ended:
        _handleBattleEnd();
        break;
      default:
        break;
    }
  }

  void _updateBattleProgress() {
    // Update battle progress based on user states
    // This will be called when gifts are sent during battle
  }

  void _startCountdown() {
    remainingSeconds.value = PKBattleConfig.countdownDurationInSecond;
    battleType.value = BattleType.waiting;
    
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
    battleType.value = BattleType.running;
    
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
    battleType.value = BattleType.ended;
    
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

  void _ensureParticipantStates() {
    // Clear existing states
    userStates.clear();
    
    // Add host as participant
    final hostState = LivestreamUserState(
      userId: 1, // Default host ID
      type: LivestreamUserType.host,
      currentBattleCoin: 0,
      totalBattleCoin: 0,
    );
    userStates.add(hostState);
    
    // Add co-host as participant
    final coHostState = LivestreamUserState(
      userId: 2, // Default co-host ID
      type: LivestreamUserType.co_host,
      currentBattleCoin: 0,
      totalBattleCoin: 0,
    );
    userStates.add(coHostState);
    
    print('Participants ensured: ${userStates.length} participants');
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

  void openGiftSheet() {
    // Placeholder for gift sheet functionality
    print('Opening gift sheet for battle');
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

