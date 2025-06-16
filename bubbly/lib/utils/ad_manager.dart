import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:bubbly/utils/ad_helper.dart';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  // Singleton instance
  static AdManager get instance => _instance;

  // Ad frequency management
  int _totalVideosWatched = 0;
  DateTime? _sessionStartTime;
  int _adsShownInSession = 0;
  DateTime? _lastAdShown;
  static const int MAX_ADS_PER_SESSION = 5;
  static const int SESSION_DURATION_MINUTES = 30;
  static const int MIN_TIME_BETWEEN_ADS_SECONDS = 120;

  void onVideoWatched() {
    _totalVideosWatched++;
    _checkSession();
  }

  void onAdShown() {
    _adsShownInSession++;
    _lastAdShown = DateTime.now();
  }

  bool canShowAd() {
    _checkSession();
    
    // Check session limits
    if (_adsShownInSession >= MAX_ADS_PER_SESSION) return false;
    
    // Check minimum time between ads
    if (_lastAdShown != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastAdShown!).inSeconds;
      if (timeSinceLastAd < MIN_TIME_BETWEEN_ADS_SECONDS) return false;
    }
    
    return true;
  }

  int getCurrentAdFrequency({int adminConfigured = 5}) {
    if (_totalVideosWatched < 10) {
      return 8; // Show ad every 8 videos for first 10 videos
    } else if (_totalVideosWatched < 20) {
      return 6; // Show ad every 6 videos for videos 10-20
    } else {
      return adminConfigured; // Use admin-configured frequency (default 5) after 20 videos
    }
  }

  bool shouldShowAdAfterIndex(int index, {int adminConfigured = 5}) {
    int frequency = getCurrentAdFrequency(adminConfigured: adminConfigured);
    return (index + 1) % frequency == 0 && canShowAd();
  }

  void _checkSession() {
    if (_sessionStartTime == null || 
        DateTime.now().difference(_sessionStartTime!).inMinutes >= SESSION_DURATION_MINUTES) {
      _sessionStartTime = DateTime.now();
      _adsShownInSession = 0;
    }
  }

  void reset() {
    _totalVideosWatched = 0;
    _sessionStartTime = null;
    _adsShownInSession = 0;
    _lastAdShown = null;
  }
} 