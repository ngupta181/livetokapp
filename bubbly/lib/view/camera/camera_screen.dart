import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/custom_view/common_ui.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/modal/sound/sound.dart';
import 'package:bubbly/utils/app_res.dart';
import 'package:bubbly/utils/assert_image.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/my_loading/my_loading.dart';
import 'package:bubbly/utils/url_res.dart';
import 'package:bubbly/view/camera/widget/seconds_tab.dart';
import 'package:bubbly/view/dialog/confirmation_dialog.dart';
import 'package:bubbly/view/music/music_screen.dart';
import 'package:bubbly/view/preview_screen.dart';
import 'package:bubbly_camera/bubbly_camera.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:video_compress/video_compress.dart';


class CameraScreen extends StatefulWidget {
  final String? soundUrl;
  final String? soundTitle;
  final String? soundId;

  CameraScreen({this.soundUrl, this.soundTitle, this.soundId});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

@pragma('vm:entry-point')
class _CameraScreenState extends State<CameraScreen> {
  bool isFlashOn = false;
  bool isFront = false;
  bool isSelected15s = true;
  bool isMusicSelect = false;
  bool isStartRecording = false;
  bool isRecordingStaring = false;
  bool isShowPlayer = false;
  bool isRetouchEnabled = false;
  double retouchIntensity = 0.5;
  String? soundId = '';

  Timer? timer;
  double currentSecond = 0;
  double currentPercentage = 0;
  double totalSeconds = 15;

  AudioPlayer? _audioPlayer;

  SoundList? _selectedMusic;
  String? _localMusic;

  Map<String, dynamic> creationParams = <String, dynamic>{};
  //FlutterVideoInfo _flutterVideoInfo = FlutterVideoInfo();
  ReceivePort _port = ReceivePort();
  ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    initPermission();
    if (widget.soundUrl != null) {
      soundId = widget.soundId;
      _bindBackgroundIsolate();
      //FlutterDownloader.registerCallback(downloadCallback);
      downloadMusic();
    }
    MethodChannel(ConstRes.bubblyCamera).setMethodCallHandler((payload) async {
      gotoPreviewScreen(payload.arguments.toString());
      return;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _audioPlayer?.release();
    _audioPlayer?.dispose();
    _unbindBackgroundIsolate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Platform.isAndroid
              ? AndroidView(
                  viewType: 'camera',
                  layoutDirection: TextDirection.ltr,
                  creationParams: creationParams,
                  creationParamsCodec: StandardMessageCodec(),
                )
              : UiKitView(
                  viewType: 'camera',
                  layoutDirection: TextDirection.ltr,
                  creationParams: creationParams,
                  creationParamsCodec: StandardMessageCodec(),
                ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    child: LinearProgressIndicator(
                        backgroundColor: ColorRes.white,
                        minHeight: 3,
                        value: currentPercentage / 100,
                        color: ColorRes.colorPrimaryDark),
                  ),
                ),
              ),
              Visibility(
                visible: isMusicSelect,
                replacement: SizedBox(height: 10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    widget.soundTitle != null
                        ? '${widget.soundTitle ?? ''}'
                        : _selectedMusic != null
                            ? "${_selectedMusic?.soundTitle ?? ''}"
                            : '',
                    style: TextStyle(
                        fontFamily: FontRes.fNSfUiSemiBold,
                        fontSize: 15,
                        color: ColorRes.white),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isStartRecording)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: IconWithRoundGradient(
                        size: 22,
                        iconData: Icons.close_rounded,
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (mContext) {
                                return ConfirmationDialog(
                                  aspectRatio: 2,
                                  title1: LKey.areYouSure.tr,
                                  title2: LKey.doYouReallyWantToGoBack.tr,
                                  positiveText: LKey.yes.tr,
                                  onPositiveTap: () async {
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                  },
                                );
                              });
                        },
                      ),
                    ),
                  Spacer(),
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: IconWithRoundGradient(
                          size: 20,
                          iconData: !isFlashOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          onTap: () async {
                            isFlashOn = !isFlashOn;
                            setState(() {});
                            await BubblyCamera.flashOnOff;
                          },
                        ),
                      ),
                      isStartRecording
                          ? SizedBox()
                          : Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: IconWithRoundGradient(
                                iconData: Icons.flip_camera_android_rounded,
                                size: 20,
                                onTap: () async {
                                  isFront = !isFront;
                                  await BubblyCamera.toggleCamera;
                                  setState(() {});
                                },
                              ),
                            ),
                      isStartRecording
                          ? SizedBox()
                          : Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: IconWithRoundGradient(
                                iconData: !isRetouchEnabled
                                    ? Icons.face_retouching_natural
                                    : Icons.face_retouching_off,
                                size: 20,
                                onTap: () async {
                                  setState(() {
                                    isRetouchEnabled = !isRetouchEnabled;
                                  });
                                  try {
                                    await BubblyCamera.toggleRetouch(
                                      intensity: retouchIntensity,
                                    );
                                  } catch (e) {
                                    // If toggling retouch fails, revert the UI state
                                    setState(() {
                                      isRetouchEnabled = !isRetouchEnabled;
                                    });
                                    CommonUI.showToast(
                                      msg: "Failed to toggle retouch filter. Please try again.",
                                    );
                                  }
                                },
                              ),
                            ),
                      isRecordingStaring
                          ? SizedBox()
                          : Visibility(
                              visible: soundId == null || soundId!.isEmpty,
                              child: InkWell(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(15))),
                                    backgroundColor: ColorRes.colorPrimaryDark,
                                    isScrollControlled: true,
                                    builder: (context) {
                                      return MusicScreen(
                                        (data, localMusic) async {
                                          isMusicSelect = true;
                                          _selectedMusic = data;
                                          _localMusic = localMusic;
                                          soundId = data?.soundId.toString();
                                          setState(() {});
                                        },
                                      );
                                    },
                                  ).then((value) {
                                    Provider.of<MyLoading>(context,
                                            listen: false)
                                        .setLastSelectSoundId('');
                                  });
                                },
                                child: Padding(
                                  padding: EdgeInsets.only(top: 20),
                                  child: ImageWithRoundGradient(icMusic, 11),
                                ),
                              ),
                            ),
                    ],
                  )
                ],
              ),
              if (isRetouchEnabled && !isStartRecording) _buildRetouchControls(),
              Spacer(),
              isRecordingStaring
                  ? SizedBox()
                  : Visibility(
                      visible: !isMusicSelect,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SecondsTab(
                            onTap: () {
                              isSelected15s = true;
                              totalSeconds = 15;
                              setState(() {});
                            },
                            isSelected: isSelected15s,
                            title: AppRes.fiftySecond,
                          ),
                          SizedBox(width: 15),
                          SecondsTab(
                            onTap: () {
                              isSelected15s = false;
                              totalSeconds = 30;
                              setState(() {});
                            },
                            isSelected: !isSelected15s,
                            title: AppRes.thirtySecond,
                          ),
                        ],
                      ),
                    ),
              SizedBox(height: 5),
              SafeArea(
                top: false,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      isRecordingStaring
                          ? SizedBox(
                              width: 40,
                              height: isMusicSelect ? 0 : 40,
                            )
                          : Container(
                              width: 40,
                              height: isMusicSelect ? 0 : 40,
                              child: IconWithRoundGradient(
                                iconData: Icons.image,
                                size: isMusicSelect ? 0 : 20,
                                onTap: () => _showFilePicker(),
                              ),
                            ),
                      InkWell(
                        onTap: () async {
                          isStartRecording = !isStartRecording;
                          isRecordingStaring = true;
                          setState(() {});
                          startProgress();
                        },
                        child: Container(
                          height: 85,
                          width: 85,
                          decoration: BoxDecoration(
                              color: ColorRes.white, shape: BoxShape.circle),
                          padding: EdgeInsets.all(10.0),
                          alignment: Alignment.center,
                          child: isStartRecording
                              ? Icon(
                                  Icons.pause,
                                  color: ColorRes.colorTheme,
                                  size: 50,
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: ColorRes.colorTheme,
                                    shape: isStartRecording
                                        ? BoxShape.rectangle
                                        : BoxShape.circle,
                                  ),
                                ),
                        ),
                      ),
                      Visibility(
                        visible: !isStartRecording,
                        replacement: SizedBox(height: 38, width: 38),
                        child: IconWithRoundGradient(
                          iconData: Icons.check_circle_rounded,
                          size: 20,
                          onTap: () async {
                            if (!isRecordingStaring) {
                              CommonUI.showToast(msg: LKey.videoIsToShort.tr);
                            } else {
                              if (soundId != null &&
                                  soundId!.isNotEmpty &&
                                  Platform.isIOS) {
                                await _stopAndMergeVideoForIos();
                              } else {
                                await BubblyCamera.stopRecording;
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (!_permissionNotGranted)
            Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              color: ColorRes.colorPrimaryDark,
              child: SafeArea(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: InkWell(
                        onTap: () {
                          Get.back();
                        },
                        child: Container(
                            height: 35,
                            width: 35,
                            margin: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: ColorRes.white.withOpacity(0.1)),
                            alignment: Alignment.center,
                            child: const Icon(Icons.close_rounded,
                                color: ColorRes.white, size: 25)),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: RichText(
                        text: TextSpan(
                          text: '${LKey.allow.tr} ',
                          children: [
                            TextSpan(
                                text: appName,
                                style: TextStyle(
                                    color: ColorRes.colorPink,
                                    fontFamily: FontRes.fNSfUiBold,
                                    fontSize: 17)),
                            TextSpan(
                                text:
                                    ' ${LKey.toAccessYourCameraAndMicrophone}')
                          ],
                          style: TextStyle(
                            fontFamily: FontRes.fNSfUiSemiBold,
                            fontSize: 20,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30.0),
                      child: Text(
                        LKey.ifAppearsThatCameraPermissionHasNotBeenGrantedEtc
                            .tr,
                        style: TextStyle(
                            fontFamily: FontRes.fNSfUiRegular,
                            color: ColorRes.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    InkWell(
                      onTap: () {
                        openAppSettings();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: ColorRes.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          LKey.openSettings.tr,
                          style: TextStyle(
                              color: ColorRes.colorPink,
                              fontFamily: FontRes.fNSfUiSemiBold,
                              fontSize: 15),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 33),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 40,
                          height: isMusicSelect ? 0 : 40,
                          child: IconWithRoundGradient(
                            iconData: Icons.image,
                            size: isMusicSelect ? 0 : 20,
                            onTap: () => _showFilePicker(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15)
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  void _bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    _port.listen((dynamic data) async {
      int status = data[1];

      if (status == 3) {
        Navigator.pop(context);
        _audioPlayer = AudioPlayer();
        isMusicSelect = true;
        _localMusic = _localMusic! + '/' + widget.soundUrl!;
        setState(() {});
      }
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }

  Future<String> _findLocalPath() async {
    final directory = Platform.isAndroid
        ? await (getExternalStorageDirectory())
        : await getApplicationDocumentsDirectory();
    return directory!.path;
  }

  void downloadMusic() async {        
    _localMusic =
        await ApiService().downloadFile(ConstRes.itemBaseUrl + widget.soundUrl!, 'sound.wav');
  }

  // void downloadMusic() async {
  //   _localMusic =
  //       (await _findLocalPath()) + Platform.pathSeparator + UrlRes.camera;
  //   final savedDir = Directory(_localMusic!);
  //   bool hasExisted = await savedDir.exists();
  //   if (!hasExisted) {
  //     savedDir.create();
  //   }
  //   if (File(_localMusic! + widget.soundUrl!).existsSync()) {
  //     File(_localMusic! + widget.soundUrl!).deleteSync();
  //   }
  //   await FlutterDownloader.enqueue(
  //     url: ConstRes.itemBaseUrl + widget.soundUrl!,
  //     savedDir: _localMusic!,
  //     showNotification: false,
  //     openFileFromNotification: false,
  //   );
  //   CommonUI.showLoader(context);
  // }

  // Recording
  void startProgress() async {
    if (timer == null) {
      initProgress();
    } else {
      if (isStartRecording) {
        initProgress();
      } else {
        cancelTimer();
      }
    }

    if (isStartRecording) {
      if (currentSecond == 0) {
        if (soundId != null && soundId!.isNotEmpty) {
          try {
            _audioPlayer = AudioPlayer(playerId: '1');
            await _audioPlayer?.play(
              DeviceFileSource(_localMusic!),
              mode: PlayerMode.mediaPlayer,
              ctx: AudioContext(
                android: AudioContextAndroid(isSpeakerphoneOn: true),
                iOS: AudioContextIOS(
                  category: AVAudioSessionCategory.playAndRecord,
                  options: {
                    AVAudioSessionOptions.allowAirPlay,
                    AVAudioSessionOptions.allowBluetooth,
                    AVAudioSessionOptions.allowBluetoothA2DP,
                    AVAudioSessionOptions.defaultToSpeaker,
                  },
                ),
              ),
            );
            var totalSecond = await Future.delayed(
              Duration(milliseconds: 300),
              () => _audioPlayer!.getDuration(),
            );
            totalSeconds = totalSecond!.inSeconds.toDouble();
            initProgress();
          } catch (e) {
            print('Error playing audio: $e');
          }
        }

        try {
          await BubblyCamera.startRecording();
        } catch (e) {
          print('Error starting recording: $e');
        }
      } else {
        print('Audio Resume Recording');
        try {
          await _audioPlayer?.resume();
          await BubblyCamera.resumeRecording();
        } catch (e) {
          print('Error resuming recording: $e');
        }
      }
    } else {
      print('Audio Pause Recording');
      try {
        await _audioPlayer?.pause();
        await BubblyCamera.pauseRecording();
      } catch (e) {
        print('Error pausing recording: $e');
      }
    }

    print('============ $currentSecond');
  }

  // Stop Merge For iOS
  Future<void> _stopAndMergeVideoForIos({bool isAutoStop = false}) async {
    print('_stopAndMergeVideoForIos');
    CommonUI.showLoader(context);
    if (isAutoStop) {
      await BubblyCamera.pauseRecording;
    }
    await Future.delayed(Duration(milliseconds: 500));
    await BubblyCamera.mergeAudioVideo(_localMusic ?? '');
  }

  void gotoPreviewScreen(String pathOfVideo) async {
    if (soundId != null && soundId!.isNotEmpty) {
      CommonUI.showLoader(context);
      try {
        String localPath = await _findLocalPath();
        if (!Platform.isAndroid) {
          await FFmpegKit.execute(
              '-i $pathOfVideo -y -ss 00:00:01.000 -vframes 1 "$localPath${Platform.pathSeparator}thumbNail.png"');
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PreviewScreen(
                postVideo: '$pathOfVideo',
                thumbNail: "$localPath${Platform.pathSeparator}thumbNail.png",
                soundId: soundId,
                duration: currentSecond.toInt(),
              ),
            ),
          ).then(
            (value) {
              Navigator.pop(context);
            },
          );
        } else {
          if (isFront) {
            await FFmpegKit.execute(
                '-i "$pathOfVideo" -y -vf hflip "$localPath${Platform.pathSeparator}out1.mp4"');
            await FFmpegKit.execute(
                '-i "$localPath${Platform.pathSeparator}out1.mp4" -i $_localMusic -y -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 -shortest $localPath${Platform.pathSeparator}out.mp4');
            await FFmpegKit.execute(
                '-i $localPath${Platform.pathSeparator}out.mp4 -y -ss 00:00:01.000 -vframes 1 "$localPath${Platform.pathSeparator}thumbNail.png"');
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PreviewScreen(
                  postVideo: '$localPath${Platform.pathSeparator}out.mp4',
                  thumbNail: "$localPath${Platform.pathSeparator}thumbNail.png",
                  soundId: soundId,
                  duration: currentSecond.toInt(),
                ),
              ),
            ).then(
              (value) {
                Navigator.pop(context);
              },
            );
          } else {
            await FFmpegKit.execute(
                '-i $pathOfVideo -i $_localMusic -y -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 -shortest $localPath${Platform.pathSeparator}out.mp4');
            await FFmpegKit.execute(
                '-i $localPath${Platform.pathSeparator}out.mp4 -y -ss 00:00:01.000 -vframes 1 "$localPath${Platform.pathSeparator}thumbNail.png"');
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PreviewScreen(
                  postVideo: '$localPath${Platform.pathSeparator}out.mp4',
                  thumbNail: "$localPath${Platform.pathSeparator}thumbNail.png",
                  soundId: soundId,
                  duration: currentSecond.toInt(),
                ),
              ),
            ).then(
              (value) {
                Navigator.pop(context);
              },
            );
          }
        }
      } catch (e) {
        Navigator.pop(context);
      }
      return;
    }

    CommonUI.showLoader(context);
    try {
      String localPath = await _findLocalPath();
      String soundPath =
          '$localPath${Platform.pathSeparator}${DateTime.now().millisecondsSinceEpoch.toString()}sound.wav';
      await FFmpegKit.execute('-i "$pathOfVideo" -y $soundPath');
      if (Platform.isAndroid && isFront) {
        await FFmpegKit.execute(
            '-i "$pathOfVideo" -y -vf hflip "$localPath${Platform.pathSeparator}out1.mp4"');
        await FFmpegKit.execute(
            '-i "$localPath${Platform.pathSeparator}out1.mp4" -y -ss 00:00:01.000 -vframes 1 "$localPath${Platform.pathSeparator}thumbNail.png"');
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PreviewScreen(
              postVideo: '$localPath${Platform.pathSeparator}out1.mp4',
              thumbNail: '$localPath${Platform.pathSeparator}thumbNail.png',
              sound: soundPath,
              duration: currentSecond.toInt(),
            ),
          ),
        ).then(
          (value) {
            Navigator.pop(context);
          },
        );
      } else {
        await FFmpegKit.execute(
            '-i "$pathOfVideo" -y -ss 00:00:01.000 -vframes 1 "$localPath${Platform.pathSeparator}thumbNail.png"');
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PreviewScreen(
              postVideo: pathOfVideo,
              thumbNail: "$localPath${Platform.pathSeparator}thumbNail.png",
              sound: soundPath,
              duration: currentSecond.toInt(),
            ),
          ),
        ).then(
          (value) {
            Navigator.pop(context);
          },
        );
      }
    } catch (e) {
      Navigator.pop(context);
      CommonUI.showToast(msg: LKey.anErrorOccurredWhileProcessingTheEtc.tr);
    }
  }

  void _showFilePicker() async {
    HapticFeedback.mediumImpact();
    CommonUI.getLoader();
    try {
      final videoFile = await _picker.pickVideo(
          source: ImageSource.gallery, maxDuration: Duration(minutes: 1));
      Get.back();

      if (videoFile != null && videoFile.path.isNotEmpty) {
        double fileSize = await getFileSizeInMB(File(videoFile.path));
        try {
          // VideoData? videoInfo =
          //     await _flutterVideoInfo.getVideoInfo(videoFile.path);
          if (fileSize > maxUploadMB) {
            Get.dialog(ConfirmationDialog(
              aspectRatio: 1.8,
              title1: LKey.tooLargeVideo,
              title2: LKey.thisVideoIsGreaterThan50MbNPleaseSelectAnother.tr,
              positiveText: LKey.selectAnother.tr,
              onPositiveTap: () {
                Get.back();
                _showFilePicker();
              },
            ));

            return;
          }

          // if (((videoInfo?.duration ?? 0) / 1000) > maxUploadSecond) {
          //   Get.dialog(ConfirmationDialog(
          //     aspectRatio: 1.8,
          //     title1: LKey.tooLongVideo.tr,
          //     title2: LKey.thisVideoIsGreaterThan1MinNPleaseSelectAnother.tr,
          //     positiveText: LKey.selectAnother.tr,
          //     onPositiveTap: () {
          //       Get.back();
          //       _showFilePicker();
          //     },
          //   ));
          //   return;
          // }

          // Video length
          MediaInfo? videoInfo = await VideoCompress.getMediaInfo(videoFile.path);
          int videoDurationInSecond = ((videoInfo?.duration ?? 0) / 1000).toInt();
          if (videoDurationInSecond > maxUploadSecond) {
            return Get.dialog(ConfirmationDialog(
              aspectRatio: 1.8,
              title1: LKey.tooLongVideo.tr,
              title2: LKey.thisVideoIsGreaterThan1MinNPleaseSelectAnother.tr,
              positiveText: LKey.selectAnother.tr,
              onPositiveTap: () {
                Get.back();
                _showFilePicker();
              },
            ));
          }

          CommonUI.getLoader();

          try {
            String localPath = await _findLocalPath();
            await FFmpegKit.execute(
                '-i "${videoFile.path}" -y $localPath${Platform.pathSeparator}sound.wav');
            await FFmpegKit.execute(
                '-i "${videoFile.path}" -y -ss 00:00:01.000 -vframes 1 "$localPath${Platform.pathSeparator}thumbNail.png"');

            Get.back(); // Close the loader
            Get.to(() => PreviewScreen(
                  postVideo: videoFile.path,
                  thumbNail: "$localPath${Platform.pathSeparator}thumbNail.png",
                  sound: "$localPath${Platform.pathSeparator}sound.wav",
                  duration: videoDurationInSecond,  
                ))?.then(
              (value) {
                Navigator.pop(context);
              },
            );
          } catch (e) {
            Get.back(); // Close the loader if FF mpeg fails
            CommonUI.showToast(
                msg: LKey.anErrorOccurredWhileProcessingTheEtc.tr);
          }
        } catch (e) {
          CommonUI.showToast(
              msg: LKey.pleaseAcceptLibraryPermissionToPickAVideo.tr);
        }
      }
    } catch (e) {
      Get.back(); // Close the loader if picking video fails
      CommonUI.showToast(
          msg: LKey.pleaseAcceptLibraryPermissionToPickAVideo.tr);
    }
  }

  void initProgress() {
    timer?.cancel();
    timer = null;

    timer = Timer.periodic(Duration(milliseconds: 10), (time) async {
      currentSecond += 0.01;
      currentPercentage = (100 * currentSecond) / totalSeconds;
      if (totalSeconds.toInt() <= currentSecond.toInt()) {
        timer?.cancel();
        timer = null;
        if (soundId != null && soundId!.isNotEmpty && Platform.isIOS) {
          _stopAndMergeVideoForIos(isAutoStop: true);
        } else {
          await BubblyCamera.stopRecording;
        }
      }
      setState(() {});
    });
  }

  void cancelTimer() {
    timer?.cancel();
    timer = null;
  }

  Future<double> getFileSizeInMB(File file) async {
    try {
      int fileSizeInBytes = await file.length();
      double fileSizeInMB = fileSizeInBytes / (1024 * 1024);
      return fileSizeInMB;
    } catch (e) {
      print('Error getting file size: $e');
      return -1;
    }
  }

  bool _permissionNotGranted = true;

  void initPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();
    print(statuses[Permission.camera]?.isGranted);
    print(statuses[Permission.microphone]?.isGranted);
    if (statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted) {
      print('Granted');
      _permissionNotGranted = true;
    } else {
      _permissionNotGranted = false;
      print('Not Granted');
    }
    setState(() {});
  }

  Widget _buildRetouchControls() {
    return AnimatedOpacity(
      opacity: isRetouchEnabled ? 1.0 : 0.0,
      duration: Duration(milliseconds: 200),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Retouch Intensity',
              style: TextStyle(
                color: ColorRes.white,
                fontSize: 12,
                fontFamily: FontRes.fNSfUiMedium,
              ),
            ),
            SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: ColorRes.colorTheme,
                inactiveTrackColor: ColorRes.white.withOpacity(0.3),
                thumbColor: ColorRes.colorTheme,
                overlayColor: ColorRes.colorTheme.withOpacity(0.2),
                trackHeight: 2,
              ),
              child: Slider(
                value: retouchIntensity,
                onChanged: (value) {
                  setState(() {
                    retouchIntensity = value;
                  });
                  try {
                    BubblyCamera.toggleRetouch(intensity: value);
                  } catch (e) {
                    // Log the error but don't revert the UI as it's just an intensity change
                    print("Error setting retouch intensity: $e");
                  }
                },
                min: 0.0,
                max: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IconWithRoundGradient extends StatelessWidget {
  final IconData iconData;
  final double size;
  final Function? onTap;

  IconWithRoundGradient(
      {required this.iconData, required this.size, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: InkWell(
        onTap: () => onTap?.call(),
        child: Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [ColorRes.colorTheme, ColorRes.colorPink])),
          child: Icon(iconData, color: ColorRes.white, size: size),
        ),
      ),
    );
  }
}

class ImageWithRoundGradient extends StatelessWidget {
  final String imageData;
  final double padding;

  ImageWithRoundGradient(this.imageData, this.padding);

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [ColorRes.colorTheme, ColorRes.colorPink],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Image(
            image: AssetImage(imageData),
            color: ColorRes.white,
          ),
        ),
      ),
    );
  }
}
