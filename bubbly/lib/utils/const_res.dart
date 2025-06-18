import 'image_utils.dart';

class ConstRes {
  static final String base = 'https://livetok.app/';
  static const String apiKey = 'Y29tLmxpdmUudG9rLmFwcA==';
  static final String baseUrl = '${base}api/';

  static final String itemBaseUrl = 'https://delqviq69zgnh.cloudfront.net/livetok/';
  
  // Helper method to safely construct image URLs
  static String getImageUrl(String? imagePath) {
    return ImageUtils.getValidImageUrl(itemBaseUrl, imagePath);
  }
  
  // Agora Credential
  static final String customerId = '33732a1071124385b3b6818e537fe8cf';
  static final String customerSecret = '9253ac90996246d29d74b644f449053f';

  // Starting screen open end_user_license_agreement sheet link
  static final String agreementUrl = "https://livetok.app/";

  static final String bubblyCamera = 'bubbly_camera';
  static final bool isDialog = false;
}

const String appName = 'LiveTok';
const String recharge = 'Recharge';
const companyName = 'LiveTok';
const defaultPlaceHolderText = 'L';
const byDefaultLanguage = 'en';

const int paginationLimit = 10;

// Live broadcast Video Quality : Resolution (Width×Height)
int liveWeight = 640;
int liveHeight = 480;
int liveFrameRate = 15; //Frame rate (fps）

// Image Quality
double maxHeight = 720;
double maxWidth = 720;
int imageQuality = 100;

// max Video upload limit in MB
int maxUploadMB = 150;
// max Video upload second
int maxUploadSecond = 180;

//Strings
const List<String> paymentMethods = ['Paypal', 'Stripe','Other'];
const List<String> reportReasons = ['Sexual', 'Nudity', 'Religion', 'Other'];

// Video Moderation models  :- https://sightengine.com/docs/moderate-stored-video-asynchronously
String nudityModels = 'nudity,wad';