<?php

namespace App\Http\Controllers\API;

use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;
use Validator;
use File;
use Session;
use DB;
use Log;
use App\Admin;
use App\Common;
use App\User;
use App\Post;
use App\CoinRate;
use App\CoinPlan;
use App\Gifts;
use App\GlobalSettings;
use App\RewardingAction;
use App\Notification;
use App\RedeemRequest;
use App\Transaction;

class WalletController extends Controller
{
    public function addCoin(Request $request)
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
            'rewarding_action_id' => 'required',
        ];

        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => 401, 'message' => $msg]);
        }
        $rewarding_action_id = $request->get('rewarding_action_id');

        $settings = GlobalSettings::first();
        $coin = 0;

        if ($rewarding_action_id == 3) {
            $coin = $settings->reward_video_upload;
        }
        $wallet_update = User::where('user_id', $user_id)->increment('my_wallet', $coin);

        if ($wallet_update) {
            // Record transaction
            Transaction::create([
                'user_id' => $user_id,
                'transaction_type' => 'reward',
                'coins' => $coin,
                'status' => 'completed',
                'meta_data' => json_encode(['rewarding_action_id' => $rewarding_action_id])
            ]);
            
            return response()->json(['status' => 200, 'message' => "Coin Added Successfully."]);
        } else {
            return response()->json(['status' => 401, 'message' => "Error While Add Coin."]);
        }
    }

    public function sendCoin(Request $request)
    {
        $user_id = $request->user()->user_id;
        $full_name = $request->user()->full_name;

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
            'to_user_id' => 'required',
            'coin' => 'required',
        ];

        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => 401, 'message' => $msg]);
        }
        $to_user_id = $request->get('to_user_id');
        $coin = $request->get('coin');
        $gift_id = $request->get('gift_id'); // Optional gift ID if this is a gift transaction

        $userData =  User::select('my_wallet')->where('user_id', $user_id)->first();
        $wallet = $userData['my_wallet'];

        if ($wallet >= $coin) {
            $count_update = User::where('user_id', $user_id)->where('my_wallet', '>', $coin)->decrement('my_wallet', $coin);
            $wallet_update = User::where('user_id', $to_user_id)->increment('my_wallet', $coin);

            // Record the gift transaction
            Transaction::create([
                'user_id' => $user_id,
                'to_user_id' => $to_user_id,
                'transaction_type' => !empty($gift_id) ? 'gift' : 'transfer',
                'coins' => $coin,
                'gift_id' => $gift_id,
                'status' => 'completed'
            ]);

            // Update user level points for gifting coins - convert coins to points
            try {
                // Calculate level points - 5 points per coin as defined in LevelUtils.dart
                $levelPoints = $coin * 5;
                
                \Log::info("Updating level points for user $user_id sending gift: $levelPoints points");
                
                // Get the unique key from the original request
                $uniqueKey = $request->header('unique-key');
                
                // Create a new request with the required headers
                $levelRequest = new \Illuminate\Http\Request([
                    'points' => $levelPoints,
                    'action_type' => !empty($gift_id) ? 'send_gift' : 'send_coins',
                    'user_id' => $user_id
                ]);
                
                // Set the required headers
                $levelRequest->headers->set('unique-key', $uniqueKey);
                
                // Call UserController to update level points
                $senderPointsResponse = app(\App\Http\Controllers\API\UserController::class)->updateUserLevelPoints(
                    $levelRequest
                );
                
                // Log response for debugging
                \Log::info("Sender level points update response: " . json_encode($senderPointsResponse->getData()));
                
                // Also reward the recipient with some level points (25% of the sender's points)
                $recipientPoints = intval($levelPoints * 0.25);
                if ($recipientPoints > 0) {
                    \Log::info("Updating level points for recipient $to_user_id: $recipientPoints points");
                    
                    // Create another request for the recipient with headers
                    $recipientRequest = new \Illuminate\Http\Request([
                        'points' => $recipientPoints,
                        'action_type' => 'receive_gift',
                        'user_id' => $to_user_id
                    ]);
                    
                    // Set the required headers again
                    $recipientRequest->headers->set('unique-key', $uniqueKey);
                    
                    $recipientPointsResponse = app(\App\Http\Controllers\API\UserController::class)->updateUserLevelPoints(
                        $recipientRequest
                    );
                    
                    \Log::info("Recipient level points update response: " . json_encode($recipientPointsResponse->getData()));
                }
            } catch (\Exception $e) {
                // Log the error but continue with the transaction
                \Log::error('Error updating user level points: ' . $e->getMessage());
                \Log::error($e->getTraceAsString());
            }

            $noti_user_id = $to_user_id;

            $userData =  User::where('user_id', $noti_user_id)->first();
            $platform = $userData['platform'];
            $device_token = $userData['device_token'];
            $message = $full_name . ' sent you ' . $coin . ' Stars';

            $notificationdata = array(
                'sender_user_id' => $user_id,
                'received_user_id' => $noti_user_id,
                'notification_type' => 4,
                'item_id' => $user_id,
                'message' => $message,
            );

            Notification::insert($notificationdata);
            $notification_title = "LiveTok";
            if($userData->is_notification == 1 ){
                Common::send_push($device_token, $notification_title, $message, $platform);
            }
            return response()->json(['status' => 200, 'message' => "Coin Send Successfully."]);
        } else {
            return response()->json(['status' => 401, 'message' => "You have Insufficient Wallet Balance."]);
        }
    }

    public function purchaseCoin(Request $request)
    {
        $user_id = $request->user()->user_id;
        $full_name = $request->user()->full_name;

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
            'coin' => 'required',
        ];

        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => 401, 'message' => $msg]);
        }

        $coin = $request->get('coin');
        $amount = $request->get('amount', 0);
        $payment_method = $request->get('payment_method', 'in_app_purchase');
        $transaction_reference = $request->get('transaction_reference');
        $platform = $request->get('platform', 'unknown');
        
        $wallet_update = User::where('user_id', $user_id)->increment('my_wallet', $coin);
        
        // Record the purchase transaction
        Transaction::create([
            'user_id' => $user_id,
            'transaction_type' => 'purchase',
            'coins' => $coin,
            'amount' => $amount,
            'payment_method' => $payment_method,
            'transaction_reference' => $transaction_reference,
            'platform' => $platform,
            'status' => 'completed'
        ]);

        return response()->json(['status' => 200, 'message' => "Coin Purchased Successfully."]);
    }

    public function getMyWalletCoin(Request $request)
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

        $user = User::select('my_wallet')->where('user_id', $user_id)->first();
        
        // Get transaction stats
        $stats = DB::table('tbl_transactions')
            ->select(
                DB::raw('SUM(CASE WHEN transaction_type = "purchase" THEN coins ELSE 0 END) as purchased'),
                DB::raw('SUM(CASE WHEN transaction_type = "reward" THEN coins ELSE 0 END) as upload_video'),
                DB::raw('SUM(CASE WHEN transaction_type = "reward" AND meta_data LIKE "%check_in%" THEN coins ELSE 0 END) as check_in'),
                DB::raw('SUM(CASE WHEN transaction_type = "gift" AND to_user_id = '.$user_id.' THEN coins ELSE 0 END) as from_fans'),
                DB::raw('SUM(CASE WHEN user_id = '.$user_id.' AND transaction_type IN ("gift", "transfer") THEN coins ELSE 0 END) as total_send'),
                DB::raw('SUM(CASE WHEN to_user_id = '.$user_id.' AND transaction_type IN ("gift", "transfer") THEN coins ELSE 0 END) as total_received')
            )
            ->where(function($query) use ($user_id) {
                $query->where('user_id', $user_id)
                      ->orWhere('to_user_id', $user_id);
            })
            ->first();
        
        $data = [
            'my_wallet' => $user->my_wallet ? (int)$user->my_wallet : 0,
            'total_send' => (int)($stats->total_send ?? 0),
            'total_received' => (int)($stats->total_received ?? 0),
            'from_fans' => (int)($stats->from_fans ?? 0),
            'purchased' => (int)($stats->purchased ?? 0),
            'upload_video' => (int)($stats->upload_video ?? 0),
            'check_in' => (int)($stats->check_in ?? 0),
        ];

        if (!empty($data)) {
            return response()->json(['status' => 200, 'message' => "My Wallet Data Get Successfully.", 'data' => $data]);
        } else {
            return response()->json(['status' => 401, 'message' => "No Data Found.", 'data' => $data]);
        }
    }

    public function getTransactionHistory(Request $request)
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

        $transaction_type = $request->get('transaction_type'); // Optional filter
        $limit = $request->get('limit', 20);
        $offset = $request->get('offset', 0);
        
        $query = Transaction::with(['user:user_id,user_name,full_name,user_profile', 'recipient:user_id,user_name,full_name,user_profile'])
            ->where(function($q) use ($user_id) {
                $q->where('user_id', $user_id)
                  ->orWhere('to_user_id', $user_id);
            });
            
        if (!empty($transaction_type)) {
            $query->where('transaction_type', $transaction_type);
        }
        
        $total = $query->count();
        $transactions = $query->orderBy('created_at', 'desc')
            ->offset($offset)
            ->limit($limit)
            ->get();
            
        return response()->json([
            'status' => 200, 
            'message' => "Transaction History Retrieved Successfully.",
            'total' => $total,
            'data' => $transactions
        ]);
    }

    public function getCoinPlanList(Request $request)
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

        $data = CoinPlan::get();

        if (!empty($data)) {
            return response()->json(['status' => 200, 'message' => "Coin Plan Data Get Successfully.", 'data' => $data]);
        } else {
            return response()->json(['status' => 401, 'message' => "No Data Found.", 'data' => $data]);
        }
    }

    public function redeemRequest(Request $request)
    {
        $user_id = $request->user()->user_id;
        $full_name = $request->user()->full_name;

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
            'amount' => 'required',
            'redeem_request_type' => 'required',
            'account' => 'required',
        ];

        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => 401, 'message' => $msg]);
        }
        
        $coin = $request->get('coin') ? $request->get('coin') : 0;
        $amount = $request->get('amount');
        $redeem_request_type = $request->get('redeem_request_type');
        $account = $request->get('account');
        
        // Check if user has enough coins
        $user = User::select('my_wallet')->where('user_id', $user_id)->first();
        if (!$user || $user->my_wallet < $coin) {
            return response()->json(['status' => 401, 'message' => "Insufficient coins in your wallet."]);
        }

        // Create redeem request with reference to transaction
        $data = array(
            'redeem_request_type' => $redeem_request_type, 
            'account' => $account, 
            'amount' => $amount, 
            'user_id' => $user_id,
            'coins' => $coin,
            'status' => 0 // 0 = pending
        );
        $insert = RedeemRequest::insert($data);

        // Record the redeem transaction
        $transaction = Transaction::create([
            'user_id' => $user_id,
            'transaction_type' => 'redeem',
            'coins' => $coin,
            'amount' => $amount,
            'payment_method' => $redeem_request_type,
            'status' => 'pending',
            'meta_data' => json_encode(['account' => $account])
        ]);

        // Deduct only the withdrawal amount from wallet instead of setting to zero
        $remainingCoins = $user->my_wallet - $coin;
        $update_data = array(
            'my_wallet' => $remainingCoins,
        );

        $count_update = User::where('user_id', $user_id)->update($update_data);
        if ($insert) {
            return response()->json(['status' => 200, 'message' => "Redeem Request Successfully."]);
        } else {
            return response()->json(['status' => 401, 'message' => "Redeem Request Failed."]);
        }
    }
}
