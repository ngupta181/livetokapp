import 'dart:developer';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/modal/explore/explore_hash_tag.dart';
import 'package:bubbly/modal/user_video/user_video.dart';
import 'package:bubbly/utils/app_res.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/my_loading/my_loading.dart';
import 'package:bubbly/view/hashtag/videos_by_hashtag.dart';
import 'package:bubbly/view/video/video_list_screen.dart';
import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/view/video/item_video.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:bubbly/utils/native_ad_manager.dart';
import 'package:bubbly/custom_view/native_ad_video.dart';

class VideoFeedScreen extends StatefulWidget {
  final List<Data> videos;
  final int initialIndex;

  VideoFeedScreen({required this.videos, required this.initialIndex});

  @override
  _VideoFeedScreenState createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  late PageController _pageController;
  Map<int, VideoPlayerController> controllers = {};
  int focusedIndex = 0;
  final NativeAdManager _nativeAdManager = NativeAdManager.instance;
  Map<int, bool> _adPositions = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    focusedIndex = widget.initialIndex;
    _initializePlayer();
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
    
    // NativeAdManager handles the actual loading
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
        
        if (nativeAd == null) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ColorRes.colorTheme),
            ),
          );
        }
        
        // Record that we're showing an ad
        _nativeAdManager.onAdShown();
        
        return NativeAdVideo(
          nativeAd: nativeAd,
          adPosition: index,
          onAdClosed: () {
            // Skip this ad and move to the next content
            _pageController.nextPage(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          },
        );
      },
    );
  }

  void _initializePlayer() async {
    // Initialize current video
    await _initializeControllerAtIndex(focusedIndex);
    _playControllerAtIndex(focusedIndex);
    
    // Initialize next video if available
    if (focusedIndex < widget.videos.length - 1) {
      await _initializeControllerAtIndex(focusedIndex + 1);
    }
  }

  Future _initializeControllerAtIndex(int index) async {
    if (index >= 0 && index < widget.videos.length && !controllers.containsKey(index)) {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(ConstRes.itemBaseUrl + (widget.videos[index].postVideo ?? '')),
      );
      controllers[index] = controller;
      await controller.initialize();
      setState(() {});
      log('Initialized video at index $index');
    }
  }

  void _playControllerAtIndex(int index) {
    if (controllers[index] != null) {
      controllers[index]!.play();
      controllers[index]!.setLooping(true);
      
      // Track view
      final String postId = widget.videos[index].postId.toString();
      ApiService().increasePostViewCount(postId);
      ApiService().trackInteraction(postId, 'view');
    }
  }

  void _stopControllerAtIndex(int index) {
    if (controllers[index] != null) {
      controllers[index]!.pause();
      controllers[index]!.seekTo(Duration.zero);
    }
  }

  void _disposeControllerAtIndex(int index) {
    if (controllers[index] != null) {
      controllers[index]!.dispose();
      controllers.remove(index);
    }
  }

  void _onPageChanged(int index) {
    // Increment video count for ad tracking
    _nativeAdManager.incrementVideoCount();
    
    // Preload native ad for upcoming positions
    _preloadFutureAds(index);

    if (index > focusedIndex) {
      // Going forward
      _stopControllerAtIndex(focusedIndex);
      _disposeControllerAtIndex(focusedIndex - 1);
      _playControllerAtIndex(index);
      if (index < widget.videos.length - 1) {
        _initializeControllerAtIndex(index + 1);
      }
    } else {
      // Going backward
      _stopControllerAtIndex(focusedIndex);
      _disposeControllerAtIndex(focusedIndex + 1);
      _playControllerAtIndex(index);
      if (index > 0) {
        _initializeControllerAtIndex(index - 1);
      }
    }
    focusedIndex = index;
  }
  
  // Preloads ads for upcoming positions
  void _preloadFutureAds(int currentIndex) {
    // Preload ads for the next few positions
    for (int i = currentIndex + 1; i < currentIndex + 5; i++) {
      if (_nativeAdManager.shouldShowAdAfterIndex(i)) {
        _adPositions[i] = true;
        _preloadAdForPosition(i);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.videos.length,
            itemBuilder: (context, index) {
              // Check if this position should show an ad
              if (_shouldShowAdAtIndex(index)) {
                return _buildNativeAdItem(index);
              }
              
              return ItemVideo(
                videoData: widget.videos[index],
                videoPlayerController: controllers[index],
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nativeAdManager.dispose();
    controllers.forEach((_, controller) => controller.dispose());
    _pageController.dispose();
    super.dispose();
  }
}

class ItemExplore extends StatefulWidget {
  final ExploreData exploreData;
  final MyLoading myLoading;

  ItemExplore({required this.exploreData, required this.myLoading});

  @override
  _ItemExploreState createState() => _ItemExploreState();
}

class _ItemExploreState extends State<ItemExplore> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return VideosByHashTagScreen(widget.exploreData.hashTagName);
        }));
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipOval(
                  child: Container(
                    height: 45,
                    width: 45,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [ColorRes.colorTheme, ColorRes.colorPink],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Text(
                        AppRes.hashTag,
                        style: TextStyle(
                            fontSize: 25,
                            fontFamily: FontRes.fNSfUiHeavy,
                            color: ColorRes.white),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppRes.hashTag}${widget.exploreData.hashTagName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontFamily: FontRes.fNSfUiBold,
                        ),
                      ),
                      Text(
                        '${widget.exploreData.hashTagVideosCount} ${LKey.videos.tr}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            color: ColorRes.colorTextLight,
                            fontFamily: FontRes.fNSfUiLight),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          VideosByHashTagScreen(widget.exploreData.hashTagName),
                    ),
                  ),
                  child: Text(
                    LKey.viewAll.tr,
                    style: TextStyle(
                      fontSize: 13,
                      color: ColorRes.colorTextLight,
                      fontFamily: FontRes.fNSfUiLight,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                )
              ],
            ),
            SizedBox(height: 15),
            if (widget.exploreData.recentVideos != null && 
                widget.exploreData.recentVideos!.isNotEmpty)
              Container(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.exploreData.recentVideos!.length > 15 
                      ? 15 
                      : widget.exploreData.recentVideos!.length,
                  itemBuilder: (context, index) {
                    final video = widget.exploreData.recentVideos![index];
                    return InkWell(
                      onTap: () async {
                        try {
                          final response = await ApiService().getPostByHashTag(
                            "0",
                            "100",
                            widget.exploreData.hashTagName!.replaceAll(AppRes.hashTag, ''),
                          );

                          if (response.data != null && response.data!.isNotEmpty) {
                            final matchingVideoIndex = response.data!.indexWhere(
                              (v) => v.postVideo == video.video,
                            );
                            
                            final initialIndex = matchingVideoIndex >= 0 ? matchingVideoIndex : 0;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoFeedScreen(
                                  videos: response.data!,
                                  initialIndex: initialIndex,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          log('Error fetching video details: $e');
                        }
                      },
                      child: Container(
                        width: 120,
                        margin: EdgeInsets.only(right: 5),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                ConstRes.getImageUrl(video.thumbnail),
                                fit: BoxFit.cover,
                              ),
                              if (index == 14 && widget.exploreData.recentVideos!.length > 15)
                                Container(
                                  color: Colors.black54,
                                  child: Center(
                                    child: Text(
                                      '+${widget.exploreData.recentVideos!.length - 15}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              AspectRatio(
                aspectRatio: 1 / 0.4,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  child: Container(
                    color: ColorRes.colorPrimary,
                    child: Image(
                      height: 165,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      image: NetworkImage(ConstRes.getImageUrl(
                          widget.exploreData.hashTagProfile)),
                    ),
                  ),
                ),
              ),
            SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}
