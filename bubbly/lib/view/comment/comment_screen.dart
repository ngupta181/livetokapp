import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/custom_view/common_ui.dart';
import 'package:bubbly/custom_view/data_not_found.dart';
import 'package:bubbly/custom_view/image_place_holder.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/modal/comment/comment.dart';
import 'package:bubbly/modal/search/search_user.dart';
import 'package:bubbly/modal/user_video/user_video.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/key_res.dart';
import 'package:bubbly/utils/my_loading/my_loading.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:bubbly/utils/date_time_utils.dart';
import 'package:bubbly/view/comment/widget/item_comment.dart';
import 'package:bubbly/view/login/login_sheet.dart';
import 'package:bubbly/view/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class CommentScreen extends StatefulWidget {
  final Data? videoData;
  final Function onComment;

  CommentScreen(this.videoData, this.onComment);

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  ScrollController _scrollController = ScrollController();
  TextEditingController _commentController = TextEditingController();
  FocusNode commentFocusNode = FocusNode();
  SessionManager sessionManager = SessionManager();
  bool hasNoMore = false;
  List<CommentData> commentList = [];
  bool isLogin = false;
  bool isLoading = true;
  
  // For handling mentions
  List<SearchUserData> suggestedUsers = [];
  bool showMentionSuggestions = false;
  String currentMentionQuery = '';
  Timer? _debounceTimer;
  
  // For handling replies
  CommentData? replyingTo;
  bool isReplying = false;

  @override
  void initState() {
    prefData();
    callApiForComments();
    _scrollController.addListener(
      () {
        if (_scrollController.position.maxScrollExtent == _scrollController.position.pixels && !isLoading) {
          callApiForComments();
        }
      },
    );

    // Add listener for comment input to detect @ mentions
    _commentController.addListener(_onCommentChanged);

    super.initState();
  }

  void _onCommentChanged() {
    String text = _commentController.text;
    int cursorPosition = _commentController.selection.baseOffset;
    
    // Find the word being typed at cursor position
    String wordBeingTyped = _getWordAtCursor(text, cursorPosition);
    
    if (wordBeingTyped.startsWith('@') && wordBeingTyped.length > 1) {
      // Search for users matching the query
      _searchUsers(wordBeingTyped.substring(1));
    } else {
      setState(() {
        showMentionSuggestions = false;
      });
    }
  }

  String _getWordAtCursor(String text, int cursorPosition) {
    if (cursorPosition < 0 || text.isEmpty) return '';
    
    // Find the start of the current word
    int start = cursorPosition;
    while (start > 0 && text[start - 1] != ' ') {
      start--;
    }
    
    // Find the end of the current word
    int end = cursorPosition;
    while (end < text.length && text[end] != ' ') {
      end++;
    }
    
    return text.substring(start, end);
  }

  void _searchUsers(String query) {
    // Cancel previous timer if exists
    _debounceTimer?.cancel();
    
    // Set new timer
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      if (query.length > 0) {
        print('Searching for users with query: "$query"');
        ApiService().getSearchUser('0', '10', query).then((response) {
          if (mounted && response.data != null) {
            print('Search results for "$query": ${response.data!.length} users found');
            for (var user in response.data!) {
              print('User: ${user.fullName} (@${user.userName}) - Profile: "${user.userProfile}"');
              if (user.userProfile != null && user.userProfile!.isNotEmpty) {
                String fullUrl = ConstRes.itemBaseUrl + user.userProfile!;
                print('Full profile URL: $fullUrl');
              } else {
                print('No profile image for user: ${user.userName}');
              }
            }
            setState(() {
              suggestedUsers = response.data!;
              showMentionSuggestions = suggestedUsers.isNotEmpty;
            });
          } else {
            print('No search results for "$query"');
            setState(() {
              suggestedUsers = [];
              showMentionSuggestions = false;
            });
          }
        }).catchError((error) {
          print('Error searching users: $error');
          setState(() {
            suggestedUsers = [];
            showMentionSuggestions = false;
          });
        });
      }
    });
  }

  void _onUsernameTap(String username) {
    // Navigate to user profile using existing profile screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          type: 1, // Type 1 for other user's profile
          userId: username,
        ),
      ),
    );
  }

  void _insertMention(SearchUserData user) {
    String text = _commentController.text;
    int cursorPosition = _commentController.selection.baseOffset;
    
    // Find the start of the @ mention
    int start = cursorPosition;
    while (start > 0 && text[start - 1] != ' ' && text[start - 1] != '@') {
      start--;
    }
    if (start > 0 && text[start - 1] == '@') start--;
    
    // Replace the partial mention with the full username
    String newText = text.substring(0, start) + '@${user.userName} ' + text.substring(cursorPosition);
    
    setState(() {
      _commentController.text = newText;
      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: start + (user.userName?.length ?? 0) + 2), // Fixed: Cast to int not needed since length is already int
      );
      showMentionSuggestions = false;
    });
  }

  void _navigateToUserProfile(SearchUserData user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          type: 1, // Type 1 for other user's profile
          userId: user.userId.toString(),
        ),
      ),
    );
  }

  void _clearMentionSuggestions() {
    setState(() {
      showMentionSuggestions = false;
      suggestedUsers = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, MyLoading myLoading, child) {
        return Container(
          margin: EdgeInsets.only(top: AppBar().preferredSize.height),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            color: myLoading.isDark ? ColorRes.colorPrimaryDark : ColorRes.white,
          ),
          constraints: BoxConstraints(maxHeight: 500),
          child: Column(
            children: [
              SizedBox(height: 5),
              Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '${commentList.length} ${LKey.comments.tr}', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(Icons.close_rounded),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              Divider(
                color: ColorRes.colorTextLight,
                thickness: 0.2,
                height: 0.2,
              ),
              SizedBox(height: 5),
              Expanded(
                child: isLoading
                    ? CommonUI.getWidgetLoader()
                    : commentList.isEmpty
                        ? DataNotFound()
                        : ListView.builder(
                            padding: EdgeInsets.only(bottom: 25),
                            controller: _scrollController,
                            itemCount: commentList.length,
                            itemBuilder: (BuildContext context, int index) {
                              CommentData commentData = commentList[index];
                              if (commentData.parentId != null) return SizedBox.shrink();
                              
                              return ItemComment(
                                commentData: commentData,
                                onRemoveClick: () => _deleteCommentApi(commentData),
                                onReplyClick: (comment) => _handleReplyClick(comment),
                                onLikeClick: (comment) => _handleLikeClick(comment),
                                onEditClick: (comment, newText) => _handleEditComment(comment, newText),
                              );
                            },
                          ),
              ),
              if (showMentionSuggestions)
                Container(
                  constraints: BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: myLoading.isDark ? ColorRes.colorPrimaryDark : ColorRes.white,
                    border: Border(
                      top: BorderSide(color: ColorRes.colorTextLight.withOpacity(0.2)),
                      bottom: BorderSide(color: ColorRes.colorTextLight.withOpacity(0.2)),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with close button
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              'Mention someone',
                              style: TextStyle(
                                fontSize: 12,
                                color: ColorRes.colorTextLight,
                                fontFamily: FontRes.fNSfUiMedium,
                              ),
                            ),
                            Spacer(),
                            InkWell(
                              onTap: _clearMentionSuggestions,
                              child: Icon(Icons.close, size: 18, color: ColorRes.colorTextLight),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: ColorRes.colorTextLight.withOpacity(0.2)),
                      // User list
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: suggestedUsers.length,
                          itemBuilder: (context, index) {
                            final user = suggestedUsers[index];
                            return ListTile(
                              dense: true,
                              leading: ClipOval(
                                child: Image.network(
                                  ConstRes.itemBaseUrl +
                                      (user.userProfile == null ||
                                              user.userProfile!.isEmpty
                                          ? ''
                                          : user.userProfile ?? ''),
                                  height: 40,
                                  width: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error loading profile image for ${user.userName}: $error');
                                    return ImagePlaceHolder(
                                      name: user.fullName,
                                      heightWeight: 40,
                                      fontSize: 20,
                                    );
                                  },
                                ),
                              ),
                              title: Text(
                                user.fullName ?? '',
                                style: TextStyle(
                                  fontFamily: FontRes.fNSfUiMedium,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '@${user.userName}',
                                style: TextStyle(
                                  color: ColorRes.colorTextLight,
                                  fontFamily: FontRes.fNSfUiMedium,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.person, size: 20, color: ColorRes.colorTheme),
                                onPressed: () => _navigateToUserProfile(user),
                              ),
                              onTap: () => _insertMention(user),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              if (isReplying)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      Text(
                        '${LKey.replyingTo.tr} ',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      Text(
                        '${replyingTo?.fullName}',
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          color: ColorRes.colorTheme
                        ),
                      ),
                      Spacer(),
                      InkWell(
                        onTap: () {
                          setState(() {
                            isReplying = false;
                            replyingTo = null;
                          });
                        },
                        child: Icon(Icons.close, size: 18, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Emoji Row
                    Container(
                      height: 50,
                      margin: EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildEmojiButton('❤️'),
                          _buildEmojiButton('🙌'),
                          _buildEmojiButton('🔥'),
                          _buildEmojiButton('👏'),
                          _buildEmojiButton('😢'),
                          _buildEmojiButton('😍'),
                          _buildEmojiButton('😮'),
                          _buildEmojiButton('😂'),
                        ],
                      ),
                    ),
                    // Comment Box
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                        color: myLoading.isDark ? ColorRes.colorPrimary : ColorRes.greyShade100,
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              enabled: isCommentSend == false ? true : false,
                              focusNode: commentFocusNode,
                              maxLines: 4,
                              minLines: 1,
                              textCapitalization: TextCapitalization.sentences,
                              style: TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: isReplying 
                                  ? LKey.typeYourReply.tr 
                                  : LKey.leaveYourComment.tr,
                                hintStyle: TextStyle(color: ColorRes.colorTextLight),
                                contentPadding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                              ),
                              cursorColor: ColorRes.colorTextLight,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(right: 4, bottom: 4),
                            child: InkWell(
                              onTap: isCommentSend ? null : _addComment,
                              child: Container(
                                height: 38,
                                width: 38,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [ColorRes.colorTheme, ColorRes.colorTheme]),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.send_rounded, color: ColorRes.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
            ],
          ),
        );
      },
    );
  }

  void callApiForComments() {
    if (hasNoMore) {
      return;
    }
    setState(() {
      isLoading = true;
    });
    ApiService()
        .getCommentByPostId('${commentList.length}', '$paginationLimit', '${widget.videoData?.postId}')
        .then((value) {
      setState(() {
        isLoading = false;
      });
      
      // Check if we got a valid response
      if (value.status == 0) {
        // Handle error case
        print('Error loading comments: ${value.message}');
        setState(() {
          // Show empty state or error message
          hasNoMore = true;
        });
        return;
      }
      
      // Check if we've reached the end of pagination
      if ((value.data?.length ?? 0) < paginationLimit) {
        hasNoMore = true;
      }
      
      // Add comments to the list
      if (commentList.isEmpty) {
        setState(() {
          commentList.addAll(value.data ?? []);
        });
      } else {
        setState(() {
          for (int i = 0; i < (value.data?.length ?? 0); i++) {
            commentList.add(value.data?[i] ?? CommentData());
          }
        });
      }
    }).catchError((error) {
      print('Error fetching comments: $error');
      setState(() {
        isLoading = false;
        hasNoMore = true; // Prevent further loading attempts
      });
    });
  }

  void _deleteCommentApi(CommentData comment) {
    // If this is a parent comment, need to also remove all replies
    int commentsToRemove = 1; // Start with the comment itself
    
    // Also count the replies if this is a parent comment
    if (comment.replies != null) {
      commentsToRemove += comment.replies!.length;
    }
    
    commentList.remove(comment);
    setState(() {});
    
    ApiService().deleteComment(comment.commentsId.toString()).then((value) {
      // Update the comment count in the UI
      for (int i = 0; i < commentsToRemove; i++) {
        widget.videoData?.setPostCommentCount(false);
      }
      widget.onComment.call();
    });
  }
  
  void _handleReplyClick(CommentData comment) {
    setState(() {
      isReplying = true;
      replyingTo = comment;
    });
    commentFocusNode.requestFocus();
  }
  
  void _handleLikeClick(CommentData comment) {
    // First update UI for immediate feedback
    setState(() {
      comment.toggleLike();
    });
    
    // Then make API call to persist the change
    ApiService().likeComment(comment.commentsId.toString()).then((value) {
      // If API fails, revert the UI change (optional)
      if (value.status != 200) {
        setState(() {
          comment.toggleLike(); // Toggle back if API failed
        });
      }
    });
  }
  
  void _handleEditComment(CommentData comment, String newText) {
    // First update UI for immediate feedback
    setState(() {
      comment.updateComment(newText);
    });
    
    // Then make API call to persist the change
    ApiService().editComment(comment.commentsId.toString(), newText).then((value) {
      // If API fails, we could show an error message
      if (value.status != 200) {
        CommonUI.showToast(msg: LKey.errorEditingComment.tr);
      }
    });
  }

  bool isCommentSend = false;

  void _addComment() {
    if (isCommentSend == true) return;
    if (_commentController.text.trim().isEmpty) {
      CommonUI.showToast(msg: LKey.enterCommentFirst.tr);
    } else {
      if (SessionManager.userId == -1 || !isLogin) {
        showModalBottomSheet(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          )),
          isScrollControlled: true,
          context: context,
          builder: (context) {
            return LoginSheet();
          },
        );
      } else {
        setState(() {
          isCommentSend = true;
        });
        
        // Extract mentions from comment
        List<Map<String, dynamic>> mentions = [];
        RegExp mentionRegex = RegExp(r'@(\w+)');
        mentionRegex.allMatches(_commentController.text).forEach((match) {
          String username = match.group(1)!;
          var mentionedUser = suggestedUsers.firstWhere(
            (user) => user.userName == username,
            orElse: () => SearchUserData(
              userId: -1,
              userName: '',
              fullName: '',
              userProfile: '',
            ),
          );
          if (mentionedUser.userId != null && mentionedUser.userId != -1) {
            mentions.add({
              'userId': mentionedUser.userId,
              'userName': mentionedUser.userName,
              'fullName': mentionedUser.fullName,
              'userProfile': mentionedUser.userProfile,
            });
          }
        });
        
        if (isReplying && replyingTo != null) {
          // Add reply with mentions
          ApiService().addReply(
            _commentController.text.trim(), 
            '${widget.videoData?.postId}',
            replyingTo!.commentsId.toString(),
            mentions: mentions,
          ).then(
            (value) {
              if (value.status == 200) {
                // Clear input and update UI state
                _commentController.clear();
                commentFocusNode.unfocus();
                widget.videoData?.setPostCommentCount(true);
                widget.onComment.call();
                
                setState(() {
                  isCommentSend = false;
                  isReplying = false;
                  replyingTo = null;
                });
                
                // Reset comment list and fetch fresh comments
                setState(() {
                  commentList = [];
                  hasNoMore = false;
                });
                callApiForComments();
              } else {
                setState(() {
                  isCommentSend = false;
                });
                CommonUI.showToast(msg: value.message ?? LKey.somethingWentWrong.tr);
              }
            },
          );
        } else {
          // Add regular comment with mentions
          ApiService().addComment(
            _commentController.text.trim(), 
            '${widget.videoData?.postId}',
            mentions: mentions,
          ).then(
            (value) {
              if (value.status == 200) {
                // Clear input
                _commentController.clear();
                commentFocusNode.unfocus();
                widget.videoData?.setPostCommentCount(true);
                widget.onComment.call();
                
                // Reset comment list and fetch fresh comments
                setState(() {
                  commentList = [];
                  hasNoMore = false;
                  isCommentSend = false;
                });
                callApiForComments();
              } else {
                setState(() {
                  isCommentSend = false;
                });
                CommonUI.showToast(msg: value.message ?? LKey.somethingWentWrong.tr);
              }
            },
          );
        }
      }
    }
  }

  void prefData() async {
    await sessionManager.initPref();
    isLogin = sessionManager.getBool(KeyRes.login) ?? false;
    setState(() {});
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _commentController.removeListener(_onCommentChanged);
    _commentController.dispose();
    _scrollController.dispose();
    commentFocusNode.dispose();
    super.dispose();
  }

  Widget _buildEmojiButton(String emoji) {
    return InkWell(
      onTap: () => _insertEmoji(emoji),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }

  void _insertEmoji(String emoji) {
    final text = _commentController.text;
    final selection = _commentController.selection;
    final newText = text.replaceRange(selection.start, selection.end, emoji);
    _commentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.baseOffset + emoji.length,
      ),
    );
  }
}
