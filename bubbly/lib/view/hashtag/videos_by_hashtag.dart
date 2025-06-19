import 'dart:async';

import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/custom_view/app_bar_custom.dart';
import 'package:bubbly/custom_view/common_ui.dart';
import 'package:bubbly/custom_view/data_not_found.dart';
import 'package:bubbly/custom_view/native_ad_video.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/modal/user_video/user_video.dart';
import 'package:bubbly/utils/app_res.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/my_loading/my_loading.dart';
import 'package:bubbly/utils/native_ad_manager.dart';
import 'package:bubbly/utils/ad_helper.dart';
import 'package:bubbly/view/search/widget/item_search_video.dart';
import 'package:bubbly/view/explore/item_explore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

class VideosByHashTagScreen extends StatefulWidget {
  final String? hashTag;

  VideosByHashTagScreen(this.hashTag);

  @override
  _VideosByHashTagScreenState createState() => _VideosByHashTagScreenState();
}

class _VideosByHashTagScreenState extends State<VideosByHashTagScreen> {
  var start = 0;
  int? count = 0;
  int _currentVideoIndex = 0;
  final NativeAdManager _nativeAdManager = NativeAdManager.instance;
  
  // Track ad positions in grid view
  Map<int, bool> _adPositions = {};
  Map<int, NativeAd?> _loadedAds = {};

  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();
  final StreamController _streamController = StreamController<List<Data>?>();
  List<Data> postList = [];

  @override
  void initState() {
    _initializeAds();
    _scrollController.addListener(
      () {
        if (_scrollController.position.maxScrollExtent == _scrollController.position.pixels) {
          if (!isLoading) {
            callApiForGetPostsByHashTag();
          }
        }
      },
    );
    callApiForGetPostsByHashTag();
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

  void onVideoTap(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoFeedScreen(
          videos: postList,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, MyLoading myLoading, child) {
      return Scaffold(
        body: Column(
          children: [
            AppBarCustom(title: widget.hashTag ?? ''),
            SizedBox(height: 10),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 15),
              height: 80,
              decoration: BoxDecoration(
                color: myLoading.isDark ? ColorRes.colorPrimary : ColorRes.greyShade100,
                borderRadius: BorderRadius.all(Radius.circular(50)),
              ),
              child: Row(
                children: [
                  Container(
                    height: 65,
                    width: 65,
                    margin: EdgeInsets.only(left: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [ColorRes.colorTheme, ColorRes.colorPink],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        AppRes.hashTag,
                        style: TextStyle(fontFamily: FontRes.fNSfUiBold, fontSize: 45, color: ColorRes.white),
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.hashTag ?? '',
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: FontRes.fNSfUiBold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '$count ${LKey.videos.tr}',
                        style: TextStyle(fontSize: 16, color: ColorRes.colorTextLight),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: StreamBuilder(
                stream: _streamController.stream,
                builder: (context, snapshot) {
                  List<Data>? userVideo = [];
                  if (snapshot.data != null) {
                    userVideo = (snapshot.data as List<Data>?)!;
                    postList.addAll(userVideo);
                    _streamController.add(null);
                    
                    // Prepare native ads for new content
                    _preloadAdsForNewContent(postList.length);
                  }

                  return isLoading && postList.isEmpty
                      ? CommonUI.getWidgetLoader()
                      : postList.isEmpty
                          ? DataNotFound()
                          : GridView.builder(
                              shrinkWrap: true,
                              controller: _scrollController,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1 / 1.4,
                              ),
                              physics: BouncingScrollPhysics(),
                              padding: EdgeInsets.only(left: 10, bottom: 20),
                              itemCount: _calculateItemCount(postList.length),
                              itemBuilder: (context, index) {
                                // Check if this is an ad position
                                if (_shouldShowAdAtIndex(index)) {
                                  return _buildGridAdItem(index);
                                }
                                
                                // Calculate the actual post index accounting for ads
                                final postIndex = _getPostIndex(index);
                                
                                return GestureDetector(
                                  onTap: () => onVideoTap(postIndex),
                                  child: ItemSearchVideo(
                                    videoData: postList[postIndex],
                                    postList: postList,
                                    type: 4,
                                    hashTag: widget.hashTag,
                                  ),
                                );
                              },
                            );
                },
              ),
            ),
          ],
        ),
      );
    });
  }
  
  // Calculate total item count including ads
  int _calculateItemCount(int postCount) {
    // Add approximately one ad for every 8 items
    final adCount = (postCount / 8).floor();
    return postCount + adCount;
  }
  
  // Check if the position should show an ad
  bool _shouldShowAdAtIndex(int index) {
    // First few items should not be ads
    if (index < 6) return false;
    
    // Cache the result to maintain consistency
    if (_adPositions.containsKey(index)) {
      return _adPositions[index]!;
    }
    
    // Show an ad approximately every 8 items
    // Use a formula that creates a natural spread
    bool isAdPosition = (index + 1) % 8 == 0;
    _adPositions[index] = isAdPosition;
    
    // Preload the ad if this is an ad position
    if (isAdPosition) {
      _preloadAdForPosition(index);
    }
    
    return isAdPosition;
  }
  
  // Get the actual post index accounting for ads
  int _getPostIndex(int gridIndex) {
    // Count how many ads appear before this position
    int adCount = 0;
    for (int i = 0; i < gridIndex; i++) {
      if (_adPositions[i] == true) {
        adCount++;
      }
    }
    return gridIndex - adCount;
  }
  
  // Preload native ad for the given position
  Future<void> _preloadAdForPosition(int position) async {
    // Only preload if this is actually an ad position
    if (_adPositions[position] != true) return;
    
    try {
      // NativeAdManager handles the actual loading
      // Use isGridView=true since this is displayed in a grid
      await _nativeAdManager.preloadNativeAd(position, isGridView: true);
      
      // Force rebuild if the widget is still mounted
      if (mounted) setState(() {});
    } catch (e) {
      print('Error preloading ad for position $position: $e');
    }
  }
  
  // Preload ads for newly loaded content
  void _preloadAdsForNewContent(int totalItems) {
    final int itemCount = _calculateItemCount(totalItems);
    for (int i = 0; i < itemCount; i++) {
      if (_shouldShowAdAtIndex(i) && !_loadedAds.containsKey(i)) {
        _preloadAdForPosition(i);
      }
    }
  }
  
  // Build the grid ad item
  Widget _buildGridAdItem(int index) {
    return FutureBuilder<NativeAd?>(
      future: _nativeAdManager.preloadNativeAd(index, isGridView: true),
      builder: (context, snapshot) {
        final nativeAd = snapshot.data;
        
        if (nativeAd == null) {
          return Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ColorRes.colorTheme),
              ),
            ),
          );
        }
        
        // Record that we're showing an ad
        _nativeAdManager.onAdShown();
        
        return Container(
          margin: EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: NativeAdVideo(
              nativeAd: nativeAd,
              adPosition: index,
              height: 250,
              onAdClosed: () {
                // Remove this ad from loaded ads
                _nativeAdManager.disposeAd(index);
                _adPositions[index] = false;
                setState(() {});
              },
            ),
          ),
        );
      },
    );
  }

  void callApiForGetPostsByHashTag() {
    ApiService()
        .getPostByHashTag(
      start.toString(),
      paginationLimit.toString(),
      widget.hashTag!.replaceAll(AppRes.hashTag, ''),
    )
        .then(
      (value) {
        start += paginationLimit;
        isLoading = false;
        if (count == 0) {
          count = value.totalVideos;
          setState(() {});
        }
        _streamController.add(value.data);
      },
    );
  }

  @override
  void dispose() {
    // Clean up all loaded ads
    _loadedAds.forEach((key, ad) {
      ad?.dispose();
    });
    _loadedAds.clear();
    _nativeAdManager.dispose();
    
    _scrollController.dispose();
    _streamController.close();
    super.dispose();
  }
}
