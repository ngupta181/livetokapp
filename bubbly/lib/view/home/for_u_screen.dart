import 'dart:developer';

import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/custom_view/common_ui.dart';
import 'package:bubbly/custom_view/data_not_found.dart';
import 'package:bubbly/custom_view/native_ad_video.dart';
import 'package:bubbly/modal/user_video/user_video.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/native_ad_manager.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:bubbly/utils/url_res.dart';
import 'package:bubbly/view/video/item_video.dart';
import 'package:bubbly/utils/ad_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class ForYouScreen extends StatefulWidget {
  @override
  _ForYouScreenState createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen> with AutomaticKeepAliveClientMixin {
  List<Data> mList = [];
  PageController pageController = PageController();
  int focusedIndex = 0;
  Map<int, VideoPlayerController> controllers = {};
  bool isLoading = false;
  bool isApiCall = true;
  final NativeAdManager _nativeAdManager = NativeAdManager.instance;
  
  // Track video ads so we don't show multiple ads consecutively
  Map<int, bool> _adPositions = {};
  
  @override
  void initState() {
    _initializeAds();
    callApiForYou(
      (p0) {
        initVideoPlayer();
      },
    );
    super.initState();
  }

  Future<void> _initializeAds() async {
    try {
      await AdHelper.initAds();
    } catch (e) {
      print('Error initializing ads: $e');
      // Continue app flow even if ads fail to initialize
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return isApiCall
        ? LoaderDialog()
        : mList.isEmpty
            ? DataNotFound()
            : PageView.builder(
                controller: pageController,
                itemCount: mList.length,
                physics: ClampingScrollPhysics(),
                scrollDirection: Axis.vertical,
                onPageChanged: onPageChanged,
                itemBuilder: (context, index) {
                  // Check if this position should show an ad
                  if (_shouldShowAdAtIndex(index)) {
                    return _buildNativeAdItem(index);
                  }
                  
                  // Regular video item
                  Data data = mList[index];
                  return ItemVideo(videoData: data, videoPlayerController: controllers[index]);
                },
              );
  }
  
  // Determines if we should show an ad at the current index
  bool _shouldShowAdAtIndex(int index) {
    // First few videos should not show ads
    if (index < 3) return false;
    
    // Don't show ads at positions where we've already shown them
    if (_adPositions.containsKey(index)) return _adPositions[index]!;
    
    // Ask the ad manager if we should show an ad
    final shouldShowAd = _nativeAdManager.shouldShowAdAfterIndex(index);
    
    // Remember this decision
    _adPositions[index] = shouldShowAd;
    
    // If we should show an ad, preload it now
    if (shouldShowAd) {
      _preloadAdForPosition(index);
    }
    
    return shouldShowAd;
  }
  
  // Preloads a native ad for the given position
  Future<void> _preloadAdForPosition(int position) async {
    // Only preload if this is actually an ad position
    if (_adPositions[position] != true) return;
    
    // NativeAdManager handles the actual loading (use isGridView=false for full-screen video ads)
    await _nativeAdManager.preloadNativeAd(position, isGridView: false);
    
    // Force rebuild if the widget is still mounted
    if (mounted) setState(() {});
  }
  
  // Builds a native ad item for the video feed
  Widget _buildNativeAdItem(int index) {
    return FutureBuilder<NativeAd?>(
      future: _nativeAdManager.preloadNativeAd(index, isGridView: false),
      builder: (context, snapshot) {
        final nativeAd = snapshot.data;
        
        // If ad is still loading or failed to load, show a placeholder
        if (nativeAd == null) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ColorRes.colorTheme),
            ),
          );
        }
        
        // Record that we're showing an ad
        _nativeAdManager.onAdShown();
        
        // Return the native ad widget
        return NativeAdVideo(
          nativeAd: nativeAd,
          adPosition: index,
          onAdClosed: () {
            // Skip this ad and move to the next content
            pageController.nextPage(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          },
        );
      },
    );
  }

  void callApiForYou(Function(List<Data>) onCompletion) {
    isLoading = true;
    if (isApiCall) {
      isApiCall = true;
    }
    
    // Always use the combined feed from recommendations endpoint
    ApiService().getRecommendations(paginationLimit.toString(), SessionManager.userId.toString()).then(
      (value) {
        isLoading = false;
        isApiCall = false;

        if (value.data != null && (value.data ?? []).isNotEmpty) {
          if (mList.isEmpty) {
            mList = value.data ?? [];
          } else {
            mList.addAll(value.data ?? []);
          }
          onCompletion(mList);
        }
        setState(() {});
      },
    );
  }

  void pausePlayer() async {
    await controllers[focusedIndex]?.pause();
  }

  void _playNext(int index) {
    controllers.forEach((key, value) {
      if (value.value.isPlaying) {
        value.pause();
      }
    });

    /// Stop [index - 1] controller
    _stopControllerAtIndex(index - 1);

    /// Dispose [index - 2] controller
    _disposeControllerAtIndex(index - 2);

    /// Play current video (already initialized)
    _playControllerAtIndex(index);

    /// Initialize [index + 1] controller

    _initializeControllerAtIndex(index + 1);
  }

  void _playPrevious(int index) {
    controllers.forEach((key, value) {
      value.pause();
    });

    /// Stop [index + 1] controller
    _stopControllerAtIndex(index + 1);

    /// Dispose [index + 2] controller
    _disposeControllerAtIndex(index + 2);

    /// Play current video (already initialized)
    _playControllerAtIndex(index);

    /// Initialize [index - 1] controller
    _initializeControllerAtIndex(index - 1);
  }

  Future _initializeControllerAtIndex(int index) async {
    // Skip ad positions - they don't need video controllers
    if (_adPositions.containsKey(index) && _adPositions[index]!) {
      return;
    }
    
    if (mList.length > index && index >= 0) {
      /// Create new controller
      final VideoPlayerController controller =
          VideoPlayerController.networkUrl(Uri.parse(ConstRes.getImageUrl(mList[index].postVideo)));

      /// Add to [controllers] list
      controllers[index] = controller;

      await controller.initialize();
      if (this.mounted) {
        /// Initialize
        setState(() {});
      }

      log('🚀🚀🚀 INITIALIZED $index');
    }
  }

  void _playControllerAtIndex(int index) {
    // Skip ad positions - they don't need to be played
    if (_adPositions.containsKey(index) && _adPositions[index]!) {
      return;
    }
    
    focusedIndex = index;
    if (mList.length > index && index >= 0) {
      /// Get controller at [index]
      final controller = controllers[index];

      if (controller != null) {
        /// Play controller
        controller.play();
        controller.setLooping(true);
        log('🚀🚀🚀 PLAYING $index');
        
        // Track view interaction with the post
        final String postId = mList[index].postId.toString();
        ApiService().increasePostViewCount(postId);
        ApiService().trackInteraction(postId, 'view');
        
        // Reset watch time tracking for this video
        _videoStartTime = DateTime.now();
        
        setState(() {});
      }
    }
  }

  void _stopControllerAtIndex(int index) {
    // Skip ad positions - they don't need to be stopped
    if (_adPositions.containsKey(index) && _adPositions[index]!) {
      return;
    }
    
    if (mList.length > index && index >= 0) {
      /// Get controller at [index]
      final VideoPlayerController? controller = controllers[index];

      if (controller != null) {
        /// Pause
        controller.pause();

        /// Reset postiton to beginning
        controller.seekTo(const Duration());
        log('==================================');
        log('🚀🚀🚀 STOPPED $index');
      }
    }
  }

  void _disposeControllerAtIndex(int index) {
    // Skip ad positions - they don't need to be disposed
    if (_adPositions.containsKey(index) && _adPositions[index]!) {
      return;
    }
    
    if (mList.length > index && index >= 0) {
      /// Get controller at [index]
      final controller = controllers[index];

      /// Dispose controller
      controller?.dispose();

      if (controller != null) {
        controllers.remove(controller);
      }

      log('🚀🚀🚀 DISPOSED $index');
    }
  }

  void initVideoPlayer() async {
    /// Initialize 1st video
    await _initializeControllerAtIndex(0);

    /// Play 1st video
    _playControllerAtIndex(0);

    /// Initialize 2nd vide
    await _initializeControllerAtIndex(1);
  }

  // Track video watch time to detect quick skips
  DateTime? _videoStartTime;
  Map<int, bool> _videoTracked = {};
  
  void onPageChanged(int value) {
    // Increment video count for ad tracking
    _nativeAdManager.incrementVideoCount();
    
    // Calculate watch time for the previous video to detect skips
    if (_videoStartTime != null && focusedIndex != value) {
      final Duration watchDuration = DateTime.now().difference(_videoStartTime!);
      final int previousIndex = focusedIndex;
      
      // Skip tracking for ad positions
      if (!(_adPositions.containsKey(previousIndex) && _adPositions[previousIndex]!)) {
        // Track video interaction as a skip if watched for less than 2 seconds
        if (watchDuration.inSeconds < 2 && !_videoTracked.containsKey(previousIndex)) {
          // User quickly swiped past this video without watching - track as 'skip'
          final String postId = mList[previousIndex].postId.toString();
          log('User skipped video $postId after ${watchDuration.inMilliseconds}ms');
          
          // Track interaction as skip
          ApiService().trackInteraction(postId, 'skip');
          _videoTracked[previousIndex] = true;
        }
      }
    }
    
    // Reset timer for the new video
    _videoStartTime = DateTime.now();
    
    // Load more videos when approaching the end of the list
    if (value == mList.length - 3) {
      if (!isLoading) {
        callApiForYou(
          (p0) {},
        );
      }
    }
    
    // Preload native ad for upcoming positions
    _preloadFutureAds(value);
    
    if (value > focusedIndex) {
      _playNext(value);
    } else {
      _playPrevious(value);
    }
    
    focusedIndex = value;
  }
  
  // Preloads ads for upcoming positions
  void _preloadFutureAds(int currentIndex) {
    // Preload ads for the next few positions
    for (int i = currentIndex + 1; i < currentIndex + 5 && i < mList.length; i++) {
      if (_nativeAdManager.shouldShowAdAfterIndex(i)) {
        _adPositions[i] = true;
        _preloadAdForPosition(i);
      }
    }
  }

  @override
  void dispose() {
    _nativeAdManager.dispose();
    pageController.dispose();
    super.dispose();
    controllers.forEach((key, value) async {
      await value.dispose();
    });
  }
}
