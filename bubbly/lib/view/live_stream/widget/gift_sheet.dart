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

class GiftSheet extends StatefulWidget {
  final VoidCallback onAddShortzzTap;
  final User? user;
  final Function(Gifts? gifts) onGiftSend;
  final SettingData? settingData;
  final Function(bool isOpen, bool isMinimized)? onGiftSheetStateChanged;

  const GiftSheet({
    Key? key,
    required this.onAddShortzzTap,
    this.user,
    required this.onGiftSend,
    required this.settingData,
    this.onGiftSheetStateChanged,
  }) : super(key: key);

  @override
  State<GiftSheet> createState() => _GiftSheetState();
}

class _GiftSheetState extends State<GiftSheet> {
  bool _isMinimized = false;
  Gifts? _lastSentGift;
  int _giftCount = 0;
  
  @override
  void initState() {
    super.initState();
    // Notify that gift sheet is open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onGiftSheetStateChanged?.call(true, false);
    });
  }
  
  @override
  void dispose() {
    // Notify that gift sheet is closed
    widget.onGiftSheetStateChanged?.call(false, false);
    super.dispose();
  }

  void _toggleMinimized() {
    setState(() {
      _isMinimized = !_isMinimized;
      // Notify state change
      widget.onGiftSheetStateChanged?.call(true, _isMinimized);
    });
  }

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

  void _onGiftTap(Gifts? gift) {
    if (gift == null) return;
    
    bool isAffordable = (gift.coinPrice ?? 0) <= (widget.user?.data?.myWallet ?? 0);
    
    if (isAffordable) {
      // Track consecutive gifts
      if (_lastSentGift?.id == gift.id) {
        _giftCount++;
      } else {
        _giftCount = 1;
        _lastSentGift = gift;
      }
      
      // Call the gift send callback - DON'T close the sheet
      widget.onGiftSend(gift);
      
      // Show feedback for continuous sending
      _showGiftSentFeedback(gift);
    } else {
      _showCoinPlanDialog(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppRes.insufficientDescription),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showGiftSentFeedback(Gifts gift) {
    // Show a quick feedback animation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Image.network(
              '${ConstRes.itemBaseUrl}${gift.image}',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stack) => Icon(Icons.card_giftcard, size: 24),
            ),
            SizedBox(width: 8),
            Text('Gift sent! ${_giftCount > 1 ? 'x$_giftCount' : ''}'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 800),
        backgroundColor: Colors.green.withOpacity(0.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Allow tapping outside to close
        if (!_isMinimized) {
          widget.onGiftSheetStateChanged?.call(false, false);
          Navigator.pop(context);
        }
      },
      child: Container(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {}, // Prevent closing when tapping inside
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              // Reduce height to make it less intrusive
              height: _isMinimized ? 100 : MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              decoration: BoxDecoration(
                // Less blur and lighter background
                color: Colors.black.withOpacity(0.92),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: _isMinimized ? _buildMinimizedView() : _buildFullView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimizedView() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _toggleMinimized();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.expand_less, color: Colors.white, size: 20),
                  SizedBox(width: 4),
                  Text(
                    'Gifts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Spacer(),
          _buildCoinDisplay(),
          SizedBox(width: 8),
          _buildAddButton(),
          SizedBox(width: 8),
          _buildCloseButton(),
        ],
      ),
    );
  }

  Widget _buildFullView() {
    return Column(
      children: [
        // Draggable handle
        Container(
          margin: EdgeInsets.only(top: 8),
          height: 4,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        // Top Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // Minimize button
              GestureDetector(
                onTap: () {
                  _toggleMinimized();
                },
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.expand_more, color: Colors.white, size: 18),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Send Gift',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              _buildCoinDisplay(),
              SizedBox(width: 8),
              _buildAddButton(),
              SizedBox(width: 8),
              _buildCloseButton(),
            ],
          ),
        ),

        // Gift Categories
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Classic Gifts',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        // Gift Grid - More compact
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: widget.settingData?.gifts?.length ?? 0,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.9,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              Gifts? gift = widget.settingData?.gifts?[index];
              bool isAffordable = (gift?.coinPrice ?? 0) <= (widget.user?.data?.myWallet ?? 0);
              bool isLastSent = _lastSentGift?.id == gift?.id;

              return GestureDetector(
                onTap: () => _onGiftTap(gift),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isLastSent ? Colors.amber.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isLastSent ? Border.all(color: Colors.amber, width: 2) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: AnimatedScale(
                          scale: isLastSent ? 1.1 : 1.0,
                          duration: Duration(milliseconds: 200),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isAffordable ? Colors.transparent : Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.network(
                              '${ConstRes.itemBaseUrl}${gift?.image}',
                              fit: BoxFit.contain,
                              color: isAffordable ? null : Colors.grey,
                              colorBlendMode: isAffordable ? null : BlendMode.modulate,
                              errorBuilder: (context, error, stack) => Icon(
                                Icons.card_giftcard,
                                color: isAffordable ? Colors.white : Colors.grey,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(icCoin, width: 12, height: 12),
                            SizedBox(width: 2),
                            Text(
                              NumberFormat.compact(locale: 'en').format(gift?.coinPrice ?? 0),
                              style: TextStyle(
                                color: isAffordable ? Colors.amber : Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isLastSent && _giftCount > 1) ...[
                              SizedBox(width: 4),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'x$_giftCount',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Quick action tip
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 16),
              SizedBox(width: 6),
              Text(
                'Tap multiple times to send gifts quickly!',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoinDisplay() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(icCoin, width: 14, height: 14),
          SizedBox(width: 4),
          Text(
            NumberFormat.compact(locale: 'en').format(widget.user?.data?.myWallet ?? 0),
            style: TextStyle(
              color: Colors.amber,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => _showCoinPlanDialog(context),
      child: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.green.withOpacity(0.5)),
        ),
        child: Icon(Icons.add, color: Colors.green, size: 16),
      ),
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: () {
        widget.onGiftSheetStateChanged?.call(false, false);
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red.withOpacity(0.5)),
        ),
        child: Icon(Icons.close, color: Colors.red, size: 16),
      ),
    );
  }
}
