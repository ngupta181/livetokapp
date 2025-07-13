import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/modal/app_version.dart';

class VersionCheckService {
  static AppVersionData? _versionData;
  
  static Future<bool> checkForUpdate() async {
    try {
      // Get current app version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      print('⚡ Current app version: $currentVersion');
      
      // Get minimum version from backend
      try {
        final response = await ApiService().getAppVersion();
        print('⚡ API response received successfully');
        _versionData = response.data;
      } catch (e) {
        print('⚡ API error: $e');
        if (e.toString().contains('Unauthorized')) {
          // Handle unauthorized error - you might want to redirect to login
          print('⚡ User needs to login again');
          return false;
        }
        // For other errors, continue without forcing update
        print('⚡ Continuing without version check due to API error');
        return false;
      }
      
      if (_versionData == null) {
        print('⚡ No version data received from API');
        return false;
      }
      
      // Validate required fields
      if (_versionData!.minimumVersion == null || _versionData!.minimumVersion!.isEmpty) {
        print('⚡ Error: minimum_version is null or empty');
        return false;
      }
      
      if (_versionData!.latestVersion == null || _versionData!.latestVersion!.isEmpty) {
        print('⚡ Error: latest_version is null or empty');
        return false;
      }
      
      print('⚡ Minimum required version: ${_versionData!.minimumVersion}');
      print('⚡ Latest version available: ${_versionData!.latestVersion}');
      print('⚡ Force update required: ${_versionData!.forceUpdate}');
      
      // If force update is true, compare with latest version instead of minimum
      String versionToCompare = _versionData!.forceUpdate == true 
          ? _versionData!.latestVersion!
          : _versionData!.minimumVersion!;
          
      print('⚡ Comparing current version with: $versionToCompare (using ${_versionData!.forceUpdate == true ? "latest" : "minimum"} version)');
      
      // Compare versions
      try {
        List<int> currentParts = currentVersion.split('.').map(int.parse).toList();
        List<int> requiredParts = versionToCompare.split('.').map(int.parse).toList();
        
        // Ensure both version arrays have at least 3 parts
        while (currentParts.length < 3) currentParts.add(0);
        while (requiredParts.length < 3) requiredParts.add(0);
        
        print('⚡ Current version parts: $currentParts');
        print('⚡ Required version parts: $requiredParts');
        
        for (int i = 0; i < 3; i++) {
          if (currentParts[i] < requiredParts[i]) {
            print('⚡ Update required: Current version ($currentVersion) is lower than required ($versionToCompare)');
            return true; // Update required
          } else if (currentParts[i] > requiredParts[i]) {
            print('⚡ No update required: Current version ($currentVersion) is higher than required ($versionToCompare)');
            return false; // No update required
          }
        }
        
        // If force_update is true and versions are equal, still require update
        if (_versionData!.forceUpdate == true && currentVersion == versionToCompare) {
          print('⚡ Update required: Force update is enabled and newer version is available');
          return true;
        }
        
        print('⚡ No update required: Current version ($currentVersion) equals required ($versionToCompare)');
        return false; // Versions are equal, no update required
      } catch (e) {
        print('⚡ Error parsing version numbers: $e');
        print('⚡ Current version string: "$currentVersion"');
        print('⚡ Required version string: "$versionToCompare"');
        return false;
      }
    } catch (e) {
      print('⚡ Error checking for updates: $e');
      return false;
    }
  }

  static Future<void> openStore() async {
    if (_versionData == null) return;
    
    String storeUrl = Platform.isAndroid 
        ? _versionData!.playStoreUrl ?? ''
        : _versionData!.appStoreUrl ?? '';
        
    if (storeUrl.isEmpty) return;
    
    if (!await launchUrl(Uri.parse(storeUrl), mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch store');
    }
  }
  
  static String? get updateMessage => _versionData?.updateMessage;
  static bool get forceUpdate => _versionData?.forceUpdate ?? false;
} 