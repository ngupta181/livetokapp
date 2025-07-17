import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubbly/modal/user/user.dart';

enum LivestreamCommentType {
  normal,
  gift,
  system,
}

extension LivestreamCommentTypeExtension on LivestreamCommentType {
  String get value {
    switch (this) {
      case LivestreamCommentType.normal:
        return 'normal';
      case LivestreamCommentType.gift:
        return 'gift';
      case LivestreamCommentType.system:
        return 'system';
    }
  }

  static LivestreamCommentType fromString(String value) {
    switch (value) {
      case 'normal':
        return LivestreamCommentType.normal;
      case 'gift':
        return LivestreamCommentType.gift;
      case 'system':
        return LivestreamCommentType.system;
      default:
        return LivestreamCommentType.normal;
    }
  }
}

class LivestreamComment {
  String? id;
  String? comment;
  LivestreamCommentType type;
  int? giftId;
  String? receiverId;
  String senderId;
  UserData? sender;
  UserData? receiver;
  int createdAt;
  String? roomId;

  LivestreamComment({
    this.id,
    this.comment,
    this.type = LivestreamCommentType.normal,
    this.giftId,
    this.receiverId,
    required this.senderId,
    this.sender,
    this.receiver,
    int? createdAt,
    this.roomId,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'comment': comment,
      'type': type.value,
      'giftId': giftId,
      'receiverId': receiverId,
      'senderId': senderId,
      'sender': sender?.toJson(),
      'receiver': receiver?.toJson(),
      'createdAt': createdAt,
      'roomId': roomId,
    };
  }

  factory LivestreamComment.fromJson(Map<String, dynamic> json) {
    return LivestreamComment(
      id: json['id'],
      comment: json['comment'],
      type: json['type'] != null ? LivestreamCommentTypeExtension.fromString(json['type']) : LivestreamCommentType.normal,
      giftId: json['giftId'],
      receiverId: json['receiverId'],
      senderId: json['senderId'],
      sender: json['sender'] != null ? UserData.fromJson(json['sender']) : null,
      receiver: json['receiver'] != null ? UserData.fromJson(json['receiver']) : null,
      createdAt: json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      roomId: json['roomId'],
    );
  }

  Map<String, dynamic> toFireStore() {
    return {
      'comment': comment,
      'type': type.value,
      'giftId': giftId,
      'receiverId': receiverId,
      'senderId': senderId,
      'createdAt': createdAt,
      'roomId': roomId,
    };
  }

  factory LivestreamComment.fromFireStore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return LivestreamComment(
      id: snapshot.id,
      comment: data?['comment'],
      type: data?['type'] != null ? LivestreamCommentTypeExtension.fromString(data!['type']) : LivestreamCommentType.normal,
      giftId: data?['giftId'],
      receiverId: data?['receiverId'],
      senderId: data?['senderId'],
      createdAt: data?['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      roomId: data?['roomId'],
    );
  }

  bool get isGift => type == LivestreamCommentType.gift;
  bool get isNormal => type == LivestreamCommentType.normal;
  bool get isSystem => type == LivestreamCommentType.system;
}


