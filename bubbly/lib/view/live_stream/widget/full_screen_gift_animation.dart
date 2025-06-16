import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/modal/live_stream/live_stream.dart';
import 'package:bubbly/modal/setting/setting.dart';
import 'package:audioplayers/audioplayers.dart';

class FullScreenGiftAnimation extends StatefulWidget {
  final LiveStreamComment giftComment;
  final SettingData? settingData;

  const FullScreenGiftAnimation({
    Key? key,
    required this.giftComment,
    this.settingData,
  }) : super(key: key);

  @override
  State<FullScreenGiftAnimation> createState() =>
      _FullScreenGiftAnimationState();
}

class _FullScreenGiftAnimationState extends State<FullScreenGiftAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _timer;
  bool _hasError = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..forward();

    // Scale animation sequence
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutExpo)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 70,
      ),
    ]).animate(_controller);

    // Fade animation sequence
    _fadeAnimation = TweenSequence([
      TweenSequenceItem(
        tween:
            Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween:
            Tween(begin: 1.0, end: 1.0).chain(CurveTween(curve: Curves.linear)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_controller);

    // Auto-remove after animation
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {});
      }
    });

    // Play gift sound
    _playGiftSound();
  }

  Future<void> _playGiftSound() async {
    try {
      // Get the gift details to determine which sound to play
      Gifts? gift = _findGiftFromImage();

      // Try multiple path variations to find the working one
      List<String> possiblePaths = [
        'sounds/gift_default.mp3',
        'assets/sounds/gift_default.mp3',
        gift?.giftSound ?? '',
      ];

      for (String path in possiblePaths) {
        if (path.isEmpty) continue;

        try {
          debugPrint('Attempting to play sound from: $path');
          final player = AudioPlayer();
          await player.play(AssetSource(path));
          // If successful, break the loop
          break;
        } catch (e) {
          debugPrint('Failed to play sound from $path: $e');
          // Continue trying next path
          continue;
        }
      }
    } catch (e) {
      debugPrint('Error in _playGiftSound: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Find the gift details from the comment
  Gifts? _findGiftFromImage() {
    if (widget.settingData?.gifts == null) return null;
    String giftImage = widget.giftComment.comment ?? '';
    for (Gifts gift in widget.settingData!.gifts!) {
      if (gift.image == giftImage) {
        return gift;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    String giftImage = widget.giftComment.comment ?? '';

    if (_hasError) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Center(
              child: Container(
                width: 200,
                height: 200,
                child: Image.network(
                  '${ConstRes.itemBaseUrl}$giftImage',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) {
                    _hasError = true;
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
