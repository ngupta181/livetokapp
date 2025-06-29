import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:bubbly/modal/live_stream/live_stream.dart';
import 'package:bubbly/modal/setting/setting.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/level_utils.dart';
import 'package:bubbly/view/live_stream/widget/full_screen_gift_animation.dart';

class GiftQueueItem {
  final LiveStreamComment comment;
  final DateTime timestamp;
  int comboCount;
  String id;

  GiftQueueItem({
    required this.comment,
    required this.timestamp,
    this.comboCount = 1,
    String? id,
  }) : id = id ?? '${comment.userId}_${comment.comment}_${timestamp.millisecondsSinceEpoch}';
}

class GiftQueueDisplay extends StatefulWidget {
  final List<LiveStreamComment> commentList;
  final SettingData? settingData;

  const GiftQueueDisplay({
    Key? key,
    required this.commentList,
    this.settingData,
  }) : super(key: key);

  @override
  State<GiftQueueDisplay> createState() => _GiftQueueDisplayState();
}

class _GiftQueueDisplayState extends State<GiftQueueDisplay>
    with TickerProviderStateMixin {
  final Queue<GiftQueueItem> _giftQueue = Queue();
  final Map<String, AnimationController> _controllers = {};
  final Map<int, bool> _processedGifts = {};
  Timer? _processingTimer;
  
  // For handling full-screen animations
  final List<LiveStreamComment> _fullScreenGifts = [];
  final Map<int, bool> _processedFullScreenGifts = {};
  bool _debugMode = false;

  @override
  void initState() {
    super.initState();
    _processingTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _processComments();
    });
  }

  @override
  void dispose() {
    _processingTimer?.cancel();
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _processComments() {
    for (final comment in widget.commentList) {
      if (comment.commentType == 'image' && 
          comment.id != null && 
          !_processedGifts.containsKey(comment.id)) {
        
        // Check if this is a full-screen animation gift
        Gifts? giftDetails = _findGiftFromImage(comment.comment ?? '');
        
        if (_debugMode) {
          print("GiftQueueDisplay: Processing gift ${comment.id}, image: ${comment.comment}");
          print("Animation style: ${giftDetails?.animationStyle}");
        }
        
        if (giftDetails != null && giftDetails.animationStyle == 'full_screen') {
          if (_debugMode) {
            print("GiftQueueDisplay: Adding FULL SCREEN gift ${comment.id}");
          }
          
          // Mark as processed for both systems
          _processedGifts[comment.id!] = true;
          _processedFullScreenGifts[comment.id!] = true;
          
          // Add to full screen gifts list
          setState(() {
            _fullScreenGifts.add(comment);
          });
          
          // Auto remove after 5 seconds
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              setState(() {
                _fullScreenGifts.remove(comment);
              });
            }
          });
        } else {
          // Regular gift - add to queue
          _processedGifts[comment.id!] = true;
          _addGiftToQueue(comment);
        }
      }
    }
  }

  // Find the gift details from the comment
  Gifts? _findGiftFromImage(String image) {
    if (widget.settingData?.gifts == null) {
      if (_debugMode) print("GiftQueueDisplay: No gifts in settingData");
      return null;
    }

    for (Gifts gift in widget.settingData!.gifts!) {
      if (gift.image == image) {
        if (_debugMode) print("GiftQueueDisplay: Found gift with animation style: ${gift.animationStyle}");
        return gift;
      }
    }
    return null;
  }

  void _addGiftToQueue(LiveStreamComment comment) {
    setState(() {
      final newGift = GiftQueueItem(
        comment: comment,
        timestamp: DateTime.now(),
      );
      
      _giftQueue.add(newGift);
      
      // Create animation controller
      final controller = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      _controllers[newGift.id] = controller;
      controller.forward();
      
      // Limit queue size
      while (_giftQueue.length > 4) {
        final removed = _giftQueue.removeFirst();
        _controllers[removed.id]?.dispose();
        _controllers.remove(removed.id);
      }
      
      // Auto remove after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _giftQueue.removeWhere((item) => item.id == newGift.id);
            _controllers[newGift.id]?.dispose();
            _controllers.remove(newGift.id);
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final gifts = _giftQueue.toList();
    
    return Stack(
      children: [
        // Regular gift queue display
        Positioned(
          bottom: 280,
          left: 15,
          right: MediaQuery.of(context).size.width * 0.35,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: gifts.reversed.map((giftItem) {
              final controller = _controllers[giftItem.id];
              if (controller == null) return const SizedBox.shrink();
              
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: controller,
                  curve: Curves.easeOutBack,
                )),
                child: FadeTransition(
                  opacity: controller,
                  child: Container(
                    margin: EdgeInsets.only(bottom: 8),
                    child: _buildGiftItem(giftItem),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        // Full-screen gift animations (if any)
        if (_fullScreenGifts.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Stack(
                children: _fullScreenGifts.map((gift) {
                  return FullScreenGiftAnimation(
                    key: ValueKey(gift.id),
                    giftComment: gift,
                    settingData: widget.settingData,
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGiftItem(GiftQueueItem giftItem) {
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: ColorRes.colorPink.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // User Avatar with level frame
          LevelUtils.getProfileWithFrame(
            userProfileUrl: "${ConstRes.itemBaseUrl}${giftItem.comment.userImage}",
            level: giftItem.comment.userLevel ?? 1,
            initialText: giftItem.comment.fullName?.substring(0, 1).toUpperCase() ?? 'U',
            frameSize: 35,
            fontSize: 12,
          ),
          SizedBox(width: 8),
          // Name
          Flexible(
            child: Text(
              giftItem.comment.fullName ?? 'User',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8),
          // Gift Icon
          Container(
            width: 30,
            height: 30,
            child: Image.network(
              '${ConstRes.itemBaseUrl}${giftItem.comment.comment}',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.card_giftcard,
                color: ColorRes.colorPink,
                size: 20,
              ),
            ),
          ),
          // Combo
          if (giftItem.comboCount > 1)
            Container(
              margin: EdgeInsets.only(left: 5),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ColorRes.colorPink,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'x${giftItem.comboCount}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
} 