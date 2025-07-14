import 'package:flutter/material.dart';
import 'package:bubbly/modal/pk_battle/livestream_user_state.dart';
import 'package:bubbly/modal/user/user.dart';
import 'package:bubbly/utils/pk_battle_config.dart';
import 'package:bubbly/custom_view/image_place_holder.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BattleUserView extends StatelessWidget {
  final LivestreamUserState userState;
  final bool isWinner;
  final bool isLeft;
  final VoidCallback? onTap;

  const BattleUserView({
    Key? key,
    required this.userState,
    this.isWinner = false,
    this.isLeft = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = userState.user;
    final teamColor = isLeft 
        ? Color(PKBattleConfig.redTeamColor) 
        : Color(PKBattleConfig.blueTeamColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.45,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: teamColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isWinner ? Colors.amber : teamColor,
            width: isWinner ? 3 : 2,
          ),
          boxShadow: isWinner
              ? [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            _buildUserAvatar(user, teamColor),
            const SizedBox(height: 8),
            _buildUserInfo(user, teamColor),
            const SizedBox(height: 8),
            _buildCoinDisplay(teamColor),
            if (isWinner) _buildWinnerBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(UserData? user, Color teamColor) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: teamColor,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: teamColor.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: user?.image != null
                ? CachedNetworkImage(
                    imageUrl: user!.image!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const ImagePlaceHolder(),
                    errorWidget: (context, url, error) => const ImagePlaceHolder(),
                  )
                : const ImagePlaceHolder(),
          ),
        ),
        // Mute indicator
        if (userState.isMuted)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.mic_off,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        // Video off indicator
        if (!userState.isVideoOn)
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.videocam_off,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        // Host/Co-host indicator
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: userState.isHost ? Colors.amber : teamColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              userState.isHost ? 'HOST' : 'CO-HOST',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo(UserData? user, Color teamColor) {
    return Column(
      children: [
        Text(
          user?.userName ?? 'Unknown',
          style: TextStyle(
            color: teamColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (user?.isVerified == true)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified,
                color: Colors.blue,
                size: 12,
              ),
              const SizedBox(width: 2),
              Text(
                'Verified',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 10,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildCoinDisplay(Color teamColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: teamColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: teamColor, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.monetization_on,
            color: teamColor,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            PKBattleConfig.formatCoins(userState.currentBattleCoin),
            style: TextStyle(
              color: teamColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerBadge() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber, Colors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          const Text(
            'WINNER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

