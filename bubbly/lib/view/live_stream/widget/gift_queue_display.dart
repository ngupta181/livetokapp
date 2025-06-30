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
  final bool isGiftSheetOpen;
  final bool isGiftSheetMinimized;

  const GiftQueueDisplay({
    Key? key,
    required this.commentList,
    this.settingData,
    this.isGiftSheetOpen = false,
    this.isGiftSheetMinimized = false,
  }) : super(key: key);

  @override
  State<GiftQueueDisplay> createState() => _GiftQueueDisplayState();
}

class _GiftQueueDisplayState extends State<GiftQueueDisplay>
    with TickerProviderStateMixin {
  final Queue<GiftQueueItem> _giftQueue = Queue();
  final Map<String, AnimationController> _controllers = {};
  final Map<int, bool> _processedGifts = {};
  final Map<String, Timer> _removalTimers = {};
  Timer? _processingTimer;
  
  // For handling full-screen animations
  final List<LiveStreamComment> _fullScreenGifts = [];
  final Map<int, bool> _processedFullScreenGifts = {};
  bool _debugMode = true; // Set to true for debugging combo logic

  // Combo detection window in seconds
  static const int _comboWindowSeconds = 5;

  // Method to toggle debug mode
  void toggleDebugMode() {
    setState(() {
      _debugMode = !_debugMode;
    });
  }

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
    _removalTimers.forEach((_, timer) => timer.cancel());
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
      // Create a combo key based on user ID and gift image
      String comboKey = '${comment.userId}_${comment.comment}';
      
             // Check if there's already a gift from the same user with the same gift type
       GiftQueueItem? existingGift;
       if (_debugMode) {
         print("GiftQueueDisplay: Checking for combo - User: ${comment.userId}, Gift: ${comment.comment}");
         print("Current queue size: ${_giftQueue.length}");
       }
       
       for (var gift in _giftQueue) {
         if (gift.comment.userId == comment.userId && 
             gift.comment.comment == comment.comment) {
           // Check if it's within the combo time window
           final timeDiff = DateTime.now().difference(gift.timestamp).inSeconds;
           if (_debugMode) {
             print("Found matching gift, time diff: ${timeDiff}s (window: ${_comboWindowSeconds}s)");
           }
           if (timeDiff <= _comboWindowSeconds) {
             existingGift = gift;
             if (_debugMode) {
               print("COMBO MATCH FOUND! Current count: ${gift.comboCount}");
             }
             break;
           }
         }
       }
      
      if (existingGift != null) {
        // This is a combo! Increment the count
        existingGift.comboCount++;
        
        if (_debugMode) {
          print("GiftQueueDisplay: Combo detected! Count: ${existingGift.comboCount}");
        }
        
        // Cancel the existing removal timer
        _removalTimers[existingGift.id]?.cancel();
        
                 // Create combo count animation (scale effect)
         final controller = _controllers[existingGift.id];
         if (controller != null) {
           controller.reset();
           controller.forward();
         } else if (_debugMode) {
           print("Warning: No controller found for gift ${existingGift.id}");
         }
        
        // Set a new removal timer
        _removalTimers[existingGift.id] = Timer(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _giftQueue.removeWhere((item) => item.id == existingGift!.id);
              _controllers[existingGift!.id]?.dispose();
              _controllers.remove(existingGift!.id);
              _removalTimers.remove(existingGift!.id);
            });
          }
        });
      } else {
        // Create new gift item
        final newGift = GiftQueueItem(
          comment: comment,
          timestamp: DateTime.now(),
        );
        
        _giftQueue.add(newGift);
        
        if (_debugMode) {
          print("GiftQueueDisplay: New gift added from ${comment.fullName}");
        }
        
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
          _removalTimers[removed.id]?.cancel();
          _removalTimers.remove(removed.id);
        }
        
        // Set removal timer
        _removalTimers[newGift.id] = Timer(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _giftQueue.removeWhere((item) => item.id == newGift.id);
              _controllers[newGift.id]?.dispose();
              _controllers.remove(newGift.id);
              _removalTimers.remove(newGift.id);
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gifts = _giftQueue.toList();
    
    // Calculate bottom position based on gift sheet state
    double bottomPosition = 280; // Default position
    if (widget.isGiftSheetOpen) {
      if (widget.isGiftSheetMinimized) {
        // When minimized, gift sheet is about 100px high
        bottomPosition = 120;
      } else {
        // When expanded, gift sheet is 45% of screen height
        final screenHeight = MediaQuery.of(context).size.height;
        final giftSheetHeight = screenHeight * 0.45;
        bottomPosition = giftSheetHeight + 20; // Add some padding
      }
    }
    
    return Stack(
      children: [
        // Regular gift queue display
        Positioned(
          bottom: bottomPosition,
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
          // Combo with enhanced animation
          if (giftItem.comboCount > 1)
            Container(
              margin: EdgeInsets.only(left: 5),
              child: _controllers[giftItem.id] != null 
                ? ScaleTransition(
                    scale: Tween<double>(
                      begin: 1.0,
                      end: 1.3,
                    ).animate(CurvedAnimation(
                      parent: _controllers[giftItem.id]!,
                      curve: Curves.elasticOut,
                    )),
                                        child: _buildComboContainer(giftItem.comboCount),
                  )
                : _buildComboContainer(giftItem.comboCount),
            ),
        ],
      ),
    );
  }

  Widget _buildComboContainer(int comboCount) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorRes.colorPink,
            Colors.deepOrange,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: ColorRes.colorPink.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        'x$comboCount',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 2,
              offset: Offset(1, 1),
            ),
          ],
        ),
      ),
    );
  }
} 