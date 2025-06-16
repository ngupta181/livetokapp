import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'crash_reporter.dart';

/// A reusable widget for loading network images with proper error handling
class SafeNetworkImage extends StatelessWidget {
  /// The URL of the image to load
  final String imageUrl;
  
  /// Width of the image
  final double? width;
  
  /// Height of the image
  final double? height;
  
  /// How to fit the image in the available space
  final BoxFit fit;
  
  /// Placeholder widget to show while image is loading
  final Widget? placeholder;
  
  /// Error widget to show if image fails to load
  final Widget? errorWidget;
  
  /// Optional cache key for CachedNetworkImage
  final String? cacheKey;
  
  /// Border radius for the image
  final BorderRadius? borderRadius;
  
  /// Background color
  final Color? backgroundColor;

  /// Creates a SafeNetworkImage
  const SafeNetworkImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.cacheKey,
    this.borderRadius,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Don't try to load empty URLs
    if (imageUrl.isEmpty) {
      if (kDebugMode) {
        print('Empty image URL provided');
      }
      return _buildErrorWidget(context);
    }

    // Use ClipRRect if borderRadius is provided
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: _buildCachedImage(),
      );
    }
    
    return _buildCachedImage();
  }

  Widget _buildCachedImage() {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheKey: cacheKey,
      placeholder: (context, url) => _buildPlaceholder(context),
      errorWidget: (context, url, error) {
        // Log the error to Crashlytics
        CrashReporter.logImageError(url, error, null);
        return _buildErrorWidget(context);
      },
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholder != null) {
      return placeholder!;
    }
    
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    if (errorWidget != null) {
      return errorWidget!;
    }
    
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey[400],
          size: (width != null && height != null) 
              ? (width! < height! ? width! * 0.5 : height! * 0.5) 
              : 24.0,
        ),
      ),
    );
  }
} 