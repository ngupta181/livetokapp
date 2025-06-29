import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bubbly/modal/live_stream/live_stream.dart';
import 'package:bubbly/modal/setting/setting.dart';
import 'package:bubbly/utils/firebase_res.dart';
import 'package:bubbly/view/live_stream/widget/gift_animation.dart';
import 'package:bubbly/view/live_stream/widget/full_screen_gift_animation.dart';
import 'package:bubbly/view/live_stream/widget/gift_animation_controller.dart';

class GiftDisplay extends StatefulWidget {
  final List<LiveStreamComment> commentList;
  final SettingData? settingData;

  const GiftDisplay({
    Key? key,
    required this.commentList,
    this.settingData,
  }) : super(key: key);

  @override
  State<GiftDisplay> createState() => _GiftDisplayState();
}

class _GiftDisplayState extends State<GiftDisplay> {
  final GiftAnimationController _controller = GiftAnimationController();
  Timer? _processingTimer;
  // Set to true only for debugging
  bool _debugMode = true;

  @override
  void initState() {
    super.initState();

    if (_debugMode) print("GiftDisplay: initializing");

    // Set up a timer to regularly check for new gifts
    _processingTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _processComments();
    });

    // Force an initial check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_debugMode) print("GiftDisplay: Initial check for gifts");
      _processComments();
    });
  }

  void _processComments() {
    // Only process if we have comments and the controller is available
    if (widget.commentList.isNotEmpty) {
      if (_debugMode) {
        print(
            "GiftDisplay: Processing ${widget.commentList.length} comments for gifts");
      }

      // Use the controller to process comments and manage animations
      _controller.processComments(widget.commentList, widget.settingData);
    }
  }

  @override
  void dispose() {
    if (_debugMode) print("GiftDisplay: Disposing");
    _processingTimer?.cancel();
    super.dispose();
  }

  // Find the gift details from the comment
  Gifts? _findGiftFromImage(String image) {
    if (_debugMode) print("Finding gift for image: $image");
    
    if (widget.settingData?.gifts == null) {
      if (_debugMode) print("No gifts in settingData");
      return null;
    }
    
    if (_debugMode) {
      print("Available gifts: ${widget.settingData!.gifts!.length}");
      widget.settingData!.gifts!.forEach((gift) {
        print("Gift ID: ${gift.id}, Image: ${gift.image}, AnimationStyle: ${gift.animationStyle}");
      });
    }

    for (Gifts gift in widget.settingData!.gifts!) {
      if (gift.image == image) {
        if (_debugMode) print("Found gift with ID: ${gift.id}, AnimationStyle: ${gift.animationStyle}");
        return gift;
      }
    }
    
    if (_debugMode) print("No gift found for image: $image");
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_debugMode) {
      print(
          "GiftDisplay: Building with ${_controller.activeGifts.length} active gifts");
    }

    return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // No need to render if no active gifts
          if (_controller.activeGifts.isEmpty) {
            return const SizedBox.shrink();
          }

          // Use full screen container to position gifts
          return Positioned.fill(
            child: IgnorePointer(
              // Prevents interaction with the gifts (allows touches to pass through)
              ignoring: true,
              child: Container(
                color: Colors.transparent,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: _controller.activeGifts.map((gift) {
                    if (_debugMode) {
                      print(
                          "GiftDisplay: Rendering gift ${gift.id} - ${gift.comment}");
                    }

                    // Find the gift details
                    Gifts? giftDetails = _findGiftFromImage(gift.comment ?? '');
                    
                    // Debug the animation style
                    if (_debugMode) {
                      print("Gift animation style: ${giftDetails?.animationStyle}");
                    }

                    // Check if this is a full-screen animation
                    if (giftDetails != null && giftDetails.animationStyle == 'full_screen') {
                      if (_debugMode) {
                        print("Using FULL SCREEN animation for gift ${gift.id}");
                      }
                      return FullScreenGiftAnimation(
                        key: ValueKey(gift.id),
                        giftComment: gift,
                        settingData: widget.settingData,
                      );
                    } else {
                      if (_debugMode) {
                        print("Using REGULAR animation for gift ${gift.id}");
                      }
                      // Regular animation
                      return Positioned(
                        top: MediaQuery.of(context).size.height / 2 - 40,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GiftAnimation(
                            key: ValueKey(gift.id),
                            giftComment: gift,
                            settingData: widget.settingData,
                          ),
                        ),
                      );
                    }
                  }).toList(),
                ),
              ),
            ),
          );
        });
  }
}
