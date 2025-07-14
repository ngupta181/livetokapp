class PKBattleConfig {
  // Battle Timing Configuration
  static const int battleStartInSecond = 10;          // Countdown duration before battle starts
  static const int countdownDurationInSecond = 10;    // Countdown duration before battle starts
  static const int battleDurationInMinutes = 1;       // Battle duration in minutes
  static const int battleDurationInSecond = 60;       // Battle duration in seconds
  static const int battleEndMainViewInSecond = 10;    // Time to show end screen
  static const int battleCooldownDurationInSecond = 10; // Cooldown before next battle

  // Audio Assets
  static const String battleStartAudio = 'assets/sounds/battle_start.mp3';
  static const String endCountdownAudio = 'assets/sounds/end_countdown.mp3';
  static const String winSoundAudio = 'assets/sounds/win_sound.mp3';

  // Image Assets
  static const String battleViewIcon = 'assets/images/ic_battle_view.png';
  static const String crownIcon = 'assets/images/ic_crown.png';
  static const String vsIcon = 'assets/images/ic_vs.png';

  // UI Configuration
  static const int giftDialogDismissTime = 2;         // Gift animation time in seconds
  static const double battleProgressBarHeight = 8.0;
  static const double battleProgressBarWidth = 0.8;   // Percentage of screen width

  // Firebase Collection Names
  static const String liveStreamsCollection = 'livestreams';
  static const String userStateSubCollection = 'user_state';
  static const String commentsSubCollection = 'comments';

  // Firebase Field Names
  static const String battleStartedAtField = 'battleStartedAt';
  static const String battleWinnerField = 'battleWinner';
  static const String battleTypeField = 'battleType';
  static const String battleCreatedAtField = 'battleCreatedAt';
  static const String battleDurationField = 'battleDuration';
  static const String currentBattleCoinField = 'currentBattleCoin';
  static const String totalBattleCoinField = 'totalBattleCoin';
  static const String liveCoinField = 'liveCoin';
  static const String typeField = 'type';
  static const String watchingCountField = 'watchingCount';
  static const String hostIdField = 'hostId';
  static const String coHostIdsField = 'coHostIds';
  static const String roomIDField = 'roomID';

  // Battle Colors
  static const int redTeamColor = 0xFFFF4444;
  static const int blueTeamColor = 0xFF4444FF;
  static const int progressBarRedColor = 0xFFFF6B6B;
  static const int progressBarBlueColor = 0xFF4ECDC4;

  // Animation Durations
  static const int countdownAnimationDuration = 1000; // milliseconds
  static const int progressBarAnimationDuration = 300; // milliseconds
  static const int giftAnimationDuration = 2000; // milliseconds

  // Minimum Requirements
  static const int minViewersForBattle = 2;
  static const int minCoinsForGift = 1;

  // Battle States
  static const String battleStateInitiate = 'INITIATE';
  static const String battleStateWaiting = 'WAITING';
  static const String battleStateRunning = 'RUNNING';
  static const String battleStateEnd = 'END';

  // Livestream Types
  static const String livestreamTypeLive = 'LIVESTREAM';
  static const String livestreamTypeBattle = 'BATTLE';
  static const String livestreamTypeDummy = 'DUMMY';

  // User Types
  static const String userTypeHost = 'HOST';
  static const String userTypeCoHost = 'CO_HOST';
  static const String userTypeAudience = 'AUDIENCE';

  // Comment Types
  static const String commentTypeText = 'TEXT';
  static const String commentTypeGift = 'GIFT';
  static const String commentTypeJoin = 'JOIN';
  static const String commentTypeLeave = 'LEAVE';
  static const String commentTypeFollow = 'FOLLOW';

  // Error Messages
  static const String battleEndedGiftNotSent = 'Battle has ended, gift cannot be sent';
  static const String insufficientCoins = 'Insufficient coins to send gift';
  static const String battleAlreadyRunning = 'A battle is already running';
  static const String noCohostForBattle = 'No co-host available for battle';
  static const String networkError = 'Network error, please try again';

  // Success Messages
  static const String battleStarted = 'Battle started successfully';
  static const String giftSentSuccessfully = 'Gift sent successfully';
  static const String joinedBattle = 'Joined battle successfully';

  // Helper Methods
  static int get totalBattleSeconds => battleDurationInMinutes * 60;
  static int get totalBattleWithCountdownSeconds => totalBattleSeconds + battleStartInSecond;

  static String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  static String formatCoins(int coins) {
    if (coins >= 1000000) {
      return '${(coins / 1000000).toStringAsFixed(1)}M';
    } else if (coins >= 1000) {
      return '${(coins / 1000).toStringAsFixed(1)}K';
    }
    return coins.toString();
  }
}

