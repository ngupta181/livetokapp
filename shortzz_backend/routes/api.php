<?php
/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

use App\Http\Controllers\Admin\SettingsController;
use Illuminate\Support\Facades\Route;

    Route::post('login', 'API\UserController@Registration')->name('login')->middleware('security');
    //Route::post('login', 'API\UserController@Registration')->name('login');    
    Route::get('getVersion','API\AppVersionController@getVersion');
    Route::get('v/{shortCode}', 'API\PostController@resolveShareableLink');
    Route::prefix('User')->middleware('security')->group(function () {
    Route::post('Registration', 'API\UserController@Registration');
    Route::post('getProfile', 'API\UserController@getProfile');
    Route::get('getUserLevel', 'API\UserController@getUserLevel');
    Route::post('updateUserLevelPoints', 'API\UserController@updateUserLevelPoints')->middleware('wallet.security');
});

Route::prefix('Post')->group(function () {
    Route::post('getUserVideos', 'API\PostController@getUserVideos');
    Route::post('getUserLikesVideos', 'API\PostController@getUserLikesVideos');
    Route::post('getPostList', 'API\PostController@getPostList');
    Route::post('getFollowerList', 'API\PostController@getFollowerList');
    Route::post('getFollowingList', 'API\PostController@getFollowingList');
    Route::post('getUserSearchPostList', 'API\PostController@getUserSearchPostList');
    Route::post('getSearchPostList', 'API\PostController@getSearchPostList');
    Route::post('getExploreHashTagPostList', 'API\PostController@getExploreHashTagPostList');
    Route::post('getSingleHashTagPostList', 'API\PostController@getSingleHashTagPostList');
    Route::post('ReportPost', 'API\PostController@ReportPost');
    Route::post('getPostListById', 'API\PostController@getPostListById');
    Route::post('getPostBySoundId', 'API\PostController@getPostBySoundId');
    Route::post('getCommentByPostId', 'API\PostController@getCommentByPostId');
});

// Route::prefix('Recommendation')->group(function () {
//     Route::post('getRecommendations', 'API\RecommendationController@getRecommendations');
// });

Route::prefix('Recommendation')->group(function () {
    Route::post('getRecommendations', 'API\RecommendationController@getRecommendations');
    Route::post('trackInteraction', 'API\RecommendationController@trackInteraction'); // Move here temporarily
});

Route::post('fetchSettingsData', [SettingsController::class, 'fetchSettingsData']);

Route::post('uploadFileGivePath', 'API\PostController@uploadFileGivePath');

Route::group(['middleware' => ['auth:api', 'security']], function () {
    
    //Route::get('getVersion','API\AppVersionController@getVersion');

    Route::prefix('User')->group(function () {
        Route::post('Logout', 'API\UserController@Logout');
        Route::post('updateProfile', 'API\UserController@updateProfile');
        Route::post('verifyRequest', 'API\UserController@verifyRequest');
        Route::post('checkUsername', 'API\UserController@checkUsername');
        Route::post('getNotificationList', 'API\UserController@getNotificationList');
        Route::post('setNotificationSettings', 'API\UserController@setNotificationSettings');
        Route::get('getProfileCategoryList', 'API\UserController@getProfileCategoryList');
        Route::post('blockUser', 'API\UserController@blockUser');
        Route::post('deleteMyAccount', 'API\UserController@deleteMyAccount');
        Route::post('pushNotificationToSingleUser', 'API\UserController@pushNotificationToSingleUser');
        Route::post('generateAgoraToken', 'API\UserController@generateAgoraToken');
        Route::post('uploadContactsCsv', 'API\UserController@uploadContactsCsv');

    });

    Route::prefix('Post')->group(function () {
        Route::post('addPost', 'API\PostController@addPost');
        Route::post('deletePost', 'API\PostController@deletePost');
        Route::post('LikeUnlikePost', 'API\PostController@LikeUnlikePost');
        Route::post('FollowUnfollowPost', 'API\PostController@FollowUnfollowPost');
        Route::get('getSoundList', 'API\PostController@getSoundList');
        Route::post('getSoundByCategoryId', 'API\PostController@getSoundByCategoryId');
        Route::post('getSearchSoundList', 'API\PostController@getSearchSoundList');
        Route::post('IncreasePostViewCount', 'API\PostController@IncreasePostViewCount');
        Route::post('addComment', 'API\PostController@addComment');
        Route::post('deleteComment', 'API\PostController@deleteComment');
        Route::post('editComment', 'API\PostController@editComment');
        Route::post('likeComment', 'API\PostController@likeComment');
        Route::post('getFavouriteSoundList', 'API\PostController@getFavouriteSoundList');
        Route::post('bookMarkedPost', 'API\PostController@bookMarkedPost');
        Route::post('getBookmarkPostList', 'API\PostController@getBookmarkPostList');
        Route::post('generate-share-link', 'API\PostController@generateShareableLink');

    });

    Route::prefix('Wallet')->middleware(['security', 'wallet.security'])->group(function () {
        Route::post('addCoin', 'API\WalletController@addCoin');
        Route::post('sendCoin', 'API\WalletController@sendCoin');
        Route::post('purchaseCoin', 'API\WalletController@purchaseCoin');
        Route::get('getMyWalletCoin', 'API\WalletController@getMyWalletCoin');
        Route::get('getCoinPlanList', 'API\WalletController@getCoinPlanList');
        Route::post('redeemRequest', 'API\WalletController@redeemRequest');
        Route::post('getTransactionHistory', 'API\WalletController@getTransactionHistory');

    });

    // PK Battle Routes
    Route::prefix('PkBattle')->group(function () {
        Route::post('createBattle', 'API\PkBattleController@createBattle');
        Route::post('respondToBattle', 'API\PkBattleController@respondToBattle');
        Route::get('getActiveBattles', 'API\PkBattleController@getActiveBattles');
        Route::post('getBattleDetails', 'API\PkBattleController@getBattleDetails');
        Route::post('sendBattleGift', 'API\PkBattleController@sendBattleGift');
        Route::post('endBattle', 'API\PkBattleController@endBattle');
        Route::post('cancelBattle', 'API\PkBattleController@cancelBattle');
        Route::post('cleanupMyBattles', 'API\PkBattleController@cleanupMyBattles');
        Route::get('getUserBattleHistory', 'API\PkBattleController@getUserBattleHistory');
    });
});

// User Level System
//Route::get('User/getUserLevel', 'API\UserController@getUserLevel');