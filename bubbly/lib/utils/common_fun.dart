import 'package:bubbly/utils/app_res.dart';
import 'package:bubbly/utils/firebase_res.dart';

class CommonFun {
  static String getLastMsg({required String type, required String message}) {
    return type == FirebaseRes.image
        ? AppRes.imageMessage
        : type == FirebaseRes.video
            ? AppRes.videoMessage
            : message;
  }
}
