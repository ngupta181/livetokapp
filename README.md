# LiveTok Flutter App

**Date:** June 18 2025

## Summary Changelog 

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
