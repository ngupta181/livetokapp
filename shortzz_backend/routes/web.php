<?php

use App\Http\Controllers\Admin\SettingsController;
use App\Http\Controllers\PagesController;
use App\Http\Controllers\API\PostController;
use App\Http\Controllers\AccountController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('/', function () {
    return view('landing'); // This loads resources/views/landing.blade.php
});

Route::get('/account/remove', [AccountController::class, 'showRemovePage'])->name('account.remove');


// Legal and Contact Routes
Route::get('/privacy-policy', function () {
    return view('privacy-policy');
})->name('privacy-policy');

Route::get('/terms-of-service', function () {
    return view('terms');
})->name('terms');

Route::get('/contact', function () {
    return view('contact');
})->name('contact');


Route::get('/v/{shortCode}', [PostController::class, 'resolveShareableLink'])->name('resolve.share.link');

Route::get('/admin', 'Admin\AdminController@showLogin')->name('admin.login');
Route::post('dologin', 'Admin\AdminController@doLogin')->name('login.submit');
Route::get('logout/{flag}', 'Admin\AdminController@logout')->name('logout');

Route::get('privacypolicy', [PagesController::class, 'privacypolicy'])->name('privacypolicy');
Route::get('termsOfUse', [PagesController::class, 'termsOfUse'])->name('termsOfUse');

Route::group(array('middleware' => 'checkRole'), function () {

    Route::get('dashboard', 'Admin\AdminController@showDashboard')->name('dashboard');
    Route::get('my-profile', 'Admin\AdminController@MyProfile')->name('my-profile');
    Route::post('updateAdminProfile', 'Admin\AdminController@updateAdminProfile')->name('updateAdminProfile');


    Route::prefix('hash_tag')->group(function () {
        Route::get('list', 'Admin\HashTagsController@viewListHashTags')->name('hash_tag/list');
        Route::post('showHashTagsList', 'Admin\HashTagsController@showHashTagsList')->name('showHashTagsList');
        Route::post('ExploreHashtagImage', 'Admin\HashTagsController@ExploreHashtagImage')->name('ExploreHashtagImage');
        Route::post('RemoveExploreHashTags', 'Admin\HashTagsController@RemoveExploreHashTags')->name('RemoveExploreHashTags');
    });

    Route::prefix('user')->group(function () {
        Route::get('list', 'Admin\UserController@viewListUser')->name('user/list');
        Route::post('showUserList', 'Admin\UserController@showUserList')->name('showUserList');
        Route::get('view/{id}', 'Admin\UserController@viewUser')->name('user/view');
        Route::get('post/{id}', 'Admin\UserController@postUser')->name('user/post');
        Route::post('showUserPostList', 'Admin\UserController@showUserPostList')->name('showUserPostList');
        Route::post('deleteUser', 'Admin\UserController@deleteUser')->name('deleteUser');
        Route::post('sendNotification', 'Admin\UserController@sendNotification')->name('sendNotification');
    });

    Route::prefix('post')->group(function () {
        Route::get('list', 'Admin\PostController@viewListPost')->name('post/list');
        Route::post('showPostList', 'Admin\PostController@showPostList')->name('showPostList');
        Route::post('deletePost', 'Admin\PostController@deletePost')->name('deletePost');
        Route::post('ChangeTrendingStatus', 'Admin\PostController@ChangeTrendingStatus')->name('ChangeTrendingStatus');
    });

    Route::prefix('sound')->group(function () {
        Route::get('list', 'Admin\SoundController@viewListSound')->name('sound/list');
        Route::post('showSoundList', 'Admin\SoundController@showSoundList')->name('showSoundList');
        Route::post('getSoundByID', 'Admin\SoundController@getSoundByID')->name('getSoundByID');
        Route::post('addUpdateSound', 'Admin\SoundController@addUpdateSound')->name('addUpdateSound');
        Route::post('deleteSound', 'Admin\SoundController@deleteSound')->name('deleteSound');
    });
    
    Route::prefix('sound_category')->group(function () {
        Route::get('list', 'Admin\SoundController@viewListSoundCategory')->name('sound_category/list');
        Route::post('showSoundCategoryList', 'Admin\SoundController@showSoundCategoryList')->name('showSoundCategoryList');
        Route::post('addUpdateSoundCategory', 'Admin\SoundController@addUpdateSoundCategory')->name('addUpdateSoundCategory');
        Route::post('deleteSoundCategory', 'Admin\SoundController@deleteSoundCategory')->name('deleteSoundCategory');
    });

    Route::prefix('profile_category')->group(function () {
        Route::get('list', 'Admin\UserController@viewListProfileCategory')->name('profile_category/list');
        Route::post('showProfileCategoryList', 'Admin\UserController@showProfileCategoryList')->name('showProfileCategoryList');
        Route::post('addUpdateProfileCategory', 'Admin\UserController@addUpdateProfileCategory')->name('addUpdateProfileCategory');
        Route::post('deleteProfileCategory', 'Admin\UserController@deleteProfileCategory')->name('deleteProfileCategory');
    });

    Route::prefix('verification_request')->group(function () {
        Route::get('list', 'Admin\VerificationRequestController@viewListVerificationRequest')->name('verification_request/list');
        Route::post('showVerificationRequestList', 'Admin\VerificationRequestController@showVerificationRequestList')->name('showVerificationRequestList');
        Route::post('addUpdateVerificationRequest', 'Admin\VerificationRequestController@addUpdateVerificationRequest')->name('addUpdateVerificationRequest');
        Route::post('deleteVerificationRequest', 'Admin\VerificationRequestController@deleteVerificationRequest')->name('deleteVerificationRequest');
        Route::post('verifyRequest', 'Admin\VerificationRequestController@verifyRequest')->name('verifyRequest');
    });

    Route::prefix('report')->group(function () {
        Route::get('list', 'Admin\ReportController@viewListReport')->name('report/list');
        Route::post('showReportList', 'Admin\ReportController@showReportList')->name('showReportList');
        Route::post('showReportPostList', 'Admin\ReportController@showReportPostList')->name('showReportPostList');
        Route::post('deleteReport', 'Admin\ReportController@deleteReport')->name('deleteReport');
        Route::post('confirmReport', 'Admin\ReportController@confirmReport')->name('confirmReport');
    });

    Route::prefix('coin_plan')->group(function () {
        Route::get('list', 'Admin\CoinController@viewListCoinPlan')->name('coin_plan/list');
        Route::post('showCoinPlanList', 'Admin\CoinController@showCoinPlanList')->name('showCoinPlanList');
        Route::post('addUpdateCoinPlan', 'Admin\CoinController@addUpdateCoinPlan')->name('addUpdateCoinPlan');
        Route::post('deleteCoinPlan', 'Admin\CoinController@deleteCoinPlan')->name('deleteCoinPlan');
    });
    Route::prefix('gifts')->group(function () {
        Route::get('list', 'Admin\CoinController@viewListGifts')->name('gifts/list');
        Route::post('showGiftsList', 'Admin\CoinController@showGiftsList')->name('showGiftsList');
        Route::post('addUpdateGift', 'Admin\CoinController@addUpdateGift')->name('addUpdateGift');
        Route::post('deleteGift', 'Admin\CoinController@deleteGift')->name('deleteGift');
    });

    Route::prefix('redeem_request')->group(function () {
        Route::get('list', 'Admin\RedeemRequestController@viewListRedeemRequest')->name('redeem_request/list');
        Route::post('showRedeemRequestList', 'Admin\RedeemRequestController@showRedeemRequestList')->name('showRedeemRequestList');
        Route::post('changeRedeemRequestStatus', 'Admin\RedeemRequestController@changeRedeemRequestStatus')->name('changeRedeemRequestStatus');
    });
    Route::prefix('settings')->group(function () {
        Route::get('list', [SettingsController::class, 'viewSettings'])->name('settings/list');
        Route::post('updateGlobalSettings', [SettingsController::class, 'updateGlobalSettings'])->name('updateGlobalSettings');
        Route::post('changeCompressStatus', [SettingsController::class, 'changeCompressStatus'])->name('changeCompressStatus');
        Route::post('changeContentModerationStatus', [SettingsController::class, 'changeContentModerationStatus'])->name('changeContentModerationStatus');
    });
    
   Route::prefix('rewarding_action')->group(function () {
        Route::get('list', 'Admin\RewardingActionController@viewListRewardingAction')->name('rewarding_action/list');
        Route::post('showRewardingActionList', 'Admin\RewardingActionController@showRewardingActionList')->name('showRewardingActionList');
        Route::post('updateRewardingAction', 'Admin\RewardingActionController@updateRewardingAction')->name('updateRewardingAction');
        Route::post('deleteRewardingAction', 'Admin\RewardingActionController@deleteRewardingAction')->name('deleteRewardingAction');
    });

    // Pages Routes
    Route::get('viewPrivacy', [PagesController::class, 'viewPrivacy'])->name('viewPrivacy');
    Route::post('updatePrivacy', [PagesController::class, 'updatePrivacy'])->name('updatePrivacy');
    Route::get('viewTerms', [PagesController::class, 'viewTerms'])->name('viewTerms');
    Route::post('updateTerms', [PagesController::class, 'updateTerms'])->name('updateTerms');
    
   // Bulk Video Upload Routes
    Route::get('bulk-video-upload', 'Admin\PostController@viewBulkUpload')->name('admin.bulk-video-upload');
    Route::get('bulk-video-upload/template', 'Admin\PostController@downloadTemplate')->name('admin.bulk-video-upload.template');
    Route::post('bulk-video-upload', 'Admin\PostController@bulkVideoUpload')->name('admin.bulk-video-upload.process');
    
    // Blocked IPs Management Routes
    Route::prefix('blocked-ips')->group(function () {
        Route::get('list', 'Admin\BlockedIpController@index')->name('admin.blocked-ips.index');
        Route::get('create', 'Admin\BlockedIpController@create')->name('admin.blocked-ips.create');
        Route::post('store', 'Admin\BlockedIpController@store')->name('admin.blocked-ips.store');
        Route::get('show/{ip}', 'Admin\BlockedIpController@show')->name('admin.blocked-ips.show');
        Route::get('unblock/{id}', 'Admin\BlockedIpController@unblock')->name('admin.blocked-ips.unblock');
        Route::get('export', 'Admin\BlockedIpController@export')->name('admin.blocked-ips.export');
        Route::get('cleanup', 'Admin\BlockedIpController@cleanup')->name('admin.blocked-ips.cleanup');
        Route::post('block-ajax', 'Admin\BlockedIpController@blockIpAjax')->name('admin.blocked-ips.block-ajax');
        Route::post('unblock-ajax', 'Admin\BlockedIpController@unblockIpAjax')->name('admin.blocked-ips.unblock-ajax');
    });
    
});
