class AppVersionResponse {
  bool? status;
  String? message;
  AppVersionData? data;

  AppVersionResponse({this.status, this.message, this.data});

  AppVersionResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
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
    minimumVersion = json['minimum_version'];
    latestVersion = json['latest_version'];
    updateMessage = json['update_message'];
    forceUpdate = json['force_update'];
    playStoreUrl = json['play_store_url'];
    appStoreUrl = json['app_store_url'];
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