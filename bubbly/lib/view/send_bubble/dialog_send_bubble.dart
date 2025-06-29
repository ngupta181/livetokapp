import 'dart:ui';

import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/custom_view/common_ui.dart';
import 'package:bubbly/custom_view/send_coin_result.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/modal/user_video/user_video.dart';
import 'package:bubbly/utils/assert_image.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/my_loading/my_loading.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class DialogSendBubble extends StatelessWidget {
  final Data? videoData;

  DialogSendBubble(this.videoData);

  // Colors for the UI
  final Color goldColor = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, MyLoading myLoading, child) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorRes.colorTheme,
                  ColorRes.colorPink
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight
              ),
              borderRadius: BorderRadius.all(Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(height: 24),
                Text(
                  '${LKey.send.tr}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: goldColor,
                  ),
                  child: Center(
                    child: Image.asset(
                      icCoin,
                      height: 40,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    LKey.creatorWillBeNotifiedNAboutYourLove.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Grid of coin options
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      children: [
                        CoinGridItem(5, videoData, myLoading, ColorRes.colorTheme,
                            goldColor),
                        CoinGridItem(10, videoData, myLoading, ColorRes.colorTheme,
                            goldColor),
                        CoinGridItem(15, videoData, myLoading, ColorRes.colorTheme,
                            goldColor),
                        CoinGridItem(20, videoData, myLoading, ColorRes.colorTheme,
                            goldColor),
                      ],
                    ),
                  ),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Text(
                      LKey.cancel.tr,
                      style: TextStyle(
                        fontFamily: FontRes.fNSfUiMedium,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class CoinGridItem extends StatelessWidget {
  final int bubblesCount;
  final Data? videoData;
  final MyLoading myLoading;
  final Color backgroundColor;
  final Color coinColor;
  final SessionManager sessionManager = new SessionManager();

  CoinGridItem(this.bubblesCount, this.videoData, this.myLoading,
      this.backgroundColor, this.coinColor);

  @override
  Widget build(BuildContext context) {
    final user = myLoading.getUser;

    // Initialize preferences
    _initializePreferences();

    return GestureDetector(
      onTap: () async {
        if ((user?.data?.myWallet ?? 0) > bubblesCount) {
          try {
            // Capture initial wallet balance
            final initialBalance = user?.data?.myWallet ?? 0;

            CommonUI.showLoader(context);
            final response = await ApiService().sendCoin(
                bubblesCount.toString(), videoData!.userId.toString());

            // Close loader
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }

            // Close dialog
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }

            // Refresh wallet data
            await sessionManager.initPref();
            final updatedUser = sessionManager.getUser();
            myLoading.setUser(updatedUser);
            final updatedBalance = updatedUser?.data?.myWallet ?? 0;

            // Update user level points when coins are sent
            if (response.status == 200 || initialBalance > updatedBalance) {
              try {
                // The level points are already updated in the API service sendCoin method
                // Just refresh the user profile to get the updated level
                await ApiService().getProfile(updatedUser?.data?.userId.toString() ?? '');
              } catch (e) {
                print('Error updating level: $e');
              }
            }

            // Check if transaction was successful either by API response or by wallet balance change
            final bool isTransactionSuccessful =
                response.status == 200 || initialBalance > updatedBalance;

            // Show result dialog with appropriate message
            showDialog(
                context: context,
                builder: (context) => SendCoinsResult(
                    isTransactionSuccessful,
                    isTransactionSuccessful
                        ? "Coins sent successfully!"
                        : response.message ?? LKey.somethingWentWrong.tr));
          } catch (error) {
            // Close loader if open
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            // Close dialog
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }

            // Check if transaction may have still succeeded by checking wallet balance
            try {
              final initialBalance = user?.data?.myWallet ?? 0;
              await sessionManager.initPref();
              final updatedUser = sessionManager.getUser();
              myLoading.setUser(updatedUser);
              final updatedBalance = updatedUser?.data?.myWallet ?? 0;

              if (initialBalance > updatedBalance) {
                // Transaction was successful despite error, update level points
                try {
                  await ApiService().getProfile(updatedUser?.data?.userId.toString() ?? '');
                } catch (e) {
                  print('Error updating level: $e');
                }
                
                // Show success dialog
                showDialog(
                    context: context,
                    builder: (context) =>
                        SendCoinsResult(true, "Coins sent successfully!"));
              } else {
                // Show error toast
                CommonUI.showToast(msg: LKey.somethingWentWrong.tr);
              }
            } catch (e) {
              // Show error toast
              CommonUI.showToast(msg: LKey.somethingWentWrong.tr);
            }
          }
        } else {
          CommonUI.showToast(msg: LKey.insufficientBalance.tr);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ColorRes.colorTheme.withOpacity(0.1),
              ColorRes.colorPink.withOpacity(0.1)
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight
          ),
          borderRadius: BorderRadius.all(Radius.circular(16)),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 35,
                  height: 35,
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Image.asset(
                      icCoin,
                      height: 25,
                      width: 25,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '$bubblesCount',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Initialize preferences asynchronously without blocking the UI
  void _initializePreferences() {
    Future.microtask(() async {
      await sessionManager.initPref();
    });
  }
}
