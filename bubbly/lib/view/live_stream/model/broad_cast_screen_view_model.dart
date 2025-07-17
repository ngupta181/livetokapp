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
import 'package:bubbly/view/live_stream/widget/co_host_invitation_dialog.dart';
import 'package:bubbly/view/profile/profile_screen.dart';
import 'package:bubbly/view/wallet/dialog_coins_plan.dart';
import 'package:bubbly/services/co_host_invitation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stacked/stacked.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class BroadCastScreenViewModel extends BaseViewModel {
  SettingData? settingData;
  bool _isDisposed = false;

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
    
    // Listen for co-host invitations if not host
    if (!isHost) {
      _listenForInvitations();
    }
  }

  String _agoraToken = '';
  String _channelName = '';
  
  // Getters for private fields
  String get agoraToken => _agoraToken;
  String get channelName => _channelName;
  int? get coHostID => _coHostID;
  User? registrationUser;
  int _localUserID = 0; //  local user uid
  int? _remoteID; //  remote user uid
  int? _coHostID; //  co-host user uid
  Set<int> _coHostUIDs = {}; // Track all co-host UIDs
  bool _isJoined = false; // Indicates if the local user has joined the channel
  bool isHost =
      true; // Indicates whether the user has joined as a host or audience
  bool isCoHost = false; // Indicates if user is a co-host
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
  StreamSubscription<QuerySnapshot>? invitationStream;
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

  // Gift sheet state tracking
  bool _isGiftSheetOpen = false;
  bool _isGiftSheetMinimized = false;
  
  bool get isGiftSheetOpen => _isGiftSheetOpen;
  bool get isGiftSheetMinimized => _isGiftSheetMinimized;

  void _onGiftSheetStateChanged(bool isOpen, bool isMinimized) {
    _isGiftSheetOpen = isOpen;
    _isGiftSheetMinimized = isMinimized;
    notifyListeners();
  }

  void rtcEngineHandlerCall() {
    engineEventHandler = RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        _isJoined = true;
        if (isHost) {
          db
              .collection(FirebaseRes.liveStreamUser)
              .doc(_channelName)
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
        print('User joined: $remoteUid, isHost: $isHost, isCoHost: $isCoHost');
        
        // Prevent operations on disposed widget
        if (_isDisposed) return;
        
        // Use post frame callback to ensure safe UI updates
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_isDisposed) return;
          
          try {
            if (isHost) {
              // For host: Set co-host ID for any broadcaster joining (simplified approach)
              // We'll assume that if someone joins as a broadcaster, they're a co-host
              // This is a temporary solution until we have better co-host tracking
              if (_coHostID == null) {
                _coHostID = remoteUid;
                print('Co-host detected with ID: $remoteUid');
                
                // Temporarily disabled automatic join message for co-host to prevent crashes
                // TODO: Re-implement with better error handling
                // _sendAutomaticJoinMessage('Co-host has joined the stream', isCoHost: true);
              }
              
              // Update watching count (with delay)
              Future.delayed(Duration(milliseconds: 500), () {
                if (!_isDisposed) {
                  _updateWatchingCount(1);
                }
              });
            } else if (isCoHost) {
              // Co-host sees host
              _remoteID = remoteUid;
            } else {
              // Regular audience sees host
              _remoteID = remoteUid;
              
              // Temporarily disabled automatic join message for viewers to prevent crashes
              // TODO: Re-implement with better error handling
              // _sendAutomaticJoinMessage('${user?.data?.userName ?? 'Viewer'} joined the stream');
              
              // Update watching count (with delay)
              Future.delayed(Duration(milliseconds: 500), () {
                if (!_isDisposed) {
                  _updateWatchingCount(1);
                }
              });
            }
            
            // Safe UI update
            if (!_isDisposed) {
              notifyListeners();
            }
          } catch (e) {
            print('Error in onUserJoined post frame callback: $e');
          }
        });
      },
       onUserOffline: (RtcConnection connection, int remoteUid,
          UserOfflineReasonType reason) {
        print('onUserOffline: $remoteUid');
        if (Get.isBottomSheetOpen == true) {
          Get.back();
        }
        
        if (remoteUid == _coHostID) {
          _coHostID = null;
        } else if (remoteUid == _remoteID) {
          _remoteID = null;
        }
        notifyListeners();
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
    } else if (isHost && _coHostID != null) {
      // Host with co-host - split screen view
      return _buildSplitScreenView();
    } else if (isCoHost && _remoteID != null) {
      // Co-host with host - split screen view
      return _buildSplitScreenView();
    } else if (isHost) {
      // Host without co-host - full screen
      return AgoraVideoView(
        controller: VideoViewController(
            rtcEngine: agoraEngine,
            canvas: VideoCanvas(
                uid: _localUserID,
                sourceType: VideoSourceType.videoSourceCameraPrimary)),
      );
    } else {
      // Audience viewing host
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

  Widget _buildSplitScreenView() {
    return Row(
      children: [
        // Left half - Host video
        Expanded(
          child: Container(
            height: 300, // Fixed height of 300 pixels
            child: Stack(
              children: [
                // Host video (local for host, remote for co-host)
                isHost
                    ? AgoraVideoView(
                        controller: VideoViewController(
                            rtcEngine: agoraEngine,
                            canvas: VideoCanvas(
                                uid: _localUserID,
                                sourceType: VideoSourceType.videoSourceCameraPrimary)),
                      )
                    : (_remoteID != null
                        ? AgoraVideoView(
                            controller: VideoViewController.remote(
                              rtcEngine: agoraEngine,
                              canvas: VideoCanvas(uid: _remoteID),
                              connection: RtcConnection(channelId: _channelName),
                            ),
                          )
                        : Container(color: Colors.black)),
                
                // Host label
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isHost ? 'You (Host)' : 'Host',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Vertical divider (transparent)
        Container(
          width: 2,
          color: Colors.transparent,
        ),
        
        // Right half - Co-host video
        Expanded(
          child: Container(
            height: 300, // Fixed height of 300 pixels
            child: Stack(
              children: [
                // Co-host video (remote for host, local for co-host)
                isHost
                    ? (_coHostID != null
                        ? AgoraVideoView(
                            controller: VideoViewController.remote(
                              rtcEngine: agoraEngine,
                              canvas: VideoCanvas(uid: _coHostID),
                              connection: RtcConnection(channelId: _channelName),
                            ),
                          )
                        : Container(color: Colors.black))
                    : AgoraVideoView(
                        controller: VideoViewController(
                            rtcEngine: agoraEngine,
                            canvas: VideoCanvas(
                                uid: _localUserID,
                                sourceType: VideoSourceType.videoSourceCameraPrimary)),
                      ),
                
                // Co-host label
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isHost ? 'Co-Host' : 'You (Co-Host)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
      
      // Check if livestream document was deleted (host ended the stream)
      if (!isHost && !event.exists && !_isDisposed) {
        print('Host ended the live stream - automatically closing viewer stream');
        // Use post frame callback to ensure safe UI operations
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isDisposed) {
            _handleHostEndedStream();
          }
        });
        return;
      }
      
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
    
    try {
      print('Sending comment to channel: $_channelName');
      print('Comment type: $commentType');
      print('Comment content: $commentContent');
      print('User data: ${user?.data?.userName}');
      
      // Ensure the parent document exists before adding comment
      if (isHost) {
        // For host, make sure the livestream document exists
        await db.collection(FirebaseRes.liveStreamUser).doc(_channelName).get().then((doc) {
          if (!doc.exists) {
            print('Warning: Livestream document does not exist, creating it...');
            // Create the document if it doesn't exist
            return db.collection(FirebaseRes.liveStreamUser).doc(_channelName).set(
              LiveStreamUser(
                fullName: registrationUser?.data?.fullName ?? '',
                isVerified: registrationUser?.data?.isVerify == 1 ? true : false,
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
              ).toJson(),
            );
          }
        });
      }
      
      await db
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
      
      print('Comment sent successfully');
    } catch (e) {
      print('Error sending comment: $e');
      // Show error to user
      Get.snackbar(
        'Error',
        'Failed to send message. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
      return;
    }

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
        onGiftSheetStateChanged: _onGiftSheetStateChanged,
        onGiftSend: (gift) async {
          print("Gift selected: ${gift?.image}");
          // Remove Navigator.pop(context) to allow continuous gift sending

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

  // Listen for co-host invitations
  void _listenForInvitations() async {
    await pref.initPref();
    final currentUser = pref.getUser();
    
    if (currentUser?.data?.userId != null) {
      invitationStream = CoHostInvitationService.listenForInvitations(
        currentUser!.data!.userId!,
      ).listen((snapshot) {
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          
          // Check if invitation is still valid (not expired)
          final expiresAt = data['expiresAt'] as int?;
          if (expiresAt != null && DateTime.now().millisecondsSinceEpoch > expiresAt) {
            // Invitation expired, skip
            continue;
          }
          
          // Show invitation dialog
          _showInvitationDialog(data);
        }
      });
    }
  }

  void _showInvitationDialog(Map<String, dynamic> invitationData) {
    Get.dialog(
      CoHostInvitationDialog(
        roomId: invitationData['roomId'] ?? '',
        hostName: invitationData['hostName'] ?? 'Host',
        hostImage: invitationData['hostImage'],
        invitedUserId: invitationData['invitedUserId'] ?? 0,
        onAccepted: () {
          // Handle invitation acceptance
          print('Co-host invitation accepted');
          _promoteToCoHost(invitationData['roomId'] ?? '');
        },
        onDeclined: () {
          // Handle invitation decline
          print('Co-host invitation declined');
        },
      ),
      barrierDismissible: false, // Prevent dismissing by tapping outside
    );
  }

  // Promote current user to co-host
  Future<void> _promoteToCoHost(String roomId) async {
    try {
      // Leave current channel as audience
      await agoraEngine.leaveChannel();
      
      // Update local state
      isCoHost = true;
      isHost = false;
      
      // Rejoin as broadcaster (co-host)
      await agoraEngine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await agoraEngine.enableVideo();
      await agoraEngine.enableAudio();
      
      // Join the channel again as co-host
      await agoraEngine.joinChannel(
        token: _agoraToken,
        channelId: roomId,
        uid: _localUserID,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );
      
      notifyListeners();
      
      Get.snackbar(
        'Co-Host Activated',
        'You are now a co-host! Your camera is now live.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
      
    } catch (e) {
      print('Error promoting to co-host: $e');
      Get.snackbar(
        'Error',
        'Failed to activate co-host mode. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    }
  }

  // Method to add a user to co-host tracking (called when inviting someone)
  void addCoHostUID(int uid) {
    _coHostUIDs.add(uid);
    print('Added co-host UID: $uid to tracking set');
    notifyListeners();
  }

  // Method to remove a user from co-host tracking
  void removeCoHostUID(int uid) {
    _coHostUIDs.remove(uid);
    print('Removed co-host UID: $uid from tracking set');
    notifyListeners();
  }

  // Method to manually set co-host ID (for debugging/testing)
  void setCoHostID(int? uid) {
    _coHostID = uid;
    print('Manually set co-host ID to: $uid');
    notifyListeners();
  }

  // Method to check if we have a co-host
  bool get hasCoHost => _coHostID != null;

  // Temporary method to force co-host detection (for debugging)
  void forceCoHostDetection() {
    if (_coHostID == null && _remoteID != null) {
      _coHostID = _remoteID;
      print('Forced co-host detection: set coHostID to $_coHostID');
      notifyListeners();
    }
  }

  // Method to send automatic join messages
  Future<void> _sendAutomaticJoinMessage(String message, {bool isCoHost = false}) async {
    // Prevent operations on disposed widget
    if (_isDisposed) return;
    
    try {
      // Add a longer delay to prevent UI conflicts
      await Future.delayed(Duration(milliseconds: 1500));
      
      // Double check if widget is still active
      if (_isDisposed) return;
      
      // Ensure the livestream document exists before adding comment
      final docSnapshot = await db.collection(FirebaseRes.liveStreamUser).doc(_channelName).get();
      if (!docSnapshot.exists || _isDisposed) {
        print('Livestream document does not exist or widget disposed, skipping join message');
        return;
      }
      
      // Use a try-catch for the Firebase operation
      try {
        await db
            .collection(FirebaseRes.liveStreamUser)
            .doc(_channelName)
            .collection(FirebaseRes.comment)
            .add(LiveStreamComment(
              id: DateTime.now().millisecondsSinceEpoch,
              userName: 'System',
              userImage: '',
              userId: -1,
              fullName: 'System',
              comment: message,
              commentType: FirebaseRes.msg, // Use msg type for system messages
              isVerify: false,
              userLevel: 1,
            ).toJson());
        
        print('Automatic join message sent: $message');
      } catch (firebaseError) {
        print('Firebase error in join message: $firebaseError');
        // Silently fail to prevent crashes
      }
    } catch (e) {
      print('Error sending automatic join message: $e');
      // Don't rethrow to prevent crashes
    }
  }

  // Method to update watching count
  Future<void> _updateWatchingCount(int increment) async {
    try {
      await db.collection(FirebaseRes.liveStreamUser).doc(_channelName).update({
        FirebaseRes.watchingCount: FieldValue.increment(increment),
      });
      print('Watching count updated by: $increment');
    } catch (e) {
      print('Error updating watching count: $e');
    }
  }

  // Method to handle when host ends the stream (for viewers)
  void _handleHostEndedStream() {
    if (_isDisposed) return; // Prevent operations on disposed widget
    
    print('Host ended stream - starting viewer cleanup process');
    
    try {
      // Immediately stop all timers and streams
      timer?.cancel();
      minimumUserLiveTimer?.cancel();
      commentStream?.cancel();
      invitationStream?.cancel();
      
      // Leave Agora channel immediately
      agoraEngine.leaveChannel().catchError((error) {
        print('Error leaving Agora channel: $error');
      });
      
      // Show notification to user
      Get.snackbar(
        'Live Stream Ended',
        'The host has ended the live stream.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
      
      // Navigate back with a small delay to ensure cleanup
      Future.delayed(Duration(milliseconds: 300), () {
        if (!_isDisposed) {
          try {
            // Force close the current screen
            if (Get.isRegistered<BroadCastScreenViewModel>()) {
              Get.back();
            } else {
              // Fallback navigation
              Navigator.of(Get.context!).pop();
            }
            print('Viewer successfully navigated back after host ended stream');
          } catch (navError) {
            print('Navigation error: $navError');
            // Last resort - try system back
            SystemNavigator.pop();
          }
        }
      });
      
    } catch (e) {
      print('Error in _handleHostEndedStream: $e');
      // Emergency fallback - force close
      try {
        Get.back();
      } catch (backError) {
        print('Emergency back failed: $backError');
        SystemNavigator.pop();
      }
    }
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    // Cancel all timers first
    timer?.cancel();
    minimumUserLiveTimer?.cancel();
    
    // Cancel all streams
    commentStream?.cancel();
    invitationStream?.cancel();
    
    // Clean up controllers
    commentController.dispose();
    commentFocus.dispose();
    
    // Clean up Agora engine
    try {
      if (engineEventHandler != null) {
        agoraEngine.unregisterEventHandler(engineEventHandler!);
      }
    } catch (e) {
      print('Error unregistering event handler: $e');
    }
    
    super.dispose();
  }
}
