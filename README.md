# LiveTok Flutter App

## Summary Changelog 

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

