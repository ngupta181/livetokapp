import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/custom_view/app_bar_custom.dart';
import 'package:bubbly/custom_view/common_ui.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/modal/setting/setting.dart';
import 'package:bubbly/modal/wallet/my_wallet.dart';
import 'package:bubbly/utils/app_res.dart';
import 'package:bubbly/utils/assert_image.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/my_loading/my_loading.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:bubbly/view/redeem/redeem_screen.dart';
import 'package:bubbly/view/wallet/dialog_coins_plan.dart';
import 'package:bubbly/view/wallet/transaction_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class WalletScreen extends StatefulWidget {
  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  MyWalletData? _myWalletData;
  SessionManager sessionManager = SessionManager();
  SettingData? settingData;

  bool isLoading = true;

  @override
  void initState() {
    prefData();
    getMyWalletData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyLoading>(builder: (context, myLoading, child) {
      return Scaffold(
        body: Column(
          children: [
            AppBarCustom(title: LKey.myWallet.tr),
            isLoading
                ? Expanded(child: Center(child: CircularProgressIndicator()))
                : Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(15),
                            margin: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                  colors: [
                                    ColorRes.colorTheme,
                                    ColorRes.colorPink
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LinearProgressIndicator(
                                  color: ColorRes.white,
                                  value: (_myWalletData?.myWallet ?? 0) /
                                      (settingData?.minRedeemCoins ?? 0),
                                  minHeight: 2,
                                  borderRadius: BorderRadius.circular(10),
                                  backgroundColor:
                                      ColorRes.white.withOpacity(0.40),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 5),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'Minimum :${settingData?.minRedeemCoins ?? 0}',
                                      style: TextStyle(
                                        fontFamily: FontRes.fNSfUiLight,
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            NumberFormat.compact(
                                              locale: 'en',
                                            ).format(
                                                _myWalletData?.myWallet ?? 0),
                                            style: TextStyle(
                                                color: ColorRes.white,
                                                fontFamily:
                                                    FontRes.fNSfUiSemiBold,
                                                fontSize: 35),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${LKey.coins.tr} ${LKey.youHave.tr}',
                                            style: TextStyle(
                                                color: ColorRes.white
                                                    .withOpacity(0.8),
                                                fontFamily:
                                                    FontRes.fNSfUiRegular,
                                                fontSize: 15),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          backgroundColor: Colors.transparent,
                                          isScrollControlled: true,
                                          builder: (BuildContext context) {
                                            return DialogCoinsPlan();
                                          },
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 15),
                                        decoration: BoxDecoration(
                                          color: ColorRes.colorPrimaryDark,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${LKey.add.tr} ${LKey.coins.tr}',
                                          style: TextStyle(
                                              color: ColorRes.white,
                                              fontSize: 15,
                                              fontFamily:
                                                  FontRes.fNSfUiRegular),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(
                                    height:
                                        AppBar().preferredSize.height * 1.2),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        AppRes.redeemTitle(
                                            (settingData?.coinValue ?? 0.0)
                                                .toStringAsFixed(4)),
                                        style: TextStyle(
                                            fontFamily: FontRes.fNSfUiRegular,
                                            fontSize: 13,
                                            color: ColorRes.white),
                                      ),
                                    ),
                                    Image.asset(icCoin, height: 36, width: 36)
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Divider(
                              color: ColorRes.white.withOpacity(0.1),
                              endIndent: 15,
                              indent: 15),
                          Container(
                            height: 58,
                            margin: EdgeInsets.all(15),
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: myLoading.isDark
                                  ? ColorRes.colorPrimary
                                  : ColorRes.greyShade100,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(13),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: LinearGradient(
                                        colors: [
                                          ColorRes.colorTheme,
                                          ColorRes.colorPink
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight),
                                  ),
                                  child: Text(
                                    "+${NumberFormat.compact(locale: 'en').format(settingData?.rewardVideoUpload ?? 0)}",
                                    style: TextStyle(
                                      color: ColorRes.white,
                                      fontSize: 18,
                                      overflow: TextOverflow.ellipsis,
                                      fontFamily: FontRes.fNSfUiMedium,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    LKey.wheneverYouUploadVideo.tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontFamily: FontRes.fNSfUiMedium,
                                        fontSize: 17),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            color: ColorRes.white.withOpacity(0.1),
                            endIndent: 15,
                            indent: 15,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                            child: _buildActionButton(
                              context,
                              icon: Icons.history,
                              label: LKey.transactionHistory.tr,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TransactionHistoryScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              if ((_myWalletData?.myWallet ?? 0) <=
                                  (settingData?.minRedeemCoins ?? 0)) {
                                CommonUI.showToast(msg: LKey.insufficientBalance.tr);
                                CommonUI.showToast(msg: LKey.insufficientBalance.tr);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => RedeemScreen()),
                                ).then((value) {
                                  getMyWalletData();
                                });
                              }
                            },
                            child: Container(
                              height: 54,
                              margin: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                gradient: LinearGradient(
                                  colors: [ColorRes.colorTheme, ColorRes.colorPink],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  LKey.withdraw.tr.toUpperCase(),
                                  style: TextStyle(
                                      color: ColorRes.white,
                                      fontSize: 17,
                                      fontFamily: FontRes.fNSfUiMedium),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      );
    });
  }

  Widget _buildActionButton(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorRes.colorPrimary),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: ColorRes.colorPrimary),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: ColorRes.colorPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void getMyWalletData() {
    isLoading = true;
    ApiService().getMyWalletCoin().then((value) {
      _myWalletData = value.data;
      print(_myWalletData?.toJson());
      isLoading = false;
      setState(() {});
    });
  }

  void prefData() async {
    await sessionManager.initPref();
    // Force refresh settings from server to get latest coin value
    try {
      final settings = await ApiService().fetchSettingsData();
      settingData = settings.data;
    } catch (e) {
      print("Error fetching settings: $e");
      // Fallback to stored settings
      settingData = sessionManager.getSetting()?.data;
    }

    if (mounted) setState(() {});
  }
}
