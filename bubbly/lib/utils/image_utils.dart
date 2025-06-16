import 'package:flutter/foundation.dart';

/// Utility class for handling image URLs safely
class ImageUtils {
  /// Safely constructs a complete image URL by ensuring the base URL and path don't create invalid URLs
  /// 
  /// Prevents issues like:
  /// - Empty file paths
  /// - Double slashes
  /// - Missing file extensions
  static String getValidImageUrl(String baseUrl, String? imagePath) {
    // If path is null or empty, return a placeholder URL instead of the base URL with trailing slash
    if (imagePath == null || imagePath.trim().isEmpty) {
      // Log problematic empty URL request in debug mode
      if (kDebugMode) {
        print('WARNING: Empty image path detected for base URL: $baseUrl');
      }
      
      // Return empty string which will trigger errorBuilder in Image widgets
      return '';
    }
    
    // Remove trailing slash from base URL if it exists and path doesn't start with slash
    String cleanBaseUrl = baseUrl;
    if (cleanBaseUrl.endsWith('/') && !imagePath.startsWith('/')) {
      cleanBaseUrl = cleanBaseUrl.substring(0, cleanBaseUrl.length - 1);
    }
    
    // Ensure path starts with slash if base URL doesn't end with one
    String cleanPath = imagePath;
    if (!cleanBaseUrl.endsWith('/') && !cleanPath.startsWith('/')) {
      cleanPath = '/$cleanPath';
    }
    
    // Final URL should be properly formed
    String finalUrl = '$cleanBaseUrl$cleanPath';
    
    // Log in debug mode
    if (kDebugMode) {
      print('Image URL constructed: $finalUrl');
    }
    
    return finalUrl;
  }
} 