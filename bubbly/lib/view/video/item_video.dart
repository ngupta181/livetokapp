import 'dart:async';
import 'package:bouncing_widget/bouncing_widget.dart';
import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/custom_view/image_place_holder.dart';
import 'package:bubbly/modal/user_video/user_video.dart';
import 'package:bubbly/utils/app_res.dart';
import 'package:bubbly/utils/assert_image.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/key_res.dart';
import 'package:bubbly/utils/native_ad_manager.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:bubbly/utils/url_res.dart';
import 'package:bubbly/view/comment/comment_screen.dart';
import 'package:bubbly/view/hashtag/videos_by_hashtag.dart';
import 'package:bubbly/view/login/login_sheet.dart';
import 'package:bubbly/view/profile/profile_screen.dart';
import 'package:bubbly/view/report/report_screen.dart';
import 'package:bubbly/view/send_bubble/dialog_send_bubble.dart';
import 'package:bubbly/view/video/widget/like_unlike_button.dart';
import 'package:bubbly/view/video/widget/music_disk.dart';
import 'package:bubbly/view/video/widget/share_sheet.dart';
import 'package:detectable_text_field/detectable_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:bubbly/utils/ad_helper.dart';

// ignore: must_be_immutable
class ItemVideo extends StatefulWidget {
  final Data? videoData;
  ItemVideoState? item;
  final VideoPlayerController? videoPlayerController;

  ItemVideo({this.videoData, this.videoPlayerController});

  @override
  ItemVideoState createState() => ItemVideoState();
}

class ItemVideoState extends State<ItemVideo> {
  bool isLogin = false;
  SessionManager sessionManager = SessionManager();
  DateTime? _startWatchTime;
  Timer? _viewDurationTimer;
  bool _hasTrackedView = false;
  bool isPlaying = false;
  final NativeAdManager _nativeAdManager = NativeAdManager.instance;
  Duration currentPosition = Duration.zero;
  bool isShowingControls = false;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    prefData();
    super.initState();
    
    // Add video playback state listener
    widget.videoPlayerController?.addListener(_videoListener);
    
    // Add position update listener with mounted check
    widget.videoPlayerController?.addListener(_positionListener);
  }

  @override
  void dispose() {
    // First remove all listeners to prevent callbacks after dispose
    widget.videoPlayerController?.removeListener(_videoListener);
    widget.videoPlayerController?.removeListener(_positionListener);
    
    // Cancel timers    
    _viewDurationTimer?.cancel();
    _hideControlsTimer?.cancel();
    
    // Track view duration before disposal
    _trackViewDuration();
    
    // Safely pause the player if it's currently playing
    final wasPlaying = widget.videoPlayerController?.value.isPlaying ?? false;
    if (wasPlaying) {
      _pauseVideoSafely();
    }
    
    // Always call super.dispose() directly (not in an async block)
    super.dispose();
  }

  void _videoListener() {
    if (widget.videoPlayerController?.value.isPlaying != isPlaying) {
      isPlaying = widget.videoPlayerController?.value.isPlaying ?? false;
      
      // Track video count for ad placement if playing
      if (isPlaying) {
        _nativeAdManager.incrementVideoCount();
      }
    }
  }

  // Separate method for position updates to allow clean removal
  void _positionListener() {
    if (!mounted) return;
    
    setState(() {
      currentPosition = widget.videoPlayerController?.value.position ?? Duration.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onLongPress: _onLongPress,
          onTap: () {
            _onTap();
            _showControls();
          },
          child: VisibilityDetector(
            onVisibilityChanged: (VisibilityInfo info) {
              var visiblePercentage = info.visibleFraction * 100;
              if (visiblePercentage > 50) {
                widget.videoPlayerController?.play();
                // Track when user starts viewing video
                _startVideoTracking();
              } else {
                widget.videoPlayerController?.pause();
                // Track when user stops viewing video
                _trackViewDuration();
              }
            },
            key: Key('ke1' + ConstRes.getImageUrl(widget.videoData!.postVideo)),
            child: SizedBox.expand(
              child: FittedBox(
                fit: (widget.videoPlayerController?.value.size.width ?? 0) <
                        (widget.videoPlayerController?.value.size.height ?? 0)
                    ? BoxFit.cover
                    : BoxFit.fitWidth,
                child: SizedBox(
                  width: widget.videoPlayerController?.value.size.width ?? 0,
                  height: widget.videoPlayerController?.value.size.height ?? 0,
                  child: widget.videoPlayerController != null ? VideoPlayer(widget.videoPlayerController!) : SizedBox(),
                ),
              ),
            ),
          ),
        ),
        InkWell(
          onLongPress: _onLongPress,
          onTap: () {
            _onTap();
            _showControls();
          },
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 100,
              width: double.infinity,
              foregroundDecoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.3),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.2, 0.6, 1],
                ),
              ),
            ),
          ),
        ),
        // Add video progress controls
        if (isShowingControls && widget.videoPlayerController != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Time indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(currentPosition),
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      Text(
                        _formatDuration(widget.videoPlayerController?.value.duration ?? Duration.zero),
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Progress bar
                  VideoProgressIndicator(
                    widget.videoPlayerController!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: Colors.white,
                      bufferedColor: Colors.white.withOpacity(0.3),
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Visibility(
                          visible: widget.videoData!.profileCategoryName!.isNotEmpty,
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.grey.shade300, borderRadius: BorderRadius.all(Radius.circular(3))),
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            child: Text(
                              widget.videoData?.profileCategoryName ?? '',
                              style: TextStyle(fontSize: 11, fontFamily: FontRes.fNSfUiSemiBold, color: Colors.black),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfileScreen(type: 1, userId: widget.videoData?.userId.toString() ?? '-1'),
                            ),
                          ),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 5),
                            child: Row(
                              children: [
                                Text(
                                  '${AppRes.atSign}${widget.videoData?.userName}',
                                  style: TextStyle(
                                    fontFamily: FontRes.fNSfUiSemiBold,
                                    letterSpacing: 0.6,
                                    fontSize: 16,
                                    color: ColorRes.white,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Image(
                                  image: AssetImage(icVerify),
                                  height: widget.videoData!.isVerify == 1 ? 18 : 0,
                                  width: widget.videoData!.isVerify == 1 ? 18 : 0,
                                )
                              ],
                            ),
                          ),
                        ),
                        Visibility(
                          visible: widget.videoData!.postDescription!.isNotEmpty,
                          child: Container(
                            margin: EdgeInsets.only(bottom: 5),
                            child: DetectableText(
                              text: widget.videoData?.postDescription ?? '',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              detectedStyle: TextStyle(
                                  fontFamily: FontRes.fNSfUiBold,
                                  letterSpacing: 0.6,
                                  fontSize: 13,
                                  color: ColorRes.white),
                              basicStyle: TextStyle(
                                fontFamily: FontRes.fNSfUiRegular,
                                letterSpacing: 0.6,
                                fontSize: 13,
                                color: ColorRes.white,
                                shadows: [
                                  Shadow(offset: Offset(1, 1), color: Colors.black.withOpacity(0.5), blurRadius: 5),
                                ],
                              ),
                              onTap: (text) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VideosByHashTagScreen(text),
                                  ),
                                );
                              },
                              detectionRegExp: detectionRegExp(hashtag: true)!,
                            ),
                          ),
                        ),
                        Text(
                          widget.videoData?.soundTitle ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: FontRes.fNSfUiMedium,
                            letterSpacing: 0.7,
                            fontSize: 13,
                            color: ColorRes.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      BouncingWidget(
                        duration: Duration(milliseconds: 100),
                        scaleFactor: 1,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return ProfileScreen(type: 1, userId: widget.videoData?.userId.toString() ?? '-1');
                              },
                            ),
                          );
                        },
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(border: Border.all(color: ColorRes.white), shape: BoxShape.circle),
                          child: ClipOval(
                            child: Image.network(
                              ConstRes.itemBaseUrl + widget.videoData!.userProfile!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return ImagePlaceHolder(
                                  heightWeight: 40,
                                  name: widget.videoData?.fullName,
                                  fontSize: 20,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      Visibility(
                        visible: SessionManager.userId != widget.videoData!.userId,
                        child: InkWell(
                          onTap: () {
                            if (SessionManager.userId != -1 || isLogin) {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return DialogSendBubble(widget.videoData);
                                  });
                            } else {
                              showModalBottomSheet(
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                isScrollControlled: true,
                                context: context,
                                builder: (context) {
                                  return LoginSheet();
                                },
                              );
                            }
                          },
                          child: Image.asset(
                            icGift,
                            height: 35,
                            width: 35,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: SessionManager.userId != widget.videoData?.userId ? 15 : 0,
                      ),
                      LikeUnLikeButton(
                        videoData: widget.videoData,
                        likeUnlike: () {
                          if (widget.videoData?.videoLikesOrNot == 1) {
                            widget.videoData?.setVideoLikesOrNot(0);
                            // No need to track unlike as it's covered by the API call
                          } else {
                            widget.videoData?.setVideoLikesOrNot(1);
                            // Track like interaction
                            if (SessionManager.userId != -1) {
                              ApiService().trackInteraction(
                                widget.videoData!.postId.toString(),
                                'like',
                              );
                            }
                          }
                          setState(() {});
                        },
                      ),
                      Text(
                        NumberFormat.compact(locale: 'en').format(widget.videoData?.postLikesCount ?? 0),
                        style: TextStyle(color: ColorRes.white, fontFamily: FontRes.fNSfUiSemiBold),
                      ),
                      SizedBox(height: 15),
                      InkWell(
                        onTap: () {
                          // Track comment interaction
                          if (SessionManager.userId != -1) {
                            ApiService().trackInteraction(
                              widget.videoData!.postId.toString(),
                              'comment',
                            );
                          }
                          
                          Get.bottomSheet(
                            CommentScreen(widget.videoData, () {
                              setState(() {});
                            }),
                            isScrollControlled: true,
                          );
                        },
                        child: Image.asset(icComment, height: 35, width: 35, color: ColorRes.white),
                      ),
                      Text(NumberFormat.compact(locale: 'en').format(widget.videoData?.postCommentsCount ?? 0),
                          style: TextStyle(color: ColorRes.white)),
                      SizedBox(height: 15),
                      InkWell(
                        onTap: () {
                          // Track share interaction
                          if (SessionManager.userId != -1) {
                            ApiService().trackInteraction(
                              widget.videoData!.postId.toString(),
                              'share',
                            );
                          }
                          
                          shareLink(widget.videoData!);
                        },
                        child: Image.asset(icShare, height: 32, width: 32, color: ColorRes.white),
                      ),
                      SizedBox(height: 15),
                      MusicDisk(widget.videoData),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
          ],
        ),
      ],
    );
  }

  void shareLink(Data videoData) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SocialLinkShareSheet(videoData: videoData);
      },
    );
  }

  void _onTap() {
    if (widget.videoPlayerController != null && widget.videoPlayerController!.value.isPlaying) {
      widget.videoPlayerController?.pause();
      // Track view duration when video is paused
      _trackViewDuration();
    } else {
      widget.videoPlayerController?.play();
      // Reset start time when video is played
      _startVideoTracking();
    }
  }

  void _onLongPress() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return ReportScreen(1, widget.videoData!.postId.toString());
        },
        isScrollControlled: true,
        backgroundColor: Colors.transparent);
  }

  void prefData() async {
    await sessionManager.initPref();
    isLogin = sessionManager.getBool(KeyRes.login) ?? false;
    setState(() {});
  }
  
  // Start tracking video view time
  void _startVideoTracking() {
    if (!_hasTrackedView && SessionManager.userId != -1) {
      _hasTrackedView = true;
      // Track initial 'view' interaction when video starts playing
      ApiService().trackInteraction(
        widget.videoData!.postId.toString(),
        'view',
      );
    }
    
    _startWatchTime = DateTime.now();
    
    // Setup timer to periodically track duration
    _viewDurationTimer?.cancel();
    _viewDurationTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _trackViewDuration(periodicUpdate: true);
    });
  }
  
  // Track video view duration
  void _trackViewDuration({bool periodicUpdate = false}) {
    if (_startWatchTime != null && SessionManager.userId != -1) {
      _viewDurationTimer?.cancel();
      
      // Calculate duration in seconds
      final duration = DateTime.now().difference(_startWatchTime!).inSeconds;
      
      // Only track if duration is meaningful (> 1 second)
      if (duration > 1) {
        ApiService().trackInteraction(
          widget.videoData!.postId.toString(),
          'view',
          duration: duration.toString(),
        );
      }
      
      // If this is a periodic update, reset the start time
      if (periodicUpdate) {
        _startWatchTime = DateTime.now();
        // Restart the timer
        _viewDurationTimer = Timer.periodic(Duration(seconds: 10), (timer) {
          _trackViewDuration(periodicUpdate: true);
        });
      } else {
        _startWatchTime = null;
      }
    }
  }

  void _showControls() {
    if (!mounted) return;
    
    // Cancel any existing hide timer
    _hideControlsTimer?.cancel();
    
    setState(() {
      isShowingControls = true;
    });
    
    // Set a new hide timer
    _hideControlsTimer = Timer(Duration(seconds: 3), _hideControls);
  }
  
  void _hideControls() {
    if (!mounted) return;
    
    setState(() {
      isShowingControls = false;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  // Separate method for async operations
  Future<void> _pauseVideoSafely() async {
    try {
      await widget.videoPlayerController?.pause();
    } catch (e) {
      // Ignore errors during disposal
    }
  }
}
