import 'dart:async';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Widget that displays a native ad in the video feed with TikTok/Instagram-style UI
class NativeAdVideo extends StatefulWidget {
  final NativeAd? nativeAd;
  final VoidCallback? onAdClosed;
  final int adPosition;
  final double height;
  final bool isGridView;
  
  const NativeAdVideo({
    Key? key, 
    required this.nativeAd,
    required this.adPosition,
    this.onAdClosed,
    this.height = 500,
    this.isGridView = false,
  }) : super(key: key);

  @override
  State<NativeAdVideo> createState() => _NativeAdVideoState();
}

class _NativeAdVideoState extends State<NativeAdVideo> with SingleTickerProviderStateMixin {
  bool _isAdVisible = true;
  bool _isSkippable = false;
  int _remainingTime = 15; // Maximum ad duration (seconds)
  Timer? _countdownTimer;
  Timer? _skipTimer;
  
  // Animation controller for progress bar
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller for the progress bar
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Match max ad duration
    )..forward();
    
    // Start the countdown for auto-dismiss
    _startCountdown();
    
    // Allow skip after 5 seconds
    _skipTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isSkippable = true;
        });
      }
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingTime--;
        });
      }
      
      // Auto-dismiss ad when countdown reaches zero
      if (_remainingTime <= 0) {
        _handleSkipAd();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _skipTimer?.cancel();
    _progressController.dispose();
    // Note: don't dispose the ad here, as it's managed by NativeAdManager
    super.dispose();
  }

  void _handleSkipAd() {
    if (!_isSkippable && _remainingTime > 10) return; // Prevent skipping too early
    
    setState(() {
      _isAdVisible = false;
    });
    
    _countdownTimer?.cancel();
    _skipTimer?.cancel();
    widget.onAdClosed?.call();
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.nativeAd == null || !_isAdVisible) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    
    return Container(
      width: size.width,
      height: size.height,
      color: Colors.black,
      child: Stack(
        children: [
          // Centered Ad Container
          Center(
            child: Container(
              width: size.width,
              height: size.height - 160, // Account for top and bottom spacing
              margin: EdgeInsets.only(
                top: topPadding + 80, // Increased space for top bar and tabs
                bottom: 80, // Space for bottom actions
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(widget.isGridView ? 8 : 0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.isGridView ? 8 : 0),
                child: AdWidget(ad: widget.nativeAd!),
              ),
            ),
          ),

          // Top Bar with Sponsored and Skip - Moved lower to avoid tab overlap
          Positioned(
            top: topPadding + 48, // Increased top padding to move below tabs
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Progress indicator (TikTok/Instagram style)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: 1 - (_remainingTime / 15), // Progress from 0 to 1
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 2,
                        );
                      },
                    ),
                  ),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sponsored Label
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Sponsored',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontFamily: FontRes.fNSfUiMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Skip Button with Countdown
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isSkippable ? _handleSkipAd : null,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Show countdown or skip icon
                                _isSkippable
                                    ? Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 14,
                                      )
                                    : Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: Colors.white24,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$_remainingTime',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                SizedBox(width: 4),
                                Text(
                                  _isSkippable ? 'Skip Ad' : 'Skip in ${5 - (15 - _remainingTime > 5 ? 5 : 15 - _remainingTime)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: FontRes.fNSfUiMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Tappable overlay to make entire video clickable (Instagram/TikTok behavior)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true, // Let AdWidget handle its own clicks
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 