import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bubbly/modal/pk_battle/battle_type.dart';
import 'package:bubbly/modal/pk_battle/gift.dart';
import 'package:bubbly/modal/pk_battle/livestream_user_state.dart';
import 'package:bubbly/modal/user/user.dart';
import 'package:bubbly/view/pk_battle/controllers/gift_sheet_controller.dart';
import 'package:bubbly/utils/pk_battle_config.dart';
import 'package:bubbly/custom_view/image_place_holder.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GiftSheet extends StatefulWidget {
  final GiftType giftType;
  final BattleView battleView;
  final List<LivestreamUserState> streamUsers;
  final String roomId;
  final Function(Gift gift, LivestreamUserState user)? onGiftSelected;

  const GiftSheet({
    Key? key,
    this.giftType = GiftType.battle,
    this.battleView = BattleView.red,
    required this.streamUsers,
    required this.roomId,
    this.onGiftSelected,
  }) : super(key: key);

  @override
  State<GiftSheet> createState() => _GiftSheetState();
}

class _GiftSheetState extends State<GiftSheet> {
  late GiftSheetController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(GiftSheetController(
      widget.giftType,
      widget.streamUsers,
      widget.roomId,
    ));
  }

  @override
  void dispose() {
    Get.delete<GiftSheetController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildBattleUserIndicator(),
          _buildUserCoinBalance(),
          Expanded(child: _buildGiftGrid()),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Send Gifts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleUserIndicator() {
    if (widget.giftType != GiftType.battle || widget.streamUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    final targetUser = widget.streamUsers.first;
    final teamColor = widget.battleView == BattleView.red
        ? Color(PKBattleConfig.redTeamColor)
        : Color(PKBattleConfig.blueTeamColor);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: teamColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: teamColor, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: teamColor, width: 2),
            ),
            child: ClipOval(
              child: targetUser.user?.userProfile != null
                  ? CachedNetworkImage(
                      imageUrl: targetUser.user!.userProfile!,
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const ImagePlaceHolder(),
                      errorWidget: (context, url, error) => const ImagePlaceHolder(),
                    )
                  : const ImagePlaceHolder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  targetUser.user?.userName ?? 'Unknown',
                  style: TextStyle(
                    color: teamColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Team ${widget.battleView.value.toUpperCase()}',
                  style: TextStyle(
                    color: teamColor.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: teamColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '${PKBattleConfig.formatCoins(targetUser.currentBattleCoin)} coins',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCoinBalance() {
    return Obx(() {
      final userCoins = controller.userCoins.value;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade400, Colors.orange.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Your Balance: ${PKBattleConfig.formatCoins(userCoins)} Coins',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildGiftGrid() {
    return Obx(() {
      final gifts = controller.availableGifts;
      
      if (gifts.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.card_giftcard_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No gifts available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: gifts.length,
        itemBuilder: (context, index) {
          final gift = gifts[index];
          return _buildGiftCard(gift);
        },
      );
    });
  }

  Widget _buildGiftCard(Gift gift) {
    return Obx(() {
      final selectedGift = controller.selectedGift.value;
      final isSelected = selectedGift?.id == gift.id;
      final canAfford = controller.canAffordGift(gift);

      return GestureDetector(
        onTap: () => controller.selectGift(gift),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? Colors.blue 
                  : canAfford 
                      ? Colors.grey.shade300 
                      : Colors.red.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: gift.image != null
                    ? CachedNetworkImage(
                        imageUrl: gift.image!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Icon(Icons.card_giftcard),
                        errorWidget: (context, url, error) => const Icon(Icons.card_giftcard),
                      )
                    : const Icon(Icons.card_giftcard),
              ),
              const SizedBox(height: 8),
              Text(
                gift.name ?? 'Gift',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: canAfford ? Colors.black : Colors.red,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: canAfford ? Colors.amber : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${gift.coinPrice ?? 0}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSendButton() {
    return Obx(() {
      final selectedGift = controller.selectedGift.value;
      final canSend = selectedGift != null && controller.canAffordGift(selectedGift);

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: canSend ? _sendGift : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canSend 
                  ? (widget.battleView == BattleView.red 
                      ? Color(PKBattleConfig.redTeamColor) 
                      : Color(PKBattleConfig.blueTeamColor))
                  : Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: canSend ? 4 : 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.send,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  selectedGift != null 
                      ? 'Send ${selectedGift.name} (${selectedGift.coinPrice} coins)'
                      : 'Select a gift',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _sendGift() {
    final selectedGift = controller.selectedGift.value;
    if (selectedGift != null && widget.streamUsers.isNotEmpty) {
      final targetUser = widget.streamUsers.first;
      
      controller.sendGift(selectedGift, targetUser, widget.battleView).then((_) {
        widget.onGiftSelected?.call(selectedGift, targetUser);
        Navigator.pop(context);
        
        // Show success message
        Get.snackbar(
          'Gift Sent!',
          'You sent ${selectedGift.name} to ${targetUser.user?.userName}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }).catchError((error) {
        Get.snackbar(
          'Error',
          'Failed to send gift: $error',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      });
    }
  }
}

