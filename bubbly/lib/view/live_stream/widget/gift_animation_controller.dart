import 'package:bubbly/modal/live_stream/live_stream.dart';
import 'package:bubbly/modal/setting/setting.dart';
import 'package:bubbly/utils/firebase_res.dart';
import 'package:flutter/material.dart';

class GiftAnimationController extends ChangeNotifier {
  // Singleton instance
  static final GiftAnimationController _instance =
      GiftAnimationController._internal();
  factory GiftAnimationController() => _instance;
  GiftAnimationController._internal() {
    print("GiftAnimationController initialized");
  }

  // List to store active gift comments for animation
  final List<LiveStreamComment> _activeGifts = [];
  List<LiveStreamComment> get activeGifts => _activeGifts;

  // Map to track processed gifts
  final Map<int, bool> _processedGifts = {};

  // Debug mode flag - set to true for debugging
  bool _debugMode = true;

  // Add a new gift to be animated
  void addGift(LiveStreamComment giftComment) {
    if (_debugMode) {
      print(
          "GiftAnimationController.addGift called with: ${giftComment.comment} from: ${giftComment.fullName}");
    }

    if (giftComment.id == null) {
      if (_debugMode) print("Gift has null ID, generating one...");
      // Generate ID if missing
      giftComment = LiveStreamComment(
        id: DateTime.now().millisecondsSinceEpoch,
        userName: giftComment.userName,
        userImage: giftComment.userImage,
        userId: giftComment.userId,
        fullName: giftComment.fullName,
        comment: giftComment.comment,
        commentType: FirebaseRes.image,
        isVerify: giftComment.isVerify,
        userLevel: giftComment.userLevel,
      );
    }

    if (_processedGifts.containsKey(giftComment.id)) {
      if (_debugMode) print("Gift already processed: ${giftComment.id}");
      return;
    }

    if (_debugMode)
      print("GiftAnimationController: Adding gift with ID ${giftComment.id} - Image: ${giftComment.comment}");

    // Mark as processed
    _processedGifts[giftComment.id!] = true;

    // Add to active gifts (limit to 3)
    if (_activeGifts.length >= 3) {
      _activeGifts.removeAt(0);
      if (_debugMode) print("Removed oldest gift to make room");
    }
    _activeGifts.add(giftComment);

    // Notify listeners to update UI
    notifyListeners();
    if (_debugMode)
      print(
          "Notified listeners about new gift. Active gifts count: ${_activeGifts.length}");

    // Auto-remove after 10 seconds to match the animation duration
    Future.delayed(const Duration(seconds: 11), () {
      if (_activeGifts.contains(giftComment)) {
        _activeGifts.remove(giftComment);
        notifyListeners();
        if (_debugMode)
          print("GiftAnimationController: Removed gift ${giftComment.id}");
      }
    });
  }

  // Process a list of comments to find and add new gift comments
  void processComments(
      List<LiveStreamComment> comments, SettingData? settingData) {
    if (_debugMode) {
      print("Processing ${comments.length} comments for gifts");
      print("Setting data exists: ${settingData != null}");
      print("Gifts in setting data: ${settingData?.gifts?.length ?? 'null'}");
    }

    for (final comment in comments) {
      if (comment.commentType == FirebaseRes.image &&
          comment.id != null &&
          !_processedGifts.containsKey(comment.id)) {
        if (_debugMode) {
          print("Found unprocessed gift: ${comment.id} - ${comment.comment}");
          
          // Check if this gift has a matching entry in the settingData
          if (settingData?.gifts != null) {
            final matchingGift = settingData!.gifts!.firstWhere(
              (gift) => gift.image == comment.comment,
              orElse: () => Gifts(),
            );
            print("Matched gift info - ID: ${matchingGift.id}, AnimationStyle: ${matchingGift.animationStyle}");
          }
        }
        
        addGift(comment);
      }
    }
  }

  // Clear all animations
  void clearAll() {
    _activeGifts.clear();
    notifyListeners();
    if (_debugMode) print("Cleared all gifts");
  }
}
