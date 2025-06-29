import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/custom_view/common_ui.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/modal/live_stream/live_stream.dart';
import 'package:bubbly/modal/setting/setting.dart';
import 'package:bubbly/modal/user/user.dart';
import 'package:bubbly/utils/common_fun.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/firebase_res.dart';
import 'package:bubbly/utils/key_res.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:bubbly/utils/level_utils.dart';
import 'package:bubbly/view/dialog/confirmation_dialog.dart';
import 'package:bubbly/view/live_stream/screen/live_stream_end_screen.dart';
import 'package:bubbly/view/live_stream/widget/gift_animation_controller.dart';
import 'package:bubbly/view/live_stream/widget/gift_sheet.dart';
import 'package:bubbly/view/live_stream/widget/level_up_animation_controller.dart';
import 'package:bubbly/view/profile/profile_screen.dart';
import 'package:bubbly/view/wallet/dialog_coins_plan.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stacked/stacked.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class BroadCastScreenViewModel extends BaseViewModel {
  SettingData? settingData;

  void init(
      {required bool isBroadCast,
      required String agoraToken,
      required String channelName,
      User? registrationUser}) {
    isHost = isBroadCast;
    _channelName = channelName;
    _agoraToken = agoraToken;
    commentList = [];
    this.registrationUser = registrationUser;
    prefData();
    rtcEngineHandlerCall();
    setupVideoSDKEngine();
  }

  String _agoraToken = '';
  String _channelName = '';
  User? registrationUser;
  int _localUserID = 0; //  local user uid
  int? _remoteID; //  remote user uid
  bool _isJoined = false; // Indicates if the local user has joined the channel
  bool isHost =
      true; // Indicates whether the user has joined as a host or audience
  late RtcEngine agoraEngine; // Agora engine instance
  RtcEngineEventHandler? engineEventHandler;
  bool isMic = false;
  FirebaseFirestore db = FirebaseFirestore.instance;
  TextEditingController commentController = TextEditingController();
  FocusNode commentFocus = FocusNode();
  List<LiveStreamComment> commentList = [];
  SessionManager pref = SessionManager();
  User? user;
  StreamSubscription<QuerySnapshot<LiveStreamComment>>? commentStream;
  bool startStop = true;
  Timer? timer;
  Stopwatch watch = Stopwatch();
  String elapsedTime = '';
  LiveStreamUser? liveStreamUser;
  DateTime? dateTime;
  Timer? minimumUserLiveTimer;
  int countTimer = 0;
  int maxMinutes = 0;
  Gifts? selectedGift;

  void rtcEngineHandlerCall() {
    engineEventHandler = RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        _isJoined = true;
        if (isHost) {
          db
              .collection(FirebaseRes.liveStreamUser)
              .doc(registrationUser?.data?.identity)
              .set(LiveStreamUser(
                fullName: registrationUser?.data?.fullName ?? '',
                isVerified:
                    registrationUser?.data?.isVerify == 1 ? true : false,
                agoraToken: _agoraToken,
                collectedDiamond: 0,
                hostIdentity: registrationUser?.data?.identity ?? '',
                id: DateTime.now().millisecondsSinceEpoch,
                joinedUser: [],
                userId: registrationUser?.data?.userId ?? -1,
                userImage: registrationUser?.data?.userProfile ?? '',
                userName: registrationUser?.data?.userName ?? '',
                watchingCount: 0,
                followers: registrationUser?.data?.followersCount,
                userLevel: registrationUser?.data?.userLevel ?? 1,
              ).toJson());
        }
        notifyListeners();
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        _remoteID = remoteUid;
        notifyListeners();
      },
      onUserOffline: (RtcConnection connection, int remoteUid,
          UserOfflineReasonType reason) {
        print('onUserOffline');
        if (Get.isBottomSheetOpen == true) {
          Get.back();
        }
        _remoteID = null;
        agoraEngine.leaveChannel();
        agoraEngine.release();
        Get.back();
      },
      onLeaveChannel: (connection, stats) {
        if (isHost) {
          Get.off(LivestreamEndScreen());
        }
      },
    );
  }

  Widget videoPanel() {
    if (!_isJoined) {
      return LoaderDialog();
    } else if (isHost) {
      // Local user joined as a host
      return AgoraVideoView(
        controller: VideoViewController(
            rtcEngine: agoraEngine,
            canvas: VideoCanvas(
                uid: _localUserID,
                sourceType: VideoSourceType.videoSourceCameraPrimary)),
      );
    } else {
      return _remoteID != null
          ? AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: agoraEngine,
                canvas: VideoCanvas(uid: _remoteID),
                connection: RtcConnection(channelId: _channelName),
              ),
            )
          : SizedBox();
    }
  }

  Future<void> setupVideoSDKEngine() async {
    // retrieve or request camera and microphone permissions
    await [Permission.microphone, Permission.camera].request();

    //create an instance of the Agora engine
    agoraEngine = createAgoraRtcEngine();

    await agoraEngine
        .initialize(RtcEngineContext(appId: settingData?.agoraAppId));

    // Set the video configuration
    VideoEncoderConfiguration videoConfig = VideoEncoderConfiguration(
        frameRate: liveFrameRate,
        dimensions: VideoDimensions(width: liveWeight, height: liveHeight));

    // Apply the configuration
    await agoraEngine.setVideoEncoderConfiguration(videoConfig);

    await agoraEngine.enableVideo();

    join();

    // Register the event handler
    if (engineEventHandler != null) {
      agoraEngine.registerEventHandler(engineEventHandler!);
    }
  }

  void join() async {
    // Set channel options
    ChannelMediaOptions options;

    // Set channel profile and client role
    if (isHost) {
      startWatch();
      options = const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      );
      await agoraEngine.startPreview();
    } else {
      options = const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleAudience,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      );
    }
    await agoraEngine.joinChannel(
        token: _agoraToken,
        channelId: _channelName,
        options: options,
        uid: _localUserID);
    notifyListeners();
  }

  void onEndButtonClick() {
    Get.dialog(
      ConfirmationDialog(
          title1: LKey.areYouSure.tr,
          title2: 'You want to end the live video.',
          onPositiveTap: () {
            Get.back();
            leave();
          },
          aspectRatio: 2),
      barrierDismissible: true,
    );
  }

  void leave() async {
    _isJoined = false;
    _remoteID = null;
    notifyListeners();
    liveStreamData();
    agoraEngine
        .leaveChannel(
      options: const LeaveChannelOptions(),
    )
        .then((value) async {
      if (isHost) {
        db.collection(FirebaseRes.liveStreamUser).doc(_channelName).delete();
        final batch = db.batch();
        var collection = db
            .collection(FirebaseRes.liveStreamUser)
            .doc(_channelName)
            .collection(FirebaseRes.comment);
        var snapshots = await collection.get();
        for (var doc in snapshots.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        if (Get.isDialogOpen == true) {
          Get.back();
        }
        stopWatch();
      }
    });
  }

  void prefData() async {
    await pref.initPref();
    user = pref.getUser();
    settingData = pref.getSetting()?.data;
    maxMinutes = (settingData?.liveTimeout ?? 0) * 60;
    initFirebase();
    getProfile();
  }

  void initFirebase() {
    db
        .collection(FirebaseRes.liveStreamUser)
        .doc(_channelName)
        .withConverter(
          fromFirestore: LiveStreamUser.fromFireStore,
          toFirestore: (LiveStreamUser value, options) => value.toFireStore(),
        )
        .snapshots()
        .listen((event) {
      liveStreamUser = event.data();
      if (isHost) {
        minimumUserLiveTimer ??=
            Timer.periodic(const Duration(seconds: 1), (timer) {
          countTimer++;
          if (countTimer == maxMinutes &&
              liveStreamUser!.watchingCount! <=
                  (settingData?.liveMinViewers ?? -1)) {
            timer.cancel();
            leave();
          }
          if (countTimer == maxMinutes) {
            countTimer = 0;
          }
        });
        notifyListeners();
      }
      notifyListeners();
    });
    commentStream = db
        .collection(FirebaseRes.liveStreamUser)
        .doc(_channelName)
        .collection(FirebaseRes.comment)
        .orderBy(FirebaseRes.id, descending: true)
        .withConverter(
          fromFirestore: LiveStreamComment.fromFireStore,
          toFirestore: (LiveStreamComment value, options) {
            return value.toFireStore();
          },
        )
        .snapshots()
        .listen((event) {
      commentList = [];
      for (int i = 0; i < event.docs.length; i++) {
        commentList.add(event.docs[i].data());
      }
      notifyNewComment();
    });
  }

  void onComment() {
    if (commentController.text.isEmpty) {
      return;
    }
    onCommentSend(
        commentType: FirebaseRes.msg, msg: commentController.text.trim());
    commentController.clear();
    commentFocus.unfocus();
    notifyListeners();
  }

  Future<void> onCommentSend({required String commentType, String? msg}) async {
    if (commentType == FirebaseRes.msg && (msg == null || msg.isEmpty)) {
      return;
    }
    
    // For image/gift comments, use the gift image from the selected gift
    String commentContent = commentType == FirebaseRes.msg 
        ? msg ?? '' 
        : selectedGift?.image ?? '';
    
    db
        .collection(FirebaseRes.liveStreamUser)
        .doc(_channelName)
        .collection(FirebaseRes.comment)
        .add(LiveStreamComment(
          id: DateTime.now().millisecondsSinceEpoch,
          userName: user?.data?.userName ?? '',
          userImage: user?.data?.userProfile ?? '',
          userId: user?.data?.userId ?? -1,
          fullName: user?.data?.fullName ?? '',
          comment: commentContent,
          commentType: commentType,
          isVerify: user?.data?.isVerify == 1 ? true : false,
          userLevel: user?.data?.userLevel ?? 1,
        ).toJson());

    // If it's a gift, trigger animation immediately as well
    if (commentType == FirebaseRes.image) {
      print("Gift comment - adding to animation controller");
      GiftAnimationController().addGift(LiveStreamComment(
        id: DateTime.now().millisecondsSinceEpoch,
        userName: user?.data?.userName ?? '',
        userImage: user?.data?.userProfile ?? '',
        userId: user?.data?.userId ?? -1,
        fullName: user?.data?.fullName ?? '',
        comment: selectedGift?.image ?? '',
        commentType: FirebaseRes.image,
        isVerify: user?.data?.isVerify == 1 ? true : false,
        userLevel: user?.data?.userLevel ?? 1,
      ));
    }

    notifyNewComment();
  }

  // New method to notify listeners when new comments are received
  void notifyNewComment() {
    notifyListeners();
  }

  void flipCamera() {
    agoraEngine.switchCamera();
  }

  void onMuteUnMute() {
    isMic = !isMic;
    notifyListeners();
    agoraEngine.muteLocalAudioStream(isMic);
  }

  void audienceExit() async {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }

    await db.collection(FirebaseRes.liveStreamUser).doc(_channelName).update(
      {
        FirebaseRes.watchingCount:
            liveStreamUser != null && liveStreamUser?.watchingCount != 0
                ? liveStreamUser!.watchingCount! - 1
                : 0
      },
    );
    _remoteID = null;
    agoraEngine.leaveChannel();
    Get.back();
  }

  void onGiftTap(BuildContext context) {
    print("Opening gift sheet");
    getProfile();
    Get.bottomSheet(
      GiftSheet(
        onAddShortzzTap: () {
          Get.bottomSheet(
            DialogCoinsPlan(),
            backgroundColor: Colors.transparent,
          );
        },
        settingData: settingData,
        user: user,
        onGiftSend: (gift) async {
          print("Gift selected: ${gift?.image}");
          Navigator.pop(context);

          try {
            // Update diamond count for host
            int value = liveStreamUser!.collectedDiamond! + gift!.coinPrice!;
            await db
                .collection(FirebaseRes.liveStreamUser)
                .doc(_channelName)
                .update({FirebaseRes.collectedDiamond: value});

            // Send coins to host with gift ID for transaction tracking
            try {
              print("Sending coins to host: ${gift.coinPrice} coins, giftId: ${gift.id}");
              final response = await ApiService()
                  .sendCoin(
                    '${gift.coinPrice}', 
                    '${liveStreamUser?.userId}',
                    giftId: '${gift.id}'
                  );
              
              print("Coin sending response: ${response.status} - ${response.message}");
              
              if (response.status == 200) {
                // Get updated profile to reflect wallet and level changes
                print("Getting updated profile after gift transaction");
                await getProfile();
                
                // Check if level increased by comparing before/after profiles
                final int previousLevel = user?.data?.userLevel ?? 1;
                await getProfile(); // Refresh again to ensure latest data
                final int currentLevel = user?.data?.userLevel ?? 1;
                
                if (currentLevel > previousLevel) {
                  print("Level up detected! $previousLevel → $currentLevel");
                  LevelUpAnimationController().showLevelUp(previousLevel, currentLevel);
                } else {
                  print("No level change detected: still at level $currentLevel");
                  // If server didn't update level, try explicit client update as fallback
                  try {
                    print("Sending explicit level points update as fallback");
                    int levelPoints = LevelUtils.coinsToPoints(gift.coinPrice ?? 0);
                    await ApiService().updateUserLevelPoints(levelPoints, 'live_gift')
                        .then((value) {
                      print("Explicit level update response: ${value.status} - ${value.message}");
                      // Check if this caused a level up
                      getProfile().then((_) {
                        final int updatedLevel = user?.data?.userLevel ?? 1;
                        if (updatedLevel > currentLevel) {
                          print("Level up after explicit update! $currentLevel → $updatedLevel");
                          LevelUpAnimationController().showLevelUp(currentLevel, updatedLevel);
                        } else {
                          print("Still at level $updatedLevel after explicit update");
                        }
                      });
                    });
                  } catch (levelError) {
                    print("Error in explicit level points update: $levelError");
                    // Get the latest profile anyway to ensure we have updated data
                    await getProfile();
                  }
                }
              } else {
                print("Error in coin transaction: ${response.message}");
              }
            } catch (e) {
              print("Error sending coins: $e");
              // Continue even if coin transaction fails
            }

            // Store the selected gift for comment use
            selectedGift = gift;
            
            // Always send gift comment to trigger animation
            print("Sending gift comment with image: ${gift.image}");
            await onCommentSend(
                commentType: FirebaseRes.image, msg: null);
            print("Gift comment sent and animation should trigger");
          } catch (e) {
            print("Error processing gift: $e");
            // Show error to user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to send gift. Please try again.")),
            );
          }
        },
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> getProfile() async {
    try {
      User value = await ApiService().getProfile(SessionManager.userId.toString());
      user = value;
      notifyListeners();
    } catch (e) {
      print("Error in getProfile: $e");
    }
  }

  void onUserTap(BuildContext context) async {
    _remoteID = null;
    db.collection(FirebaseRes.liveStreamUser).doc(_channelName).update(
      {
        FirebaseRes.watchingCount:
            liveStreamUser != null && liveStreamUser?.watchingCount != null
                ? liveStreamUser!.watchingCount! - 1
                : 0
      },
    );
    await agoraEngine.leaveChannel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProfileScreen(type: 1, userId: '${liveStreamUser?.userId ?? -1}'),
      ),
    );
  }
  
  Future<void> followUser(int userId) async {
    try {
      if (userId <= 0) return;
      
      // Call API to follow user
      ApiService().followUnFollowUser(userId.toString()).then((value) {
        if (value.status == 200) {
          // Show success message using ScaffoldMessenger
          Get.showSnackbar(
            GetSnackBar(
              message: 'User followed successfully',
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
          
          // Update UI if needed
          notifyListeners();
        }
      });
    } catch (e) {
      print('Error following user: $e');
    }
  }

  void startWatch() {
    startStop = false;
    watch.start();
    timer = Timer.periodic(const Duration(milliseconds: 100), updateTime);
    dateTime = DateTime.now();
    notifyListeners();
  }

  updateTime(Timer timer) {
    if (watch.isRunning) {
      elapsedTime = transformMilliSeconds(watch.elapsedMilliseconds);
      notifyListeners();
    }
  }

  void stopWatch() {
    startStop = true;
    watch.stop();
    setTime();
    notifyListeners();
  }

  void setTime() {
    var timeSoFar = watch.elapsedMilliseconds;
    elapsedTime = transformMilliSeconds(timeSoFar);
    notifyListeners();
  }

  String transformMilliSeconds(int milliseconds) {
    int hundreds = (milliseconds / 10).truncate();
    int seconds = (hundreds / 100).truncate();
    int minutes = (seconds / 60).truncate();
    int hours = (minutes / 60).truncate();

    String hoursStr = (hours % 60).toString().padLeft(2, '0');
    String minutesStr = (minutes % 60).toString().padLeft(2, '0');
    String secondsStr = (seconds % 60).toString().padLeft(2, '0');

    return "$hoursStr:$minutesStr:$secondsStr";
  }

  Future<void> liveStreamData() async {
    pref.saveString(KeyRes.liveStreamingTiming, elapsedTime);
    pref.saveString(
        KeyRes.liveStreamWatchingUser, "${liveStreamUser?.joinedUser?.length}");
    pref.saveString(
        KeyRes.liveStreamCollected, "${liveStreamUser?.collectedDiamond}");
    pref.saveString(KeyRes.liveStreamProfile, "${liveStreamUser?.userImage}");
  }

  @override
  void dispose() {
    commentController.dispose();
    commentStream?.cancel();
    agoraEngine.unregisterEventHandler(engineEventHandler!);
    timer?.cancel();
    minimumUserLiveTimer?.cancel();
    super.dispose();
  }
}
