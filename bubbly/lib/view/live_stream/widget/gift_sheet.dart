import 'dart:ui';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/modal/setting/setting.dart';
import 'package:bubbly/modal/user/user.dart';
import 'package:bubbly/utils/app_res.dart';
import 'package:bubbly/utils/assert_image.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/my_loading/my_loading.dart';
import 'package:bubbly/view/live_stream/widget/gift_animation_controller.dart';
import 'package:bubbly/view/wallet/dialog_coins_plan.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GiftSheet extends StatelessWidget {
  final VoidCallback onAddShortzzTap;
  final User? user;
  final Function(Gifts? gifts) onGiftSend;
  final SettingData? settingData;

  const GiftSheet({
    Key? key,
    required this.onAddShortzzTap,
    this.user,
    required this.onGiftSend,
    required this.settingData,
  }) : super(key: key);

  void _showCoinPlanDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: DialogCoinsPlan(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blurred transparent background
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: Colors.black.withOpacity(0.3),
          ),
        ),

        // Gift sheet UI
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Bar with Coins and Close
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Spacer(),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            icCoin,
                            width: 16,
                            height: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            NumberFormat.compact(locale: 'en')
                                .format(user?.data?.myWallet ?? 0),
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showCoinPlanDialog(context),
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // Classic Text
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 12.0),
                  child: Text(
                    'Classic',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // Gift Grid
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: settingData?.gifts?.length ?? 0,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    Gifts? gift = settingData?.gifts?[index];
                    bool isAffordable =
                        (gift?.coinPrice ?? 0) <= (user?.data?.myWallet ?? 0);

                    return GestureDetector(
                      onTap: () {
                        if (isAffordable) {
                          onGiftSend(gift);
                        } else {
                          _showCoinPlanDialog(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppRes.insufficientDescription),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                              ),
                              child: Image.network(
                                '${ConstRes.itemBaseUrl}${gift?.image}',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                icCoin,
                                width: 14,
                                height: 14,
                              ),
                              SizedBox(width: 2),
                              Text(
                                NumberFormat.compact(locale: 'en')
                                    .format(gift?.coinPrice ?? 0),
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Navigation Bar Space
              SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}
