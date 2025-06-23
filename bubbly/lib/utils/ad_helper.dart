import 'dart:io';
import 'dart:async';
import 'package:bubbly/modal/setting/setting.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

/// Helper class for handling native ads
class AdHelper {
  static final SessionManager _sessionManager = SessionManager();
  static SettingData? get _settings => _sessionManager.getSetting()?.data;

  /// Get the appropriate native ad unit ID based on platform
  static String get nativeAdUnitId {
    if (_settings == null) return _getTestAdUnitId();
    
    if (Platform.isAndroid) {
      return _settings!.admobNative ?? _getTestAdUnitId();
    } else if (Platform.isIOS) {
      return _settings!.admobNativeIos ?? _getTestAdUnitId();
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /// Get test ad unit ID for the current platform
  static String _getTestAdUnitId() {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/2247696110'; // Android test native ad ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/3986624511'; // iOS test native ad ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Initialize Google Mobile Ads SDK
  static Future<void> initAds() async {
    await _sessionManager.initPref();
    await MobileAds.instance.initialize();
  }
  
  /// Load a native ad with the specified options and callbacks
  static Future<NativeAd?> loadNativeAd({
    required NativeAdOptions adOptions,
    required void Function(NativeAd ad) onAdLoaded,
    required void Function(LoadAdError error) onAdFailedToLoad,
    bool isGridView = false,
    bool preferVideo = false,
  }) async {
    try {
      final completer = Completer<NativeAd?>();
      
      final nativeAd = NativeAd(
        adUnitId: nativeAdUnitId,
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            onAdLoaded(ad as NativeAd);
            completer.complete(ad as NativeAd);
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            onAdFailedToLoad(error);
            completer.complete(null);
          },
          // Add only supported video callbacks
          onAdOpened: (ad) {
            print('Native ad opened: ${ad.adUnitId}');
          },
          onAdClosed: (ad) {
            print('Native ad closed: ${ad.adUnitId}');
          },
          onAdImpression: (ad) {
            print('Native ad impression recorded');
          },
        ),
        request: AdRequest(
          // Add specific request for video content if preferred
          contentUrl: preferVideo ? 'https://www.youtube.com/watch?v=shortvideos' : null,
          keywords: preferVideo ? ['video', 'short form', 'entertainment'] : null,
        ),
        // Instagram-style native template
        nativeTemplateStyle: NativeTemplateStyle(
          // Use appropriate template size
          templateType: isGridView ? TemplateType.small : TemplateType.medium,
          // Use dark theme colors
          mainBackgroundColor: Colors.black,
          cornerRadius: isGridView ? 8.0 : 0.0,
          // Style for CTA button
          callToActionTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white,
            backgroundColor: Colors.blue[600]!,
            style: NativeTemplateFontStyle.bold,
            size: 14.0,
          ),
          // Style for ad headline
          primaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white,
            backgroundColor: Colors.transparent,
            style: NativeTemplateFontStyle.bold,
            size: 16.0,
          ),
          // Style for advertiser name
          secondaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white70,
            backgroundColor: Colors.transparent,
            style: NativeTemplateFontStyle.normal,
            size: 14.0,
          ),
          // Style for ad body text
          tertiaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white70,
            backgroundColor: Colors.transparent,
            style: NativeTemplateFontStyle.normal,
            size: 13.0,
          ),
        ),
        nativeAdOptions: adOptions,
      );
      
      await nativeAd.load();
      return await completer.future;
    } catch (e) {
      print('Error loading native ad: $e');
      return null;
    }
  }
} 