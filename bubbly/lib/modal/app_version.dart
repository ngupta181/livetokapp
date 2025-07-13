class AppVersionResponse {
  bool? status;
  String? message;
  AppVersionData? data;

  AppVersionResponse({this.status, this.message, this.data});

  AppVersionResponse.fromJson(Map<String, dynamic> json) {
    // Handle status field that can be int or bool
    if (json['status'] != null) {
      if (json['status'] is bool) {
        status = json['status'];
      } else if (json['status'] is int) {
        status = json['status'] == 200 || json['status'] == 1;
      } else if (json['status'] is String) {
        status = json['status'] == 'true' || json['status'] == '200';
      } else {
        // Default to false for unknown types
        status = false;
      }
    } else {
      status = false;
    }
    
    message = json['message']?.toString();
    data = json['data'] != null ? AppVersionData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class AppVersionData {
  String? minimumVersion;
  String? latestVersion;
  String? updateMessage;
  bool? forceUpdate;
  String? playStoreUrl;
  String? appStoreUrl;

  AppVersionData({
    this.minimumVersion,
    this.latestVersion,
    this.updateMessage,
    this.forceUpdate,
    this.playStoreUrl,
    this.appStoreUrl,
  });

  AppVersionData.fromJson(Map<String, dynamic> json) {
    minimumVersion = json['minimum_version']?.toString();
    latestVersion = json['latest_version']?.toString();
    updateMessage = json['update_message']?.toString();
    
    // Handle force_update field that can be bool, int, or string
    if (json['force_update'] != null) {
      if (json['force_update'] is bool) {
        forceUpdate = json['force_update'];
      } else if (json['force_update'] is int) {
        forceUpdate = json['force_update'] == 1;
      } else if (json['force_update'] is String) {
        forceUpdate = json['force_update'].toLowerCase() == 'true' || json['force_update'] == '1';
      } else {
        // Default to false for unknown types
        forceUpdate = false;
      }
    } else {
      forceUpdate = false;
    }
    
    playStoreUrl = json['play_store_url']?.toString();
    appStoreUrl = json['app_store_url']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['minimum_version'] = minimumVersion;
    data['latest_version'] = latestVersion;
    data['update_message'] = updateMessage;
    data['force_update'] = forceUpdate;
    data['play_store_url'] = playStoreUrl;
    data['app_store_url'] = appStoreUrl;
    return data;
  }
} 