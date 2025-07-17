import 'package:flutter/material.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/assert_image.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/view/live_stream/widget/live_stream_chat_list.dart';
import 'package:bubbly/view/live_stream/widget/live_stream_bottom_filed.dart';
import 'package:bubbly/view/live_stream/model/broad_cast_screen_view_model.dart';
import 'package:bubbly/modal/live_stream/live_stream.dart';

class SwipeableComments extends StatefulWidget {
  final BroadCastScreenViewModel model;
  final List<LiveStreamComment> commentList;
  final BuildContext pageContext;

  const SwipeableComments({
    Key? key,
    required this.model,
    required this.commentList,
    required this.pageContext,
  }) : super(key: key);

  @override
  State<SwipeableComments> createState() => _SwipeableCommentsState();
}

class _SwipeableCommentsState extends State<SwipeableComments>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _isVisible = true;
  int _unreadCount = 0;
  int _lastSeenCommentCount = 0;
  bool _showSwipeHint = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Show swipe hint after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSwipeHint = true;
        });
        // Hide hint after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showSwipeHint = false;
            });
          }
        });
      }
    });

    _lastSeenCommentCount = widget.commentList.length;
  }

  @override
  void didUpdateWidget(SwipeableComments oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if there are new comments while panel is hidden
    if (!_isVisible && widget.commentList.length > _lastSeenCommentCount) {
      setState(() {
        _unreadCount = widget.commentList.length - _lastSeenCommentCount;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleVisibility() {
    setState(() {
      if (_isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
        // Reset unread count when opening the panel
        _unreadCount = 0;
        _lastSeenCommentCount = widget.commentList.length;
      }
      _isVisible = !_isVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main comments panel
        SlideTransition(
          position: _offsetAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Stack(
                  children: [
                    GestureDetector(
                      onHorizontalDragEnd: (DragEndDetails details) {
                        if (details.primaryVelocity! > 0) {
                          // Swiped right to left (hide)
                          _toggleVisibility();
                        }
                      },
                      child: LiveStreamChatList(
                        commentList: widget.commentList,
                        pageContext: widget.pageContext,
                      ),
                    ),
                    // Swipe hint indicator
                    if (_showSwipeHint)
                      Positioned(
                        right: 10,
                        top: 50,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.swipe_left, color: Colors.white, size: 18),
                              SizedBox(width: 5),
                              Text(
                                'Swipe to hide',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: FontRes.fNSfUiMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              LiveStreamBottomField(model: widget.model),
            ],
          ),
        ),

        // Bubble icon when comments are hidden
        Positioned(
          right: 0,
          bottom: 100,
          child: AnimatedOpacity(
            opacity: _isVisible ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: GestureDetector(
              onTap: _toggleVisibility,
              onHorizontalDragEnd: (DragEndDetails details) {
                if (details.primaryVelocity! < 0) {
                  // Swiped left to right (show)
                  _toggleVisibility();
                }
              },
              child: Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [ColorRes.colorPink, ColorRes.colorTheme],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        bottomLeft: Radius.circular(25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                  // Unread messages counter
                  if (_unreadCount > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: ColorRes.colorPink,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
