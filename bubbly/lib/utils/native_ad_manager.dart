import 'package:bubbly/utils/ad_helper.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';

/// Manages native ads displayed in video feed
class NativeAdManager {
  static final NativeAdManager _instance = NativeAdManager._internal();
  factory NativeAdManager() => _instance;
  NativeAdManager._internal();

  // Singleton instance accessor
  static NativeAdManager get instance => _instance;
  
  // Map to track native ads by position index
  final Map<int, NativeAd> _loadedAds = {};
  
  // Track positions where ads are actively loading
  final Set<int> _loadingPositions = {};
  
  // Tracking video counts between ads
  int _totalVideosWatched = 0;
  DateTime? _sessionStartTime;
  int _adsShownInSession = 0;
  DateTime? _lastAdTime;
  
  // Ad constants
  static const int _minTimeBetweenAds = 60; // 1 minute
  static const int _maxAdsPerSession = 8;
  static const int SESSION_DURATION_MINUTES = 30;
  
  // TikTok-style algorithm variables
  int _viewsWithoutAds = 0;  // Track consecutive non-ad views
  int _totalAdViews = 0;     // Total ad views by the user
  final Map<int, bool> _adShownPositions = {}; // Track where ads were shown
  
  // Ad frequency and session management
  final SessionManager _sessionManager = SessionManager();

  /// Returns ad frequency based on user engagement and TikTok-style algorithm
  int get _videosBetweenAds {
    // Progressive frequency based on total videos watched
    if (_totalVideosWatched < 10) {
      return 8;  // New users see fewer ads
    } else if (_totalVideosWatched < 20) {
      return 6;
    } else if (_totalAdViews > 15) {
      // Slightly increase frequency for users who've seen many ads (retention protection)
      return (_sessionManager.getSetting()?.data?.videosBetweenAds ?? 5) + 1;
    } else {
      return _sessionManager.getSetting()?.data?.videosBetweenAds ?? 5;
    }
  }
  
  /// Tracks video view count with TikTok-style engagement awareness
  void incrementVideoCount() {
    _totalVideosWatched++;
    _viewsWithoutAds++;
    _checkSession();
  }
  
  /// Manages session time limits
  void _checkSession() {
    if (_sessionStartTime == null || 
        DateTime.now().difference(_sessionStartTime!).inMinutes >= SESSION_DURATION_MINUTES) {
      _sessionStartTime = DateTime.now();
      _adsShownInSession = 0;
    }
  }
  
  /// Determines if we can show an ad based on frequency and session limits
  bool canShowAd() {
    _checkSession();
    
    // Check session limits
    if (_adsShownInSession >= _maxAdsPerSession) {
      return false;
    }
    
    // Check minimum time between ads
    if (_lastAdTime != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastAdTime!).inSeconds;
      if (timeSinceLastAd < _minTimeBetweenAds) {
        return false;
      }
    }
    
    return true;
  }

  /// Instagram/TikTok use a more sophisticated algorithm than just exact counts
  /// This simulates their "variable frequency" approach
  bool shouldShowAdAfterIndex(int index) {
    // Don't show ads too early in the feed (first few videos are ad-free)
    if (index < 3) return false;
    
    // Check if we've already decided for this position
    if (_adShownPositions.containsKey(index)) {
      return _adShownPositions[index]!;
    }
    
    // Increment index by 1 to make it 1-based for more intuitive frequency calculation
    int position = index + 1;
    
    // Base logic: frequency check
    bool shouldShow = position % _videosBetweenAds == 0;
    
    // TikTok-style modifications:
    
    // 1. Randomized variation (slightly randomizes ad placement)
    if (!shouldShow && position > 5 && _viewsWithoutAds > (_videosBetweenAds - 1)) {
      // Random chance to show ad earlier to create less predictable pattern
      shouldShow = (DateTime.now().millisecondsSinceEpoch % 3 == 0); 
    }
    
    // 2. Engagement protection: don't interrupt highly engaged sessions
    if (shouldShow && _viewsWithoutAds < 3) {
      // User just started viewing videos after an ad, give them a break
      shouldShow = false;
    }
    
    // 3. Session limits still apply
    if (shouldShow && !canShowAd()) {
      shouldShow = false;
    }
    
    // Cache the decision
    _adShownPositions[index] = shouldShow;
    
    return shouldShow;
  }
  
  /// Pre-loads native ads for upcoming positions with better performance management
  Future<NativeAd?> preloadNativeAd(int position, {bool isGridView = false}) async {
    // Check if we already have a loaded ad for this position
    if (_loadedAds.containsKey(position)) {
      return _loadedAds[position];
    }
    
    // Check if we're already loading an ad for this position
    if (_loadingPositions.contains(position)) {
      // Wait until the ad finishes loading (or 3 seconds max)
      int attempts = 0;
      while (_loadingPositions.contains(position) && attempts < 30) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      
      // Return the loaded ad if available
      if (_loadedAds.containsKey(position)) {
        return _loadedAds[position];
      }
    }
    
    // Mark this position as loading
    _loadingPositions.add(position);
    
    // Create native ad options for video feed
    final adOptions = NativeAdOptions(
      adChoicesPlacement: AdChoicesPlacement.topRightCorner,
      mediaAspectRatio: isGridView ? MediaAspectRatio.portrait : MediaAspectRatio.landscape,
      videoOptions: VideoOptions(
        startMuted: true,
        clickToExpandRequested: true,
      ),
    );
    
    try {
      // Try to load a native video ad first (preferred for full-screen video feed)
      final nativeAd = await AdHelper.loadNativeAd(
        adOptions: adOptions,
        isGridView: isGridView,
        preferVideo: !isGridView, // Prefer video ads for full-screen feed
        onAdLoaded: (ad) {
          _loadedAds[position] = ad;
          _loadingPositions.remove(position);
          
          // If this is a success, start preloading the next potential ad position
          _preloadNextPosition(position);
        },
        onAdFailedToLoad: (error) {
          print('Native ad failed to load for position $position: ${error.message}');
          _loadingPositions.remove(position);
          
          // Attempt to load a regular native ad as fallback if video native failed
          // Error code 3 is NO_FILL in AdMob
          if (!isGridView && error.code != 3) {
            _tryLoadFallbackAd(position, isGridView, adOptions);
          }
        },
      );
      
      return nativeAd;
    } catch (e) {
      print('Error loading native ad: $e');
      _loadingPositions.remove(position);
      return null;
    }
  }
  
  /// Preload the next potential ad position based on frequency
  void _preloadNextPosition(int currentPosition) {
    // Calculate the next potential ad position
    final nextAdPosition = currentPosition + _videosBetweenAds;
    
    // Only preload if we're not already loading this position and it's not already loaded
    if (!_loadingPositions.contains(nextAdPosition) && !_loadedAds.containsKey(nextAdPosition)) {
      // Delay the preload slightly to avoid resource contention
      Future.delayed(const Duration(milliseconds: 500), () {
        preloadNativeAd(nextAdPosition, isGridView: false);
      });
    }
  }
  
  /// Tries to load a fallback ad when primary ad loading fails
  Future<void> _tryLoadFallbackAd(int position, bool isGridView, NativeAdOptions adOptions) async {
    try {
      _loadingPositions.add(position);
      
      // Try loading a regular native ad as fallback with less strict requirements
      final fallbackAd = await AdHelper.loadNativeAd(
        adOptions: adOptions,
        isGridView: isGridView,
        preferVideo: false, // Don't require video in fallback
        onAdLoaded: (ad) {
          _loadedAds[position] = ad;
          _loadingPositions.remove(position);
        },
        onAdFailedToLoad: (error) {
          print('Fallback native ad failed to load: ${error.message}');
          _loadingPositions.remove(position);
        },
      );
      
      if (fallbackAd != null) {
        _loadedAds[position] = fallbackAd;
      }
    } catch (e) {
      print('Error loading fallback ad: $e');
      _loadingPositions.remove(position);
    }
  }
  
  /// Records when an ad is shown with TikTok-style metrics
  void onAdShown() {
    _lastAdTime = DateTime.now();
    _adsShownInSession++;
    _totalAdViews++;
    _viewsWithoutAds = 0; // Reset consecutive views counter
  }
  
  /// Removes an ad from loaded ads map
  void disposeAd(int position) {
    if (_loadedAds.containsKey(position)) {
      _loadedAds[position]?.dispose();
      _loadedAds.remove(position);
    }
  }
  
  /// Clears all loaded ads
  void dispose() {
    _loadedAds.forEach((key, ad) {
      ad.dispose();
    });
    _loadedAds.clear();
    _loadingPositions.clear();
  }
} 