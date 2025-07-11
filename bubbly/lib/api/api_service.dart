import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:bubbly/modal/agora/agora.dart';
import 'package:bubbly/modal/agora/agora_token.dart';
import 'package:bubbly/modal/app_version.dart';
import 'package:bubbly/modal/chat/chat.dart';
import 'package:bubbly/modal/comment/comment.dart';
import 'package:bubbly/modal/explore/explore_hash_tag.dart';
import 'package:bubbly/modal/file_path/file_path.dart';
import 'package:bubbly/modal/followers/follower_following_data.dart';
import 'package:bubbly/modal/hashtag/hash_tag_video.dart';
import 'package:bubbly/modal/live_stream/live_stream.dart';
import 'package:bubbly/modal/notification/notification.dart';
import 'package:bubbly/modal/nudity/nudity_checker.dart';
import 'package:bubbly/modal/nudity/nudity_media_id.dart';
import 'package:bubbly/modal/plan/coin_plans.dart';
import 'package:bubbly/modal/profileCategory/profile_category.dart';
import 'package:bubbly/modal/rest/rest_response.dart';
import 'package:bubbly/modal/search/search_user.dart';
import 'package:bubbly/modal/setting/setting.dart';
import 'package:bubbly/modal/shareable_link.dart';
import 'package:bubbly/modal/single/single_post.dart';
import 'package:bubbly/modal/sound/fav/favourite_music.dart';
import 'package:bubbly/modal/sound/sound.dart';
import 'package:bubbly/modal/status.dart';
import 'package:bubbly/modal/user/user.dart';
import 'package:bubbly/modal/user/user_level.dart';
import 'package:bubbly/modal/user_video/user_video.dart';
import 'package:bubbly/modal/wallet/my_wallet.dart';
import 'package:bubbly/modal/wallet/transaction_history.dart';
import 'package:bubbly/utils/level_utils.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/crash_reporter.dart';
import 'package:bubbly/utils/key_res.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:bubbly/utils/url_res.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as FireBaseAuth1;
import 'package:path_provider/path_provider.dart';

class ApiService {
  var client = http.Client();

  /// Safely executes an API call and reports errors to Crashlytics
  Future<T> _safeApiCall<T>(String endpoint, Future<T> Function() apiCall) async {
    try {
      CrashReporter.log('API Call: $endpoint');
      return await apiCall();
    } catch (error, stackTrace) {
      // Log the API error to Crashlytics with endpoint context
      await CrashReporter.logError(
        error, 
        stackTrace,
        customKeys: {
          'api_endpoint': endpoint,
          'user_id': SessionManager.userId.toString(),
        },
      );
      
      // Rethrow the error after logging
      rethrow;
    }
  }

  Future<User> registerUser(HashMap<String, String?> params) async {
    return _safeApiCall(UrlRes.registerUser, () async {
      final response = await client.post(Uri.parse(UrlRes.registerUser),
          headers: {UrlRes.uniqueKey: ConstRes.apiKey}, body: params);
      print('PARAMS : $params');
  
      final responseJson = jsonDecode(response.body);
      SessionManager sessionManager = SessionManager();
      await sessionManager.initPref();
      sessionManager.saveUser(
        jsonEncode(User.fromJson(responseJson)),
      );
      return User.fromJson(responseJson);
    });
  }

  Future<UserVideo> getUserVideos(
      String star, String limit, String? userId, int type) async {
    Map map = {};
    map[UrlRes.start] = star;
    map[UrlRes.limit] = limit;
    map[UrlRes.userId] = '$userId';
    map[UrlRes.myUserId] = '${SessionManager.userId}';

    final response = await client.post(
      Uri.parse(type == 0 ? UrlRes.getUserVideos : UrlRes.getUserLikesVideos),
      body: map,
      headers: {UrlRes.uniqueKey: ConstRes.apiKey},
    );
    final responseJson = jsonDecode(response.body);

    return UserVideo.fromJson(responseJson);
  }

  Future<UserVideo> getPostList(
      String limit, String userId, String type) async {
    final response = await client.post(
      Uri.parse(UrlRes.getPostList),
      body: {
        UrlRes.limit: limit,
        UrlRes.userId: userId,
        UrlRes.type: type,
      },
      headers: {UrlRes.uniqueKey: ConstRes.apiKey},
    );
    final responseJson = jsonDecode(response.body);
    return UserVideo.fromJson(responseJson);
  }
  
  Future<UserVideo> getRecommendations(String limit, String userId) async {
    final response = await client.post(
      Uri.parse(UrlRes.getRecommendations),
      body: {
        UrlRes.limit: limit,
        UrlRes.userId: userId,
      },
      headers: {UrlRes.uniqueKey: ConstRes.apiKey},
    );
    final responseJson = jsonDecode(response.body);
    return UserVideo.fromJson(responseJson);
  }
  
  Future<RestResponse> trackInteraction(String postId, String interactionType, {String? duration}) async {
    final Map<String, dynamic> body = {
      UrlRes.postId: postId,
      UrlRes.interactionType: interactionType,
      'user_id': SessionManager.userId.toString(),
      // Add userId parameter as well (for compatibility)
      'userId': SessionManager.userId.toString(),
    };
    
    if (duration != null) {
      body[UrlRes.viewDuration] = duration;
    }
    
    // Debug: Log request details
    //print('TRACK INTERACTION REQUEST:');
    //print('URL: ${UrlRes.trackInteraction}');
    //print('USER ID: ${SessionManager.userId}');
    //print('TOKEN: ${SessionManager.accessToken}');
    //print('BODY: $body');
    
    try {
      final response = await client.post(
        Uri.parse(UrlRes.trackInteraction),
        body: body,
        headers: {
          UrlRes.uniqueKey: ConstRes.apiKey,
          UrlRes.authorization: SessionManager.accessToken,
        },
      );
      
      // Debug: Log response
      print('TRACK INTERACTION RESPONSE: ${response.statusCode}');
      print('RESPONSE BODY: ${response.body}');
      
      final responseJson = jsonDecode(response.body);
      return RestResponse.fromJson(responseJson);
    } catch (e) {
      // Debug: Log any errors
      print('TRACK INTERACTION ERROR: $e');
      return RestResponse(status: 500, message: 'Error tracking interaction: $e');
    }
  }

  Future<RestResponse> likeUnlikePost(String postId) async {
    // print(SessionManager.accessToken);
    final response = await client.post(
      Uri.parse(UrlRes.likeUnlikePost),
      body: {
        UrlRes.postId: postId,
      },
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      },
    );

    final responseJson = jsonDecode(response.body);
    return RestResponse.fromJson(responseJson);
  }

  Future<Comment> getCommentByPostId(
      String start, String limit, String postId) async {
    try {
      final response = await client.post(
        Uri.parse(UrlRes.getCommentByPostId),
        body: {
          UrlRes.postId: postId,
          UrlRes.start: start,
          UrlRes.limit: limit,
        },
        headers: {
          UrlRes.uniqueKey: ConstRes.apiKey,
          //UrlRes.authorization: SessionManager.accessToken,
        },
      );

      // Debug info
      print('COMMENT API RESPONSE CODE: ${response.statusCode}');
      print('COMMENT API RESPONSE BODY TYPE: ${response.body.substring(0, math.min(50, response.body.length))}...');
      
      try {
        final responseJson = jsonDecode(response.body);
        return Comment.fromJson(responseJson);
      } catch (e) {
        // If JSON parsing fails, return an empty comment object
        print('ERROR PARSING COMMENT RESPONSE: $e');
        return Comment(
          status: 0,
          message: 'Error parsing response from server',
          data: [],
        );
      }
    } catch (e) {
      print('COMMENT API ERROR: $e');
      return Comment(
        status: 0,
        message: 'Error connecting to server',
        data: [],
      );
    }
  }

  Future<RestResponse> addComment(String comment, String postId, {List<Map<String, dynamic>>? mentions}) async {
    try {
      var body = {
        UrlRes.comment: comment,
        UrlRes.postId: postId,
      };
      
      if (mentions != null && mentions.isNotEmpty) {
        body['mentions'] = json.encode(mentions);
      }

      final response = await client.post(
        Uri.parse(UrlRes.addComment),
        body: {
          UrlRes.postId: postId,
          UrlRes.comment: comment,
        },
        headers: {
          UrlRes.uniqueKey: ConstRes.apiKey,
          UrlRes.authorization: SessionManager.accessToken,
        },
      );

      // Check if response is valid JSON
      try {
        final responseJson = jsonDecode(response.body);
        return RestResponse.fromJson(responseJson);
      } catch (e) {
        // If the response is not valid JSON (like HTML), check the status code
        if (response.statusCode == 200 || response.statusCode == 201) {
          // If status code indicates success, return a success response
          return RestResponse(
            status: 200,
            message: "Comment added successfully!",
          );
        } else {
          // For other status codes, return appropriate error
          return RestResponse(
            status: response.statusCode,
            message: "Server error. Please try again later.",
          );
        }
      }
    } catch (e) {
      // Handle network or other exceptions
      return RestResponse(
        status: 500,
        message: "Connection error. Please check your internet connection.",
      );
    }
  }

  Future<RestResponse> deleteComment(String commentID) async {
    try {
      final response = await client.post(
        Uri.parse(UrlRes.deleteComment),
        body: {
          UrlRes.commentId: commentID,
        },
        headers: {
          UrlRes.uniqueKey: ConstRes.apiKey,
          UrlRes.authorization: SessionManager.accessToken,
        },
      );

      // Check if response is valid JSON
      try {
        final responseJson = jsonDecode(response.body);
        return RestResponse.fromJson(responseJson);
      } catch (e) {
        // If the response is not valid JSON (like HTML), check the status code
        if (response.statusCode == 200 || response.statusCode == 201) {
          // If status code indicates success, return a success response
          return RestResponse(
            status: 200,
            message: "Comment deleted successfully!",
          );
        } else {
          // For other status codes, return appropriate error
          return RestResponse(
            status: response.statusCode,
            message: "Server error. Please try again later.",
          );
        }
      }
    } catch (e) {
      // Handle network or other exceptions
      return RestResponse(
        status: 500,
        message: "Connection error. Please check your internet connection.",
      );
    }
  }
  
  Future<RestResponse> addReply(String comment, String postId, String parentId, {List<Map<String, dynamic>>? mentions}) async {
    try {
      var body = {
        UrlRes.comment: comment,
        UrlRes.postId: postId,
        'parent_id': parentId,
      };
      
      if (mentions != null && mentions.isNotEmpty) {
        body['mentions'] = json.encode(mentions);
      }

      final response = await client.post(
        Uri.parse(UrlRes.addComment),
        body: {
          UrlRes.postId: postId,
          UrlRes.comment: comment,
          'parent_id': parentId,
        },
        headers: {
          UrlRes.uniqueKey: ConstRes.apiKey,
          UrlRes.authorization: SessionManager.accessToken,
        },
      );

      // Check if response is valid JSON
      try {
        final responseJson = jsonDecode(response.body);
        return RestResponse.fromJson(responseJson);
      } catch (e) {
        // If the response is not valid JSON (like HTML), check the status code
        if (response.statusCode == 200 || response.statusCode == 201) {
          // If status code indicates success, return a success response
          return RestResponse(
            status: 200,
            message: "Reply added successfully!",
          );
        } else {
          // For other status codes, return appropriate error
          return RestResponse(
            status: response.statusCode,
            message: "Server error. Please try again later.",
          );
        }
      }
    } catch (e) {
      // Handle network or other exceptions
      return RestResponse(
        status: 500,
        message: "Connection error. Please check your internet connection.",
      );
    }
  }
  
  Future<RestResponse> likeComment(String commentId) async {
    try {
      final response = await client.post(
        Uri.parse(UrlRes.likeComment),
        body: {
          UrlRes.commentId: commentId,
        },
        headers: {
          UrlRes.uniqueKey: ConstRes.apiKey,
          UrlRes.authorization: SessionManager.accessToken,
        },
      );

      // Check if response is valid JSON
      try {
        final responseJson = jsonDecode(response.body);
        return RestResponse.fromJson(responseJson);
      } catch (e) {
        // If the response is not valid JSON (like HTML), check the status code
        if (response.statusCode == 200 || response.statusCode == 201) {
          // If status code indicates success, return a success response
          return RestResponse(
            status: 200,
            message: "Comment like status updated!",
          );
        } else {
          // For other status codes, return appropriate error
          return RestResponse(
            status: response.statusCode,
            message: "Server error. Please try again later.",
          );
        }
      }
    } catch (e) {
      // Handle network or other exceptions
      return RestResponse(
        status: 500,
        message: "Connection error. Please check your internet connection.",
      );
    }
  }
  
  Future<RestResponse> editComment(String commentId, String newCommentText) async {
    try {
      final response = await client.post(
        Uri.parse(UrlRes.editComment),
        body: {
          UrlRes.commentId: commentId,
          UrlRes.comment: newCommentText,
        },
        headers: {
          UrlRes.uniqueKey: ConstRes.apiKey,
          UrlRes.authorization: SessionManager.accessToken,
        },
      );

      // Check if response is valid JSON
      try {
        final responseJson = jsonDecode(response.body);
        return RestResponse.fromJson(responseJson);
      } catch (e) {
        // If the response is not valid JSON (like HTML), check the status code
        if (response.statusCode == 200 || response.statusCode == 201) {
          // If status code indicates success, return a success response
          return RestResponse(
            status: 200,
            message: "Comment updated successfully!",
          );
        } else {
          // For other status codes, return appropriate error
          return RestResponse(
            status: response.statusCode,
            message: "Server error. Please try again later.",
          );
        }
      }
    } catch (e) {
      // Handle network or other exceptions
      return RestResponse(
        status: 500,
        message: "Connection error. Please check your internet connection.",
      );
    }
  }

  Future<UserVideo> getPostByHashTag(
      String start, String limit, String? hashTag) async {
    // print(hashTag);
    final response = await client.post(
      Uri.parse(UrlRes.videosByHashTag),
      body: {
        UrlRes.start: start,
        UrlRes.limit: limit,
        UrlRes.userId: SessionManager.userId.toString(),
        UrlRes.hashTag: hashTag,
      },
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
      },
    );
    final responseJson = jsonDecode(response.body);
    return UserVideo.fromJson(responseJson);
  }

  Future<UserVideo> getPostBySoundId(
      String start, String limit, String? soundId) async {
    final response = await client.post(
      Uri.parse(UrlRes.getPostBySoundId),
      body: {
        UrlRes.start: start,
        UrlRes.limit: limit,
        UrlRes.userId: SessionManager.userId.toString(),
        UrlRes.soundId: soundId,
      },
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
      },
    );
    final responseJson = jsonDecode(response.body);
    return UserVideo.fromJson(responseJson);
  }

  Future<RestResponse> sendCoin(String coin, String toUserId, {String? giftId}) async {
    client = http.Client();
    final body = {
      UrlRes.toUserId: toUserId,
      UrlRes.coin: coin,
    };
    
    if (giftId != null) {
      body['gift_id'] = giftId;
    }
    
    print("COIN API: Sending ${coin} coins to user ${toUserId} ${giftId != null ? 'with gift #$giftId' : ''}");
    
    final response = await client.post(
      Uri.parse(UrlRes.sendCoin),
      body: body,
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      },
    );
    final responseJson = jsonDecode(response.body);
    print("COIN API: Response status: ${responseJson['status']}, message: ${responseJson['message']}");
    
    // Points should now be updated on the server from the WalletController.php
    // But we'll add a short delay and refresh user data to ensure we have the updated level
    try {
      // Short delay to allow server to process the level update
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get the updated profile with new level
      await getProfile(SessionManager.userId.toString());
      print("COIN API: Refreshed profile after coin transaction");
    } catch (e) {
      print("COIN API: Error refreshing profile: $e");
    }
    
    return RestResponse.fromJson(responseJson);
  }

  Future<ExploreHashTag> getExploreHashTag(String start, String limit) async {
    final response = await client.post(
      Uri.parse(UrlRes.getExploreHashTag),
      body: {
        UrlRes.start: start,
        UrlRes.limit: limit,
        'include_recent_videos': 'true',
        'recent_videos_limit': '15',
      },
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
      },
    );
    // print(response.body);
    final responseJson = jsonDecode(response.body);
    return ExploreHashTag.fromJson(responseJson);
  }

  Future<SearchUser> getSearchUser(String start, String limit, String keyWord) async {
    client = http.Client();
    final response = await client.post(
      Uri.parse(UrlRes.getUserSearchPostList),
      body: {
        UrlRes.start: start,
        UrlRes.limit: limit,
        UrlRes.keyWord: keyWord,
      },
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
      },
    );
    // print(response.body);
    final responseJson = jsonDecode(response.body);
    return SearchUser.fromJson(responseJson);
  }

  Future<UserVideo> getSearchPostList(
      String start, String limit, String? userId, String? keyWord) async {
    client = http.Client();
    final response = await client.post(
      Uri.parse(UrlRes.getSearchPostList),
      body: {
        UrlRes.start: start,
        UrlRes.limit: limit,
        UrlRes.userId: userId,
        UrlRes.keyWord: keyWord,
      },
      headers: {UrlRes.uniqueKey: ConstRes.apiKey},
    );
    final responseJson = jsonDecode(response.body);
    return UserVideo.fromJson(responseJson);
  }

  Future<UserNotifications> getNotificationList(
      String start, String limit) async {
    client = http.Client();
    final response = await client.post(
      Uri.parse(UrlRes.getNotificationList),
      body: {
        UrlRes.start: start,
        UrlRes.limit: limit,
      },
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      },
    );
    // print(response.statusCode);
    final responseJson = jsonDecode(response.body);
    return UserNotifications.fromJson(responseJson);
  }

  Future<RestResponse> setNotificationSettings(String? deviceToken) async {
    client = http.Client();
    final response = await client.post(
      Uri.parse(UrlRes.setNotificationSettings),
      body: {
        UrlRes.deviceToken: deviceToken,
      },
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      },
    );
    // print(response.body);
    final responseJson = jsonDecode(response.body);
    return RestResponse.fromJson(responseJson);
  }

  Future<MyWallet> getMyWalletCoin() async {
    client = http.Client();
    final response = await client.get(
      Uri.parse(UrlRes.getMyWalletCoin),
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      },
    );
    final responseJson = jsonDecode(response.body);
    return MyWallet.fromJson(responseJson);
  }

  Future<RestResponse> redeemRequest(String amount, String redeemRequestType,
      String account, String coin) async {
    client = http.Client();
    final response = await client.post(
      Uri.parse(UrlRes.redeemRequest),
      body: {
        UrlRes.amount: amount,
        UrlRes.redeemRequestType: redeemRequestType,
        UrlRes.account: account,
        UrlRes.coin: coin,
      },
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      },
    );
    final responseJson = jsonDecode(response.body);
    await getProfile(SessionManager.userId.toString());
    return RestResponse.fromJson(responseJson);
  }

  Future<RestResponse> verifyRequest(String idNumber, String name,
      String address, File? photoIdImage, File? photoWithIdImage) async {
    var request = http.MultipartRequest(
      "POST",
      Uri.parse(UrlRes.verifyRequest),
    );
    request.headers[UrlRes.uniqueKey] = ConstRes.apiKey;
    request.headers[UrlRes.authorization] = SessionManager.accessToken;
    request.fields[UrlRes.idNumber] = idNumber;
    request.fields[UrlRes.name] = name;
    request.fields[UrlRes.address] = address;
    if (photoIdImage != null) {
      request.files.add(
        http.MultipartFile(UrlRes.photoIdImage,
            photoIdImage.readAsBytes().asStream(), photoIdImage.lengthSync(),
            filename: photoIdImage.path.split("/").last),
      );
    }
    if (photoWithIdImage != null) {
      request.files.add(
        http.MultipartFile(
            UrlRes.photoWithIdImage,
            photoWithIdImage.readAsBytes().asStream(),
            photoWithIdImage.lengthSync(),
            filename: photoWithIdImage.path.split("/").last),
      );
    }
    var response = await request.send();
    var respStr = await response.stream.bytesToString();
    await getProfile(SessionManager.userId.toString());
    return RestResponse.fromJson(jsonDecode(respStr));
  }

  Future<User> getProfile(String? userId) async {
    Map<String, dynamic> map = {};
    if (SessionManager.userId != -1) {
      map[UrlRes.myUserId] = SessionManager.userId.toString();
    }
    map[UrlRes.userId] = userId;
    final response = await client.post(
      Uri.parse(UrlRes.getProfile),
      body: map,
      headers: {UrlRes.uniqueKey: ConstRes.apiKey},
    );
    final responseJson = jsonDecode(response.body);
    if (userId == SessionManager.userId.toString()) {
      SessionManager sessionManager = SessionManager();
      await sessionManager.initPref();
      User user = User.fromJson(responseJson);
      if (SessionManager.accessToken.isNotEmpty) {
        user.data?.setToken(SessionManager.accessToken);
      }
      sessionManager.saveUser(jsonEncode(user));
    }
    return User.fromJson(responseJson);
  }

  Future<ProfileCategory> getProfileCategoryList() async {
    client = http.Client();
    final response = await client.get(
      Uri.parse(UrlRes.getProfileCategoryList),
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      },
    );

    final responseJson = jsonDecode(response.body);
    return ProfileCategory.fromJson(responseJson);
  }

  Future<User> updateProfile(
      {String? fullName,
      String? userName,
      String? bio,
      String? fbUrl,
      String? instagramUrl,
      String? youtubeUrl,
      String? profileCategory,
      File? profileImage,
      String? isNotification}) async {
    var request = http.MultipartRequest(
      "POST",
      Uri.parse(UrlRes.updateProfile),
    );
    request.headers[UrlRes.uniqueKey] = ConstRes.apiKey;
    request.headers[UrlRes.authorization] = SessionManager.accessToken;

    if (fullName != null && fullName.isNotEmpty) {
      request.fields[UrlRes.fullName] = fullName;
    }
    if (userName != null && userName.isNotEmpty) {
      request.fields[UrlRes.userName] = userName;
    }
    if (bio != null && bio.isNotEmpty) {
      request.fields[UrlRes.bio] = bio;
    }
    if (isNotification != null && isNotification.isNotEmpty) {
      request.fields[UrlRes.isNotification] = isNotification;
    }
    if (fbUrl != null && fbUrl.isNotEmpty) {
      request.fields[UrlRes.fbUrl] = fbUrl;
    }
    if (instagramUrl != null && instagramUrl.isNotEmpty) {
      request.fields[UrlRes.instaUrl] = instagramUrl;
    }
    if (youtubeUrl != null && youtubeUrl.isNotEmpty)
      request.fields[UrlRes.youtubeUrl] = youtubeUrl;
    if (profileCategory != null && profileCategory.isNotEmpty) {
      request.fields[UrlRes.profileCategory] = profileCategory;
    }
    if (profileImage != null) {
      request.files.add(
        http.MultipartFile(UrlRes.userProfile,
            profileImage.readAsBytes().asStream(), profileImage.lengthSync(),
            filename: profileImage.path.split("/").last),
      );
    }

    var response = await request.send();
    var respStr = await response.stream.bytesToString();

    User user = User.fromJson(jsonDecode(respStr));
    if (user.data?.userId.toString() == SessionManager.userId.toString()) {
      SessionManager sessionManager = SessionManager();
      await sessionManager.initPref();
      if (SessionManager.accessToken.isNotEmpty) {
        user.data?.setToken(SessionManager.accessToken);
      }
      sessionManager.saveUser(jsonEncode(user));
    }
    return User.fromJson(jsonDecode(respStr));
  }

  Future<RestResponse> followUnFollowUser(String toUserId) async {
    try {
      final response = await client.post(
        Uri.parse(UrlRes.followUnFollowPost),
        body: {UrlRes.toUserId: toUserId},
        headers: {
          UrlRes.uniqueKey: ConstRes.apiKey,
          UrlRes.authorization: SessionManager.accessToken,
        },
      );

      // Check if the response has a successful status code
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          // Try to decode JSON response
          final responseJson = jsonDecode(response.body);
          return RestResponse.fromJson(responseJson);
        } catch (e) {
          // If JSON decode fails but HTTP status is success, assume operation succeeded
          return RestResponse(
            status: 200, // Force success status regardless of HTML response
            message: "Action completed successfully.",
          );
        }
      } else {
        // Non-success HTTP status, return appropriate error
        try {
          final responseJson = jsonDecode(response.body);
          return RestResponse.fromJson(responseJson);
        } catch (e) {
          // Error response is not valid JSON
          return RestResponse(
            status: response.statusCode,
            message: "Action completed successfully.",
          );
        }
      }
    } catch (e) {
      // Handle network or other exceptions
      return RestResponse(
        status: 500,
        message: "Connection error: ${e.toString()}",
      );
    }
  }

  Future<FollowerFollowingData> getFollowersList(
      String userId, String start, String count, int type) async {
    final response = await client.post(
      Uri.parse(type == 0 ? UrlRes.getFollowerList : UrlRes.getFollowingList),
      body: {
        UrlRes.userId: userId,
        UrlRes.start: start,
        UrlRes.limit: count,
      },
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      },
    );

    final responseJson = jsonDecode(response.body);
    return FollowerFollowingData.fromJson(responseJson);
  }

  Future<Sound> getSoundList() async {
    final response = await client.get(
      Uri.parse(UrlRes.getSoundList),
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken
      },
    );

    final responseJson = jsonDecode(response.body);
    return Sound.fromJson(responseJson);
  }

  Future<FavouriteMusic> getFavouriteSoundList() async {
    SessionManager sessionManager = new SessionManager();
    await sessionManager.initPref();
    final response = await client.post(
      Uri.parse(UrlRes.getFavouriteSoundList),
      body: jsonEncode(<String, List<String>>{
        UrlRes.soundIds: sessionManager.getFavouriteMusic(),
      }),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      },
    );

    final responseJson = jsonDecode(response.body);
    return FavouriteMusic.fromJson(responseJson);
  }

  Future<RestResponse> addPost({
    required String postDescription,
    required String postHashTag,
    required String isOriginalSound,
    String? soundTitle,
    String? audioDuration,
    String? singer,
    String? soundId,
    File? postVideo,
    File? thumbnail,
    File? postSound,
    File? soundImage,
  }) async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse(UrlRes.addPost),
      );
      
      // Set a longer timeout for video uploads
      request.headers[UrlRes.uniqueKey] = ConstRes.apiKey;
      request.headers[UrlRes.authorization] = SessionManager.accessToken;
      request.fields[UrlRes.userId] = SessionManager.userId.toString();
      
      if (postDescription.isNotEmpty) {
        request.fields[UrlRes.postDescription] = postDescription;
      }
      if (postHashTag.isNotEmpty) {
        request.fields[UrlRes.postHashTag] = postHashTag;
      }
      request.fields[UrlRes.isOriginalSound] = isOriginalSound;
      
      if (isOriginalSound == '1') {
        request.fields[UrlRes.soundTitle] = soundTitle!;
        request.fields[UrlRes.duration] = audioDuration!;
        request.fields[UrlRes.singer] = singer!;
        if (postSound != null) {
          request.files.add(
            http.MultipartFile(UrlRes.postSound,
                postSound.readAsBytes().asStream(), postSound.lengthSync(),
                filename: postSound.path.split("/").last),
          );
        }
        if (soundImage != null) {
          request.files.add(http.MultipartFile(UrlRes.soundImage,
                soundImage.readAsBytes().asStream(), soundImage.lengthSync(),
                filename: soundImage.path.split("/").last),
          );
        }
      } else {
        request.fields[UrlRes.soundId] = soundId!;
      }
      
      if (postVideo != null) {
        // Check video file size
        var videoSize = postVideo.lengthSync();
        print('Video file size: ${(videoSize / 1024 / 1024).toStringAsFixed(2)} MB');
        
        if (videoSize > 100 * 1024 * 1024) { // 100MB limit
          return RestResponse(
            status: 413,
            message: "File size too large. Please upload a smaller video.",
          );
        }
        
        request.files.add(http.MultipartFile(UrlRes.postVideo, postVideo.readAsBytes().asStream(),
              postVideo.lengthSync(),
              filename: postVideo.path.split("/").last),
        );
      }
      
      if (thumbnail != null) {
        request.files.add(http.MultipartFile(UrlRes.postImage, thumbnail.readAsBytes().asStream(),
              thumbnail.lengthSync(),
              filename: thumbnail.path.split("/").last),
        );
      }

      print('PARAMETER : ${request.fields}');
      print('AUTHORISATION : ${SessionManager.accessToken}');
      print('PARAMETER Files : ${request.files.map((e) => e.field)}');

      // Create a client with custom timeout
      var client = http.Client();
      
      try {
        // Send the request with a timeout
        var streamedResponse = await client.send(request).timeout(
          const Duration(minutes: 5), // 5 minute timeout for large video uploads
          onTimeout: () {
            client.close();
            throw Exception('Upload timeout. Please check your internet connection and try again.');
          },
        );
        
        var response = await http.Response.fromStream(streamedResponse);
        
        log('Add Post : ${response.statusCode}');
        var respStr = response.body;
        
        if (response.statusCode == 413) {
          return RestResponse(
            status: 413,
            message: "File size too large. Please upload a smaller video.",
          );
        }
        
        final responseJson = jsonDecode(respStr);
        log('Add Post json: ${responseJson}');
        
        addCoin();
        return RestResponse.fromJson(responseJson);
        
      } catch (e) {
        print('Upload error: $e');
        
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection reset') ||
            e.toString().contains('Connection closed')) {
          return RestResponse(
            status: 500,
            message: "Connection lost during upload. Please check your internet connection and try again.",
          );
        }
        
        return RestResponse(
          status: 500,
          message: "Upload failed: ${e.toString()}",
        );
      } finally {
        client.close();
      }
      
    } catch (e) {
      print('Add post error: $e');
      return RestResponse(
        status: 500,
        message: "Error uploading post: ${e.toString()}",
      );
    }
  }

  Future<FavouriteMusic> getSearchSoundList(String keyword) async {
    client = http.Client();
    SessionManager sessionManager = new SessionManager();
    await sessionManager.initPref();
    final response = await client.post(
      Uri.parse(UrlRes.getSearchSoundList),
      body: {
        UrlRes.keyWord: keyword,
      },
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      },
    );

    // print(response.body);
    final responseJson = jsonDecode(response.body);
    return FavouriteMusic.fromJson(responseJson);
  }

  Future<UserVideo> getPostsByType({
    required int? pageDataType,
    required String start,
    required String limit,
    String? userId,
    String? soundId,
    String? hashTag,
    String? keyWord,
  }) {
    ///PagedDataType
    ///1 = UserVideo
    ///2 = UserLikesVideo
    ///3 = PostsBySound
    ///4 = PostsByHashTag
    ///5 = PostsBySearch
    switch (pageDataType) {
      case 1:
        return getUserVideos(start, limit, userId, 0);
      case 2:
        return getUserVideos(start, limit, userId, 1);
      case 3:
        return getPostBySoundId(start, limit, soundId);
      case 4:
        return getPostByHashTag(start, limit, hashTag!.replaceAll('#', ''));
      case 5:
        return getSearchPostList(start, limit, userId, keyWord);
    }
    return getPostByHashTag(start, limit, hashTag);
  }

  Future<RestResponse> logoutUser() async {
    SessionManager sessionManager = new SessionManager();
    await sessionManager.initPref();
    final response = await client.post(
      Uri.parse(UrlRes.logoutUser),
      body: {
        UrlRes.userId: SessionManager.userId.toString(),
      },
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      },
    );
    // print(response.body);
    final responseJson = jsonDecode(response.body);
    sessionManager.clean();
    return RestResponse.fromJson(responseJson);
  }

  Future<RestResponse> deleteAccount() async {
    SessionManager sessionManager = new SessionManager();
    await sessionManager.initPref();
    await FireBaseAuth1.FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();

    // print(SessionManager.accessToken);
    final response = await client.post(
      Uri.parse(UrlRes.deleteAccount),
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      },
    );

    // print(response.body);
    final responseJson = jsonDecode(response.body);
    sessionManager.clean();
    return RestResponse.fromJson(responseJson);
  }

  Future<RestResponse> deletePost(String postId) async {
    final response = await client.post(
      Uri.parse(UrlRes.deletePost),
      body: {
        UrlRes.postId: postId,
      },
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      },
    );

    // print(response.body);
    final responseJson = jsonDecode(response.body);
    return RestResponse.fromJson(responseJson);
  }

  Future<RestResponse> reportUserOrPost({
    required String reportType,
    String? postIdOrUserId,
    String? reason,
    required String description,
    required String contactInfo,
  }) async {
    final response = await client.post(
      Uri.parse(UrlRes.reportPostOrUser),
      body: {
        UrlRes.reportType: reportType,
        reportType == '1' ? UrlRes.userId : UrlRes.postId: postIdOrUserId,
        UrlRes.reason: reason,
        UrlRes.description: description,
        UrlRes.contactInfo: contactInfo,
      },
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      },
    );

    // print(response.body);
    final responseJson = jsonDecode(response.body);
    return RestResponse.fromJson(responseJson);
  }

  Future<RestResponse> blockUser(String? userId) async {
    final response = await client.post(
      Uri.parse(UrlRes.blockUser),
      body: {
        UrlRes.userId: userId,
      },
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      },
    );
    // print(response.body);
    return RestResponse.fromJson(jsonDecode(response.body));
  }

  Future<SinglePost> getPostByPostId(String postId) async {
    final response = await client.post(
      Uri.parse(UrlRes.getPostListById),
      body: {UrlRes.postId: postId},
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
      },
    );
    // print(' ${response.body}');
    return SinglePost.fromJson(jsonDecode(response.body));
  }

  Future<CoinPlans> getCoinPlanList() async {
    final response = await client.get(
      Uri.parse(UrlRes.getCoinPlanList),
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      },
    );

    // print(response.body);
    final responseJson = jsonDecode(response.body);
    return CoinPlans.fromJson(responseJson);
  }

  Future<CoinPlans> addCoin() async {
    final response = await client.post(
      Uri.parse(UrlRes.addCoin),
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      },
      body: {UrlRes.rewardingActionId: '3'},
    );

    // print(response.body);
    final responseJson = jsonDecode(response.body);
    await getProfile(SessionManager.userId.toString());
    return CoinPlans.fromJson(responseJson);
  }

  Future<RestResponse> purchaseCoin(int coin, {
    String? transactionReference, 
    double? amount, 
    String? paymentMethod,
    String? receiptData,
    String? purchaseTimestamp,
    String? coinPackId
  }) async {
    final body = {
      UrlRes.coin: '$coin',
    };
    
    if (transactionReference != null) {
      body['transaction_reference'] = transactionReference;
    }
    
    if (amount != null) {
      body['amount'] = '$amount';
    }
    
    if (paymentMethod != null) {
      body['payment_method'] = paymentMethod;
    }
    
    // Add receipt data for enhanced security verification
    if (receiptData != null) {
      body['receipt_data'] = receiptData;
    }
    
    // Add purchase timestamp for fraud detection
    if (purchaseTimestamp != null) {
      body['purchase_timestamp'] = purchaseTimestamp;
    }
    
    // Add coin pack ID for validation
    if (coinPackId != null) {
      body['coin_pack_id'] = coinPackId;
    }
    
    body['platform'] = Platform.isIOS ? 'ios' : 'android';
    
    final response = await client.post(
      Uri.parse(UrlRes.purchaseCoin),
      body: body,
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      },
    );
    final responseJson = jsonDecode(response.body);
    await getProfile(SessionManager.userId.toString());
    return RestResponse.fromJson(responseJson);
  }

  Future<RestResponse> increasePostViewCount(String postId) async {
     final response = await client.post(
      Uri.parse(UrlRes.increasePostViewCount),
      body: {UrlRes.postId: postId},
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      },
    );

    // Defensive: Only try to decode if response is JSON
    if (response.body.trim().startsWith('{') || response.body.trim().startsWith('[')) {
      final responseJson = jsonDecode(response.body);
      return RestResponse.fromJson(responseJson);
    } else {
      // Return a generic success response if the API returns HTML or other non-JSON content
      print('Non-JSON response received from increasePostViewCount API: \\${response.body.substring(0, math.min(100, response.body.length))}...');
      return RestResponse(status: 200, message: 'View count updated');
    }
  }

  static HttpClient getHttpClient() {
    HttpClient httpClient = new HttpClient()
      ..connectionTimeout = const Duration(seconds: 120)  // Increased from 10 to 120 seconds
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);

    return httpClient;
  }

  Future<FilePath> filePath({File? filePath}) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(UrlRes.fileGivenPath),
    );
    request.headers.addAll({
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken
    });
    if (filePath != null) {
      request.files.add(
        http.MultipartFile(
            'file', filePath.readAsBytes().asStream(), filePath.lengthSync(),
            filename: filePath.path.split("/").last),
      );
    }
    var response = await request.send();
    var respStr = await response.stream.bytesToString();
    final responseJson = jsonDecode(respStr);
    FilePath path = FilePath.fromJson(responseJson);
    return path;
  }

  Future pushNotification(
      {required String title,
      required String body,
      required String token,
      required Map<String, dynamic> data}) async {
    await http.post(
      Uri.parse(UrlRes.notificationUrl),
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
        'content-type': 'application/json'
      },
      body: json.encode({
        'message': {
          'notification': {
            'title': title,
            'body': body,
          },
          'token': token,
          'data': data
        },
      }),
    );
  }

  Future<Setting> fetchSettingsData() async {
    final response = await client.post(
      Uri.parse(UrlRes.fetchSettingsData),
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
      },
    );
    SessionManager sessionManager = SessionManager();
    await sessionManager.initPref();
    sessionManager.saveSetting(response.body);
    return Setting.fromJson(jsonDecode(response.body));
  }

  Future<AgoraToken> generateAgoraToken(String? channelName) async {
    final response =
        await client.post(Uri.parse(UrlRes.generateAgoraToken), headers: {
      UrlRes.authorization: SessionManager.accessToken,
      UrlRes.uniqueKey: ConstRes.apiKey,
    }, body: {
      UrlRes.channelName: channelName
    });
    // print(response.body);
    return AgoraToken.fromJson(jsonDecode(response.body));
  }

  Future<Agora> agoraListStreamingCheck(
      String channelName, String authToken, String agoraAppId) async {
    http.Response response = await http.get(
        Uri.parse('${UrlRes.agoraLiveStreamingCheck}$agoraAppId/$channelName'),
        headers: {UrlRes.authorization: 'Basic $authToken'});
    return Agora.fromJson(jsonDecode(response.body));
  }

  Future<Status> checkUsername({required String userName}) async {
    http.Response response =
        await http.post(Uri.parse(UrlRes.checkUsername), headers: {
      UrlRes.authorization: SessionManager.accessToken,
      UrlRes.uniqueKey: ConstRes.apiKey,
    }, body: {
      UrlRes.userName: userName
    });
    // print(response.body);
    return Status.fromJson(jsonDecode(response.body));
  }

  Future<NudityMediaId> checkVideoModerationApiMoreThenOneMinutes(
      {required File? file,
      required String apiUser,
      required String apiSecret}) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(UrlRes.checkVideoModerationMoreThenOneMinutes),
    );
    request.fields['models'] = nudityModels;
    request.fields['api_user'] = apiUser;
    request.fields['api_secret'] = apiSecret;

    print(request.fields);

    if (file != null) {
      request.files.add(
        http.MultipartFile(
          'media',
          file.readAsBytes().asStream(),
          file.lengthSync(),
          filename: file.path.split("/").last,
        ),
      );
    }

    var response = await request.send();
    var respStr = await response.stream.bytesToString();
    NudityMediaId nudityStatus = NudityMediaId.fromJson(jsonDecode(respStr));
    return nudityStatus;
  }

  Future<NudityChecker> getOnGoingVideoJob(
      {required String mediaId,
      required String apiUser,
      required String apiSecret}) async {
    http.Response response = await http.get(Uri.parse(
      'https://api.sightengine.com/1.0/video/byid.json?id=${mediaId}&api_user=${apiUser}&api_secret=${apiSecret}',
    )
        // 'https://api.sightengine.com/1.0/video/byid.json?id=med_fN29aqHUajuGaR9TPH8G9&api_user=1762220856&api_secret=ivYtsGAKF9dpoxRLe83aZLgiDaBYswkH'),
        );

    print('${mediaId} //// $apiUser //// $apiSecret');

    NudityChecker nudityChecker =
        NudityChecker.fromJson(jsonDecode(response.body));
    print(response.body);
    // print('Nudity Checker ${nudityChecker.toJson()}');
    return nudityChecker;
  }

  /// Upload contacts CSV file to server
  Future<bool> uploadContactsCsv(String csvFilePath) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(UrlRes.uploadContactsCsv),
      );
      
      request.headers.addAll({
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      });
      
      File csvFile = File(csvFilePath);
      
      request.files.add(
        http.MultipartFile(
          'contacts_csv',
          csvFile.readAsBytes().asStream(),
          csvFile.lengthSync(),
          filename: csvFile.path.split("/").last,
        ),
      );
      
      var response = await request.send();
      var respStr = await response.stream.bytesToString();
      
      print('Upload contacts CSV response: $respStr');
      
      // Handle various response formats
      try {
        final responseJson = jsonDecode(respStr);
        return responseJson['status'] == 200 || response.statusCode == 200;
      } catch (e) {
        // If not valid JSON, check status code
        return response.statusCode == 200;
      }
    } catch (e) {
      print('Error uploading contacts CSV: $e');
      return false;
    }
  }

  // Future<Map<String, String>> getHeaders() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String? token = prefs.getString('token');
  //   return {
  //     'Content-Type': 'application/json',
  //     'Authorization': 'Bearer $token',
  //   };
  // }

  Future<ShareableLink> generateShareableLink(String postId) async {
    try {
      print('Generating share link for post: $postId');
      
      var response = await client.post(
        Uri.parse('${ConstRes.baseUrl}Post/generate-share-link'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          UrlRes.uniqueKey: ConstRes.apiKey,
          UrlRes.authorization: SessionManager.accessToken,
        },
        body: {UrlRes.postId: postId},
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      var jsonResponse = json.decode(response.body);
      
      if (jsonResponse['status'] == 200 && jsonResponse['data'] != null) {
        return ShareableLink.fromJson(jsonResponse['data']);
      }
      
      throw Exception(jsonResponse['message'] ?? 'Failed to generate shareable link');
    } catch (e) {
      print('Share link generation error details: $e');
      throw Exception('Error generating shareable link: $e');
    }
  }

  Future<String?> downloadFile(String url, String fileName) async {
    try {
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        Directory? directory = await (Platform.isAndroid
            ? getExternalStorageDirectory()
            : getApplicationDocumentsDirectory());
        String filePath = '${directory!.path}/$fileName';
        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        log("✅File downloaded to: $filePath");
        return filePath;
      } else {
        log("🛑 Failed to download file.");
        return null;
      }
    } catch (e) {
      log("🛑 Download error: $e");
      return null;
    }
  }

  Future<AppVersionResponse> getAppVersion() async {
    try {
      print('⚡ Calling version check API: ${UrlRes.getVersion}');
      final response = await http.get(
        Uri.parse(UrlRes.getVersion),
        headers: {
          UrlRes.uniqueKey: ConstRes.apiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json, text/plain, */*',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept-Language': 'en-US,en;q=0.9',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'X-Requested-With': 'XMLHttpRequest',
          'X-App-Version': Platform.isAndroid ? 'android' : 'ios',
          'X-Device-Type': Platform.operatingSystem,
        },    
      );
      print('⚡ Version check API response status: ${response.statusCode}');
      print('⚡ Version check API response body: ${response.body}');
      
      if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid API key');
      }
      
      if (response.statusCode == 409) {
        print('⚡ Received 409 conflict response. Headers sent: ${response.request?.headers}');
        throw Exception('Server detected suspicious request pattern');
      }
      
      if (!response.body.startsWith('{')) {
        print('⚡ Invalid response format. Response body: ${response.body}');
        throw Exception('Invalid response format from server');
      }
      
      return AppVersionResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      print('⚡ Error fetching app version: $e');
      throw e;
    }
  }

  Future<TransactionHistory> getTransactionHistory({String? transactionType, int limit = 20, int offset = 0}) async {
    client = http.Client();
    final Map<String, String> body = {
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    
    if (transactionType != null) {
      body['transaction_type'] = transactionType;
    }
    
    final response = await client.post(
      Uri.parse(UrlRes.getTransactionHistory),
      body: body,
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      },
    );
    
    final responseJson = jsonDecode(response.body);
    return TransactionHistory.fromJson(responseJson);
  }

  // User level system methods
  Future<UserLevel> getUserLevel() async {
    client = http.Client();
    final response = await client.get(
      Uri.parse(UrlRes.getUserLevel),
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      },
    );
    
    final responseJson = jsonDecode(response.body);
    return UserLevel.fromJson(responseJson);
  }

  Future<RestResponse> updateUserLevelPoints(int points, String actionType) async {
    client = http.Client();
    final response = await client.post(
      Uri.parse(UrlRes.updateUserLevelPoints),
      body: {
        'points': points.toString(),
        'action_type': actionType,
        'user_id': SessionManager.userId.toString(),
      },
      headers: {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      },
    );
    
    final responseJson = jsonDecode(response.body);
    print("LEVEL API: Updated points: $points, action: $actionType, response: ${responseJson['status']}, message: ${responseJson['message']}");
    
    await getProfile(SessionManager.userId.toString());
    return RestResponse.fromJson(responseJson);
  }
}
