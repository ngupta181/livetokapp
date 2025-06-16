import 'dart:io';
import 'dart:async';
import 'package:bubbly/modal/setting/setting.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  static final SessionManager _sessionManager = SessionManager();
  static SettingData? get _settings => _sessionManager.getSetting()?.data;

  static String get bannerAdUnitId {
    if (_settings == null) return _getTestAdUnitId(AdType.banner);
    
    if (Platform.isAndroid) {
      return _settings!.admobBanner ?? _getTestAdUnitId(AdType.banner);
    } else if (Platform.isIOS) {
      return _settings!.admobBannerIos ?? _getTestAdUnitId(AdType.banner);
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (_settings == null) return _getTestAdUnitId(AdType.interstitial);
    
    if (Platform.isAndroid) {
      return _settings!.admobInt ?? _getTestAdUnitId(AdType.interstitial);
    } else if (Platform.isIOS) {
      return _settings!.admobIntIos ?? _getTestAdUnitId(AdType.interstitial);
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String _getTestAdUnitId(AdType type) {
    if (Platform.isAndroid) {
      switch (type) {
        case AdType.banner:
          return 'ca-app-pub-3940256099942544/6300978111';
        case AdType.interstitial:
          return 'ca-app-pub-3940256099942544/1033173712';
        case AdType.rewarded:
          return 'ca-app-pub-3940256099942544/5224354917';
      }
    } else if (Platform.isIOS) {
      switch (type) {
        case AdType.banner:
          return 'ca-app-pub-3940256099942544/2934735716';
        case AdType.interstitial:
          return 'ca-app-pub-3940256099942544/4411468910';
        case AdType.rewarded:
          return 'ca-app-pub-3940256099942544/1712485313';
      }
    }
    throw UnsupportedError('Unsupported platform');
  }

  static Future<void> initAds() async {
    await _sessionManager.initPref();
    await MobileAds.instance.initialize();
  }

  static Future<InterstitialAd?> loadInterstitialAd() async {
    try {
      final completer = Completer<InterstitialAd>();
      
      InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) => completer.complete(ad),
          onAdFailedToLoad: (error) => completer.complete(null),
        ),
      );

      return await completer.future;
    } catch (e) {
      print('Error loading interstitial ad: $e');
      return null;
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Test ad unit ID for Android
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // Test ad unit ID for iOS
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static Future<RewardedAd?> loadRewardedAd() async {
    try {
      final completer = Completer<RewardedAd>();
      
      RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) => completer.complete(ad),
          onAdFailedToLoad: (error) => completer.complete(null),
        ),
      );

      return await completer.future;
    } catch (e) {
      print('Error loading rewarded ad: $e');
      return null;
    }
  }
}

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  int _videoCount = 0;
  int _totalVideosWatched = 0;
  DateTime? _sessionStartTime;
  DateTime? _lastAdTime;
  InterstitialAd? _interstitialAd;
  Timer? _midRollTimer;
  Timer? _adDurationTimer;
  bool _isAdScheduled = false;
  static final SessionManager _sessionManager = SessionManager();
  
  // Ad duration and timing constants
  static const int _minTimeBetweenAds = 120; // 2 minutes
  static const int _maxAdsPerSession = 5;
  static const int _midRollDelay = 8; // Show ad after 8 seconds
  static const int _maxAdDuration = 15; // Maximum ad duration in seconds
  static const int _minAdDuration = 5; // Minimum ad duration before skip option
  int _adsShownInSession = 0;
  bool _canSkipAd = false;
  bool _isInterstitialAdReady = false;

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

  void _initializeSession() {
    if (_sessionStartTime == null || 
        DateTime.now().difference(_sessionStartTime!).inMinutes >= 30) {
      _sessionStartTime = DateTime.now();
      _adsShownInSession = 0;
    }
  }

  bool _canShowAd() {
    _initializeSession();
    
    if (_adsShownInSession >= _maxAdsPerSession) {
      return false;
    }

    if (_lastAdTime != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastAdTime!).inSeconds;
      if (timeSinceLastAd < _minTimeBetweenAds) {
        return false;
      }
    }

    return true;
  }

  void startVideoPlayback() {
    // Cancel any existing timer
    _midRollTimer?.cancel();
    
    if (_videoCount >= _videosBetweenAds && !_isAdScheduled && _canShowAd()) {
      // Schedule mid-roll ad
      _isAdScheduled = true;
      _midRollTimer = Timer(Duration(seconds: _midRollDelay), () {
        showInterstitialAd();
        _videoCount = 0;
        _isAdScheduled = false;
      });
    }
  }

  void pauseVideoPlayback() {
    // Cancel scheduled ad if video is paused
    _midRollTimer?.cancel();
    _isAdScheduled = false;
  }

  void incrementVideoCount() {
    _videoCount++;
    _totalVideosWatched++;
  }

  Future<void> preloadAds() async {
    // Dispose any existing ad first
    if (_interstitialAd != null) {
      _interstitialAd!.dispose();
      _interstitialAd = null;
    }
    
    _isInterstitialAdReady = false;
    _interstitialAd = await AdHelper.loadInterstitialAd();
    
    if (_interstitialAd != null) {
      // Configure the ad callback right after loading
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (InterstitialAd ad) {
          // Start timers for ad duration control
          _startAdDurationTimers();
        },
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          _cleanupAdTimers();
          _isInterstitialAdReady = false;
          ad.dispose();
          // Preload next ad
          preloadAds();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          print('Ad failed to show: ${error.message}');
          _cleanupAdTimers();
          _isInterstitialAdReady = false;
          ad.dispose();
          preloadAds();
        },
      );
      _isInterstitialAdReady = true;
    }
  }

  Future<void> showInterstitialAd() async {
    // If ad is not ready, try to load it first
    if (!_isInterstitialAdReady || _interstitialAd == null) {
      await preloadAds();
    }

    // Double check if ad is ready after loading attempt
    if (_isInterstitialAdReady && _interstitialAd != null && _canShowAd()) {
      try {
        _lastAdTime = DateTime.now();
        _adsShownInSession++;
        _canSkipAd = false;

        await _interstitialAd!.show();
      } catch (e) {
        print('Error showing ad: $e');
        // If showing fails, mark as not ready and reload
        _isInterstitialAdReady = false;
        preloadAds();
      }
    } else {
      // If ad still not ready, schedule a reload for next time
      preloadAds();
    }
  }

  void _startAdDurationTimers() {
    // Timer for enabling skip button
    Timer(Duration(seconds: _minAdDuration), () {
      _canSkipAd = true;
    });

    // Timer for auto-closing ad
    _adDurationTimer = Timer(Duration(seconds: _maxAdDuration), () {
      _interstitialAd?.dispose();
      preloadAds();
    });
  }

  void _cleanupAdTimers() {
    _adDurationTimer?.cancel();
    _canSkipAd = false;
  }

  bool get canSkipAd => _canSkipAd;

  void skipAd() {
    if (_canSkipAd && _interstitialAd != null) {
      _interstitialAd?.dispose();
      preloadAds();
    }
  }

  void dispose() {
    _midRollTimer?.cancel();
    _adDurationTimer?.cancel();
    if (_interstitialAd != null) {
      _interstitialAd!.dispose();
      _interstitialAd = null;
    }
    _isInterstitialAdReady = false;
  }
}

enum AdType {
  banner,
  interstitial,
  rewarded,
} 