class Comment {
  int? _status;
  String? _message;
  List<CommentData>? _data;

  int? get status => _status;

  String? get message => _message;

  List<CommentData>? get data => _data;

  Comment({int? status, String? message, List<CommentData>? data}) {
    _status = status;
    _message = message;
    _data = data;
  }

  Comment.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    if (json["data"] != null) {
      _data = [];
      json["data"].forEach((v) {
        _data!.add(CommentData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    if (_data != null) {
      map["data"] = _data!.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class CommentData {
  int? _commentsId;
  String? _comment;
  String? _createdDate;
  int? _userId;
  String? _fullName;
  String? _userName;
  String? _userProfile;
  int? _isVerify;
  int? _parentId; // For nested replies
  int? _likesCount; // Number of likes on this comment
  bool? _isLiked; // Whether current user liked this comment
  bool? _isEdited; // Whether this comment has been edited
  List<CommentData>? _replies; // Nested replies
  List<Map<String, dynamic>>? _mentions; // List of mentioned users with their details
  
  int? get commentsId => _commentsId;
  String? get comment => _comment;
  String? get createdDate => _createdDate;
  int? get userId => _userId;
  String? get fullName => _fullName;
  String? get userName => _userName;
  String? get userProfile => _userProfile;
  int? get isVerify => _isVerify;
  int? get parentId => _parentId;
  int? get likesCount => _likesCount;
  bool? get isLiked => _isLiked;
  bool? get isEdited => _isEdited;
  List<CommentData>? get replies => _replies;
  List<Map<String, dynamic>>? get mentions => _mentions;

  // Method to toggle like status
  void toggleLike() {
    if (_isLiked == true) {
      _isLiked = false;
      if (_likesCount != null && _likesCount! > 0) _likesCount = _likesCount! - 1;
    } else {
      _isLiked = true;
      _likesCount = (_likesCount ?? 0) + 1;
    }
  }
  
  // Method to update comment text
  void updateComment(String newComment) {
    _comment = newComment;
    _isEdited = true;
  }
  
  // Method to add a reply
  void addReply(CommentData reply) {
    _replies ??= [];
    _replies!.add(reply);
  }

  CommentData({
      int? commentsId,
      String? comment,
      String? createdDate,
      int? userId,
      String? fullName,
      String? userName,
      String? userProfile,
      int? isVerify,
      int? parentId,
      int? likesCount,
      bool? isLiked,
      bool? isEdited,
      List<CommentData>? replies,
      List<Map<String, dynamic>>? mentions}) {
    _commentsId = commentsId;
    _comment = comment;
    _createdDate = createdDate;
    _userId = userId;
    _fullName = fullName;
    _userName = userName;
    _userProfile = userProfile;
    _isVerify = isVerify;
    _parentId = parentId;
    _likesCount = likesCount;
    _isLiked = isLiked;
    _isEdited = isEdited;
    _replies = replies;
    _mentions = mentions;
  }

  CommentData.fromJson(dynamic json) {
    _commentsId = json["comments_id"];
    _comment = json["comment"];
    _createdDate = json["created_date"];
    _userId = json["user_id"];
    _fullName = json["full_name"];
    _userName = json["user_name"];
    _userProfile = json["user_profile"];
    _isVerify = json["is_verify"];
    _parentId = json["parent_id"];
    _likesCount = json["likes_count"];
    _isLiked = json["is_liked"] == 1;
    _isEdited = json["is_edited"] == 1;
    _mentions = json["mentions"] != null ? List<Map<String, dynamic>>.from(json["mentions"]) : null;
    
    if (json["replies"] != null) {
      _replies = [];
      json["replies"].forEach((v) {
        _replies!.add(CommentData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["comments_id"] = _commentsId;
    map["comment"] = _comment;
    map["created_date"] = _createdDate;
    map["user_id"] = _userId;
    map["full_name"] = _fullName;
    map["user_name"] = _userName;
    map["user_profile"] = _userProfile;
    map["is_verify"] = _isVerify;
    map["parent_id"] = _parentId;
    map["likes_count"] = _likesCount;
    map["is_liked"] = _isLiked == true ? 1 : 0;
    map["is_edited"] = _isEdited == true ? 1 : 0;
    map["mentions"] = _mentions;
    
    if (_replies != null) {
      map["replies"] = _replies!.map((v) => v.toJson()).toList();
    }
    return map;
  }

  // Method to add a mention
  void addMention(Map<String, dynamic> mentionData) {
    _mentions ??= [];
    _mentions!.add(mentionData);
  }

  // Method to get mentioned usernames
  List<String> getMentionedUsernames() {
    return _mentions?.map((m) => m['userName'].toString()).toList() ?? [];
  }
}
