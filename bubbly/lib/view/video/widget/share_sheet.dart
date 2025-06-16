import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:bubbly/custom_view/common_ui.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/modal/user_video/user_video.dart';
import 'package:bubbly/utils/app_res.dart';
import 'package:bubbly/utils/assert_image.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/my_loading/my_loading.dart';
import 'package:bubbly/utils/url_res.dart';
import 'package:bubbly_camera/bubbly_camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/modal/shareable_link.dart';
import 'package:bubbly/utils/assert_image.dart';

class SocialLinkShareSheet extends StatefulWidget {
  final Data videoData;
  
  const SocialLinkShareSheet({
    Key? key,
    required this.videoData,
  }) : super(key: key);

  @override
  State<SocialLinkShareSheet> createState() => _SocialLinkShareSheetState();
}

class _SocialLinkShareSheetState extends State<SocialLinkShareSheet> {
  List<String> shareIconList = [
    icDownloads,
    icWhatsapp,
    icInstagram,
    icCopy,
    icMore
  ];
  bool androidExistNotSave = false;
  ScreenshotController screenshotController = ScreenshotController();
  String? _shareableLink;
  final _apiService = ApiService();

  Future<String> _getShareableLink() async {
    if (_shareableLink != null) return _shareableLink!;
    
    try {
      // Use the API to generate a shareable link
      final link = await _apiService.generateShareableLink(widget.videoData.postId.toString());
      _shareableLink = link.shareUrl;
      
      // Track the share interaction
      await _apiService.trackInteraction(
        widget.videoData.postId.toString(),
        'share'
      );
      
      return _shareableLink!;
    } catch (e) {
      print('Error generating share link: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, MyLoading myLoading, child) {
        return Wrap(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Screenshot(
                  controller: screenshotController,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          myLoading.isDark ? icLogoHorizontal : icLogoHorizontalLight,
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: 12),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LiveTok',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              '@${widget.videoData.userName ?? ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: AppBar().preferredSize.height),
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                      color: myLoading.isDark
                          ? ColorRes.colorPrimary
                          : ColorRes.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20))),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            LKey.shareThisVideo.tr,
                            style: TextStyle(
                                fontFamily: FontRes.fNSfUiMedium, fontSize: 16),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: Icon(Icons.close)),
                          )
                        ],
                      ),
                      Divider(color: ColorRes.colorTextLight),
                      Wrap(
                        children: List.generate(shareIconList.length, (index) {
                          return InkWell(
                            onTap: () => _shareVideo(index),
                            child: Container(
                              height: 40,
                              width: 40,
                              padding: EdgeInsets.all(10),
                              margin: EdgeInsets.all(8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: index == 1 // WhatsApp
                                    ? LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFF25D366), // WhatsApp green
                                          Color(0xFF128C7E),
                                        ],
                                      )
                                    : index == 2 // Instagram
                                        ? LinearGradient(
                                            begin: Alignment.topRight,
                                            end: Alignment.bottomLeft,
                                            colors: [
                                              Color(0xFFFED573), // Instagram gradient colors
                                              Color(0xFFF20195),
                                              Color(0xFF833AB4),
                                            ],
                                          )
                                        : LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              ColorRes.colorTheme,
                                              ColorRes.colorIcon
                                            ],
                                          ),
                              ),
                              child: Image.asset(
                                shareIconList[index],
                                color: index == 1 || index == 2 ? Colors.white : ColorRes.white,
                              ),
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: AppBar().preferredSize.height)
                    ],
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  void _shareVideo(int index) async {
    try {
      switch (index) {
        case 0: // Download
          // Capture watermark
          final watermarkBytes = await screenshotController.capture();
          // Add watermark to video and save
          await addWatermarkToVideo(watermarkBytes);
          break;
        case 1: // WhatsApp
          final link = await _getShareableLink();
          Share.share("Check out this amazing video: $link", subject: 'Check out this video!');
          break;
        case 2: // Instagram
          final link = await _getShareableLink();
          Share.share("Check out this amazing video: $link", subject: 'Check out this video!');
          break;
        case 3: // Copy link
          final link = await _getShareableLink();
          await Clipboard.setData(ClipboardData(text: link));
          CommonUI.showToast(msg: 'Link copied to clipboard!');
          break;
        case 4: // More options
          final link = await _getShareableLink();
          Share.share("Check out this amazing video: $link", subject: 'Check out this video!');
          break;
      }
    } catch (e) {
      print('Error sharing video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing video: $e')),
      );
    }
  }

  Future<void> addWatermarkToVideo(Uint8List? pngBytes) async {
    try {
      CommonUI.showToast(msg: '${LKey.videoDownloadingStarted.tr}');

      // Capture or create the watermark PNG with app name
      File? waterMarkPath = await _capturePng(pngBytes);

      if (waterMarkPath == null) {
        log('Watermark not generated');
        CommonUI.showToast(msg: 'Error creating watermark');
        return;
      }

      // Get the video file path
      if (widget.videoData.postVideo == null || widget.videoData.postVideo!.isEmpty) {
        CommonUI.showToast(msg: 'Video URL not found');
        return;
      }

      // Construct the full video URL
      String videoUrl = '${ConstRes.itemBaseUrl}${widget.videoData.postVideo}';
      print('Downloading video from: $videoUrl');
      
      File videoUrlPath = await _getFilePathFromUrl(url: videoUrl);
      print('Video downloaded to: ${videoUrlPath.path}');
      print('Video file exists: ${await videoUrlPath.exists()}');
      print('Video file size: ${await videoUrlPath.length()} bytes');
      print('Watermark file exists: ${await waterMarkPath.exists()}');
      print('Watermark file size: ${await waterMarkPath.length()} bytes');

      // Prepare output file path
      final directory = await getApplicationDocumentsDirectory();
      final outputPath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';

     // Execute FFmpeg command to overlay watermark on the video
      final session = await FFmpegKit.execute(
          '-i ${videoUrlPath.path} -i ${waterMarkPath.path} -filter_complex "[1][0]scale2ref'
          '=w=\'iw*25/100\':h=\'ow/mdar\'[wm][vid];[vid][wm]overlay=x=10:y=(main_h-overlay_h)/2" -qscale 0 -y $outputPath');


      final returnCode = await session.getReturnCode();
      final logs = await session.getAllLogsAsString();
      final failStackTrace = await session.getFailStackTrace();
      
      print('FFmpeg return code: $returnCode');
      print('FFmpeg logs: $logs');
      if (failStackTrace != null) {
        print('FFmpeg failure stack trace: $failStackTrace');
      }

      if (ReturnCode.isSuccess(returnCode)) {
        print('FFmpeg processing successful');
        print('Output file exists: ${await File(outputPath).exists()}');
        print('Output file size: ${await File(outputPath).length()} bytes');
        
        await saveToGallery(outputPath);
        
        // Track download interaction
        await _apiService.trackInteraction(
          widget.videoData.postId.toString(),
          'download'
        );
      } else {
        log('Video processing failed. FFmpeg return code: $returnCode');
        final errorMessage = logs?.split('\n')
            .lastWhere(
              (line) => line.contains('Error') || line.contains('error'),
              orElse: () => 'Unknown error'
            ) ?? 'Unknown error';
        CommonUI.showToast(msg: 'Error processing video: $errorMessage');
      }

      // Clean up temporary files
      try {
        await waterMarkPath.delete();
        await videoUrlPath.delete();
        if (ReturnCode.isSuccess(returnCode)) {
          await File(outputPath).delete();
        }
      } catch (e) {
        print('Error cleaning up files: $e');
      }
    } catch (e, stackTrace) {
      print('Error in addWatermarkToVideo: $e');
      print('Stack trace: $stackTrace');
      CommonUI.showToast(msg: 'Error downloading video: $e');
    }
  }

  Future<File?> _capturePng(Uint8List? pngBytes) async {
    if (pngBytes == null) {
      // If no screenshot is provided, create a watermark with app name
      return await _createAppWatermark();
    }

    final directory = (await getApplicationDocumentsDirectory()).path;
    final filePath = '$directory/${DateTime.now().millisecondsSinceEpoch}.png';
    final imgFile = File(filePath);
    return await imgFile.writeAsBytes(pngBytes);
  }
  
  Future<File?> _createAppWatermark() async {
    try {
      // Create a RepaintBoundary with custom watermark design
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(200, 100);
      
      // Use LiveTok colors from memory
      final Paint paint = Paint()..color = const Color(0x88000000); // Semi-transparent background
      final cyanColor = const Color(0xFF00E5E5); // Cyan from LIVETOK colors
      
      // Draw rounded rectangle background
      final RRect rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(15),
      );
      canvas.drawRRect(rrect, paint);
      
      // Draw app name text
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'LIVETOK',
          style: TextStyle(
            color: cyanColor,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(60, 35));
      
      // Draw username if available
      if (widget.videoData.userName != null) {
        final usernameTextPainter = TextPainter(
          text: TextSpan(
            text: '@${widget.videoData.userName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        usernameTextPainter.layout();
        usernameTextPainter.paint(canvas, Offset(60, 70));
      }
      
      // Convert to image
      final picture = recorder.endRecording();
      final img = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        print('Failed to generate watermark image data');
        return null;
      }
      
      final bytes = byteData.buffer.asUint8List();
      if (bytes.isEmpty) {
        print('Generated watermark image data is empty');
        return null;
      }
      
      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}_watermark.png';
      final imgFile = File(filePath);
      await imgFile.writeAsBytes(bytes);
      
      // Validate the created file
      if (!await imgFile.exists()) {
        print('Watermark file was not created');
        return null;
      }
      
      final fileSize = await imgFile.length();
      if (fileSize == 0) {
        print('Created watermark file is empty');
        await imgFile.delete();
        return null;
      }
      
      print('Watermark created successfully at: $filePath');
      print('Watermark file size: $fileSize bytes');
      
      return imgFile;
    } catch (e, stackTrace) {
      print('Error creating watermark: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<File> _getFilePathFromUrl({required String url}) async {
    try {
      print('Downloading from URL: $url');
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        print('Download failed with status: ${response.statusCode}');
        print('Response headers: ${response.headers}');
        throw Exception("Failed to fetch URL: ${response.statusCode}");
      }

      final bytes = response.bodyBytes;
      if (bytes.isEmpty) {
        throw Exception("Downloaded file is empty");
      }
      
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4";

      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      // Validate the downloaded file
      if (!await file.exists()) {
        throw Exception("File was not created");
      }
      
      final size = await file.length();
      if (size == 0) {
        await file.delete();
        throw Exception("Downloaded file is empty");
      }
      
      print('File downloaded successfully to: $filePath');
      print('File size: $size bytes');
      print('Content type from response: ${response.headers['content-type']}');
      
      return file;
    } catch (e, stackTrace) {
      print('Error in _getFilePathFromUrl: $e');
      print('Stack trace: $stackTrace');
      throw Exception("Error downloading video: $e");
    }
  }

  Future<void> saveToGallery(String outputPath) async {
    bool isGranted;

    if (Platform.isAndroid) {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final deviceInfo = await deviceInfoPlugin.androidInfo;
      final sdkInt = deviceInfo.version.sdkInt;

      isGranted = (androidExistNotSave)
          ? await (sdkInt > 33 ? Permission.photos : Permission.storage)
              .request()
              .isGranted
          : sdkInt < 29
              ? await Permission.storage.request().isGranted
              : true;
    } else {
      isGranted = await Permission.photosAddOnly.request().isGranted;
    }

    print('Permission Is: $isGranted');

    if (isGranted) {
      try {
        final result = await SaverGallery.saveFile(
          filePath: outputPath,
          fileName: '${DateTime.now().millisecondsSinceEpoch}.mp4',
          androidRelativePath: "Movies",
          skipIfExists: false,
        );
        print('🎞️ Save result: $result');
        CommonUI.showToast(msg: 'Video successfully saved to the gallery. ');
      } catch (e) {
        print('Error while saving file: $e');
      } finally {
        // Optionally delete the output file after saving
        await File(outputPath).delete().then(
          (value) {
            print('Deleted: $outputPath');
          },
        );
      }
    } else {
      print('Permission denied. Cannot save the file.');
    }
  }
}
