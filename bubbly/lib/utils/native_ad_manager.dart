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
  
  // Tracking video counts between ads
  int _totalVideosWatched = 0;
  DateTime? _sessionStartTime;
  int _adsShownInSession = 0;
  DateTime? _lastAdTime;
  
  // Ad constants
  static const int _minTimeBetweenAds = 60; // 1 minute
  static const int _maxAdsPerSession = 8;
  static const int SESSION_DURATION_MINUTES = 30;
  
  // Ad frequency and session management
  final SessionManager _sessionManager = SessionManager();

  /// Returns ad frequency based on user engagement
  int get _videosBetweenAds {
    // Progressive frequency based on total videos watched
    if (_totalVideosWatched < 10) {
      return 8;
    } else if (_totalVideosWatched < 20) {
      return 6;
    } else {
      return _sessionManager.getSetting()?.data?.videosBetweenAds ?? 5;
    }
  }
  
  /// Tracks video view count
  void incrementVideoCount() {
    _totalVideosWatched++;
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

  /// Determines if ad should be shown at this video position
  bool shouldShowAdAfterIndex(int index) {
    // Increment index by 1 to make it 1-based for more intuitive frequency calculation
    int position = index + 1;
    return position % _videosBetweenAds == 0 && canShowAd();
  }
  
  /// Pre-loads native ads for upcoming positions
  Future<NativeAd?> preloadNativeAd(int position, {bool isGridView = false}) async {
    // Check if we already have a loaded ad for this position
    if (_loadedAds.containsKey(position)) {
      return _loadedAds[position];
    }
    
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
      final nativeAd = await AdHelper.loadNativeAd(
        adOptions: adOptions,
        isGridView: isGridView,
        onAdLoaded: (ad) {
          _loadedAds[position] = ad;
        },
        onAdFailedToLoad: (error) {
          print('Native ad failed to load for position $position: ${error.message}');
        },
      );
      
      return nativeAd;
    } catch (e) {
      print('Error loading native ad: $e');
      return null;
    }
  }
  
  /// Records when an ad is shown
  void onAdShown() {
    _lastAdTime = DateTime.now();
    _adsShownInSession++;
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
  }
} 