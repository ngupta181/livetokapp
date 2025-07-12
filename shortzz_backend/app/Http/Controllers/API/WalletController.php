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
            'rewarding_action_id' => 'required|integer|in:1,2,3,4,5',
        ];

        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => 401, 'message' => $msg]);
        }
        $rewarding_action_id = $request->get('rewarding_action_id');

        // Rate limiting: Max 5 reward claims per hour per user
        $recent_rewards = Transaction::where('user_id', $user_id)
            ->where('transaction_type', 'reward')
            ->where('created_at', '>=', now()->subHours(1))
            ->count();

        if ($recent_rewards >= 5) {
            \Log::warning("Rate limit exceeded for reward claims", [
                'user_id' => $user_id,
                'recent_rewards' => $recent_rewards,
                'ip' => $request->ip()
            ]);
            return response()->json([
                'status' => 429, 
                'message' => "Too many reward claims. Please wait before trying again."
            ]);
        }

        $settings = GlobalSettings::first();
        $coin = 0;

        // Security: Define all valid reward actions
        switch ($rewarding_action_id) {
            case 1:
                $coin = $settings->reward_sign_up ?? 10;
                break;
            case 2:
                $coin = $settings->reward_daily_check_in ?? 5;
                break;
            case 3:
                $coin = $settings->reward_video_upload ?? 10;
                break;
            case 4:
                $coin = $settings->reward_profile_complete ?? 15;
                break;
            case 5:
                $coin = $settings->reward_first_video ?? 25;
                break;
            default:
                return response()->json(['status' => 401, 'message' => "Invalid reward action."]);
        }

        // Security: Ensure coin amount is valid
        if ($coin <= 0) {
            return response()->json(['status' => 401, 'message' => "Invalid reward amount."]);
        }

        \Log::info("Reward claim attempt", [
            'user_id' => $user_id,
            'rewarding_action_id' => $rewarding_action_id,
            'coin_amount' => $coin,
            'ip' => $request->ip()
        ]);
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
            'to_user_id' => 'required|integer|min:1|exists:tbl_users,user_id',
            'coin' => 'required|integer|in:5,10,15,20',
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

        // Security: Prevent self-transfers
        if ($user_id == $to_user_id) {
            return response()->json(['status' => 401, 'message' => "Cannot send coins to yourself."]);
        }

        // Rate limiting: Max 10 coin transfers per minute per user
        $recent_transfers = Transaction::where('user_id', $user_id)
            ->where('transaction_type', 'transfer')
            ->where('created_at', '>=', now()->subMinutes(1))
            ->count();

        if ($recent_transfers >= 10) {
            \Log::warning("Rate limit exceeded for coin transfer", [
                'user_id' => $user_id,
                'recent_transfers' => $recent_transfers,
                'ip' => $request->ip()
            ]);
            return response()->json([
                'status' => 429, 
                'message' => "Too many transfer attempts. Please wait before trying again."
            ]);
        }

        // Security: Log coin transfer attempts for monitoring
        \Log::info("Coin transfer attempt", [
            'from_user_id' => $user_id,
            'to_user_id' => $to_user_id,
            'coin_amount' => $coin,
            'gift_id' => $gift_id,
            'ip' => $request->ip(),
            'user_agent' => $request->userAgent()
        ]);

        $userData =  User::select('my_wallet')->where('user_id', $user_id)->first();
        $wallet = $userData['my_wallet'];

        // Security: Ensure coin amount is positive (double-check)
        if ($coin <= 0) {
            \Log::warning("Negative coin transfer attempt blocked", [
                'user_id' => $user_id,
                'coin_amount' => $coin,
                'ip' => $request->ip()
            ]);
            return response()->json(['status' => 401, 'message' => "Invalid coin amount."]);
        }

        if ($wallet >= $coin) {
            // Use database transaction for atomicity
            DB::beginTransaction();
            try {
                // Security: Use more secure wallet deduction with balance verification
                $count_update = User::where('user_id', $user_id)
                    ->where('my_wallet', '>=', $coin)
                    ->decrement('my_wallet', $coin);
                
                if ($count_update === 0) {
                    DB::rollBack();
                    return response()->json(['status' => 401, 'message' => "Insufficient wallet balance or concurrent transaction."]);
                }
                
            $wallet_update = User::where('user_id', $to_user_id)->increment('my_wallet', $coin);
                
                if ($wallet_update === 0) {
                    DB::rollBack();
                    return response()->json(['status' => 401, 'message' => "Recipient user not found."]);
                }
                
                DB::commit();
                
                \Log::info("Coin transfer successful", [
                    'from_user_id' => $user_id,
                    'to_user_id' => $to_user_id,
                    'coin_amount' => $coin,
                    'sender_new_balance' => $wallet - $coin
                ]);
                
            } catch (\Exception $e) {
                DB::rollBack();
                \Log::error("Coin transfer failed", [
                    'user_id' => $user_id,
                    'to_user_id' => $to_user_id,
                    'coin_amount' => $coin,
                    'error' => $e->getMessage()
                ]);
                return response()->json(['status' => 500, 'message' => "Transfer failed. Please try again."]);
            }

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

        // Enhanced validation rules
        $rules = [
            'coin' => 'required|integer|min:1|max:10000',
            'amount' => 'required|numeric|min:0.01|max:999.99',
            'payment_method' => 'required|string|in:in_app_purchase,stripe,paypal,google_pay,apple_pay',
            'transaction_reference' => 'required|string|min:10|max:100',
            'platform' => 'required|string|in:ios,android,web',
            'receipt_data' => 'required|string|min:10', // Receipt validation data
            'purchase_timestamp' => 'required|date|before_or_equal:now|after:' . now()->subMinutes(30)->toDateString(),
        ];

        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => 401, 'message' => $msg]);
        }

        $coin = $request->get('coin');
        $amount = $request->get('amount');
        $payment_method = $request->get('payment_method');
        $transaction_reference = $request->get('transaction_reference');
        $platform = $request->get('platform');
        $receipt_data = $request->get('receipt_data');
        $purchase_timestamp = $request->get('purchase_timestamp');

        // Rate limiting check - max 5 purchases per minute
        $recent_purchases = Transaction::where('user_id', $user_id)
            ->where('transaction_type', 'purchase')
            ->where('created_at', '>=', now()->subMinutes(1))
            ->count();

        if ($recent_purchases >= 5) {
            return response()->json([
                'status' => 429, 
                'message' => "Too many purchase attempts. Please wait before trying again."
            ]);
        }

        // Check for duplicate transaction reference
        $existing_transaction = Transaction::where('transaction_reference', $transaction_reference)
            ->where('user_id', $user_id)
            ->first();

        if ($existing_transaction) {
            return response()->json([
                'status' => 409,
                'message' => "Transaction already processed."
            ]);
        }

        // Validate coin plan exists and amount matches
        $coin_plan = CoinPlan::where('coin', $coin)
            ->where('amount', $amount)
            ->first();

        if (!$coin_plan) {
            return response()->json([
                'status' => 401,
                'message' => "Invalid coin plan or amount mismatch."
            ]);
        }

        // Payment verification based on platform
        $payment_verified = false;
        $verification_details = [];

        try {
            switch ($platform) {
                case 'ios':
                    $payment_verified = $this->verifyApplePayment($receipt_data, $amount);
                    break;
                case 'android':
                    $payment_verified = $this->verifyGooglePayment($receipt_data, $amount);
                    break;
                case 'web':
                    $payment_verified = $this->verifyWebPayment($payment_method, $transaction_reference, $amount);
                    break;
            }

            if (!$payment_verified) {
                // Log failed payment verification
                Log::error("Payment verification failed", [
                    'user_id' => $user_id,
                    'amount' => $amount,
                    'coins' => $coin,
                    'transaction_reference' => $transaction_reference,
                    'platform' => $platform,
                    'ip' => $request->ip()
                ]);

                return response()->json([
                    'status' => 402,
                    'message' => "Payment verification failed. Please try again."
                ]);
            }

            // Use database transaction for atomic operation
            DB::beginTransaction();

            // Lock user record for update
            $user = User::where('user_id', $user_id)->lockForUpdate()->first();
            
            if (!$user) {
                DB::rollback();
                return response()->json(['status' => 404, 'message' => "User not found."]);
            }

            // Create transaction record first
            $transaction = Transaction::create([
            'user_id' => $user_id,
            'transaction_type' => 'purchase',
            'coins' => $coin,
            'amount' => $amount,
            'payment_method' => $payment_method,
            'transaction_reference' => $transaction_reference,
            'platform' => $platform,
                'status' => 'completed',
                'meta_data' => json_encode([
                    'receipt_data' => $receipt_data,
                    'purchase_timestamp' => $purchase_timestamp,
                    'verification_details' => $verification_details,
                    'ip_address' => $request->ip(),
                    'user_agent' => $request->userAgent()
                ])
            ]);

            // Update wallet balance
            $wallet_update = User::where('user_id', $user_id)->increment('my_wallet', $coin);

            if (!$wallet_update) {
                DB::rollback();
                return response()->json(['status' => 500, 'message' => "Failed to update wallet."]);
            }

            // Log successful purchase
            Log::info("Coin purchase successful", [
                'user_id' => $user_id,
                'transaction_id' => $transaction->transaction_id,
                'amount' => $amount,
                'coins' => $coin,
                'new_balance' => $user->my_wallet + $coin,
                'ip' => $request->ip()
            ]);

            DB::commit();

            return response()->json([
                'status' => 200, 
                'message' => "Coin Purchased Successfully.",
                'data' => [
                    'transaction_id' => $transaction->transaction_id,
                    'coins_purchased' => $coin,
                    'amount_paid' => $amount,
                    'new_balance' => $user->my_wallet + $coin
                ]
            ]);

        } catch (Exception $e) {
            DB::rollback();
            
            // Log error
            Log::error("Coin purchase error", [
                'user_id' => $user_id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'ip' => $request->ip()
            ]);

            return response()->json([
                'status' => 500,
                'message' => "Purchase failed. Please try again."
            ]);
        }
    }

    /**
     * Verify Apple In-App Purchase
     */
    private function verifyApplePayment($receipt_data, $amount)
    {
        // Implement Apple Store receipt verification
        try {
            // Production URL: https://buy.itunes.apple.com/verifyReceipt
            // Sandbox URL: https://sandbox.itunes.apple.com/verifyReceipt
            
            $receipt_url = config('app.env') === 'production' 
                ? 'https://buy.itunes.apple.com/verifyReceipt'
                : 'https://sandbox.itunes.apple.com/verifyReceipt';

            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $receipt_url);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
                'receipt-data' => $receipt_data,
                'password' => config('services.apple.shared_secret')
            ]));
            curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if ($httpCode !== 200) {
                return false;
            }

            $result = json_decode($response, true);
            return isset($result['status']) && $result['status'] === 0;

        } catch (Exception $e) {
            Log::error("Apple payment verification failed: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Verify Google Play Purchase
     */
    private function verifyGooglePayment($receipt_data, $amount)
    {
        // For testing/development environments, allow mock verification
        if (app()->environment('local', 'testing')) {
            Log::info("Development environment - verifying Google payment with mock data");
            
            // Parse receipt data for basic validation
            $receipt = json_decode($receipt_data, true);
            
            // Basic validation
            if (empty($receipt['packageName']) || empty($receipt['productId']) || empty($receipt['purchaseToken'])) {
                Log::warning("Mock Google verification failed - invalid receipt format", [
                    'receipt_data' => $receipt_data
                ]);
                return false;
            }
            
            // Verify package name matches
            $expectedPackageName = config('services.google.package_name');
            if ($receipt['packageName'] !== $expectedPackageName) {
                Log::warning("Mock Google verification failed - package name mismatch", [
                    'expected' => $expectedPackageName,
                    'received' => $receipt['packageName']
                ]);
                return false;
            }
            
            Log::info("Mock Google verification successful", [
                'packageName' => $receipt['packageName'],
                'productId' => $receipt['productId'],
                'amount' => $amount
            ]);
            
            return true;
        }
        
        // Production Google Play purchase verification
        try {
            Log::info("Verifying Google Play purchase", [
                'amount' => $amount,
                'service_account_key' => config('services.google.service_account_key')
            ]);
            
            // Use Google Play Developer API
            $client = new \Google_Client();
            $client->setAuthConfig(config('services.google.service_account_key'));
            $client->addScope('https://www.googleapis.com/auth/androidpublisher');

            $service = new \Google_Service_AndroidPublisher($client);
            
            $receipt = json_decode($receipt_data, true);
            
            // Validate receipt structure
            if (empty($receipt['packageName']) || empty($receipt['productId']) || empty($receipt['purchaseToken'])) {
                Log::error("Google verification failed - invalid receipt structure", [
                    'receipt_data' => $receipt_data
                ]);
                return false;
            }
            
            $packageName = $receipt['packageName'];
            $productId = $receipt['productId'];
            $token = $receipt['purchaseToken'];
            
            // Verify package name matches
            $expectedPackageName = config('services.google.package_name');
            if ($packageName !== $expectedPackageName) {
                Log::error("Google verification failed - package name mismatch", [
                    'expected' => $expectedPackageName,
                    'received' => $packageName
                ]);
                return false;
            }

            // Get purchase details from Google
            $purchase = $service->purchases_products->get($packageName, $productId, $token);
            
            Log::info("Google Play purchase verification response", [
                'purchaseState' => $purchase->purchaseState,
                'consumptionState' => $purchase->consumptionState ?? 'N/A',
                'purchaseTimeMillis' => $purchase->purchaseTimeMillis ?? 'N/A',
                'productId' => $productId
            ]);
            
            // Check purchase state: 0 = purchased, 1 = canceled, 2 = pending
            if ($purchase->purchaseState === 0) {
                Log::info("Google Play purchase verification successful", [
                    'packageName' => $packageName,
                    'productId' => $productId,
                    'amount' => $amount
                ]);
                return true;
            } else {
                Log::warning("Google Play purchase verification failed - invalid state", [
                    'purchaseState' => $purchase->purchaseState,
                    'productId' => $productId
                ]);
                return false;
            }

        } catch (Exception $e) {
            Log::error("Google payment verification failed - API error", [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'amount' => $amount
            ]);
            return false;
        }
    }

    /**
     * Verify Web Payment (Stripe/PayPal)
     */
    private function verifyWebPayment($payment_method, $transaction_reference, $amount)
    {
        // Implement web payment verification
        try {
            switch ($payment_method) {
                case 'stripe':
                    return $this->verifyStripePayment($transaction_reference, $amount);
                case 'paypal':
                    return $this->verifyPaypalPayment($transaction_reference, $amount);
                default:
                    return false;
            }
        } catch (Exception $e) {
            Log::error("Web payment verification failed: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Verify Stripe Payment
     */
    private function verifyStripePayment($transaction_reference, $amount)
    {
        // Implement Stripe payment verification
        \Stripe\Stripe::setApiKey(config('services.stripe.secret'));
        
        try {
            $payment_intent = \Stripe\PaymentIntent::retrieve($transaction_reference);
            return $payment_intent->status === 'succeeded' && 
                   $payment_intent->amount === ($amount * 100); // Stripe uses cents
        } catch (\Stripe\Exception\ApiErrorException $e) {
            Log::error("Stripe verification failed: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Verify PayPal Payment
     */
    private function verifyPaypalPayment($transaction_reference, $amount)
    {
        // Implement PayPal payment verification
        try {
            $client_id = config('services.paypal.client_id');
            $client_secret = config('services.paypal.client_secret');
            $base_url = config('app.env') === 'production' 
                ? 'https://api.paypal.com' 
                : 'https://api.sandbox.paypal.com';

            // Get access token
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $base_url . '/v1/oauth2/token');
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, 'grant_type=client_credentials');
            curl_setopt($ch, CURLOPT_USERPWD, $client_id . ':' . $client_secret);
            curl_setopt($ch, CURLOPT_HTTPHEADER, ['Accept: application/json']);

            $response = curl_exec($ch);
            $result = json_decode($response, true);
            curl_close($ch);

            if (!isset($result['access_token'])) {
                return false;
            }

            // Verify payment
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $base_url . '/v2/checkout/orders/' . $transaction_reference);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'Authorization: Bearer ' . $result['access_token'],
                'Content-Type: application/json'
            ]);

            $response = curl_exec($ch);
            $payment = json_decode($response, true);
            curl_close($ch);

            return isset($payment['status']) && $payment['status'] === 'COMPLETED';

        } catch (Exception $e) {
            Log::error("PayPal verification failed: " . $e->getMessage());
            return false;
        }
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
            'amount' => 'required|numeric|min:0.01|max:10000',
            'coin' => 'required|integer|min:1|max:100000',
            'redeem_request_type' => 'required|string|in:Paypal,paypal,stripe,bank_transfer,crypto',
            'account' => 'required|string|min:5|max:100',
        ];

        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => 401, 'message' => $msg]);
        }
        
        $coin = $request->get('coin');
        $amount = $request->get('amount');
        $redeem_request_type = $request->get('redeem_request_type');
        $account = $request->get('account');
        
        // Rate limiting: Max 3 redeem requests per day per user
        $recent_redeems = RedeemRequest::where('user_id', $user_id)
            ->where('created_at', '>=', now()->subDays(1))
            ->count();

        if ($recent_redeems >= 3) {
            \Log::warning("Rate limit exceeded for redeem requests", [
                'user_id' => $user_id,
                'recent_redeems' => $recent_redeems,
                'ip' => $request->ip()
            ]);
            return response()->json([
                'status' => 429, 
                'message' => "Too many redeem requests. Please wait before trying again."
            ]);
        }

        // Security: Validate minimum withdrawal amount
        if ($amount < 1.00) {
            return response()->json(['status' => 401, 'message' => "Minimum withdrawal amount is $1.00"]);
        }

        // Security: Validate coin to amount ratio (prevent manipulation)
        $expected_amount = $coin * 0.01; // Assuming 1 coin = $0.01
        if (abs($amount - $expected_amount) > 0.01) {
            \Log::warning("Coin-to-amount ratio manipulation attempt", [
                'user_id' => $user_id,
                'coin' => $coin,
                'amount' => $amount,
                'expected_amount' => $expected_amount,
                'ip' => $request->ip()
            ]);
            return response()->json(['status' => 401, 'message' => "Invalid coin to amount conversion."]);
        }

        \Log::info("Redeem request attempt", [
            'user_id' => $user_id,
            'coin' => $coin,
            'amount' => $amount,
            'redeem_request_type' => $redeem_request_type,
            'ip' => $request->ip()
        ]);
        
        // Check if user has enough coins with atomic transaction
        DB::beginTransaction();
        try {
            $user = User::select('my_wallet')->where('user_id', $user_id)->lockForUpdate()->first();
        if (!$user || $user->my_wallet < $coin) {
                DB::rollBack();
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

            // Deduct coins from wallet
        $remainingCoins = $user->my_wallet - $coin;
            $count_update = User::where('user_id', $user_id)->update(['my_wallet' => $remainingCoins]);

            if ($insert && $count_update) {
                DB::commit();
                \Log::info("Redeem request successful", [
                    'user_id' => $user_id,
                    'coin' => $coin,
                    'amount' => $amount,
                    'remaining_coins' => $remainingCoins
                ]);
            return response()->json(['status' => 200, 'message' => "Redeem Request Successfully."]);
        } else {
                DB::rollBack();
            return response()->json(['status' => 401, 'message' => "Redeem Request Failed."]);
            }
            
        } catch (\Exception $e) {
            DB::rollBack();
            \Log::error("Redeem request failed", [
                'user_id' => $user_id,
                'coin' => $coin,
                'amount' => $amount,
                'error' => $e->getMessage()
            ]);
            return response()->json(['status' => 500, 'message' => "Redeem request failed. Please try again."]);
        }
    }
}
