import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubbly/modal/pk_battle/livestream_type.dart';
import 'package:bubbly/modal/pk_battle/battle_type.dart';
import 'package:bubbly/modal/user/user.dart';

class Livestream {
  int? watchingCount;
  LivestreamType? type;
  BattleType? battleType;
  int battleDuration;
  int? battleCreatedAt;
  int? battleStartedAt;
  String? roomID;
  String? hostId;
  List<String>? coHostIds;
  String? title;
  String? description;
  bool? isActive;
  int? createdAt;
  int? endedAt;

  Livestream({
    this.watchingCount,
    this.type = LivestreamType.livestream,
    this.battleType = BattleType.initiate,
    this.battleDuration = 1,
    this.battleCreatedAt,
    this.battleStartedAt,
    this.roomID,
    this.hostId,
    this.coHostIds,
    this.title,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.endedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'watchingCount': watchingCount,
      'type': type?.value,
      'battleType': battleType?.value,
      'battleDuration': battleDuration,
      'battleCreatedAt': battleCreatedAt,
      'battleStartedAt': battleStartedAt,
      'roomID': roomID,
      'hostId': hostId,
      'coHostIds': coHostIds,
      'title': title,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt,
      'endedAt': endedAt,
    };
  }

  factory Livestream.fromJson(Map<String, dynamic> json) {
    return Livestream(
      watchingCount: json['watchingCount'],
      type: json['type'] != null ? LivestreamTypeExtension.fromString(json['type']) : LivestreamType.livestream,
      battleType: json['battleType'] != null ? BattleTypeExtension.fromString(json['battleType']) : BattleType.initiate,
      battleDuration: json['battleDuration'] ?? 1,
      battleCreatedAt: json['battleCreatedAt'],
      battleStartedAt: json['battleStartedAt'],
      roomID: json['roomID'],
      hostId: json['hostId'],
      coHostIds: json['coHostIds'] != null ? List<String>.from(json['coHostIds']) : null,
      title: json['title'],
      description: json['description'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'],
      endedAt: json['endedAt'],
    );
  }

  Map<String, dynamic> toFireStore() {
    return {
      'watchingCount': watchingCount,
      'type': type?.value,
      'battleType': battleType?.value,
      'battleDuration': battleDuration,
      'battleCreatedAt': battleCreatedAt,
      'battleStartedAt': battleStartedAt,
      'roomID': roomID,
      'hostId': hostId,
      'coHostIds': coHostIds,
      'title': title,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt,
      'endedAt': endedAt,
    };
  }

  factory Livestream.fromFireStore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Livestream(
      watchingCount: data?['watchingCount'],
      type: data?['type'] != null ? LivestreamTypeExtension.fromString(data!['type']) : LivestreamType.livestream,
      battleType: data?['battleType'] != null ? BattleTypeExtension.fromString(data!['battleType']) : BattleType.initiate,
      battleDuration: data?['battleDuration'] ?? 1,
      battleCreatedAt: data?['battleCreatedAt'],
      battleStartedAt: data?['battleStartedAt'],
      roomID: data?['roomID'],
      hostId: data?['hostId'],
      coHostIds: data?['coHostIds'] != null ? List<String>.from(data!['coHostIds']) : null,
      title: data?['title'],
      description: data?['description'],
      isActive: data?['isActive'] ?? true,
      createdAt: data?['createdAt'],
      endedAt: data?['endedAt'],
    );
  }

  // Helper methods
  List<UserData> getAllUsers(List<UserData> users) {
    List<String> allUserIds = [];
    if (hostId != null) allUserIds.add(hostId!);
    if (coHostIds != null) allUserIds.addAll(coHostIds!); 
    
    return users.where((user) => allUserIds.contains(user.userId)).toList();
  }

  UserData? getHost(List<UserData> users) {
    if (hostId == null) return null;
    try {
      return users.firstWhere((user) => user.userId == hostId);
    } catch (e) {
      return null;
    }
  }

  List<UserData> getCoHosts(List<UserData> users) {
    if (coHostIds == null || coHostIds!.isEmpty) return [];
    return users.where((user) => coHostIds!.contains(user.userId)).toList();
  }

  bool get isBattleMode => type == LivestreamType.battle || type == LivestreamType.pk_battle;
  bool get isBattleActive => battleType == BattleType.running || battleType == BattleType.waiting;
  bool get isBattleWaiting => battleType == BattleType.waiting;
  bool get isBattleRunning => battleType == BattleType.running;
  bool get isBattleEnded => battleType == BattleType.end;
}


