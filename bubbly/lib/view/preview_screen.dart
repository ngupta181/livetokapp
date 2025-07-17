import 'dart:io';
import 'dart:math';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/custom_view/app_bar_custom.dart';
import 'package:bubbly/custom_view/common_ui.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/modal/nudity/nudity_checker.dart';
import 'package:bubbly/modal/nudity/nudity_media_id.dart';
import 'package:bubbly/modal/setting/setting.dart';
import 'package:bubbly/modal/sound/sound.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:bubbly/view/main/main_screen.dart';
import 'package:bubbly/view/music/music_screen.dart';
import 'package:bubbly/view/upload/upload_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';

class PreviewScreen extends StatefulWidget {
  final String? postVideo;
  final String? thumbNail;
  final String? sound;
  final String? soundId;
  final int duration;

  PreviewScreen({this.postVideo, this.thumbNail, this.sound, this.soundId, required this.duration});

  @override
  _PreviewScreenState createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool isMuted = false;
  double videoVolume = 1.0;
  double musicVolume = 1.0;
  String? selectedMusicPath;
  String? selectedMusicId;
  AudioPlayer? _audioPlayer;
  bool isProcessing = false;
  bool isVideoReady = false;
  bool isMusicReady = false;
  bool _hasAudioFocus = false;
  Timer? _syncTimer;
  bool _isDisposed = false;
  Duration? _lastPosition;
  StreamSubscription? _videoPositionSubscription;
  
  // Add back the missing variables
  SessionManager sessionManager = SessionManager();
  SettingData? settingData;
  String mediaId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    prefData();
    _initializeVideo();
    _setupAudioPlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    
    switch (state) {
      case AppLifecycleState.paused:
        _pausePlayback();
        break;
      case AppLifecycleState.resumed:
        _resumePlayback();
        break;
      default:
        break;
    }
  }

  Future<void> _setupAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    await _audioPlayer?.setReleaseMode(ReleaseMode.loop);
    
    try {
      await _audioPlayer?.setPlayerMode(PlayerMode.mediaPlayer);
      await _audioPlayer?.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          contentType: AndroidContentType.music,
          isSpeakerphoneOn: false,
          stayAwake: true,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.duckOthers,
          }
        ),
      ));
    } catch (e) {
      print("Error setting up audio context: $e");
    }
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.file(File(widget.postVideo!));
    
    try {
      await _controller.initialize();
      
      // Set up position tracking
      _videoPositionSubscription = Stream.periodic(Duration(milliseconds: 50))
          .takeWhile((_) => !_isDisposed)
          .listen((_) {
        if (_isDisposed) return;
        _updatePlaybackSync();
      });
      
      if (!_isDisposed) {
        setState(() {
          isVideoReady = true;
        });
      }
      
      _controller.setLooping(true);
      await _controller.setVolume(videoVolume);
      _startPlayback();
    } catch (e) {
      print("Error initializing video: $e");
      CommonUI.showToast(
        msg: "Error loading video: ${e.toString()}",
        backGroundColor: ColorRes.red
      );
    }
  }

  void _updatePlaybackSync() {
    if (!mounted || _isDisposed) return;
    
    if (_controller.value.isPlaying && selectedMusicPath != null && isMusicReady) {
      final currentPosition = _controller.value.position;
      
      // Check if video has looped
      if (_lastPosition != null && currentPosition < _lastPosition!) {
        _restartMusic();
      }
      
      _lastPosition = currentPosition;
    }
  }

  Future<void> _restartMusic() async {
    if (!_isDisposed && selectedMusicPath != null && isMusicReady) {
      await _audioPlayer?.seek(Duration.zero);
      if (_controller.value.isPlaying) {
        await _audioPlayer?.resume();
      }
    }
  }

  Future<void> _startPlayback() async {
    if (_isDisposed) return;
    
    try {
      await _controller.play();
      if (selectedMusicPath != null && isMusicReady && _hasAudioFocus) {
        await _audioPlayer?.resume();
      }
    } catch (e) {
      print("Error starting playback: $e");
    }
  }

  Future<void> _pausePlayback() async {
    if (_isDisposed) return;
    
    try {
      await _controller.pause();
      if (selectedMusicPath != null && isMusicReady) {
        await _audioPlayer?.pause();
      }
    } catch (e) {
      print("Error pausing playback: $e");
    }
  }

  Future<void> _resumePlayback() async {
    if (_isDisposed) return;
    
    if (selectedMusicPath != null && !_hasAudioFocus) {
      await _requestAudioFocus();
    }
    
    try {
      await _controller.play();
      if (selectedMusicPath != null && isMusicReady && _hasAudioFocus) {
        await _audioPlayer?.resume();
      }
    } catch (e) {
      print("Error resuming playback: $e");
    }
  }

  Future<void> _togglePlayPause() async {
    if (!isVideoReady || _isDisposed) return;

    try {
      if (_controller.value.isPlaying) {
        await _pausePlayback();
      } else {
        await _resumePlayback();
      }
      if (!_isDisposed) {
        setState(() {});
      }
    } catch (e) {
      print("Error toggling play/pause: $e");
    }
  }

  Future<void> _selectMusic() async {
    try {
      await _pausePlayback();
      CommonUI.showLoader(context);
      
      await showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15))
        ),
        backgroundColor: ColorRes.colorPrimaryDark,
        isScrollControlled: true,
        builder: (context) {
          return MusicScreen((data, localMusic) async {
            try {
              if (data != null && localMusic != null) {
if (!_isDisposed) setState(() {
                  isMusicReady = false;
                  _hasAudioFocus = false;
                });
                
                await _audioPlayer?.stop();
                selectedMusicPath = localMusic;
                selectedMusicId = data.soundId.toString();
                
                await _requestAudioFocus();
                await _audioPlayer?.setSourceUrl(localMusic);
                await _audioPlayer?.setVolume(musicVolume);
                
                if (!_isDisposed) {
                  setState(() {
                    isMusicReady = true;
                  });
                }
                
                await _resumePlayback();
              }
            } catch (e) {
              print("Error setting up music: $e");
              CommonUI.showToast(
                msg: "Error playing selected music: ${e.toString()}",
                backGroundColor: ColorRes.red
              );
            }
          });
        },
      ).whenComplete(() {
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Remove loader
        }
      });
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Remove loader
      }
      CommonUI.showToast(
        msg: "Error loading music selection: ${e.toString()}",
        backGroundColor: ColorRes.red
      );
    }
  }

  Future<void> _stopAndDisposeAudio() async {
    try {
      isMusicReady = false;
      _hasAudioFocus = false;
      await _audioPlayer?.stop();
      await _audioPlayer?.dispose();
      await _setupAudioPlayer();
    } catch (e) {
      print("Error disposing audio: ${e.toString()}");
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _videoPositionSubscription?.cancel();
    _syncTimer?.cancel();
    _controller.removeListener(_videoStateListener);
    _controller.dispose();
    _stopAndDisposeAudio();
    super.dispose();
  }

  void _videoStateListener() {
    if (!mounted) return;
    
    if (_controller.value.hasError) {
      print("Video Error: ${_controller.value.errorDescription}");
      return;
    }

    // Only handle music sync if we have selected music
    if (selectedMusicPath != null && isMusicReady && _hasAudioFocus) {
      if (_controller.value.isPlaying) {
        _audioPlayer?.resume();
      } else {
        _audioPlayer?.pause();
      }
    }
  }

  Future<void> _requestAudioFocus() async {
    try {
      await _audioPlayer?.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          contentType: AndroidContentType.music,
          isSpeakerphoneOn: false,
          stayAwake: true,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.duckOthers,
          }
        ),
      ));
      _hasAudioFocus = true;
    } catch (e) {
      print("Error requesting audio focus: $e");
      _hasAudioFocus = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Video preview
            InkWell(
              onTap: _togglePlayPause,
              child: Column(
          children: [
            AppBarCustom(title: LKey.preview.tr),
            Container(height: 0.3, color: ColorRes.colorTextLight, margin: EdgeInsets.only(bottom: 0)),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                          aspectRatio: _controller.value.aspectRatio ?? 2 / 3,
                          child: VideoPlayer(_controller)
                        ),
                        // Play/Pause overlay
                        if (!_controller.value.isPlaying)
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.5),
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Top right buttons
            Positioned(
              right: 16,
              top: MediaQuery.of(context).padding.top + 60, // Position below app bar
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Music button
                  InkWell(
                    onTap: _selectMusic,
                    child: Container(
                      width: 45,
                      height: 45,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorRes.colorTheme.withOpacity(0.9),
                      ),
                      child: Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  // Mute button
                  InkWell(
                    onTap: _handleMuteToggle,
                      child: Container(
                      width: 45,
                      height: 45,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorRes.colorTheme.withOpacity(0.9),
                      ),
                      child: Icon(
                        isMuted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isProcessing ? null : onCheckButtonClick,
                            child: Container(
                              height: 50,
                              width: 50,
                              margin: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isProcessing ? Colors.grey : ColorRes.colorTheme
                              ),
                              child: Icon(
                                isProcessing ? Icons.hourglass_empty : Icons.check_rounded,
                                color: ColorRes.white
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Volume slider overlay - only show when adjusting volume
            if (selectedMusicPath != null)
              Positioned(
                bottom: 160,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Original Sound',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Slider(
                            value: videoVolume,
                            onChanged: isMuted ? null : (value) {
                              if (!_isDisposed) {
                                setState(() {
                                  videoVolume = value;
                                  _controller.setVolume(value);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Music',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Slider(
                            value: musicVolume,
                            onChanged: (value) {
                              if (!_isDisposed) {
                                setState(() {
                                  musicVolume = value;
                                  _audioPlayer?.setVolume(value);
                                });
                              }
                            },
                          ),
                        ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onCheckButtonClick() async {
    if (isProcessing) return;

    try {
      final processedVideoPath = await _processVideo();
      
    if (settingData?.isContentModeration == 1) {
        checkVideoModeration(processedVideoPath);
    } else {
        navigateToUploadScreen(processedVideoPath);
      }
    } catch (e) {
      CommonUI.showToast(msg: 'Error processing video: $e');
    }
  }

  void checkVideoModeration(String processedVideoPath) async {
    CommonUI.showLoader(context);
    NudityMediaId nudityMediaId = await ApiService().checkVideoModerationApiMoreThenOneMinutes(
      apiUser: settingData?.sightEngineApiUser ?? '',
      apiSecret: settingData?.sightEngineApiSecret ?? '',
      file: File(processedVideoPath),
    );
    Navigator.pop(context);

    if (nudityMediaId.status == 'success') {
      mediaId = nudityMediaId.media?.id ?? '';
      getVideoModerationChecker(processedVideoPath);
    } else {
      CommonUI.showToast(
        msg: nudityMediaId.error?.message ?? '',
        backGroundColor: ColorRes.red,
        duration: 2
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
        (route) => false
      );
    }
  }

  void _cleanupOldProcessedVideos() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = Directory(directory.path).listSync();
      
      // Delete processed video files older than 24 hours
      final now = DateTime.now();
      for (var file in files) {
        if (file is File && file.path.contains('processed_video_')) {
          final filename = file.path.split('/').last;
          final timestamp = int.tryParse(filename.split('_').last.replaceAll('.mp4', ''));
          if (timestamp != null) {
            final fileDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
            if (now.difference(fileDate).inHours > 24) {
              await file.delete();
            }
          }
        }
      }
    } catch (e) {
      print('Error cleaning up old videos: $e');
    }
  }

  void navigateToUploadScreen(String processedVideoPath) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      isScrollControlled: true,
      builder: (context) {
        // Clean up old processed videos after successful upload
        _cleanupOldProcessedVideos();
        
        return UploadScreen(
          postVideo: processedVideoPath,
          thumbNail: widget.thumbNail,
          sound: selectedMusicPath ?? widget.sound,
          soundId: selectedMusicId ?? widget.soundId,
        );
      },
    );
  }

  void prefData() async {
    await sessionManager.initPref();
    settingData = sessionManager.getSetting()?.data;
    if (!_isDisposed) {
      setState(() {});
    }
  }

  void getVideoModerationChecker(String processedVideoPath) async {
    List<double> nudityList = [];
    if (Get.isDialogOpen == false) {
      Get.dialog(LoaderDialog());
    }

    NudityChecker nudityChecker = await ApiService().getOnGoingVideoJob(
        mediaId: mediaId,
        apiUser: settingData?.sightEngineApiUser ?? '',
      apiSecret: settingData?.sightEngineApiSecret ?? ''
    );

    if (nudityChecker.status == 'failure') {
      Get.back();
      CommonUI.showToast(
        msg: nudityChecker.error?.message ?? '',
        backGroundColor: ColorRes.red,
        duration: 2
      );
      return;
    }

    if (nudityChecker.output?.data?.status == 'ongoing') {
      getVideoModerationChecker(processedVideoPath);
      return;
    }

    Get.back();

    if (nudityChecker.output?.data?.status == 'finished') {
      nudityChecker.output?.data?.frames?.forEach((element) {
        nudityList.add(element.nudity?.raw ?? 0.0);
        nudityList.add(element.weapon ?? 0.0);
        nudityList.add(element.alcohol ?? 0.0);
        nudityList.add(element.drugs ?? 0.0);
        nudityList.add(element.medicalDrugs ?? 0.0);
        nudityList.add(element.recreationalDrugs ?? 0.0);
        nudityList.add(element.weaponFirearm ?? 0.0);
        nudityList.add(element.weaponKnife ?? 0.0);
      });

      if (nudityList.reduce(max) > 0.7) {
        CommonUI.showToast(
            msg: "This media contains sensitive content which is not allowed to post on the platform!",
            duration: 2,
          backGroundColor: ColorRes.red
        );
        Navigator.pushAndRemoveUntil(
            context,
          MaterialPageRoute(builder: (context) => MainScreen()),
          (route) => false
        );
      } else {
        navigateToUploadScreen(processedVideoPath);
      }
    }

    if (nudityChecker.output?.data?.status == 'failure') {
      CommonUI.showToast(
        msg: nudityChecker.error?.message ?? '',
        duration: 2,
        backGroundColor: ColorRes.red
      );
      Navigator.pushAndRemoveUntil(
          context,
        MaterialPageRoute(builder: (context) => MainScreen()),
        (route) => false
      );
    }
  }

  void _handleMuteToggle() {
    if (!_isDisposed) {
      setState(() {
        isMuted = !isMuted;
        // Only mute/unmute video, keep music volume unchanged
        _controller.setVolume(isMuted ? 0 : videoVolume);
      });
    }
  }

  Future<String> _processVideo() async {
if (!_isDisposed) {
      setState(() {
        isProcessing = true;
      });
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      // Generate unique filename using timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String outputPath = '${directory.path}/processed_video_$timestamp.mp4';

      String ffmpegCommand = '';
      
      if (selectedMusicPath != null) {
        if (isMuted) {
          // Replace original audio with selected music
          ffmpegCommand = '-i "${widget.postVideo}" -i "$selectedMusicPath" -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 -shortest "$outputPath"';
        } else {
          // Mix original audio with selected music
          ffmpegCommand = '-i "${widget.postVideo}" -i "$selectedMusicPath" -filter_complex "[0:a]volume=${videoVolume}[a1];[1:a]volume=${musicVolume}[a2];[a1][a2]amix=inputs=2:duration=first[aout]" -map 0:v -map "[aout]" -c:v copy -c:a aac "$outputPath"';
        }
      } else if (isMuted) {
        // Remove audio
        ffmpegCommand = '-i "${widget.postVideo}" -c:v copy -an "$outputPath"';
      } else {
        // Adjust original audio volume
        ffmpegCommand = '-i "${widget.postVideo}" -filter:a volume=${videoVolume} -c:v copy -c:a aac "$outputPath"';
      }

      await FFmpegKit.execute(ffmpegCommand);
      
if (!_isDisposed) {
        setState(() {
          isProcessing = false;
        });
      }
      
      return outputPath;
    } catch (e) {
if (!_isDisposed) {
      setState(() {
        isProcessing = false;
      });
    }
      throw e;
    }
  }
}
