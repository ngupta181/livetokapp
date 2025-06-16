class ExploreHashTag {
  int? _status;
  String? _message;
  List<ExploreData>? _data;

  int? get status => _status;

  String? get message => _message;

  List<ExploreData>? get data => _data;

  ExploreHashTag({int? status, String? message, List<ExploreData>? data}) {
    _status = status;
    _message = message;
    _data = data;
  }

  ExploreHashTag.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    if (json["data"] != null) {
      _data = [];
      json["data"].forEach((v) {
        _data!.add(ExploreData.fromJson(v));
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

class ExploreData {
  String? _hashTagName;
  String? _hashTagProfile;
  int? _hashTagVideosCount;
  List<VideoData>? _recentVideos;

  String? get hashTagName => _hashTagName;

  String? get hashTagProfile => _hashTagProfile;

  int? get hashTagVideosCount => _hashTagVideosCount;

  List<VideoData>? get recentVideos => _recentVideos;

  ExploreData({
    String? hashTagName, 
    String? hashTagProfile, 
    int? hashTagVideosCount,
    List<VideoData>? recentVideos,
  }) {
    _hashTagName = hashTagName;
    _hashTagProfile = hashTagProfile;
    _hashTagVideosCount = hashTagVideosCount;
    _recentVideos = recentVideos;
  }

  ExploreData.fromJson(dynamic json) {
    _hashTagName = json["hash_tag_name"];
    _hashTagProfile = json["hash_tag_profile"];
    _hashTagVideosCount = json["hash_tag_videos_count"];
    if (json["recent_videos"] != null) {
      _recentVideos = [];
      json["recent_videos"].forEach((v) {
        _recentVideos!.add(VideoData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["hash_tag_name"] = _hashTagName;
    map["hash_tag_profile"] = _hashTagProfile;
    map["hash_tag_videos_count"] = _hashTagVideosCount;
    if (_recentVideos != null) {
      map["recent_videos"] = _recentVideos!.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class VideoData {
  String? _id;
  String? _thumbnail;
  String? _video;

  String? get id => _id;
  String? get thumbnail => _thumbnail;
  String? get video => _video;

  VideoData({
    String? id,
    String? thumbnail,
    String? video,
  }) {
    _id = id;
    _thumbnail = thumbnail;
    _video = video;
  }

  VideoData.fromJson(dynamic json) {
    _id = json["id"];
    _thumbnail = json["thumbnail"];
    _video = json["video"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["id"] = _id;
    map["thumbnail"] = _thumbnail;
    map["video"] = _video;
    return map;
  }
}
