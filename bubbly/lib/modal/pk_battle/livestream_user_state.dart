import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubbly/modal/pk_battle/battle_type.dart';
import 'package:bubbly/modal/user/user.dart';

class LivestreamUserState {
  bool isMuted;
  bool isVideoOn;
  LivestreamUserType type;
  int userId;
  int liveCoin;
  int currentBattleCoin;
  int totalBattleCoin;
  List<int> followersGained;
  int joinStreamTime;
  UserData? user;

  LivestreamUserState({
    this.isMuted = false,
    this.isVideoOn = true,
    this.type = LivestreamUserType.audience,
    required this.userId,
    this.liveCoin = 0,
    this.currentBattleCoin = 0,
    this.totalBattleCoin = 0,
    this.followersGained = const [],
    int? joinStreamTime,
    this.user,
  }) : joinStreamTime = joinStreamTime ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() {
    return {
      'isMuted': isMuted,
      'isVideoOn': isVideoOn,
      'type': type.value,
      'userId': userId,
      'liveCoin': liveCoin,
      'currentBattleCoin': currentBattleCoin,
      'totalBattleCoin': totalBattleCoin,
      'followersGained': followersGained,
      'joinStreamTime': joinStreamTime,
      'user': user?.toJson(),
    };
  }

  factory LivestreamUserState.fromJson(Map<String, dynamic> json) {
    return LivestreamUserState(
      isMuted: json['isMuted'] ?? false,
      isVideoOn: json['isVideoOn'] ?? true,
      type: json['type'] != null ? LivestreamUserTypeExtension.fromString(json['type']) : LivestreamUserType.audience,
      userId: json['userId'],
      liveCoin: json['liveCoin'] ?? 0,
      currentBattleCoin: json['currentBattleCoin'] ?? 0,
      totalBattleCoin: json['totalBattleCoin'] ?? 0,
      followersGained: json['followersGained'] != null ? List<int>.from(json['followersGained']) : [],
      joinStreamTime: json['joinStreamTime'] ?? DateTime.now().millisecondsSinceEpoch,
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toFireStore() {
    return {
      'isMuted': isMuted,
      'isVideoOn': isVideoOn,
      'type': type.value,
      'userId': userId,
      'liveCoin': liveCoin,
      'currentBattleCoin': currentBattleCoin,
      'totalBattleCoin': totalBattleCoin,
      'followersGained': followersGained,
      'joinStreamTime': joinStreamTime,
    };
  }

  factory LivestreamUserState.fromFireStore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return LivestreamUserState(
      isMuted: data?['isMuted'] ?? false,
      isVideoOn: data?['isVideoOn'] ?? true,
      type: data?['type'] != null ? LivestreamUserTypeExtension.fromString(data!['type']) : LivestreamUserType.audience,
      userId: data?['userId'],
      liveCoin: data?['liveCoin'] ?? 0,
      currentBattleCoin: data?['currentBattleCoin'] ?? 0,
      totalBattleCoin: data?['totalBattleCoin'] ?? 0,
      followersGained: data?['followersGained'] != null ? List<int>.from(data!['followersGained']) : [],
      joinStreamTime: data?['joinStreamTime'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  // Helper methods
  int get totalCoin => totalBattleCoin + liveCoin;

  bool get isHost => type == LivestreamUserType.host;
  bool get isCoHost => type == LivestreamUserType.co_host;
  bool get isAudience => type == LivestreamUserType.audience;
  bool get isParticipant => isHost || isCoHost;

  // Create a copy with updated values
  LivestreamUserState copyWith({
    bool? isMuted,
    bool? isVideoOn,
    LivestreamUserType? type,
    int? userId,
    int? liveCoin,
    int? currentBattleCoin,
    int? totalBattleCoin,
    List<int>? followersGained,
    int? joinStreamTime,
    UserData? user,
  }) {
    return LivestreamUserState(
      isMuted: isMuted ?? this.isMuted,
      isVideoOn: isVideoOn ?? this.isVideoOn,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      liveCoin: liveCoin ?? this.liveCoin,
      currentBattleCoin: currentBattleCoin ?? this.currentBattleCoin,
      totalBattleCoin: totalBattleCoin ?? this.totalBattleCoin,
      followersGained: followersGained ?? this.followersGained,
      joinStreamTime: joinStreamTime ?? this.joinStreamTime,
      user: user ?? this.user,
    );
  }

  // Add coins to battle score
  void addBattleCoins(int coins) {
    currentBattleCoin += coins;
    totalBattleCoin += coins;
  }

  // Add coins to live stream score
  void addLiveCoins(int coins) {
    liveCoin += coins;
  }

  // Reset battle coins (for new battle)
  void resetBattleCoins() {
    currentBattleCoin = 0;
  }
}

