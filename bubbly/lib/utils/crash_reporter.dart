import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// A utility class to help with Crashlytics reporting
class CrashReporter {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  
  /// Initialize Crashlytics with user information
  static Future<void> initialize({int? userId, String? userEmail}) async {
    if (kDebugMode) {
      // Force enable Crashlytics collection in debug mode
      await _crashlytics.setCrashlyticsCollectionEnabled(true);
    }
    
    // Set user identifiers if available
    if (userId != null) {
      await _crashlytics.setUserIdentifier(userId.toString());
    }
    
    if (userEmail != null) {
      await _crashlytics.setCustomKey('user_email', userEmail);
    }
  }
  
  /// Log a non-fatal error with stack trace
  static Future<void> logError(dynamic error, StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, dynamic>? customKeys,
  }) async {
    try {
      // Add any custom keys provided
      if (customKeys != null) {
        for (var entry in customKeys.entries) {
          await _crashlytics.setCustomKey(entry.key, entry.value.toString());
        }
      }
      
      // Log the error
      await _crashlytics.recordError(
        error,
        stackTrace,
        fatal: fatal,
      );
    } catch (e) {
      // Failsafe in case Crashlytics itself fails
      debugPrint('Failed to record error to Crashlytics: $e');
    }
  }

  /// Log image loading error with additional context
  static Future<void> logImageError(String imageUrl, dynamic error, StackTrace? stackTrace) async {
    try {
      // Add specific image error keys
      await _crashlytics.setCustomKey('failed_image_url', imageUrl);
      await _crashlytics.setCustomKey('image_error_type', error.runtimeType.toString());
      
      // Add a breadcrumb for the error
      _crashlytics.log('Image loading failed: $imageUrl');
      
      // Record the error as non-fatal
      await _crashlytics.recordError(
        'Image loading error: $error',
        stackTrace,
        reason: 'Network image failed to load',
        fatal: false,
      );
    } catch (e) {
      // Failsafe in case Crashlytics itself fails
      debugPrint('Failed to record image error to Crashlytics: $e');
    }
  }

  /// Add custom log message as breadcrumb
  static void log(String message) {
    _crashlytics.log(message);
  }
  
  /// Record a caught exception that was handled but you still want to track
  static Future<void> recordCaughtException(dynamic exception, StackTrace? stack) async {
    await _crashlytics.recordError(
      exception,
      stack,
      reason: 'Caught exception',
      fatal: false,
    );
  }
  
  /// Add custom keys for better organization of crashes
  static Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);
  }
  
  /// Test crashlytics by forcing a crash
  /// Only use this for testing purposes!
  static void forceCrash() {
    _crashlytics.crash();
  }
} 