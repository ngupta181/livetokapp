<?php

namespace App\Http\Controllers\API;

use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
use Illuminate\Validation\Rule;
use Laravel\Passport\Token;
use Hash;
use DB;
use File;
use Log;
use Storage;
use App\User;
use App\Admin;
use App\Post;
use App\Followers;
use App\Like;
use App\Bookmark;
use App\Comments;
use App\Report;
use App\ProfileCategory;
use App\VerificationRequest;
use App\Notification;
use App\BlockUser;
use App\CacheKeys;
use App\Classes\AgoraDynamicKey\RtcTokenBuilder;
use App\Common;
use App\GlobalFunction;
use App\RedeemRequest;
use Illuminate\Support\Carbon;
use Google\Client;
use Illuminate\Support\Facades\File as FacadesFile;
use Illuminate\Support\Facades\Validator;

class UserController extends Controller
{

    public static function pushNotificationToSingleUser(Request $request)
    {
        $client = new Client();
        $client->setAuthConfig(base_path('googleCredentials.json'));
        $client->addScope('https://www.googleapis.com/auth/firebase.messaging');
        $client->fetchAccessTokenWithAssertion();
        $accessToken = $client->getAccessToken();
        $accessToken = $accessToken['access_token'];

        // Log::info($accessToken);
        $contents = FacadesFile::get(base_path('googleCredentials.json'));
        $json = json_decode(json: $contents, associative: true);

        $url = 'https://fcm.googleapis.com/v1/projects/'.$json['project_id'].'/messages:send';
        // $notificationArray = array('title' => $title, 'body' => $message);

        // $device_token = $user->device_token;

        $fields = $request->json()->all();

        // $fields = array(
        //     'message'=> [
        //         'token'=> $device_token,
        //         'notification' => $notificationArray,
        //     ]
        // );

        $headers = array(
            'Content-Type:application/json',
            'Authorization:Bearer ' . $accessToken
        );
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fields));
        // print_r(json_encode($fields));
        $result = curl_exec($ch);
        // Log::debug($result);

        if ($result === FALSE) {
            die('FCM Send Error: ' . curl_error($ch));
        }
        curl_close($ch);

        // return $response;
        return response()->json(['result'=> $result, 'fields'=> $fields]);

    }

    public function generateAgoraToken(Request $request)
    {
        $headers = $request->headers->all();

        $verify_request_base = Admin::verify_request_base($headers);

        if (isset($verify_request_base['status']) && $verify_request_base['status'] == 401) {
            return response()->json(['success_code' => 401, 'message' => "Unauthorized Access!"]);
            exit();
        }
        $rules = [
            'channelName' => 'required'
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }
        $appID = env('AGORA_APP_ID');
        $appCertificate = env('AGORA_APP_CERT');
        $channelName = $request->channelName;
        $role = RtcTokenBuilder::RolePublisher;
        $expireTimeInSeconds = 7200;
        $currentTimestamp = now()->getTimestamp();
        $privilegeExpiredTs = $currentTimestamp + $expireTimeInSeconds;
        $token = RtcTokenBuilder::buildTokenWithUid($appID, $appCertificate, $channelName, 0, $role, $privilegeExpiredTs);

        return json_encode(['status' => 200, 'message' => "token generated successfully", 'token' => $token]);
    }

    public function Registration(Request $request)
    {


        $headers = $request->headers->all();

        $verify_request_base = Admin::verify_request_base($headers);

        if (isset($verify_request_base['status']) && $verify_request_base['status'] == 401) {
            return response()->json(['success_code' => 401, 'message' => "Unauthorized Access!"]);
            exit();
        }

        $rules = [
            'full_name' => 'required',
            'user_email' => 'required',
            'device_token' => 'required',
            'user_name' => 'required', //|unique:tbl_users
            'identity' => 'required',
            'login_type' => 'required',
            'platform' => 'required',
        ];

        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => 401, 'message' => $msg]);
        }

        $CheckUSer =  User::where('identity', $request->get('identity'))->first();

        if (empty($CheckUSer)) {

            $data['full_name'] = $request->get('full_name');
            $data['user_email'] = $request->get('user_email');
            $data['device_token'] = $request->get('device_token');
            $data['user_name'] = Common::generateUniqueUserId();
            $data['identity'] = $request->get('identity');
            $data['login_type'] = $request->get('login_type');
            $data['platform'] = $request->get('platform');

            $result = User::insert($data);

            if (!empty($result)) {
                $user_id = DB::getPdo()->lastInsertId();
                $User =  User::where('user_id', $user_id)->first();

                $User['token'] = 'Bearer ' . $User->createToken('LiveTok')->accessToken;
                $User['followers_count'] = Followers::where('to_user_id', $user_id)->count();
                $User['following_count'] = Followers::where('from_user_id', $user_id)->count();
                $User['my_post_likes'] = Post::select('tbl_post.*')->leftjoin('tbl_likes as l', 'l.post_id', 'tbl_post.post_id')->where('tbl_post.user_id', $user_id)->count();
                $profile_category_data = ProfileCategory::where('profile_category_id', $User->profile_category)->first();
                $User['profile_category_name'] = !empty($profile_category_data) ? $profile_category_data['profile_category_name'] : "";
                unset($User->timezone);
                unset($User->created_at);
                unset($User->updated_at);

                return response()->json(['status' => 200, 'message' => "User Registered Successfully.", 'data' => $User]);
            } else {
                return response()->json(['status' => 401, 'message' => "Error While User Registration"]);
            }
        } else {
            $identity = $request->get('identity');
            $data['device_token'] = $request->get('device_token');

            $data['login_type'] = $request->get('login_type');
            $data['platform'] = $request->get('platform');

            $user_id = $CheckUSer->user_id;
            $result =  User::where('identity', $identity)->update($data);

            $User =  User::where('user_id', $user_id)->first();
            $User['platform'] = $User->platform ? (int)$User->platform : 0;
            $User['is_verify'] = $User->is_verify ? (int)$User->is_verify : 0;
            $User['my_wallet'] = $User->my_wallet ? (int)$User->my_wallet : 0;

            $User['status'] = $User->status ? (int)$User->status : 0;
            $User['freez_or_not'] = $User->freez_or_not ? (int)$User->freez_or_not : 0;

            $User['token'] = 'Bearer ' . $User->createToken('LiveTok')->accessToken;
            $User['followers_count'] = Followers::where('to_user_id', $user_id)->count();
            $User['following_count'] = Followers::where('from_user_id', $user_id)->count();
            $User['my_post_likes'] = Post::select('tbl_post.*')->leftjoin('tbl_likes as l', 'l.post_id', 'tbl_post.post_id')->where('tbl_post.user_id', $user_id)->count();
            $profile_category_data = ProfileCategory::where('profile_category_id', $User->profile_category)->first();
            $User['profile_category_name'] = !empty($profile_category_data) ? $profile_category_data['profile_category_name'] : "";
            $User['user_mobile_no'] = $User->user_mobile_no ? $User->user_mobile_no : "";
            $User['user_profile'] = $User->user_profile ? $User->user_profile : "";
            $User['bio'] = $User->bio ? $User->bio : "";
            $User['profile_category'] = $User->profile_category ? $User->profile_category : "";
            $User['fb_url'] = $User->fb_url ? $User->fb_url : "";
            $User['insta_url'] = $User->insta_url ? $User->insta_url : "";
            $User['youtube_url'] = $User->youtube_url ? $User->youtube_url : "";

            unset($User->timezone);
            unset($User->created_at);
            unset($User->updated_at);

            return response()->json(['status' => 200, 'message' => "User registered successfully.", 'data' => $User]);
        }
    }

    public function Logout()
    {


        if (Auth::check()) {
            $user = Auth::user();
            $accessToken = Auth::user()->token();
            if (isset($user->user_id)) {
                DB::table('oauth_access_tokens')->where('id', $accessToken->id)->delete();
                $data['device_token'] = "";
                $data['platform'] = 0;
                $result =  User::where('user_id', $user->user_id)->update($data);
                return response()->json(['success_code' => 200, 'response_code' => 1, 'response_message' => "User logout successfully."]);
            } else {
                return response()->json(['success_code' => 401, 'response_code' => 0, 'response_message' => "User Id is required"]);
            }
        } else {
            return response()->json(['success_code' => 401, 'response_code' => 0, 'response_message' => "User Id is required"]);
        }
    }

    public function verifyRequest(Request $request)
    {

        $user_id = $request->user()->user_id;

        if (empty($user_id)) {
            $msg = "user id is required";
            return response()->json(['success_code' => 401, 'response_code' => 0, 'response_message' => $msg]);
        }


        $headers = $request->headers->all();

        $verify_request_base = Admin::verify_request_base($headers);

        if (isset($verify_request_base['status']) && $verify_request_base['status'] == 401) {
            return response()->json(['success_code' => 401, 'message' => "Unauthorized Access!"]);
            exit();
        }

        $rules = [
            'id_number' => 'required',
        ];

        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => 401, 'message' => $msg]);
        }

        $User =  User::where('user_id', $user_id)->first();

        $count_approve = VerificationRequest::where('user_id', $user_id)->where('status', 1)->count();

        if ($count_approve >= 1) {
            return response()->json(['status' => 200, 'message' => "Verification request already aproved."]);
        }

        $count_pending = VerificationRequest::where('user_id', $user_id)->where('status', 0)->count();

        if ($count_pending == 1) {
            return response()->json(['status' => 200, 'message' => "Your Verification request pending."]);
        }

        $id_number = $request->get('id_number') ? $request->get('id_number') : '';
        $name = $request->get('name') ? $request->get('name') : '';
        $address = $request->get('address') ? $request->get('address') : '';
        $photo_id_image = "";

        if ($request->hasfile('photo_id_image')) {
            $file = $request->file('photo_id_image');
            $photo_id_image = GlobalFunction::uploadFilToS3($file);
        }

        $photo_with_id_image = "";

        if ($request->hasfile('photo_with_id_image')) {
            $file = $request->file('photo_with_id_image');
            $photo_with_id_image = GlobalFunction::uploadFilToS3($file);
        }

        $data = array(
            'id_number' => $id_number,
            'user_id' => $user_id,
            'name' => $name,
            'address' => $address,
            'photo_id_image' => $photo_id_image,
            'photo_with_id_image' => $photo_with_id_image,
        );

        $result = VerificationRequest::insert($data);
        $data1['is_verify'] = 2;
        User::where('user_id', $user_id)->update($data1);
        if (!empty($result)) {
            return response()->json(['status' => 200, 'message' => "Verification request successfully send."]);
        } else {
            return response()->json(['status' => 401, 'message' => "Verification request send failed."]);
        }
    }

    function checkUsername(Request $request)
    {

        $user_id = $request->user()->user_id;

        if (empty($user_id)) {
            $msg = "user id is required";
            return response()->json(['success_code' => 401, 'response_code' => 0, 'response_message' => $msg]);
        }

        $headers = $request->headers->all();

        $verify_request_base = Admin::verify_request_base($headers);

        if (isset($verify_request_base['status']) && $verify_request_base['status'] == 401) {
            return response()->json(['success_code' => 401, 'message' => "Unauthorized Access!"]);
            exit();
        }

        $rules = [
            'user_name' => 'required',
        ];

        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => 401, 'message' => $msg]);
        }

        $user_name = $request->get('user_name');
        $result =  User::where('user_name', $user_name)->first();

        if (empty($result)) {
            return response()->json(['status' => 200, 'message' => "Username generet successfully"]);
        } else {
            return response()->json(['status' => 401, 'message' => "Username already exist"]);
        }
    }

    function getProfile(Request $request)
    {
        $headers = $request->headers->all();

        $verify_request_base = Admin::verify_request_base($headers);

        if (isset($verify_request_base['status']) && $verify_request_base['status'] == 401) {
            return response()->json(['success_code' => 401, 'message' => "Unauthorized Access!"]);
            exit();
        }
        
        $user_id = $request->user_id;
        $my_user_id = $request->my_user_id;
        
        // Create a unique cache key based on user_id and my_user_id
        $cacheKey = CacheKeys::USER_PROFILE . $user_id . ':' . $my_user_id;
        
        // Try to get from cache first
        return Cache::remember($cacheKey, CacheKeys::TTL_HOUR, function () use ($user_id, $my_user_id, $request) {
            $User = User::where('user_id', $user_id)->first();
            if (empty($User)) {
                return response()->json(['status' => 401, 'message' => "User Not Found"]);
            }
            
            $User->is_following_eachOther = 0;

            if ($request->has('my_user_id')) {
                $myUser = User::where('user_id', $request->my_user_id)->first();
                if ($myUser == null) {
                    return response()->json(['status' => false, 'message' => "My User doesn't exists !"]);
                }
                $my_user_id = $myUser->user_id;

                // Is following each other - cache this relationship
                $followCacheKey = 'follow:' . $myUser->user_id . ':' . $User->user_id;
                $follow = Cache::remember($followCacheKey, CacheKeys::TTL_HOUR, function () use ($myUser, $User) {
                    return Followers::where('from_user_id', $myUser->user_id)
                        ->where('to_user_id', $User->user_id)
                        ->first();
                });

                $follow2CacheKey = 'follow:' . $User->user_id . ':' . $myUser->user_id;
                $follow2 = Cache::remember($follow2CacheKey, CacheKeys::TTL_HOUR, function () use ($User, $myUser) {
                    return Followers::where('from_user_id', $User->user_id)
                        ->where('to_user_id', $myUser->user_id)
                        ->first();
                });

                if ($follow2 == null || $follow == null) {
                    $User->is_following_eachOther = 0;
                } else {
                    $User->is_following_eachOther = 1;
                }
            }

            // Cache follow count
            $isFollowCacheKey = 'is_follow:' . $my_user_id . ':' . $user_id;
            $is_count = Cache::remember($isFollowCacheKey, CacheKeys::TTL_HOUR, function () use ($my_user_id, $user_id) {
                return Followers::where('from_user_id', $my_user_id)
                    ->where('to_user_id', $user_id)
                    ->count();
            });

            $is_count = $is_count > 0 ? 1 : 0;
            
            // Cache block status
            $isBlockCacheKey = 'is_block:' . $my_user_id . ':' . $user_id;
            $is_block = Cache::remember($isBlockCacheKey, CacheKeys::TTL_HOUR, function () use ($my_user_id, $user_id) {
                return BlockUser::where('from_user_id', $my_user_id)
                    ->where('block_user_id', $user_id)
                    ->count();
            });

            $is_block = $is_block > 0 ? 1 : 0;

            // Ensure all numeric fields are properly cast to integers
            $User['platform'] = isset($User->platform) ? (int)$User->platform : 0;
            $User['is_verify'] = isset($User->is_verify) ? (int)$User->is_verify : 0;
            $User['my_wallet'] = isset($User->my_wallet) ? (int)$User->my_wallet : 0;
            $User['status'] = isset($User->status) ? (int)$User->status : 0;
            $User['freez_or_not'] = isset($User->freez_or_not) ? (int)$User->freez_or_not : 0;
            
            // Cache followers count
            $followersCacheKey = 'followers_count:' . $user_id;
            $followers_count = Cache::remember($followersCacheKey, CacheKeys::TTL_MINUTE * 15, function () use ($user_id) {
                return Followers::where('to_user_id', $user_id)->count();
            });
            $User['followers_count'] = (int)$followers_count;
            
            // Cache following count
            $followingCacheKey = 'following_count:' . $user_id;
            $following_count = Cache::remember($followingCacheKey, CacheKeys::TTL_MINUTE * 15, function () use ($user_id) {
                return Followers::where('from_user_id', $user_id)->count();
            });
            $User['following_count'] = (int)$following_count;
            
            // Cache post likes count - this can be expensive so cache longer
            $postLikesKey = 'user:post_likes:' . $user_id;
            $post_likes = Cache::remember($postLikesKey, CacheKeys::TTL_HOUR * 3, function () use ($user_id) {
                $myPostIds = Post::where('user_id', $user_id)->pluck('post_id');
                return Like::whereIn('post_id', $myPostIds)->count();
            });
            $User['my_post_likes'] = (int)$post_likes;

            // Cache profile category
            $profileCatKey = 'profile_category:' . $User->profile_category;
            $profile_category_data = Cache::remember($profileCatKey, CacheKeys::TTL_DAY, function () use ($User) {
                return ProfileCategory::where('profile_category_id', $User->profile_category)->first();
            });
            
            $User['profile_category_name'] = !empty($profile_category_data) ? $profile_category_data['profile_category_name'] : "";
            $User['is_following'] = (int)$is_count;
            $User['block_or_not'] = (int)$is_block;
            $User['user_profile'] = $User->user_profile ? $User->user_profile : "";
            $User['user_mobile_no'] = $User->user_mobile_no ? $User->user_mobile_no : "";
            $User['bio'] = $User->bio ? $User->bio : "";
            $User['profile_category'] = isset($User->profile_category) ? (int)$User->profile_category : 0;
            $User['fb_url'] = $User->fb_url ? $User->fb_url : "";
            $User['insta_url'] = $User->insta_url ? $User->insta_url : "";
            $User['youtube_url'] = $User->youtube_url ? $User->youtube_url : "";

            unset($User->status);
            unset($User->freez_or_not);
            unset($User->timezone);
            unset($User->created_at);
            unset($User->updated_at);

            return response()->json(['status' => 200, 'message' => "User Profile Get successfully.", 'data' => $User]);
        });
    }

    public function updateProfile(Request $request)
    {

        $user_id = $request->user()->user_id;

        if (empty($user_id)) {
            $msg = "user id is required";
            return response()->json(['success_code' => 401, 'response_code' => 0, 'response_message' => $msg]);
        }

        $headers = $request->headers->all();

        $verify_request_base = Admin::verify_request_base($headers);

        if (isset($verify_request_base['status']) && $verify_request_base['status'] == 401) {
            return response()->json(['success_code' => 401, 'message' => "Unauthorized Access!"]);
            exit();
        }


        // $rules = [
        //     'full_name' => 'required',
        // ];

        // $validator = Validator::make($request->all(), $rules);

        // if ($validator->fails()) {
        //     $messages = $validator->errors()->all();
        //     $msg = $messages[0];
        //     return response()->json(['status' => 401, 'message' => $msg]);
        // }

        $CheckUSer =  User::where('user_id', $user_id)->first();
        if (empty($CheckUSer)) {
            return response()->json(['status' => 401, 'message' => "User Not Found"]);
        }
        if ($request->hasfile('user_profile')) {
            $file = $request->file('user_profile');
            $data['user_profile'] = GlobalFunction::uploadFilToS3($file);
        }

        if ($request->has('is_notification')) {
            $data['is_notification'] = $request->get('is_notification');
        }
        if (!empty($request->get('full_name'))) {
            $data['full_name'] = $request->get('full_name');
        }
        if (!empty($request->get('user_email'))) {
            $data['user_email'] = $request->get('user_email');
        }
        if (!empty($request->get('user_name'))) {
            $result =  User::where('user_name', $request->get('user_name'))->first();
            if (empty($result)) {
                $data['user_name'] = $request->get('user_name');
            } else {
                return response()->json(['status' => 401, 'message' => "Username already exist"]);
            }
        }
        if (!empty($request->get('user_mobile_no'))) {
            $data['user_mobile_no'] = $request->get('user_mobile_no');
        }
        if (!empty($request->get('profile_category'))) {
            $data['profile_category'] = $request->get('profile_category');
            if($request->get('profile_category') == -1){
                $data['profile_category'] = -1;
            }
        }
        $data['bio'] = $request->get('bio');

        $data['fb_url'] = $request->get('fb_url');
        $data['insta_url'] = $request->get('insta_url');
        $data['youtube_url'] = $request->get('youtube_url');

        $result =  User::where('user_id', $user_id)->update($data);
        if (!empty($result)) {

            $User =  User::where('user_id', $user_id)->first();

            $User['platform'] = $User->platform ? (int)$User->platform : 0;
            $User['is_verify'] = $User->is_verify ? (int)$User->is_verify : 0;

            $User['my_wallet'] = $User->my_wallet ? (int)$User->my_wallet : 0;


            $User['status'] = $User->status ? (int)$User->status : 0;
            $User['freez_or_not'] = $User->freez_or_not ? (int)$User->freez_or_not : 0;

            $User['followers_count'] = Followers::where('to_user_id', $user_id)->count();
            $User['following_count'] = Followers::where('from_user_id', $user_id)->count();
            $User['my_post_likes'] = Post::select('tbl_post.*')->leftjoin('tbl_likes as l', 'l.post_id', 'tbl_post.post_id')->where('tbl_post.user_id', $user_id)->count();
            $profile_category_data = ProfileCategory::where('profile_category_id', $User->profile_category)->first();
            $User['profile_category_name'] = !empty($profile_category_data) ? $profile_category_data['profile_category_name'] : "";

            $User['user_profile'] = $User->user_profile ? $User->user_profile : "";
            $User['user_mobile_no'] = $User->user_mobile_no ? $User->user_mobile_no : "";
            $User['bio'] = $User->bio ? $User->bio : "";
            $User['profile_category'] = $User->profile_category ? $User->profile_category : "";
            $User['fb_url'] = $User->fb_url ? $User->fb_url : "";
            $User['insta_url'] = $User->insta_url ? $User->insta_url : "";
            $User['youtube_url'] = $User->youtube_url ? $User->youtube_url : "";

            unset($User->timezone);
            unset($User->created_at);
            unset($User->updated_at);
            
            // Invalidate user profile cache after update
            $this->invalidateUserCache($user_id);

            return response()->json(['status' => 200, 'message' => "User details update successfully", 'data' => $User]);
        } else {
            return response()->json(['status' => 401, 'message' => "Error While User Profile Update", 'data' => []]);
        }
    }



    public function deleteMyAccount(Request $request)
    {

        $user_id = $request->user()->user_id;

        if (empty($user_id)) {
            $msg = "user id is required";
            return response()->json(['success_code' => 401, 'response_code' => 0, 'response_message' => $msg]);
        }

        $headers = $request->headers->all();

        $verify_request_base = Admin::verify_request_base($headers);

        if (isset($verify_request_base['status']) && $verify_request_base['status'] == 401) {
            return response()->json(['success_code' => 401, 'message' => "Unauthorized Access!"]);
            exit();
        }

        $CheckUSer =  User::where('user_id', $user_id)->first();
        if (empty($CheckUSer)) {
            return response()->json(['status' => 401, 'message' => "User Not Found"]);
        }
        $result =  User::where('user_id', $user_id)->delete();
        Post::where('user_id', $user_id)->delete();
        Bookmark::where('user_id', $user_id)->delete();
        Comments::where('user_id', $user_id)->delete();
        Followers::where('from_user_id', $user_id)->orWhere('to_user_id', $user_id)->delete();
        Like::where('user_id', $user_id)->delete();
        RedeemRequest::where('user_id', $user_id)->delete();
        Report::where('user_id', $user_id)->delete();
        VerificationRequest::where('user_id', $user_id)->delete();
        Notification::where('received_user_id', $user_id)->orWhere('sender_user_id', $user_id)->orWhere('item_id', $user_id)->delete();

        if ($result) {
            // Invalidate all caches related to this user
            $this->invalidateUserCache($user_id);
            
            // Also invalidate any recommendations that might include this user's content
            Cache::forget(CacheKeys::RECOMMENDATION_FOR_USER . $user_id . ':*');
            Cache::forget(CacheKeys::TRENDING_POSTS . '*');
            
            return response()->json(['status' => 200, 'message' => "User Account Deleted successfully"]);
        } else {
            return response()->json(['status' => 401, 'message' => "Error While User Account Delete", 'data' => []]);
        }
    }

    public function getNotificationList(Request $request)
    {


        $user_id = $request->user()->user_id;
        if (empty($user_id)) {
            $msg = "user id is required";
            return response()->json(['success_code' => 401, 'response_code' => 0, 'response_message' => $msg]);
        }

        $headers = $request->headers->all();
        $verify_request_base = Admin::verify_request_base($headers);

        if (isset($verify_request_base['status']) && $verify_request_base['status'] == 401) {
            return response()->json(['success_code' => 401, 'message' => "Unauthorized Access!"]);
            exit();
        }

        $rules = [
            'start' => 'required',
        ];

        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => 401, 'message' => $msg]);
        }

        $limit = $request->get('limit') ? $request->get('limit') : 20;
        $start = $request->get('start') ? $request->get('start') : 0;

        $NotificationData  = Notification::where('received_user_id', $user_id)->orderBy('notification_id', 'DESC')
            ->with(['sender_user'])
            ->offset($start)
            ->limit($limit)
            ->get();

        return response()->json(['status' => 200, 'message' => "Notification Data Get Successfully.", 'data' => $NotificationData]);
    }

    public function setNotificationSettings(Request $request)
    {


        $user_id = $request->user()->user_id;
        if (empty($user_id)) {
            $msg = "user id is required";
            return response()->json(['success_code' => 401, 'response_code' => 0, 'response_message' => $msg]);
        }

        $headers = $request->headers->all();
        $verify_request_base = Admin::verify_request_base($headers);

        if (isset($verify_request_base['status']) && $verify_request_base['status'] == 401) {
            return response()->json(['success_code' => 401, 'message' => "Unauthorized Access!"]);
            exit();
        }

        $rules = [
            'device_token' => 'required',
        ];

        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => 401, 'message' => $msg]);
        }

        $device_token = $request->get('device_token') ? $request->get('device_token') : "";
        $data['device_token'] = $device_token;
        $result  = User::where('user_id', $user_id)->update($data);

        if ($result) {
            return response()->json(['status' => 200, 'message' => "Setting Update Successfully"]);
        } else {
            return response()->json(['status' => 401, 'message' => "Error While Setting Update"]);
        }
    }

    public function getProfileCategoryList(Request $request)
    {



        $user_id = $request->user()->user_id;
        if (empty($user_id)) {
            $msg = "user id is required";
            return response()->json(['success_code' => 401, 'response_code' => 0, 'response_message' => $msg]);
        }

        $headers = $request->headers->all();
        $verify_request_base = Admin::verify_request_base($headers);
        if (isset($verify_request_base['status']) && $verify_request_base['status'] == 401) {
            return response()->json(['success_code' => 401, 'message' => "Unauthorized Access!"]);
            exit();
        }

        $ProfileCategoryData  = ProfileCategory::orderBy('profile_category_id', 'DESC')->get();

        if (count($ProfileCategoryData) > 0) {

            $data = [];
            $i = 0;
            foreach ($ProfileCategoryData as $value) {
                $data[$i]['profile_category_id'] = (int)$value['profile_category_id'];
                $data[$i]['profile_category_name'] = $value['profile_category_name'];
                $data[$i]['profile_category_image'] = $value['profile_category_image'] ? $value['profile_category_image'] : "";
                $i++;
            }

            return response()->json(['status' => 200, 'message' => "Profile Category Data Get Successfully.", 'data' => $data]);
        } else {
            return response()->json(['status' => 401, 'message' => "No Data Found."]);
        }
    }

    public function blockUser(Request $request)
    {

        $from_user_id = $request->user()->user_id;

        if (empty($from_user_id)) {
            $msg = "user id is required";
            return response()->json(['success_code' => 401, 'response_code' => 0, 'response_message' => $msg]);
        }

        $headers = $request->headers->all();
        $verify_request_base = Admin::verify_request_base($headers);

        if (isset($verify_request_base['status']) && $verify_request_base['status'] == 401) {
            return response()->json(['success_code' => 401, 'message' => "Unauthorized Access!"]);
            exit();
        }

        $rules = [
            'user_id' => 'required',
        ];

        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => 401, 'message' => $msg]);
        }

        $block_user_id = $request->get('user_id');

        $countBlockUser = BlockUser::where('from_user_id', $from_user_id)->where('block_user_id', $block_user_id)->count();

        if ($countBlockUser > 0) {

            $delete = BlockUser::where('from_user_id', $from_user_id)->where('block_user_id', $block_user_id)->delete();
            return response()->json(['status' => 200, 'message' => "User Unblock successful"]);
        } else {

            $data = array('block_user_id' => $block_user_id, 'from_user_id' => $from_user_id);
            $insert =  BlockUser::insert($data);

            return response()->json(['status' => 200, 'message' => "User Block successful."]);
        }
    }
    
      /**
     * Upload contacts CSV file and store reference
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function uploadContactsCsv(Request $request)
    {
        // Get authenticated user
        $user_id = $request->user()->user_id;
        if (empty($user_id)) {
            return response()->json(['status' => 401, 'message' => "User ID is required"]);
        }

        // Verify API request
        $headers = $request->headers->all();
        $verify_request_base = Admin::verify_request_base($headers);
        if (isset($verify_request_base['status']) && $verify_request_base['status'] == 401) {
            return response()->json(['status' => 401, 'message' => "Unauthorized Access!"]);
        }

        // Validate that CSV file was uploaded
        if (!$request->hasFile('contacts_csv')) {
            return response()->json(['status' => 401, 'message' => "No CSV file uploaded"]);
        }

        try {
            $file = $request->file('contacts_csv');
            
            // Verify it's a CSV file
            if ($file->getClientOriginalExtension() !== 'csv') {
                return response()->json(['status' => 401, 'message' => "Uploaded file must be a CSV"]);
            }

            // Create a directory for contacts if it doesn't exist
            if (!file_exists(storage_path('app/contacts'))) {
                mkdir(storage_path('app/contacts'), 0755, true);
            }

            // Store the file in the storage/app/contacts directory
            $fileName = 'user_' . $user_id . '_contacts_' . date('Y-m-d_H-i-s') . '.csv';
            $filePath = $file->storeAs('contacts', $fileName);
            
            if (!$filePath) {
                return response()->json(['status' => 500, 'message' => "Failed to store CSV file"]);
            }
            
            // Start transaction
            DB::beginTransaction();
            
            // Delete existing contacts file record for this user
            \App\Contact::where('user_id', $user_id)->delete();
            
            // Create a new contact record with the file path
            $contactRecord = new \App\Contact([
                'user_id' => $user_id,
                'csv_file_path' => $filePath
            ]);
            
            $contactRecord->save();
            
            // Commit the transaction
            DB::commit();
            
            // Get the number of records in the CSV (rough estimate)
            $path = storage_path('app/' . $filePath);
            $contactCount = 0;
            
            if (($handle = fopen($path, "r")) !== FALSE) {
                // Skip header row
                fgetcsv($handle, 1000, ',');
                
                // Count rows
                while (($data = fgetcsv($handle, 1000, ',')) !== FALSE) {
                    if (!empty(array_filter($data))) { // Skip empty rows
                        $contactCount++;
                    }
                }
                fclose($handle);
            }
            
            // Return success response with file info
            return response()->json([
                'status' => 200, 
                'message' => "Contacts uploaded successfully", 
                'data' => [
                    'estimated_contacts' => $contactCount,
                    'csv_file' => $fileName,
                    'file_path' => $filePath
                ]
            ]);
            
        } catch (\Exception $e) {
            // Rollback transaction on error
            DB::rollBack();
            
            // Log the error
            Log::error('Contact CSV upload error: ' . $e->getMessage());
            
            // Return error response
            return response()->json([
                'status' => 500, 
                'message' => "Error processing contacts: " . $e->getMessage()
            ]);
        }
    }
   
    /**
     * Helper method to invalidate user cache
     * @param int $user_id The user ID whose caches need to be invalidated
     */
    private function invalidateUserCache($user_id)
    {
        // Clear the user profile cache using pattern matching
        $cachePattern = CacheKeys::USER_PROFILE . $user_id . ':*';
        $keys = Cache::getPrefix() . $cachePattern;
        
        try {
            $redis = app('redis')->connection();
            $redis->eval("
                local keys = redis.call('keys', ARGV[1])
                for i=1,#keys do
                    redis.call('del', keys[i])
                end
                return #keys
            ", 0, [$keys]);
            
            // Also clear other user-related caches
            Cache::forget('followers_count:' . $user_id);
            Cache::forget('following_count:' . $user_id);
            Cache::forget('user:post_likes:' . $user_id);
            
            // If profile category changed, clear that cache too
            $profileCatKey = 'profile_category:' . $user_id;
            Cache::forget($profileCatKey);
            
            Log::info("Invalidated user cache for user: " . $user_id);
        } catch (\Exception $e) {
            Log::error("Error invalidating user cache: " . $e->getMessage());
        }
    }
}
