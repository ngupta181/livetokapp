import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/modal/live_stream/live_stream.dart';
import 'package:bubbly/modal/setting/setting.dart';

class GiftAnimation extends StatefulWidget {
  final LiveStreamComment giftComment;
  final SettingData? settingData;

  const GiftAnimation({
    Key? key,
    required this.giftComment,
    this.settingData,
  }) : super(key: key);

  @override
  State<GiftAnimation> createState() => _GiftAnimationState();
}

class _GiftAnimationState extends State<GiftAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideInAnimation;
  late Animation<double> _slideOutAnimation;
  late Animation<double> _shineAnimation;
  Timer? _timer;
  final _random = math.Random();
  bool _hasError = false;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();

    // Debug logging
    print("GiftAnimation created for comment: ${widget.giftComment.comment}");
    print("From user: ${widget.giftComment.fullName}");

    // Initialize animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    // Slide in from left animation
    _slideInAnimation = Tween<double>(
      begin: -350.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuad,
    ));

    // Shine animation for golden frame effect
    _shineAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Start the animation immediately
    _controller.forward();

    // Set timer to start the exit animation after 10 seconds
    _timer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _isExiting = true;
        });

        // Initialize the slide out animation
        _slideOutAnimation = Tween<double>(
          begin: 0.0,
          end: -350.0,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInQuad,
        ));

        // Reset controller and play exit animation
        _controller.reset();
        _controller.forward().then((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // Find the gift details from the comment
  Gifts? _findGiftFromImage() {
    if (widget.settingData?.gifts == null) return null;

    String giftImage = widget.giftComment.comment ?? '';

    for (Gifts gift in widget.settingData!.gifts!) {
      if (gift.image == giftImage) {
        return gift;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Add extra protection against possible null values
    String giftImage = widget.giftComment.comment ?? '';
    String senderName = widget.giftComment.fullName ?? 'User';
    String userImage = widget.giftComment.userImage ?? '';

    // Get actual gift details if available
    Gifts? gift = _findGiftFromImage();
    // Since the Gifts class doesn't have a name property, use a default "gift" text
    // or the gift ID if available
    String giftName = gift != null ? "Gift #${gift.id}" : 'Gift';

    // Check if we've already had an error
    if (_hasError) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
              _isExiting ? _slideOutAnimation.value : _slideInAnimation.value,
              0),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            height: 60,
            width: MediaQuery.of(context).size.width * 0.75,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Color(0xFFDAA520), // Golden color
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFDAA520).withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFDAA520).withOpacity(0.2),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Shine effect
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment(
                              _shineAnimation.value, _shineAnimation.value),
                          end: Alignment(_shineAnimation.value + 0.5,
                              _shineAnimation.value + 0.5),
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.3),
                            Colors.transparent,
                          ],
                          stops: [0.35, 0.5, 0.65],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcATop,
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),

                // Content row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // User profile picture
                    Container(
                      width: 50,
                      height: 50,
                      margin: EdgeInsets.only(left: 5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color(0xFFDAA520),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: userImage.isNotEmpty
                            ? Image.network(
                                '${ConstRes.itemBaseUrl}$userImage',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) {
                                  return CircleAvatar(
                                    backgroundColor: ColorRes.colorPink,
                                    child: Text(
                                      senderName.isNotEmpty
                                          ? senderName[0].toUpperCase()
                                          : 'U',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                },
                              )
                            : CircleAvatar(
                                backgroundColor: ColorRes.colorPink,
                                child: Text(
                                  senderName.isNotEmpty
                                      ? senderName[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                      ),
                    ),

                    SizedBox(width: 15),

                    // Gift info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            senderName,
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: FontRes.fNSfUiMedium,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'sent $giftName',
                            style: TextStyle(
                              color: Colors.white70,
                              fontFamily: FontRes.fNSfUiMedium,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 10),

                    // Gift icon
                    Container(
                      width: 45,
                      height: 45,
                      margin: EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color(0xFFDAA520),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getRandomColor().withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: giftImage.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.network(
                                '${ConstRes.itemBaseUrl}$giftImage',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) {
                                  // Mark that we had an error
                                  _hasError = true;
                                  print("Error loading gift image: $error");
                                  return Icon(Icons.card_giftcard,
                                      color: Colors.white, size: 35);
                                },
                              ),
                            )
                          : Icon(Icons.card_giftcard,
                              color: Colors.white, size: 35),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getRandomColor() {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
    ];
    return colors[_random.nextInt(colors.length)];
  }
}

class _Particle {
  final Color color;
  final Offset position;
  final double size;
  final double speed;
  final double angle;
  final double rotationSpeed;

  _Particle({
    required this.color,
    required this.position,
    required this.size,
    required this.speed,
    required this.angle,
    required this.rotationSpeed,
  });
}
