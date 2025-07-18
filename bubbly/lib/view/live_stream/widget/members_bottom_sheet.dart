import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/firebase_res.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:bubbly/modal/user/user.dart';
import 'package:bubbly/modal/live_stream/live_stream.dart';
import 'package:bubbly/view/live_stream/widget/co_host_invitation_sheet.dart';
import 'package:bubbly/services/co_host_invitation_service.dart';
import 'package:bubbly/view/pk_battle/controllers/pk_battle_controller.dart';
import 'package:bubbly/modal/pk_battle/battle_type.dart';

class MembersBottomSheet extends StatefulWidget {
  final String channelName;
  final bool isHost;
  final List<LiveStreamComment> commentList;
  final Function(String userId)? onCoHostInvited;
  final Function(String userId)? onCoHostAccepted;
  final Function()? onCoHostRemoved;
  final dynamic model; // BroadCastScreenViewModel

  const MembersBottomSheet({
    Key? key,
    required this.channelName,
    required this.isHost,
    required this.commentList,
    this.onCoHostInvited,
    this.onCoHostAccepted,
    this.onCoHostRemoved,
    this.model,
  }) : super(key: key);

  @override
  State<MembersBottomSheet> createState() => _MembersBottomSheetState();
}

class _MembersBottomSheetState extends State<MembersBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SessionManager _pref = SessionManager();

  List<UserData> _audienceUsers = [];
  List<UserData> _invitedUsers = [];
  List<UserData> _coHostUsers = [];
  List<UserData> _requestUsers = [];
  List<UserData> _filteredUsers = [];
  
  bool _isLoading = false;
  String _searchQuery = '';
  int _currentTabIndex = 1; // Start with Audience tab

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);
    _tabController.addListener(_onTabChanged);
    _searchController.addListener(_onSearchChanged);
    _loadMembersData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      _currentTabIndex = _tabController.index;
      _filterUsers();
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterUsers();
    });
  }

  void _filterUsers() {
    List<UserData> sourceList;
    switch (_currentTabIndex) {
      case 0: // Requests
        sourceList = _requestUsers;
        break;
      case 1: // Audience
        sourceList = _audienceUsers;
        break;
      case 2: // Invited
        sourceList = _invitedUsers;
        break;
      case 3: // Co-hosts
        sourceList = _coHostUsers;
        break;
      default:
        sourceList = _audienceUsers;
    }

    if (_searchQuery.isEmpty) {
      _filteredUsers = List.from(sourceList);
    } else {
      _filteredUsers = sourceList.where((user) {
        return (user.userName?.toLowerCase().contains(_searchQuery) ?? false) ||
               (user.fullName?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
  }

  Future<void> _loadMembersData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _pref.initPref();
      final currentUser = _pref.getUser();
      
      // Get current viewers from comments (active users)
      Set<String> activeUserIds = {};
      for (var comment in widget.commentList) {
        if (comment.userId != currentUser?.data?.userId) {
          activeUserIds.add(comment.userId.toString());
        }
      }

      // Load audience users from active commenters
      List<UserData> audienceUsers = [];
      for (String userId in activeUserIds) {
        try {
          // You might need to implement getUserById in your ApiService
          // For now, we'll create a mock user from comment data
          final comment = widget.commentList.firstWhere(
            (c) => c.userId.toString() == userId,
            orElse: () => widget.commentList.first,
          );
          
          audienceUsers.add(UserData(
            userId: comment.userId,
            userName: comment.userName,
            fullName: comment.fullName,
            userProfile: comment.userImage,
            isVerify: (comment.isVerify ?? false) ? 1 : 0,
            identity: userId,
          ));
        } catch (e) {
          print('Error loading user $userId: $e');
        }
      }

      // Load invited users
      final invitationsSnapshot = await _db
          .collection(FirebaseRes.liveStreamUser)
          .doc(widget.channelName)
          .collection('co_host_invitations')
          .where('status', isEqualTo: 'pending')
          .get();

      List<UserData> invitedUsers = [];
      for (var doc in invitationsSnapshot.docs) {
        final data = doc.data();
        invitedUsers.add(UserData(
          userId: data['userId'],
          userName: data['userName'],
          fullName: data['fullName'],
          userProfile: data['userImage'],
          identity: doc.id,
        ));
      }

      // Load co-hosts
      final coHostsSnapshot = await _db
          .collection(FirebaseRes.liveStreamUser)
          .doc(widget.channelName)
          .collection('co_hosts')
          .get();

      List<UserData> coHostUsers = [];
      for (var doc in coHostsSnapshot.docs) {
        final data = doc.data();
        coHostUsers.add(UserData(
          userId: data['userId'],
          userName: data['userName'],
          fullName: data['fullName'],
          userProfile: data['userImage'],
          identity: doc.id,
        ));
      }

      // Load join requests
      final requestsSnapshot = await _db
          .collection(FirebaseRes.liveStreamUser)
          .doc(widget.channelName)
          .collection('join_requests')
          .where('status', isEqualTo: 'pending')
          .get();

      List<UserData> requestUsers = [];
      for (var doc in requestsSnapshot.docs) {
        final data = doc.data();
        requestUsers.add(UserData(
          userId: data['userId'],
          userName: data['userName'],
          fullName: data['fullName'],
          userProfile: data['userImage'],
          identity: doc.id,
        ));
      }

      setState(() {
        _audienceUsers = audienceUsers;
        _invitedUsers = invitedUsers;
        _coHostUsers = coHostUsers;
        _requestUsers = requestUsers;
        _filterUsers();
      });
    } catch (e) {
      print('Error loading members data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Members',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: FontRes.fNSfUiSemiBold,
                    color: Colors.black,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: ColorRes.colorTheme,
              unselectedLabelColor: Colors.grey,
              indicatorColor: ColorRes.colorTheme,
              labelStyle: TextStyle(
                fontFamily: FontRes.fNSfUiSemiBold,
                fontSize: 14,
              ),
              unselectedLabelStyle: TextStyle(
                fontFamily: FontRes.fNSfUiMedium,
                fontSize: 14,
              ),
              tabs: [
                Tab(text: 'Requests'),
                Tab(text: 'Audience'),
                Tab(text: 'Invited'),
                Tab(text: 'Co-hosts'),
              ],
            ),
          ),

          // Search bar
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search here..',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: ColorRes.colorTheme),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Host Control Buttons (moved from top bar)
          if (widget.isHost) ...[
            Divider(color: Colors.grey.shade300),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildHostControlButton(
                    icon: Icons.person_add,
                    label: 'Invite Co-Host',
                    onTap: () => _showCoHostInvitationSheet(),
                    color: ColorRes.colorTheme,
                  ),
                  GetBuilder<PKBattleController>(
                    init: PKBattleController(widget.channelName),
                    builder: (controller) {
                      final isRunning = controller.battleType == BattleType.running;
                      final isWaiting = controller.battleType == BattleType.waiting;
                      
                      if (isWaiting) {
                        return _buildHostControlButton(
                          icon: Icons.timer,
                          label: 'Battle Starting...',
                          onTap: null, // Disabled during waiting
                          color: Colors.orange,
                        );
                      }
                      
                      return _buildHostControlButton(
                        icon: isRunning ? Icons.stop : Icons.sports_mma,
                        label: isRunning ? 'Stop PK Battle' : 'Start PK Battle',
                        onTap: isRunning ? () => _stopPKBattle(controller) : () => _startPKBattle(controller),
                        color: Colors.red,
                      );
                    },
                  ),
                  if (_hasActiveCoHost()) 
                    _buildHostControlButton(
                      icon: Icons.person_remove,
                      label: 'Remove Co-Host',
                      onTap: () => _showRemoveCoHostDialog(),
                      color: Colors.red,
                    ),
                ],
              ),
            ),
            Divider(color: Colors.grey.shade300),
          ],

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsTab(),
                _buildAudienceTab(),
                _buildInvitedTab(),
                _buildCoHostsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_filteredUsers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_add_outlined,
        title: 'No Join Requests Yet',
        subtitle: 'View and manage audience requests to join the live stream.',
      );
    }

    return ListView.builder(
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserTile(
          user: user,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _acceptJoinRequest(user),
                icon: Icon(Icons.check, color: Colors.green),
              ),
              IconButton(
                onPressed: () => _declineJoinRequest(user),
                icon: Icon(Icons.close, color: Colors.red),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAudienceTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_filteredUsers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'No Audience Yet',
        subtitle: 'Viewers will appear here when they join your live stream.',
      );
    }

    return ListView.builder(
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserTile(
          user: user,
          trailing: widget.isHost
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _inviteAsCoHost(user),
                      icon: Icon(Icons.videocam, color: ColorRes.colorTheme),
                      tooltip: 'Invite as Co-host',
                    ),
                    IconButton(
                      onPressed: () => _muteUser(user),
                      icon: Icon(Icons.mic_off, color: Colors.grey),
                      tooltip: 'Mute',
                    ),
                    IconButton(
                      onPressed: () => _removeUser(user),
                      icon: Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Remove',
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }

  Widget _buildInvitedTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_filteredUsers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.mail_outline,
        title: 'No One Invited',
        subtitle: 'You haven\'t invited anyone yet. Invited users will be listed here.',
      );
    }

    return ListView.builder(
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserTile(
          user: user,
          trailing: widget.isHost
              ? IconButton(
                  onPressed: () => _cancelInvitation(user),
                  icon: Icon(Icons.cancel, color: Colors.red),
                  tooltip: 'Cancel Invitation',
                )
              : null,
        );
      },
    );
  }

  Widget _buildCoHostsTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_filteredUsers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.co_present,
        title: 'No Co-hosts',
        subtitle: 'Co-hosts will appear here when they join your live stream.',
      );
    }

    return ListView.builder(
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserTile(
          user: user,
          trailing: widget.isHost
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _muteCoHost(user),
                      icon: Icon(Icons.mic_off, color: Colors.grey),
                      tooltip: 'Mute',
                    ),
                    IconButton(
                      onPressed: () => _removeCoHost(user),
                      icon: Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Remove Co-host',
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontFamily: FontRes.fNSfUiSemiBold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile({
    required UserData user,
    Widget? trailing,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: user.userProfile != null && user.userProfile!.isNotEmpty
            ? CachedNetworkImageProvider(user.userProfile!)
            : null,
        child: user.userProfile == null || user.userProfile!.isEmpty
            ? Text(
                (user.fullName?.isNotEmpty == true ? user.fullName! : user.userName ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
        backgroundColor: ColorRes.colorTheme,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              user.fullName ?? user.userName ?? 'Unknown User',
              style: TextStyle(
                fontFamily: FontRes.fNSfUiSemiBold,
                fontSize: 16,
              ),
            ),
          ),
          if (user.isVerify == 1)
            Icon(
              Icons.verified,
              color: Colors.blue,
              size: 18,
            ),
        ],
      ),
      subtitle: user.userName != null
          ? Text(
              user.userName!,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            )
          : null,
      trailing: trailing,
    );
  }

  // Action methods
  Future<void> _inviteAsCoHost(UserData user) async {
    try {
      await _db
          .collection(FirebaseRes.liveStreamUser)
          .doc(widget.channelName)
          .collection('co_host_invitations')
          .doc(user.identity)
          .set({
        'userId': user.userId,
        'userName': user.userName,
        'fullName': user.fullName,
        'userImage': user.userProfile,
        'invitedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'hostId': _pref.getUser()?.data?.userId,
      });

      Get.snackbar(
        'Invitation Sent',
        'Co-host invitation sent to ${user.fullName ?? user.userName}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      if (widget.onCoHostInvited != null) {
        widget.onCoHostInvited!(user.identity ?? '');
      }

      _loadMembersData(); // Refresh data
    } catch (e) {
      print('Error inviting co-host: $e');
      Get.snackbar(
        'Error',
        'Failed to send invitation. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _acceptJoinRequest(UserData user) async {
    // Implement join request acceptance logic
    print('Accepting join request for ${user.userName}');
  }

  Future<void> _declineJoinRequest(UserData user) async {
    // Implement join request decline logic
    print('Declining join request for ${user.userName}');
  }

  Future<void> _muteUser(UserData user) async {
    // Implement user muting logic
    print('Muting user ${user.userName}');
  }

  Future<void> _removeUser(UserData user) async {
    // Implement user removal logic
    print('Removing user ${user.userName}');
  }

  Future<void> _cancelInvitation(UserData user) async {
    try {
      await _db
          .collection(FirebaseRes.liveStreamUser)
          .doc(widget.channelName)
          .collection('co_host_invitations')
          .doc(user.identity)
          .delete();

      Get.snackbar(
        'Invitation Cancelled',
        'Co-host invitation cancelled',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      _loadMembersData(); // Refresh data
    } catch (e) {
      print('Error cancelling invitation: $e');
    }
  }

  Future<void> _muteCoHost(UserData user) async {
    // Implement co-host muting logic
    print('Muting co-host ${user.userName}');
  }

  Future<void> _removeCoHost(UserData user) async {
    try {
      // Show confirmation dialog
      bool? confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Remove Co-Host'),
          content: Text('Are you sure you want to remove ${user.fullName ?? user.userName} as co-host? They will be moved back to audience.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Remove', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Remove from co-hosts subcollection
      await _db
          .collection(FirebaseRes.liveStreamUser)
          .doc(widget.channelName)
          .collection('co_hosts')
          .doc(user.identity)
          .delete();

      // Get the co-host's Agora UID from the document before deletion
      final coHostDoc = await _db
          .collection(FirebaseRes.liveStreamUser)
          .doc(widget.channelName)
          .collection('co_hosts')
          .where('userId', isEqualTo: user.userId)
          .get();

      int? coHostUID;
      if (coHostDoc.docs.isNotEmpty) {
        coHostUID = coHostDoc.docs.first.data()['agoraUID'];
      }

      // Remove co-host UID from main document if we found it
      if (coHostUID != null) {
        await _db.collection(FirebaseRes.liveStreamUser).doc(widget.channelName).update({
          'coHostUIDs': FieldValue.arrayRemove([coHostUID]),
        });
      }

      // Send notification to co-host about removal
      await _db
          .collection(FirebaseRes.liveStreamUser)
          .doc(widget.channelName)
          .collection('co_host_notifications')
          .add({
        'type': 'removed',
        'userId': user.userId,
        'coHostUID': coHostUID,
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'You have been removed as co-host by the host',
      });

      Get.snackbar(
        'Co-host Removed',
        '${user.fullName ?? user.userName} has been removed as co-host',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      // Notify parent widget about co-host removal
      if (widget.onCoHostRemoved != null) {
        widget.onCoHostRemoved!();
      }

      _loadMembersData(); // Refresh data
    } catch (e) {
      print('Error removing co-host: $e');
      Get.snackbar(
        'Error',
        'Failed to remove co-host. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Helper methods for the new host control buttons
  Widget _buildHostControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: onTap != null ? color : color.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: FontRes.fNSfUiSemiBold,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCoHostInvitationSheet() {
    Get.bottomSheet(
      CoHostInvitationSheet(
        roomId: widget.channelName,
        commentList: widget.commentList,
        onInviteUser: (user) async {
          print('Sending co-host invitation to: ${user.userId}');
          
          try {
            await _pref.initPref();
            final currentUser = _pref.getUser();
            
            if (currentUser?.data?.userId != null) {
              final success = await CoHostInvitationService.sendInvitation(
                roomId: widget.channelName,
                invitedUser: user,
                hostUserId: currentUser!.data!.userId!,
              );
              
              if (success) {
                Get.snackbar(
                  'Invitation Sent',
                  'Co-host invitation sent to ${user.fullName ?? user.userName}',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  duration: Duration(seconds: 3),
                );
                
                if (widget.onCoHostInvited != null) {
                  widget.onCoHostInvited!(user.userId.toString());
                }
                
                _loadMembersData(); // Refresh data
              } else {
                Get.snackbar(
                  'Error',
                  'Failed to send invitation. Please try again.',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  duration: Duration(seconds: 3),
                );
              }
            }
          } catch (e) {
            print('Error sending invitation: $e');
            Get.snackbar(
              'Error',
              'An error occurred while sending the invitation.',
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: Duration(seconds: 3),
            );
          }
        },
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  void _startPKBattle(PKBattleController controller) {
    Get.dialog(
      AlertDialog(
        title: Text('Start PK Battle'),
        content: Text('Are you ready to start the PK Battle with your co-host?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              try {
                controller.initiateBattle();
                Get.snackbar(
                  'PK Battle Started',
                  'The PK Battle has begun!',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                print('Error starting PK Battle: $e');
                Get.snackbar(
                  'Error',
                  'Failed to start PK Battle. Please try again.',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Start Battle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _stopPKBattle(PKBattleController controller) {
    Get.dialog(
      AlertDialog(
        title: Text('Stop PK Battle'),
        content: Text('Are you sure you want to end the PK Battle?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              try {
                controller.endBattle();
                Get.snackbar(
                  'PK Battle Ended',
                  'The PK Battle has been stopped.',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
              } catch (e) {
                print('Error stopping PK Battle: $e');
                Get.snackbar(
                  'Error',
                  'Failed to stop PK Battle. Please try again.',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Stop Battle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  bool _hasActiveCoHost() {
    // Use the model's coHostID if available, otherwise fall back to local data
    if (widget.model != null && widget.model.coHostID != null) {
      return true;
    }
    return _coHostUsers.isNotEmpty;
  }

  void _showRemoveCoHostDialog() {
    // Use the model's removeCoHost method if available
    if (widget.model != null && widget.model.coHostID != null) {
      Get.dialog(
        AlertDialog(
          title: Text('Remove Co-Host'),
          content: Text('Are you sure you want to remove the current co-host? They will be moved back to audience.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                try {
                  widget.model.removeCoHost();
                  Get.snackbar(
                    'Co-host Removed',
                    'Co-host has been removed successfully',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  
                  // Notify parent widget about co-host removal
                  if (widget.onCoHostRemoved != null) {
                    widget.onCoHostRemoved!();
                  }
                } catch (e) {
                  print('Error removing co-host: $e');
                  Get.snackbar(
                    'Error',
                    'Failed to remove co-host. Please try again.',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Remove', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    // Fallback to Firebase-based approach if model is not available
    if (_coHostUsers.isEmpty) {
      Get.snackbar(
        'No Co-Host',
        'There are no active co-hosts to remove.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Show dialog with list of co-hosts to remove
    Get.dialog(
      AlertDialog(
        title: Text('Remove Co-Host'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select a co-host to remove:'),
            SizedBox(height: 16),
            Container(
              height: 200,
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: _coHostUsers.length,
                itemBuilder: (context, index) {
                  final coHost = _coHostUsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: coHost.userProfile != null && coHost.userProfile!.isNotEmpty
                          ? CachedNetworkImageProvider(coHost.userProfile!)
                          : null,
                      child: coHost.userProfile == null || coHost.userProfile!.isEmpty
                          ? Text((coHost.fullName?.isNotEmpty == true ? coHost.fullName! : coHost.userName ?? 'U')[0].toUpperCase())
                          : null,
                      backgroundColor: ColorRes.colorTheme,
                    ),
                    title: Text(coHost.fullName ?? coHost.userName ?? 'Unknown User'),
                    subtitle: coHost.userName != null ? Text(coHost.userName!) : null,
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        Get.back(); // Close the dialog
                        _removeCoHost(coHost);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }


}

