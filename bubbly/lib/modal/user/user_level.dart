class UserLevel {
  UserLevel({
    int? status,
    String? message,
    UserLevelData? data,
  }) {
    _status = status;
    _message = message;
    _data = data;
  }

  UserLevel.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _data = json['data'] != null ? UserLevelData.fromJson(json['data']) : null;
  }
  int? _status;
  String? _message;
  UserLevelData? _data;

  int? get status => _status;
  String? get message => _message;
  UserLevelData? get data => _data;

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

class UserLevelData {
  UserLevelData({
    int? currentLevel,
    int? nextLevel,
    int? currentPoints,
    int? pointsToNextLevel,
    String? levelBadge,
    String? avatarFrame,
    bool? hasEntryEffect,
    String? entryEffectUrl,
    int? totalPointsEarned,
  }) {
    _currentLevel = currentLevel;
    _nextLevel = nextLevel;
    _currentPoints = currentPoints;
    _pointsToNextLevel = pointsToNextLevel;
    _levelBadge = levelBadge;
    _avatarFrame = avatarFrame;
    _hasEntryEffect = hasEntryEffect;
    _entryEffectUrl = entryEffectUrl;
    _totalPointsEarned = totalPointsEarned;
  }

  UserLevelData.fromJson(dynamic json) {
    _currentLevel = json['current_level'];
    _nextLevel = json['next_level'];
    _currentPoints = json['current_points'];
    _pointsToNextLevel = json['points_to_next_level'];
    _levelBadge = json['level_badge'];
    _avatarFrame = json['avatar_frame'];
    _hasEntryEffect = json['has_entry_effect'];
    _entryEffectUrl = json['entry_effect_url'];
    _totalPointsEarned = json['total_points_earned'];
  }

  int? _currentLevel;
  int? _nextLevel;
  int? _currentPoints;
  int? _pointsToNextLevel;
  String? _levelBadge;
  String? _avatarFrame;
  bool? _hasEntryEffect;
  String? _entryEffectUrl;
  int? _totalPointsEarned;

  int? get currentLevel => _currentLevel;
  int? get nextLevel => _nextLevel;
  int? get currentPoints => _currentPoints;
  int? get pointsToNextLevel => _pointsToNextLevel;
  String? get levelBadge => _levelBadge;
  String? get avatarFrame => _avatarFrame;
  bool? get hasEntryEffect => _hasEntryEffect;
  String? get entryEffectUrl => _entryEffectUrl;
  int? get totalPointsEarned => _totalPointsEarned;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['current_level'] = _currentLevel;
    map['next_level'] = _nextLevel;
    map['current_points'] = _currentPoints;
    map['points_to_next_level'] = _pointsToNextLevel;
    map['level_badge'] = _levelBadge;
    map['avatar_frame'] = _avatarFrame;
    map['has_entry_effect'] = _hasEntryEffect;
    map['entry_effect_url'] = _entryEffectUrl;
    map['total_points_earned'] = _totalPointsEarned;
    return map;
  }
} 