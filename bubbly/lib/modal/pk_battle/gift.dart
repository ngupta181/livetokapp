import 'package:bubbly/modal/pk_battle/battle_type.dart';
import 'package:bubbly/modal/user/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum GiftType {
  none,
  battle,
  normal,
  livestream,
}

extension GiftTypeExtension on GiftType {
  String get value {
    switch (this) {
      case GiftType.none:
        return 'none';
      case GiftType.battle:
        return 'battle';
      case GiftType.normal:
        return 'normal';
      case GiftType.livestream:
        return 'livestream';
    }
  }
}

class Gift {
  int? id;
  String? name;
  String? image;
  int? coinPrice;
  String? category;
  bool? isActive;
  int? createdAt;
  int? updatedAt;

  Gift({
    this.id,
    this.name,
    this.image,
    this.coinPrice,
    this.category,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'coinPrice': coinPrice,
      'category': category,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Gift.fromJson(Map<String, dynamic> json) {
    return Gift(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      coinPrice: json['coinPrice'],
      category: json['category'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toFireStore() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'coinPrice': coinPrice,
      'category': category,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Gift.fromFireStore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Gift(
      id: data?['id'],
      name: data?['name'],
      image: data?['image'],
      coinPrice: data?['coinPrice'],
      category: data?['category'],
      isActive: data?['isActive'] ?? true,
      createdAt: data?['createdAt'],
      updatedAt: data?['updatedAt'],
    );
  }
}

class GiftManager {
  Gift gift;
  UserData? streamUser;

  GiftManager({
    required this.gift,
    this.streamUser,
  });

  static Future<void> openGiftSheet({
    GiftType giftType = GiftType.none,
    BattleView battleViewType = BattleView.red,
    List<UserData> streamUsers = const [],
    required Function(GiftManager) onCompletion,
  }) async {
    // This will be implemented in the UI layer
    // For now, this is a placeholder for the gift sheet opening logic
  }
}

