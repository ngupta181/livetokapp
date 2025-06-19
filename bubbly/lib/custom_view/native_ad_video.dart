import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Widget that displays a native ad in the video feed
class NativeAdVideo extends StatefulWidget {
  final NativeAd? nativeAd;
  final VoidCallback? onAdClosed;
  final int adPosition;
  final double height;
  final bool isGridView;
  
  const NativeAdVideo({
    Key? key, 
    required this.nativeAd,
    required this.adPosition,
    this.onAdClosed,
    this.height = 500,
    this.isGridView = false,
  }) : super(key: key);

  @override
  State<NativeAdVideo> createState() => _NativeAdVideoState();
}

class _NativeAdVideoState extends State<NativeAdVideo> {
  bool _isAdVisible = true;

  @override
  void dispose() {
    // Note: don't dispose the ad here, as it's managed by NativeAdManager
    super.dispose();
  }

  void _handleSkipAd() {
    setState(() {
      _isAdVisible = false;
    });
    widget.onAdClosed?.call();
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.nativeAd == null || !_isAdVisible) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    
    return Container(
      width: size.width,
      height: size.height,
      color: Colors.black,
      child: Stack(
        children: [
          // Centered Ad Container
          Center(
            child: Container(
              width: size.width,
              height: size.height - 160, // Account for top and bottom spacing
              margin: EdgeInsets.only(
                top: topPadding + 80, // Increased space for top bar and tabs
                bottom: 80, // Space for bottom actions
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(widget.isGridView ? 8 : 0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.isGridView ? 8 : 0),
                child: AdWidget(ad: widget.nativeAd!),
              ),
            ),
          ),

          // Top Bar with Sponsored and Skip - Moved lower to avoid tab overlap
          Positioned(
            top: topPadding + 48, // Increased top padding to move below tabs
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Sponsored Label
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Sponsored',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: FontRes.fNSfUiMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Skip Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleSkipAd,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Skip Ad',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontFamily: FontRes.fNSfUiMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Content Area (App Info)
          // Positioned(
          //   left: 0,
          //   right: 0,
          //   bottom: 80, // Align with bottom action buttons
          //   child: Container(
          //     padding: const EdgeInsets.all(16),
          //     decoration: BoxDecoration(
          //       gradient: LinearGradient(
          //         begin: Alignment.bottomCenter,
          //         end: Alignment.topCenter,
          //         colors: [
          //           Colors.black.withOpacity(0.8),
          //           Colors.transparent,
          //         ],
          //       ),
          //     ),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         // App Icon and Name Row
          //         Row(
          //           children: [
          //             Container(
          //               width: 40,
          //               height: 40,
          //               decoration: BoxDecoration(
          //                 borderRadius: BorderRadius.circular(8),
          //                 color: Colors.white.withOpacity(0.1),
          //               ),
          //               margin: EdgeInsets.only(right: 12),
          //             ),
          //             Expanded(
          //               child: Column(
          //                 crossAxisAlignment: CrossAxisAlignment.start,
          //                 children: [
          //                   Text(
          //                     'App Name',
          //                     style: TextStyle(
          //                       color: Colors.white,
          //                       fontSize: 16,
          //                       fontWeight: FontWeight.bold,
          //                       fontFamily: FontRes.fNSfUiBold,
          //                     ),
          //                   ),
          //                   Text(
          //                     'Sponsored',
          //                     style: TextStyle(
          //                       color: Colors.white70,
          //                       fontSize: 12,
          //                       fontFamily: FontRes.fNSfUiMedium,
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //             ),
          //             // Install Button
          //             Container(
          //               padding: EdgeInsets.symmetric(
          //                 horizontal: 20,
          //                 vertical: 8,
          //               ),
          //               decoration: BoxDecoration(
          //                 color: Colors.blue[600],
          //                 borderRadius: BorderRadius.circular(20),
          //               ),
          //               child: Text(
          //                 'INSTALL',
          //                 style: TextStyle(
          //                   color: Colors.white,
          //                   fontSize: 14,
          //                   fontWeight: FontWeight.bold,
          //                   fontFamily: FontRes.fNSfUiBold,
          //                 ),
          //               ),
          //             ),
          //           ],
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
} 