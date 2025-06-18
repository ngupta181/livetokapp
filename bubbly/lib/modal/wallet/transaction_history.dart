import 'package:bubbly/modal/user/user.dart';

class TransactionHistory {
  int? _status;
  String? _message;
  int? _total;
  List<Transaction>? _data;

  int? get status => _status;
  String? get message => _message;
  int? get total => _total;
  List<Transaction>? get data => _data;

  TransactionHistory({int? status, String? message, int? total, List<Transaction>? data}) {
    _status = status;
    _message = message;
    _total = total;
    _data = data;
  }

  TransactionHistory.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    _total = json["total"];
    if (json["data"] != null) {
      _data = [];
      json["data"].forEach((v) {
        _data!.add(Transaction.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    map["total"] = _total;
    if (_data != null) {
      map["data"] = _data?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Transaction {
  int? _transactionId;
  int? _userId;
  int? _toUserId;
  String? _transactionType;
  int? _coins;
  double? _amount;
  String? _paymentMethod;
  String? _transactionReference;
  String? _platform;
  String? _giftId;
  String? _status;
  String? _metaData;
  String? _createdAt;
  String? _updatedAt;
  UserData? _user;
  UserData? _recipient;

  int? get transactionId => _transactionId;
  int? get userId => _userId;
  int? get toUserId => _toUserId;
  String? get transactionType => _transactionType;
  int? get coins => _coins;
  double? get amount => _amount;
  String? get paymentMethod => _paymentMethod;
  String? get transactionReference => _transactionReference;
  String? get platform => _platform;
  String? get giftId => _giftId;
  String? get status => _status;
  String? get metaData => _metaData;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;
  UserData? get user => _user;
  UserData? get recipient => _recipient;

  Transaction({
    int? transactionId,
    int? userId,
    int? toUserId,
    String? transactionType,
    int? coins,
    double? amount,
    String? paymentMethod,
    String? transactionReference,
    String? platform,
    String? giftId,
    String? status,
    String? metaData,
    String? createdAt,
    String? updatedAt,
    UserData? user,
    UserData? recipient,
  }) {
    _transactionId = transactionId;
    _userId = userId;
    _toUserId = toUserId;
    _transactionType = transactionType;
    _coins = coins;
    _amount = amount;
    _paymentMethod = paymentMethod;
    _transactionReference = transactionReference;
    _platform = platform;
    _giftId = giftId;
    _status = status;
    _metaData = metaData;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _user = user;
    _recipient = recipient;
  }

  Transaction.fromJson(dynamic json) {
    _transactionId = json["transaction_id"];
    _userId = json["user_id"];
    _toUserId = json["to_user_id"];
    _transactionType = json["transaction_type"];
    _coins = json["coins"];
    _amount = json["amount"] == null ? null : double.tryParse(json["amount"].toString());
    _paymentMethod = json["payment_method"];
    _transactionReference = json["transaction_reference"];
    _platform = json["platform"];
    _giftId = json["gift_id"];
    _status = json["status"];
    _metaData = json["meta_data"];
    _createdAt = json["created_at"];
    _updatedAt = json["updated_at"];
    _user = json["user"] != null ? UserData.fromJson(json["user"]) : null;
    _recipient = json["recipient"] != null ? UserData.fromJson(json["recipient"]) : null;
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["transaction_id"] = _transactionId;
    map["user_id"] = _userId;
    map["to_user_id"] = _toUserId;
    map["transaction_type"] = _transactionType;
    map["coins"] = _coins;
    map["amount"] = _amount;
    map["payment_method"] = _paymentMethod;
    map["transaction_reference"] = _transactionReference;
    map["platform"] = _platform;
    map["gift_id"] = _giftId;
    map["status"] = _status;
    map["meta_data"] = _metaData;
    map["created_at"] = _createdAt;
    map["updated_at"] = _updatedAt;
    if (_user != null) {
      map["user"] = _user?.toJson();
    }
    if (_recipient != null) {
      map["recipient"] = _recipient?.toJson();
    }
    return map;
  }
} 