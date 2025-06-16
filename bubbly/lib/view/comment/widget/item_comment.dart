import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/custom_view/common_ui.dart';
import 'package:bubbly/custom_view/image_place_holder.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/modal/comment/comment.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/date_time_utils.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/key_res.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/gestures.dart';
import 'package:bubbly/view/profile/profile_screen.dart';
// Using custom DateTimeUtils instead of timeago

class ItemComment extends StatefulWidget {
  final CommentData commentData;
  final VoidCallback onRemoveClick;
  final Function(CommentData) onReplyClick;
  final Function(CommentData) onLikeClick;
  final Function(CommentData, String) onEditClick;
  final bool isReply;

  const ItemComment({
    Key? key,
    required this.commentData,
    required this.onRemoveClick,
    required this.onReplyClick,
    required this.onLikeClick,
    required this.onEditClick,
    this.isReply = false,
  }) : super(key: key);

  @override
  _ItemCommentState createState() => _ItemCommentState();
}

class _ItemCommentState extends State<ItemComment> {
  bool _isEditMode = false;
  late TextEditingController _editController;
  bool _showReplies = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.commentData.comment);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _saveEdit() {
    if (_editController.text.trim().isNotEmpty) {
      widget.onEditClick(widget.commentData, _editController.text.trim());
      setState(() {
        _isEditMode = false;
      });
    } else {
      CommonUI.showToast(msg: LKey.enterCommentFirst.tr);
    }
  }

  String _getTimeAgo() {
    if (widget.commentData.createdDate == null || widget.commentData.createdDate!.isEmpty) {
      return ''; // No date available
    }
    
    try {
      // Print the raw date for debugging
      print('RAW COMMENT DATE: ${widget.commentData.createdDate}');
      
      // Try to parse the date
      DateTime? dateTime;
      try {
        dateTime = DateTime.parse(widget.commentData.createdDate!);
      } catch (parseError) {
        print('PARSE ERROR: $parseError');
        // Try alternative format (some APIs use different formats)
        try {
          final df = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
          dateTime = df.parse(widget.commentData.createdDate!);
        } catch (e) {
          print('ALTERNATIVE PARSE ERROR: $e');
        }
      }
      
      // If we successfully parsed the date
      if (dateTime != null) {
        print('PARSED DATE: $dateTime');
        return DateTimeUtils.formatDateTime(dateTime);
      } else {
        // Fallback to displaying the raw date
        return 'Recently';
      }
    } catch (e) {
      print('TIME AGO ERROR: $e');
      return 'Recently';
    }
  }

  void _navigateToProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          type: 1, // Type 1 for other user's profile
          userId: userId,
        ),
      ),
    );
  }

  List<TextSpan> _buildCommentTextSpans(String comment) {
    List<TextSpan> spans = [];
    
    // Split the comment into words
    List<String> words = comment.split(' ');
    
    for (String word in words) {
      if (word.startsWith('@')) {
        // This is a mention
        String username = word.substring(1); // Remove @ symbol
        
        // Check if this username is in the mentions list
        bool isValidMention = widget.commentData.mentions?.any(
          (mention) => mention['userName'] == username
        ) ?? false;
        
        if (isValidMention) {
          var mention = widget.commentData.mentions!.firstWhere(
            (m) => m['userName'] == username,
            orElse: () => {},
          );
          
          spans.add(TextSpan(
            text: word + ' ',
            style: TextStyle(
              color: ColorRes.colorTheme,
              fontWeight: FontWeight.w500,
              fontFamily: FontRes.fNSfUiRegular,
              fontSize: widget.isReply ? 14 : 15,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                if (mention.isNotEmpty && mention['userId'] != null) {
                  _navigateToProfile(mention['userId'].toString());
                }
              },
          ));
        } else {
          spans.add(TextSpan(
            text: word + ' ',
            style: TextStyle(
              color: Colors.black87,
              fontFamily: FontRes.fNSfUiRegular,
              fontSize: widget.isReply ? 14 : 15,
            ),
          ));
        }
      } else {
        spans.add(TextSpan(
          text: word + ' ',
          style: TextStyle(
            color: Colors.black87,
            fontFamily: FontRes.fNSfUiRegular,
            fontSize: widget.isReply ? 14 : 15,
          ),
        ));
      }
    }
    
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(
            left: widget.isReply ? 40 : 15, 
            right: 15, 
            top: 7.5, 
            bottom: 5,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => _navigateToProfile(widget.commentData.userId.toString()),
                child: ClipOval(
                  child: Image.network(
                    ConstRes.itemBaseUrl + (widget.commentData.userProfile ?? ''),
                    height: widget.isReply ? 35 : 40,
                    width: widget.isReply ? 35 : 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return ImagePlaceHolder(
                        name: widget.commentData.fullName,
                        heightWeight: widget.isReply ? 35 : 40,
                        fontSize: widget.isReply ? 20 : 25,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _navigateToProfile(widget.commentData.userId.toString()),
                          child: Text(
                            widget.commentData.fullName ?? '',
                            style: TextStyle(
                              fontFamily: FontRes.fNSfUiMedium,
                              fontSize: widget.isReply ? 12 : 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (widget.commentData.isVerify == 1)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Icon(Icons.verified, size: 14, color: ColorRes.colorTheme),
                          ),
                        Spacer(),
                        Text(
                          _getTimeAgo(),
                          style: TextStyle(
                            color: ColorRes.colorTextLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    _isEditMode
                        ? _buildEditField()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: _buildCommentTextSpans(
                                    widget.commentData.comment ?? ''
                                  ),
                                ),
                              ),
                              if (widget.commentData.isEdited == true)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    LKey.edited.tr,
                                    style: TextStyle(
                                      color: ColorRes.colorTextLight,
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        _buildActionButton(
                          icon: widget.commentData.isLiked == true 
                              ? Icons.favorite 
                              : Icons.favorite_border,
                          label: '${widget.commentData.likesCount ?? 0}',
                          color: widget.commentData.isLiked == true 
                              ? ColorRes.red 
                              : ColorRes.colorTextLight,
                          onTap: () => widget.onLikeClick(widget.commentData),
                        ),
                        SizedBox(width: 16),
                        if (!widget.isReply)
                          _buildActionButton(
                            icon: Icons.reply,
                            label: LKey.reply.tr,
                            onTap: () => widget.onReplyClick(widget.commentData),
                          ),
                        Spacer(),
                        if (widget.commentData.userId == SessionManager.userId)
                          Row(
                            children: [
                              if (!_isEditMode)
                                IconButton(
                                  icon: Icon(Icons.edit_outlined, size: 18),
                                  color: ColorRes.colorTextLight,
                                  constraints: BoxConstraints(),
                                  padding: EdgeInsets.all(4),
                                  onPressed: () {
                                    setState(() {
                                      _isEditMode = true;
                                    });
                                  },
                                ),
                              SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.delete_outline, size: 18),
                                color: ColorRes.colorTextLight,
                                constraints: BoxConstraints(),
                                padding: EdgeInsets.all(4),
                                onPressed: widget.onRemoveClick,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Show replies if any
        if (!widget.isReply && (widget.commentData.replies?.isNotEmpty ?? false))
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _showReplies = !_showReplies;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.only(left: 65, top: 4, bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        _showReplies ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 16,
                        color: ColorRes.colorTheme,
                      ),
                      SizedBox(width: 4),
                      Text(
                        _showReplies 
                            ? LKey.hideReplies.tr 
                            : '${LKey.viewReplies.tr} (${widget.commentData.replies?.length ?? 0})',
                        style: TextStyle(
                          color: ColorRes.colorTheme,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showReplies)
                ...widget.commentData.replies!.map((reply) => ItemComment(
                      commentData: reply,
                      onRemoveClick: () => _handleReplyRemove(reply),
                      onReplyClick: (_) {}, // No nested replies for now
                      onLikeClick: widget.onLikeClick,
                      onEditClick: widget.onEditClick,
                      isReply: true,
                    )),
            ],
          ),
        Divider(
          color: ColorRes.colorTextLight,
          thickness: 0.2,
          indent: widget.isReply ? 65 : 15,
          endIndent: 15,
        ),
      ],
    );
  }

  Widget _buildEditField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _editController,
              style: TextStyle(
                fontSize: widget.isReply ? 14 : 15,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: LKey.editYourComment.tr,
                hintStyle: TextStyle(color: ColorRes.colorTextLight),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              maxLines: 2,
              minLines: 1,
            ),
          ),
          IconButton(
            icon: Icon(Icons.check, color: ColorRes.colorTheme),
            constraints: BoxConstraints(),
            padding: EdgeInsets.all(4),
            onPressed: _saveEdit,
          ),
          IconButton(
            icon: Icon(Icons.close, color: ColorRes.red),
            constraints: BoxConstraints(),
            padding: EdgeInsets.all(4),
            onPressed: () {
              setState(() {
                _isEditMode = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, String? label, Color? color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? ColorRes.colorTextLight,
          ),
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                label,
                style: TextStyle(
                  color: color ?? ColorRes.colorTextLight,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleReplyRemove(CommentData reply) {
    // Call the API to remove the reply
    ApiService().deleteComment(reply.commentsId.toString()).then((value) {
      if (value.status == 200) {
        // Remove the reply from the list
        setState(() {
          widget.commentData.replies?.remove(reply);
        });
      }
    });
  }
}
