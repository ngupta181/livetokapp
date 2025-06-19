class Setting {
  Setting({
    int? status,
    String? message,
    SettingData? data,
  }) {
    _status = status;
    _message = message;
    _data = data;
  }

  Setting.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _data = json['data'] != null ? SettingData.fromJson(json['data']) : null;
  }
  int? _status;
  String? _message;
  SettingData? _data;

  int? get status => _status;
  String? get message => _message;
  SettingData? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
}

class SettingData {
  SettingData({
    int? id,
    String? currency,
    double? coinValue,
    int? minRedeemCoins,
    int? minFansVerification,
    int? minFansForLive,
    int? rewardVideoUpload,
    String? admobBanner,
    String? admobInt,
    String? admobBannerIos,
    String? admobIntIos,
    String? admobNative,
    String? admobNativeIos,
    int? maxUploadDaily,
    int? liveMinViewers,
    int? liveTimeout,
    int? isCompress,
    String? helpMail,
    int? isContentModeration,
    String? sightEngineApiUser,
    String? sightEngineApiSecret,
    String? sightEngineWorkflowId,
    String? createdAt,
    String? updatedAt,
    String? agoraAppCert,
    String? agoraAppId,
    List<Gifts>? gifts,
    int? videosBetweenAds,
  }) {
    _id = id;
    _currency = currency;
    _coinValue = coinValue;
    _minRedeemCoins = minRedeemCoins;
    _minFansVerification = minFansVerification;
    _minFansForLive = minFansForLive;
    _rewardVideoUpload = rewardVideoUpload;
    _admobBanner = admobBanner;
    _admobInt = admobInt;
    _admobBannerIos = admobBannerIos;
    _admobIntIos = admobIntIos;
    _admobNative = admobNative;
    _admobNativeIos = admobNativeIos;
    _maxUploadDaily = maxUploadDaily;
    _liveMinViewers = liveMinViewers;
    _liveTimeout = liveTimeout;
    _isCompress = isCompress;
    _helpMail = helpMail;
    _isContentModeration = isContentModeration;
    _sightEngineApiUser = sightEngineApiUser;
    _sightEngineApiSecret = sightEngineApiSecret;
    _sightEngineWorkflowId = sightEngineWorkflowId;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _agoraAppCert = agoraAppCert;
    _agoraAppId = agoraAppId;
    _gifts = gifts;
    _videosBetweenAds = videosBetweenAds;
  }

  SettingData.fromJson(dynamic json) {
    _id = json['id'];
    _currency = json['currency'];
    try {
      if (json['coin_value'] != null) {
        if (json['coin_value'] is int) {
          _coinValue = double.parse("${json['coin_value']}");
        } else if (json['coin_value'] is String) {
          _coinValue = double.tryParse("${json['coin_value']}") ?? 0.001;
        } else {
          _coinValue =
              json['coin_value'] is double ? json['coin_value'] : 0.001;
        }
        _coinValue = _coinValue! < 0.001 ? 0.001 : _coinValue;
      } else {
        _coinValue = 0.001;
      }
    } catch (e) {
      print("Error parsing coin value: $e");
      _coinValue = 0.001;
    }

    _minRedeemCoins = json['min_redeem_coins'];
    _minFansVerification = json['min_fans_verification'];
    _minFansForLive = json['min_fans_for_live'];
    _rewardVideoUpload = json['reward_video_upload'];
    _admobBanner = json['admob_banner'];
    _admobInt = json['admob_int'];
    _admobBannerIos = json['admob_banner_ios'];
    _admobIntIos = json['admob_int_ios'];
    _admobNative = json['admob_native'];
    _admobNativeIos = json['admob_native_ios'];
    _maxUploadDaily = json['max_upload_daily'];
    _liveMinViewers = json['live_min_viewers'];
    _liveTimeout = json['live_timeout'];
    _isCompress = json['is_compress'];
    _helpMail = json['help_mail'];
    _isContentModeration = json['is_content_moderation'];
    _sightEngineApiUser = json['sight_engine_api_user'];
    _sightEngineApiSecret = json['sight_engine_api_secret'];
    _sightEngineWorkflowId = json['sight_engine_workflow_id'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _agoraAppCert = json['agora_app_cert'];
    _agoraAppId = json['agora_app_id'];
    _videosBetweenAds = json['videos_between_ads'] ?? 5;
    if (json['gifts'] != null) {
      _gifts = [];
      json['gifts'].forEach((v) {
        _gifts?.add(Gifts.fromJson(v));
      });
    }
  }
  int? _id;
  String? _currency;
  double? _coinValue;
  int? _minRedeemCoins;
  int? _minFansVerification;
  int? _minFansForLive;
  int? _rewardVideoUpload;
  String? _admobBanner;
  String? _admobInt;
  String? _admobBannerIos;
  String? _admobIntIos;
  String? _admobNative;
  String? _admobNativeIos;
  int? _maxUploadDaily;
  int? _liveMinViewers;
  int? _liveTimeout;
  int? _isCompress;
  String? _helpMail;
  int? _isContentModeration;
  String? _sightEngineApiUser;
  String? _sightEngineApiSecret;
  String? _sightEngineWorkflowId;
  String? _createdAt;
  String? _updatedAt;
  String? _agoraAppCert;
  String? _agoraAppId;
  List<Gifts>? _gifts;
  int? _videosBetweenAds;

  int? get id => _id;
  String? get currency => _currency;
  double? get coinValue => _coinValue;
  int? get minRedeemCoins => _minRedeemCoins;
  int? get minFansVerification => _minFansVerification;
  int? get minFansForLive => _minFansForLive;
  int? get rewardVideoUpload => _rewardVideoUpload;
  String? get admobBanner => _admobBanner;
  String? get admobInt => _admobInt;
  String? get admobBannerIos => _admobBannerIos;
  String? get admobIntIos => _admobIntIos;
  String? get admobNative => _admobNative;
  String? get admobNativeIos => _admobNativeIos;
  int? get maxUploadDaily => _maxUploadDaily;
  int? get liveMinViewers => _liveMinViewers;
  int? get liveTimeout => _liveTimeout;
  int? get isCompress => _isCompress;
  String? get helpMail => _helpMail;
  int? get isContentModeration => _isContentModeration;
  String? get sightEngineApiUser => _sightEngineApiUser;
  String? get sightEngineApiSecret => _sightEngineApiSecret;
  String? get sightEngineWorkflowId => _sightEngineWorkflowId;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;
  String? get agoraAppCert => _agoraAppCert;
  String? get agoraAppId => _agoraAppId;
  List<Gifts>? get gifts => _gifts;
  int? get videosBetweenAds => _videosBetweenAds;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['currency'] = _currency;
    map['coin_value'] = _coinValue;
    map['min_redeem_coins'] = _minRedeemCoins;
    map['min_fans_verification'] = _minFansVerification;
    map['min_fans_for_live'] = _minFansForLive;
    map['reward_video_upload'] = _rewardVideoUpload;
    map['admob_banner'] = _admobBanner;
    map['admob_int'] = _admobInt;
    map['admob_banner_ios'] = _admobBannerIos;
    map['admob_int_ios'] = _admobIntIos;
    map['admob_native'] = _admobNative;
    map['admob_native_ios'] = _admobNativeIos;
    map['max_upload_daily'] = _maxUploadDaily;
    map['live_min_viewers'] = _liveMinViewers;
    map['live_timeout'] = _liveTimeout;
    map['is_compress'] = _isCompress;
    map['help_mail'] = _helpMail;
    map['is_content_moderation'] = _isContentModeration;
    map['sight_engine_api_user'] = _sightEngineApiUser;
    map['sight_engine_api_secret'] = _sightEngineApiSecret;
    map['sight_engine_workflow_id'] = _sightEngineWorkflowId;
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    map['agora_app_cert'] = _agoraAppCert;
    map['agora_app_id'] = _agoraAppId;
    map['videos_between_ads'] = _videosBetweenAds;
    if (_gifts != null) {
      map['gifts'] = _gifts?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Gifts {
  Gifts({
    int? id,
    int? coinPrice,
    String? image,
    String? createdAt,
    String? updatedAt,
    String? animationStyle,
    String? giftSound,
  }) {
    _id = id;
    _coinPrice = coinPrice;
    _image = image;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _animationStyle = animationStyle;
    _giftSound = giftSound;
  }

  Gifts.fromJson(dynamic json) {
    _id = json['id'];
    _coinPrice = json['coin_price'];
    _image = json['image'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _animationStyle = json['animation_style'];
    _giftSound = json['gift_sound'];
  }
  int? _id;
  int? _coinPrice;
  String? _image;
  String? _createdAt;
  String? _updatedAt;
  String? _animationStyle;
  String? _giftSound;
  int? get id => _id;
  int? get coinPrice => _coinPrice;
  String? get image => _image;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;
  String? get animationStyle => _animationStyle;
  String? get giftSound => _giftSound;
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['coin_price'] = _coinPrice;
    map['image'] = _image;
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    map['animation_style'] = _animationStyle;
    map['gift_sound'] = _giftSound;
    return map;
  }
}
