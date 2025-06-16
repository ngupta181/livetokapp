import 'dart:async';
import 'dart:io';

import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/main.dart';
import 'package:bubbly/modal/user_video/user_video.dart';
import 'package:bubbly/service/contacts_service.dart';
import 'package:bubbly/utils/assert_image.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/key_res.dart';
import 'package:bubbly/utils/my_loading/my_loading.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:bubbly/utils/url_res.dart';
import 'package:bubbly/view/camera/camera_screen.dart';
import 'package:bubbly/view/explore/explore_screen.dart';
import 'package:bubbly/view/home/home_screen.dart';
import 'package:bubbly/view/login/login_sheet.dart';
import 'package:bubbly/view/main/widget/end_user_license_agreement.dart';
import 'package:bubbly/view/notification/notifiation_screen.dart';
import 'package:bubbly/view/profile/profile_screen.dart';
import 'package:bubbly/view/video/video_list_screen.dart';
import 'package:bubbly_camera/bubbly_camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<Widget> mListOfWidget = [
    HomeScreen(),
    ExploreScreen(),
    NotificationScreen(),
    ProfileScreen(
      type: 0,
      userId: SessionManager.userId.toString(),
    ),
  ];

  SessionManager _sessionManager = SessionManager();
  bool isLogin = false;

  @override
  void initState() {
    super.initState();
    initPref();
    _requestContactsPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Consumer<MyLoading>(
        builder: (context, myLoading, child) {
          return BottomNavigationBar(
            backgroundColor:
                myLoading.isDark ? ColorRes.colorPrimaryDark : ColorRes.white,
            selectedItemColor: ColorRes.colorIcon,
            unselectedItemColor: ColorRes.colorTextLight,
            type: BottomNavigationBarType.fixed,
            onTap: (value) async {
              myLoading.setSelectedItem(value);
              isLogin = sessionManager.getBool(KeyRes.login) ?? false;
              if (value >= 2 && SessionManager.userId == -1 || !isLogin) {
                showModalBottomSheet(
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20))),
                  isScrollControlled: true,
                  context: context,
                  builder: (context) {
                    return LoginSheet();
                  },
                ).then((value) {
                  myLoading.setSelectedItem(0);
                });
              } else {
                if (value == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraScreen(),
                    ),
                  ).then((value) async {
                    _afterCameraScreenOff();
                  });
                }
              }
            },
            selectedLabelStyle: TextStyle(
                fontFamily: FontRes.fNSfUiLight,
                color: ColorRes.colorIcon,
                height: 1.5,
                fontSize: 11),
            unselectedLabelStyle: TextStyle(
                fontFamily: FontRes.fNSfUiLight, height: 1.5, fontSize: 11),
            showUnselectedLabels: true,
            showSelectedLabels: true,
            currentIndex: myLoading.getSelectedItem,
            items: [
              BottomNavigationBarItem(
                  icon: Image(
                      height: 22,
                      width: 22,
                      image: AssetImage(icHome),
                      color: myLoading.getSelectedItem == 0
                          ? ColorRes.colorIcon
                          : ColorRes.colorTextLight),
                  label: LKey.home.tr),
              BottomNavigationBarItem(
                  icon: Image(
                      height: 22,
                      width: 22,
                      image: AssetImage(icExplore),
                      color: myLoading.getSelectedItem == 1
                          ? ColorRes.colorIcon
                          : ColorRes.colorTextLight),
                  label: LKey.explore.tr),
              BottomNavigationBarItem(
                  icon: Container(
                    height: 25,
                    width: 25,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [ColorRes.colorTheme, ColorRes.colorPink]),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_rounded,
                        color: ColorRes.white, size: 25),
                  ),
                  label: LKey.create.tr),
              BottomNavigationBarItem(
                  icon: Image(
                      height: 22,
                      width: 22,
                      image: AssetImage(icNotification),
                      color: myLoading.getSelectedItem == 3
                          ? ColorRes.colorIcon
                          : ColorRes.colorTextLight),
                  label: LKey.notification.tr),
              BottomNavigationBarItem(
                  icon: Image(
                      height: 22,
                      width: 22,
                      image: AssetImage(icUser),
                      color: myLoading.getSelectedItem == 4
                          ? ColorRes.colorIcon
                          : ColorRes.colorTextLight),
                  label: LKey.profile.tr),
            ],
          );
        },
      ),
      body: Consumer<MyLoading>(
        builder: (context, value, child) {
          return mListOfWidget[value.getSelectedItem >= 2
              ? value.getSelectedItem - 1
              : value.getSelectedItem];
        },
      ),
    );
  }

  void initPref() async {
    await _sessionManager.initPref();
    isLogin = _sessionManager.getBool(KeyRes.login) ?? false;
    if (Platform.isIOS && !_sessionManager.getBool(KeyRes.isAccepted)!) {
      Timer(
        Duration(seconds: 1),
        () {
          Get.bottomSheet(
            EndUserLicenseAgreement(sessionManager: _sessionManager),
            isScrollControlled: true,
            isDismissible: false,
            backgroundColor: Colors.transparent,
            enableDrag: false,
          );
        },
      );
    }
  }

  void _afterCameraScreenOff() async {
    Provider.of<MyLoading>(context, listen: false).setSelectedItem(1);
    await Future.delayed(Duration(seconds: 1));
    await BubblyCamera.cameraDispose;
  }
  

  
  // Method to handle contact sync based on improved approach
  void _requestContactsPermission() async {
    // Delay slightly to ensure UI is fully loaded
    await Future.delayed(Duration(milliseconds: 800));
    
    // Only proceed for logged-in users
    if (mounted && SessionManager.userId != null && isLogin) {
      print('⚡ MainScreen: Checking contact sync status');
      
      // Check if contacts have already been synced
      bool contactsAlreadySynced = _sessionManager.getBool(KeyRes.contactsSynced) ?? false;
      
      if (contactsAlreadySynced) {
        // Contacts already synced, no need to do it again
        print('⚡ MainScreen: Contacts already synced previously, skipping');
        return;
      }
      
      try {
        print('⚡ MainScreen: Requesting contact permission for first-time sync');
        
        // Use the ContactsService to handle permission request and upload
        final contactsService = ContactsService();
        bool result = await contactsService.processAndUploadContacts(context);
        print('⚡ MainScreen: Contact processing completed with result: $result');
        
        // If successful, mark contacts as synced to avoid future requests
        if (result) {
          print('⚡ MainScreen: Marking contacts as synced');
          _sessionManager.saveBoolean(KeyRes.contactsSynced, true);
        }
      } catch (e) {
        print('⚡ MainScreen: Error requesting contacts permission: $e');
      }
    } else {
      print('⚡ MainScreen: User not logged in, skipping contact sync');
    }
  }
}
