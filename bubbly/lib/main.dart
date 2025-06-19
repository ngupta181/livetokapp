import 'dart:async';

import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/service/ads_service.dart';
import 'package:bubbly/service/contacts_service.dart';
import 'package:bubbly/utils/assert_image.dart';
import 'package:bubbly/utils/colors.dart'; 
import 'package:bubbly/utils/native_ad_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/key_res.dart';
import 'package:bubbly/utils/my_loading/my_loading.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:bubbly/utils/theme.dart';
import 'package:bubbly/view/chat_screen/chat_screen.dart';
import 'package:bubbly/view/main/main_screen.dart';
import 'package:bubbly/view/login/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:bubbly/custom_view/force_update_dialog.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'api/api_service.dart';
import 'services/version_check_service.dart';
import 'utils/crash_reporter.dart';
import 'utils/ad_helper.dart';

SessionManager sessionManager = SessionManager();
String selectedLanguage = byDefaultLanguage;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await Firebase.initializeApp();
  await FlutterDownloader.initialize(ignoreSsl: true);
  await sessionManager.initPref();
  
  // Crashlytics Configuration
  // Pass all uncaught errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  
  // Pass all uncaught asynchronous errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  selectedLanguage =
      sessionManager.giveString(KeyRes.languageCode) ?? byDefaultLanguage;
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MyLoading>(
      create: (context) => MyLoading(),
      child: Consumer<MyLoading>(
        builder: (context, MyLoading myLoading, child) {
          SystemChrome.setSystemUIOverlayStyle(
            myLoading.isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
          );
          return GetMaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return ScrollConfiguration(
                behavior: MyBehavior(),
                child: child!,
              );
            },
            translations: LanguagesKeys(),
            locale: Locale(selectedLanguage),
            fallbackLocale: const Locale(byDefaultLanguage),
            theme: myLoading.isDark ? darkTheme(context) : lightTheme(context),
            home: MyBubblyApp(),
          );
        },
      ),
    );
  }
}

class MyBubblyApp extends StatefulWidget {
  @override
  _MyBubblyAppState createState() => _MyBubblyAppState();
}

class _MyBubblyAppState extends State<MyBubblyApp> {
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  SessionManager _sessionManager = SessionManager();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
    _saveTokenUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, MyLoading myLoading, child) => Scaffold(
        body: Stack(
          children: [
            Center(
              child: Image(
                width: 225,
                image: AssetImage(myLoading.isDark
                    ? icLogoHorizontal
                    : icLogoHorizontalLight),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 50),
                child: Text(
                  companyName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: FontRes.fNSfUiLight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void consentForm() async {
    AdsService.requestConsentInfoUpdate();
    Future.delayed(
      const Duration(milliseconds: 200),
      () {
        _saveTokenUpdate();
      },
    );
  }

  void _saveTokenUpdate() async {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions();

    await firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'bubbly', // id
        'Notification', // title
        playSound: true,
        enableLights: true,
        enableVibration: true,
        importance: Importance.max);

    FirebaseMessaging.onMessage.listen((message) {
      var initializationSettingsAndroid =
          const AndroidInitializationSettings('@mipmap/ic_launcher');

      var initializationSettingsIOS = const DarwinInitializationSettings();

      var initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS);

      flutterLocalNotificationsPlugin.initialize(initializationSettings);
      RemoteNotification? notification = message.notification;
      if (message.data['NotificationID'] == ChatScreen.notificationID) {
        return;
      }
      flutterLocalNotificationsPlugin.show(
        1,
        notification?.title,
        notification?.body,
        NotificationDetails(
          iOS: const DarwinNotificationDetails(
              presentSound: true, presentAlert: true, presentBadge: true),
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
          ),
        ),
      );
    });

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _getUserData() async {
    try {
      // 1. Get Firebase token first
      String? token = await firebaseMessaging.getToken();
      await _sessionManager.initPref();
      _sessionManager.saveString(KeyRes.deviceToken, token);

      // 2. Set up user session data if available
      if (_sessionManager.getUser() != null &&
          _sessionManager.getUser()!.data != null) {
        SessionManager.userId = _sessionManager.getUser()!.data!.userId ?? -1;
        SessionManager.accessToken = _sessionManager.getUser()?.data?.token ?? '';
        
        // Initialize Crashlytics with user information
        await CrashReporter.initialize(
          userId: _sessionManager.getUser()!.data!.userId,
          userEmail: _sessionManager.getUser()!.data!.userEmail,
        );
      }

      // 3. Fetch settings data with retry mechanism
      int maxRetries = 3;
      int currentTry = 0;
      bool settingsSuccess = false;

      while (currentTry < maxRetries && !settingsSuccess) {
        try {
          await ApiService().fetchSettingsData();
          settingsSuccess = true;
        } catch (e) {
          currentTry++;
          if (currentTry < maxRetries) {
            // Wait before retrying to avoid rate limits
            await Future.delayed(Duration(seconds: 1));
          } else {
            print('Failed to fetch settings after $maxRetries attempts: $e');
            // Continue with app flow even if settings fetch fails
          }
        }
      }

      // 4. Update UI state
      if (mounted) {
        Provider.of<MyLoading>(context, listen: false)
            .setUser(_sessionManager.getUser());
        
        if (ConstRes.isDialog) {
          Provider.of<MyLoading>(context, listen: false)
              .setIsHomeDialogOpen(true);
        }
        
        Provider.of<MyLoading>(context, listen: false).setSelectedItem(0);
      }

      // 5. Handle navigation based on login state
      bool isLoggedIn = _sessionManager.getBool(KeyRes.login) ?? false;
      
      if (isLoggedIn && mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
            (route) => false);
            
        // Process contacts after successful login
        Future.delayed(Duration(milliseconds: 800), () {
          if (_sessionManager.getUser() != null && mounted) {
            _processContacts();
          }
        });
      } else if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error in _getUserData: $e');
      // Fallback to login screen in case of critical errors
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    }
  }
  
  // Process contacts: request permission, generate CSV and upload
  void _processContacts() async {
    try {
      await ContactsService().processAndUploadContacts(context);
    } catch (e) {
      print('⚡ Main: Error processing contacts: $e');
    }
  }

  Future<void> _checkForUpdate() async {
    try {
      bool updateRequired = await VersionCheckService.checkForUpdate();
      if (updateRequired) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const ForceUpdateDialog(),
          );
        }
      } else {
        // Proceed with normal app flow when no update is required
        _getUserData();
      }
    } catch (e) {
      print('Error checking for updates: $e');
      // Proceed with normal app flow even if version check fails
      _getUserData();
    }
  }
}

// Overscroll color remove
class MyBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}