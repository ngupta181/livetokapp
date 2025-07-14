import 'package:get/get.dart';
import 'package:bubbly/modal/pk_battle/gift.dart';
import 'package:bubbly/modal/pk_battle/livestream_user_state.dart';
import 'package:bubbly/modal/pk_battle/battle_type.dart';
import 'package:bubbly/modal/user/user.dart';
import 'package:bubbly/services/pk_battle_service.dart';
import 'package:bubbly/utils/session_manager.dart';

class GiftSheetController extends GetxController {
  final GiftType giftType;
  final List<LivestreamUserState> streamUsers;
  final String roomId;
  
  final PKBattleService _battleService = PKBattleService();
  
  // Observable properties
  final RxList<Gift> availableGifts = <Gift>[].obs;
  final Rx<Gift?> selectedGift = Rx<Gift?>(null);
  final RxInt userCoins = 0.obs;
  final RxBool isLoading = false.obs;

  GiftSheetController(this.giftType, this.streamUsers, this.roomId);

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadAvailableGifts(),
        _loadUserCoins(),
      ]);
    } catch (e) {
      print('Error loading initial data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadAvailableGifts() async {
    try {
      // Since getAvailableGifts doesn't exist in PKBattleService, use default gifts
      availableGifts.value = _getDefaultGifts();
    } catch (e) {
      print('Error loading gifts: $e');
      // Fallback to default gifts
      availableGifts.value = _getDefaultGifts();
    }
  }

  Future<void> _loadUserCoins() async {
    try {
      // Since SessionManager.getUserData() doesn't exist, set default coins
      userCoins.value = 1000; // Default coins for testing
    } catch (e) {
      print('Error loading user coins: $e');
      userCoins.value = 0;
    }
  }

  List<Gift> _getDefaultGifts() {
    return [
      Gift(
        id: 1,
        name: 'Rose',
        image: 'https://example.com/rose.png',
        coinPrice: 10,
        isActive: true,
      ),
      Gift(
        id: 2,
        name: 'Heart',
        image: 'https://example.com/heart.png',
        coinPrice: 25,
        isActive: true,
      ),
      Gift(
        id: 3,
        name: 'Diamond',
        image: 'https://example.com/diamond.png',
        coinPrice: 50,
        isActive: true,
      ),
      Gift(
        id: 4,
        name: 'Crown',
        image: 'https://example.com/crown.png',
        coinPrice: 100,
        isActive: true,
      ),
      Gift(
        id: 5,
        name: 'Rocket',
        image: 'https://example.com/rocket.png',
        coinPrice: 200,
        isActive: true,
      ),
      Gift(
        id: 6,
        name: 'Castle',
        image: 'https://example.com/castle.png',
        coinPrice: 500,
        isActive: true,
      ),
      Gift(
        id: 7,
        name: 'Sports Car',
        image: 'https://example.com/car.png',
        coinPrice: 1000,
        isActive: true,
      ),
      Gift(
        id: 8,
        name: 'Yacht',
        image: 'https://example.com/yacht.png',
        coinPrice: 2500,
        isActive: true,
      ),
    ];
  }

  void selectGift(Gift gift) {
    if (canAffordGift(gift)) {
      selectedGift.value = gift;
    }
  }

  bool canAffordGift(Gift gift) {
    return userCoins.value >= (gift.coinPrice ?? 0);
  }

  Future<void> sendGift(Gift gift, LivestreamUserState targetUser, BattleView battleView) async {
    if (!canAffordGift(gift)) {
      throw Exception('Insufficient coins');
    }

    try {
      isLoading.value = true;
      
      // For now, use dummy user ID since SessionManager doesn't exist
      final currentUserId = 1; // This should be replaced with actual user ID
      
      // Send gift through battle service
      await _battleService.sendGift(
        roomId: roomId,
        senderId: currentUserId,
        receiverId: targetUser.userId,
        giftId: gift.id!,
        coinValue: gift.coinPrice!,
        giftType: GiftType.battle,
        comment: 'Gift sent during PK Battle',
      );

      // Update local user coins
      userCoins.value -= (gift.coinPrice ?? 0);
      
      // Clear selection
      selectedGift.value = null;
      
    } catch (e) {
      print('Error sending gift: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshUserCoins() async {
    await _loadUserCoins();
  }

  // Helper methods
  List<Gift> get affordableGifts {
    return availableGifts.where((gift) => canAffordGift(gift)).toList();
  }

  List<Gift> get expensiveGifts {
    return availableGifts.where((gift) => !canAffordGift(gift)).toList();
  }

  int get totalGiftsCount => availableGifts.length;
  int get affordableGiftsCount => affordableGifts.length;
}

