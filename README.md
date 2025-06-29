# LiveTok Flutter App

## Summary Changelog 

**Date:** June 29 2025

### User Level System Implementation

#### New Files:
- `bubbly/icons/avatar_frame_1.png` - Level 1 avatar frame
- `bubbly/icons/avatar_frame_10.png` - Level 10 avatar frame
- `bubbly/icons/avatar_frame_20.png` - Level 20 avatar frame
- `bubbly/icons/avatar_frame_30.png` - Level 30 avatar frame
- `bubbly/icons/avatar_frame_40.png` - Level 40 avatar frame
- `bubbly/icons/avatar_frame_50.png` - Level 50 avatar frame
- `bubbly/lib/modal/user/user_level.dart` - User level model
- `bubbly/lib/utils/level_utils.dart` - Level calculation utilities
- `bubbly/lib/view/level/level_screen.dart` - Level information screen
- `bubbly/lib/view/live_stream/widget/gift_banner.dart` - Gift banner display
- `bubbly/lib/view/live_stream/widget/gift_queue_display.dart` - Gift queue management
- `bubbly/lib/view/live_stream/widget/level_up_animation.dart` - Level up animation
- `bubbly/lib/view/live_stream/widget/level_up_animation_controller.dart` - Level animation controller
- `bubbly/lib/view/live_stream/widget/live_stream_comment_item.dart` - Live stream comment item
- `bubbly/lib/view/live_stream/widget/top_viewers_row.dart` - Top viewers display
- `bubbly/lib/view/live_stream/widget/viewers_dialog.dart` - Viewers dialog
- `shortzz_backend/database/migrations/2023_09_15_000000_add_user_level_fields.php` - Database migration for user levels

#### Modified Files:
- `bubbly/lib/api/api_service.dart` - Added user level API integration
- `bubbly/lib/main.dart` - Main application updates for level system
- `bubbly/lib/modal/live_stream/live_stream.dart` - Updated for level integration
- `bubbly/lib/modal/user/user.dart` - Added user level properties
- `bubbly/lib/utils/const_res.dart` - Added level-related constants
- `bubbly/lib/utils/session_manager.dart` - Updated to store user level data
- `bubbly/lib/view/followers/follower_screen.dart` - Added level display
- `bubbly/lib/view/live_stream/model/broad_cast_screen_view_model.dart` - Updated for level system
- `bubbly/lib/view/live_stream/screen/audience_screen.dart` - Added level features
- `bubbly/lib/view/live_stream/screen/broad_cast_screen.dart` - Updated for level system
- `bubbly/lib/view/live_stream/widget/audience_top_bar.dart` - Added level display
- `bubbly/lib/view/live_stream/widget/broad_cast_top_bar_area.dart` - Updated for level system
- `bubbly/lib/view/live_stream/widget/full_screen_gift_animation.dart` - Enhanced with level info
- `bubbly/lib/view/live_stream/widget/gift_animation.dart` - Updated for level system
- `bubbly/lib/view/live_stream/widget/gift_animation_controller.dart` - Updated for level animations
- `bubbly/lib/view/live_stream/widget/gift_display.dart` - Added level information
- `bubbly/lib/view/live_stream/widget/live_stream_chat_list.dart` - Updated for level display
- `bubbly/lib/view/profile/widget/profile_card.dart` - Added level display
- `bubbly/lib/view/send_bubble/dialog_send_bubble.dart` - Updated for level system
- `shortzz_backend/app/Http/Controllers/API/UserController.php` - Added level management
- `shortzz_backend/app/Http/Controllers/API/WalletController.php` - Updated for level rewards
- `shortzz_backend/routes/api.php` - Added level-related endpoints

---------------------------------------------------------------------------------------------------------------

**Date:** June 23 2025

### Redis Caching Implementation

#### New Files:
- `shortzz_backend/REDIS_CACHING.md` - Redis caching documentation
- `shortzz_backend/REDIS_SETUP.md` - Redis setup instructions
- `shortzz_backend/app/CacheKeys.php` - Cache keys definitions
- `shortzz_backend/app/Providers/RedisCacheServiceProvider.php` - Redis cache service provider

#### Modified Files:
- `shortzz_backend/app/Http/Controllers/API/PostController.php` - Added Redis caching for posts
- `shortzz_backend/app/Http/Controllers/API/RecommendationController.php` - Implemented caching for recommendations
- `shortzz_backend/app/Http/Controllers/API/UserController.php` - Added user data caching
- `shortzz_backend/composer.json` - Updated dependencies for Redis
- `shortzz_backend/composer.json.dev` - Development environment Redis configuration
- `shortzz_backend/config/app.php` - Registered Redis cache service provider

---------------------------------------------------------------------------------------------------------------

**Date:** June 22 2025

### Rewarding Actions & Wallet Updates

#### Modified Files:
- `bubbly/lib/modal/app_version.dart` - App version model updates
- `bubbly/lib/view/send_bubble/dialog_send_bubble.dart` - Send bubble dialog modifications
- `bubbly/lib/view/setting/setting_screen.dart` - Settings screen updates
- `bubbly/lib/view/wallet/dialog_coins_plan.dart` - Updated coins plan dialog
- `bubbly/lib/view/wallet/wallet_screen.dart` - Wallet screen enhancements
- `bubbly/lib/utils/const_res.dart` - Updated constants
- `shortzz_backend/app/Http/Controllers/Admin/RewardingActionController.php` - Rewarding actions controller updates
- `shortzz_backend/resources/views/admin/rewarding_action/rewarding_action_list.blade.php` - Admin view updates
- `shortzz_backend/resources/views/admin_layouts/sidebar.blade.php` - Admin sidebar modifications
- `shortzz_backend/routes/web.php` - Updated web routes
- `shortzz_backend/routes/api.php` - Updated API routes

#### New Files:
- `bubbly/icons/icCoinOld.png` - New coin icon asset
- `shortzz_backend/app/RewardingAction.php` - New rewarding action model
- `shortzz_backend/database/migrations/2024_03_19_000000_create_rewarding_actions_table.php` - Database migration for rewarding actions

#### Modified Assets:
- `bubbly/icons/icCoin.png` - Updated coin icon

---------------------------------------------------------------------------------------------------------------

**Date:** June 19 2025

#### Modified Files:
- `bubbly/android/build.gradle` - Build configuration updates
- `bubbly/lib/main.dart` - Main application updates
- `bubbly/lib/modal/setting/setting.dart` - Settings model modifications
- `bubbly/lib/utils/ad_helper.dart` - Ad helper utility updates
- `bubbly/lib/view/explore/item_explore.dart` - Explore item UI modifications
- `bubbly/lib/view/hashtag/videos_by_hashtag.dart` - Hashtag videos screen updates
- `bubbly/lib/view/home/following_screen.dart` - Following screen modifications
- `bubbly/lib/view/home/for_u_screen.dart` - For You screen updates
- `bubbly/lib/view/video/item_video.dart` - Video item component changes
- `bubbly/pubspec.yaml` - Dependencies and configuration updates

#### New Files:
- `bubbly/lib/custom_view/native_ad_video.dart` - New native ad video component
- `bubbly/lib/utils/native_ad_manager.dart` - New native ad management utility

#### Deleted Files:
- `bubbly/lib/utils/ad_manager.dart` - Removed old ad manager implementation

---------------------------------------------------------------------------------------------------------------

**Date:** June 18 2025

### Transaction History Feature

#### Modified Files:
- `bubbly/lib/api/api_service.dart` - Added transaction history API integration
- `bubbly/lib/languages/languages_keys.dart` - Added new language keys for transaction screen
- `bubbly/lib/utils/const_res.dart` - Added new constants for wallet transactions
- `bubbly/lib/utils/url_res.dart` - Added new API endpoints for transactions
- `bubbly/lib/view/camera/camera_screen.dart` - UI adjustments
- `bubbly/lib/view/live_stream/model/broad_cast_screen_view_model.dart` - Updated model
- `bubbly/lib/view/preview_screen.dart` - UI adjustments
- `bubbly/lib/view/redeem/redeem_screen.dart` - Updated redeem functionality
- `bubbly/lib/view/video/widget/share_sheet.dart` - Modified sharing options
- `bubbly/lib/view/wallet/dialog_coins_plan.dart` - Updated coins plan dialog
- `bubbly/lib/view/wallet/wallet_screen.dart` - Added transaction history navigation
- `bubbly/pubspec.yaml` - Updated dependencies
- `shortzz_backend/app/Http/Controllers/API/WalletController.php` - Added transaction endpoints
- `shortzz_backend/app/Http/Controllers/Admin/RedeemRequestController.php` - Updated redeem request handling
- `shortzz_backend/routes/api.php` - Added new transaction routes

#### New Files:
- `bubbly/lib/modal/wallet/transaction_history.dart` - Transaction history model
- `bubbly/lib/view/wallet/transaction_history_screen.dart` - Transaction history UI screen
- `shortzz_backend/app/Transaction.php` - Transaction model for backend
- `shortzz_backend/database/migrations/2023_09_10_000000_create_transactions_table.php` - Database migration for transactions table

