class RestResponse {
  int? _status;
  String? _message;
  String? _errorCode;
  dynamic _data;

  int? get status => _status;
  String? get message => _message;
  String? get errorCode => _errorCode;
  dynamic get data => _data;

  RestResponse({int? status, String? message, String? errorCode, dynamic data}) {
    _status = status;
    _message = message;
    _errorCode = errorCode;
    _data = data;
  }

  RestResponse.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    _errorCode = json["error_code"];
    _data = json["data"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    if (_errorCode != null) {
      map["error_code"] = _errorCode;
    }
    if (_data != null) {
      map["data"] = _data;
    }
    return map;
  }

  // Helper methods for security error handling
  bool get isSuccess => _status == 200;
  bool get isSecurityError => _errorCode?.contains('SECURITY') == true;
  bool get isRateLimited => _errorCode == 'RATE_LIMIT_EXCEEDED';
  bool get isBlocked => _errorCode == 'USER_BLOCKED' || _errorCode == 'IP_BLOCKED';
  bool get isPaymentError => _errorCode?.contains('PAYMENT') == true;
}
