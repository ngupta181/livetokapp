<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use App\User;
use App\Transaction;
use App\BlockedIp;
use Cache;
use Log;

class WalletSecurityMiddleware
{
    /**
     * Handle an incoming request for wallet operations with enhanced security
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure(\Illuminate\Http\Request): (\Illuminate\Http\Response|\Illuminate\Http\RedirectResponse)  $next
     * @return \Illuminate\Http\Response|\Illuminate\Http\RedirectResponse
     */
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();
        $ip = $request->ip();
        $userAgent = $request->userAgent();
        
        // 0. Check if in testing mode or whitelisted
        if ($this->isTestingModeOrWhitelisted($ip)) {
            \Log::info("Wallet security bypassed for testing/whitelisted IP", [
                'ip' => $ip,
                'user_id' => $user->user_id ?? null,
                'endpoint' => $request->path(),
                'testing_mode' => config('wallet_security.ip_blocking.testing_mode.enabled', false)
            ]);
            
            // Still log the activity but bypass security checks
            $response = $next($request);
            $this->logWalletActivity($user, $ip, $request, $response);
            return $response;
        }
        
        // 1. IP Blocking Check
        if ($this->isIpBlocked($ip)) {
            Log::warning("Blocked IP attempted wallet access", [
                'ip' => $ip,
                'user_id' => $user->user_id ?? null,
                'endpoint' => $request->path(),
                'user_agent' => $userAgent
            ]);
            
            return response()->json([
                'status' => 403,
                'message' => 'Access denied. Contact support if you believe this is an error.'
            ], 403);
        }
        
        // 2. User Account Blocking Check
        if ($user && $this->isUserBlocked($user->user_id)) {
            Log::warning("Blocked user attempted wallet access", [
                'user_id' => $user->user_id,
                'ip' => $ip,
                'endpoint' => $request->path()
            ]);
            
            return response()->json([
                'status' => 403,
                'message' => 'Account temporarily suspended. Contact support for assistance.'
            ], 403);
        }
        
        // 3. Suspicious Activity Detection
        if ($user && $this->detectSuspiciousActivity($user->user_id, $ip, $request)) {
            Log::alert("Suspicious wallet activity detected", [
                'user_id' => $user->user_id,
                'ip' => $ip,
                'endpoint' => $request->path(),
                'user_agent' => $userAgent,
                'request_data' => $request->all()
            ]);
            
            // Auto-block highly suspicious activity
            if ($this->isHighlysuspicious($user->user_id, $ip, $request)) {
                $this->blockUserTemporarily($user->user_id);
                $this->blockIpTemporarily($ip);
                
                return response()->json([
                    'status' => 429,
                    'message' => 'Suspicious activity detected. Account temporarily restricted.'
                ], 429);
            }
        }
        
        // 4. Rate Limiting Enhancement (Global)
        if ($this->isGlobalRateLimitExceeded($ip)) {
            Log::warning("Global rate limit exceeded", [
                'ip' => $ip,
                'user_id' => $user->user_id ?? null,
                'endpoint' => $request->path()
            ]);
            
            return response()->json([
                'status' => 429,
                'message' => 'Too many requests. Please slow down.'
            ], 429);
        }
        
        // Continue to the next middleware/controller
        $response = $next($request);
        
        // 5. Post-request monitoring
        $this->logWalletActivity($user, $ip, $request, $response);
        
        return $response;
    }
    
    /**
     * Check if IP is in testing mode or whitelisted
     */
    private function isTestingModeOrWhitelisted($ip)
    {
        // Check if testing mode is enabled
        $testingMode = config('wallet_security.ip_blocking.testing_mode.enabled', false);
        
        if ($testingMode) {
            $allowedIps = config('wallet_security.ip_blocking.testing_mode.allowed_ips', []);
            if (in_array($ip, $allowedIps)) {
                return true;
            }
        }
        
        // Check whitelist
        $whitelist = config('wallet_security.ip_blocking.whitelist', []);
        return in_array($ip, $whitelist);
    }
    
    /**
     * Check if an IP address is blocked
     */
    private function isIpBlocked($ip)
    {
        // Check database for blocked IPs
        $isBlockedInDb = BlockedIp::isBlocked($ip);
        
        if ($isBlockedInDb) {
            return true;
        }
        
        // Check permanent blocks from config
        $permanentBlocks = config('wallet_security.ip_blocking.permanent_blocks', []);
        
        if (in_array($ip, $permanentBlocks)) {
            return true;
        }
        
        // Check temporary blocks in cache (for immediate blocking)
        return Cache::has("blocked_ip:{$ip}");
    }
    
    /**
     * Check if a user is blocked
     */
    private function isUserBlocked($userId)
    {
        // Check database for user status
        $user = User::where('user_id', $userId)->first();
        if ($user && isset($user->is_blocked) && $user->is_blocked) {
            return true;
        }
        
        // Check temporary blocks
        return Cache::has("blocked_user:{$userId}");
    }
    
    /**
     * Detect suspicious activity patterns
     */
    private function detectSuspiciousActivity($userId, $ip, $request)
    {
        $endpoint = $request->path();
        $suspicious = false;
        
        // 1. Multiple failed transactions
        $recentFailed = Transaction::where('user_id', $userId)
            ->where('status', 'failed')
            ->where('created_at', '>=', now()->subMinutes(10))
            ->count();
            
        if ($recentFailed >= 3) {
            $suspicious = true;
        }
        
        // 2. Rapid-fire requests
        $cacheKey = "requests:{$userId}:{$ip}:" . now()->format('Y-m-d-H-i');
        $requestCount = Cache::get($cacheKey, 0);
        Cache::put($cacheKey, $requestCount + 1, 60);
        
        if ($requestCount >= 30) { // 30 requests per minute
            $suspicious = true;
        }
        
        // 3. Unusual request patterns
        if ($this->hasUnusualPatterns($userId, $request)) {
            $suspicious = true;
        }
        
        return $suspicious;
    }
    
    /**
     * Check for highly suspicious activity requiring immediate action
     */
    private function isHighlysuspicious($userId, $ip, $request)
    {
        // 1. Attempting negative amounts
        $coin = $request->get('coin');
        $amount = $request->get('amount');
        $points = $request->get('points');
        
        if (($coin && $coin < 0) || ($amount && $amount < 0) || ($points && $points < 0)) {
            return true;
        }
        
        // 2. Extremely high amounts
        if (($coin && $coin > 50000) || ($amount && $amount > 1000) || ($points && $points > 50000)) {
            return true;
        }
        
        // 3. Multiple rate limit violations
        $violations = Cache::get("rate_violations:{$userId}", 0);
        if ($violations >= 3) {
            return true;
        }
        
        return false;
    }
    
    /**
     * Check for unusual request patterns
     */
    private function hasUnusualPatterns($userId, $request)
    {
        // 1. Same exact request repeated rapidly
        $requestHash = md5(json_encode($request->all()));
        $cacheKey = "request_hash:{$userId}:{$requestHash}";
        $hashCount = Cache::get($cacheKey, 0);
        Cache::put($cacheKey, $hashCount + 1, 300); // 5 minutes
        
        if ($hashCount >= 5) {
            return true;
        }
        
        // 2. Requests from multiple IPs for same user rapidly
        $userIpKey = "user_ips:{$userId}";
        $userIps = Cache::get($userIpKey, []);
        $userIps[] = $request->ip();
        $uniqueIps = array_unique($userIps);
        Cache::put($userIpKey, $uniqueIps, 600); // 10 minutes
        
        if (count($uniqueIps) >= 5) { // 5 different IPs in 10 minutes
            return true;
        }
        
        return false;
    }
    
    /**
     * Check global rate limiting
     */
    private function isGlobalRateLimitExceeded($ip)
    {
        $cacheKey = "global_rate:{$ip}:" . now()->format('Y-m-d-H-i');
        $requestCount = Cache::get($cacheKey, 0);
        Cache::put($cacheKey, $requestCount + 1, 60);
        
        return $requestCount >= 100; // 100 requests per minute globally
    }
    
    /**
     * Temporarily block a user
     */
    private function blockUserTemporarily($userId)
    {
        Cache::put("blocked_user:{$userId}", true, 3600); // 1 hour
        
        Log::alert("User temporarily blocked for suspicious activity", [
            'user_id' => $userId,
            'duration' => '1 hour'
        ]);
    }
    
    /**
     * Temporarily block an IP
     */
    private function blockIpTemporarily($ip)
    {
        // Block in cache for immediate effect
        Cache::put("blocked_ip:{$ip}", true, 7200); // 2 hours
        
        // Block in database for persistent storage
        BlockedIp::blockIp(
            $ip,
            'Automatically blocked for suspicious activity',
            null, // No specific admin user
            now()->addHours(2) // Expires in 2 hours
        );
        
        Log::alert("IP temporarily blocked for suspicious activity", [
            'ip' => $ip,
            'duration' => '2 hours',
            'blocked_in_db' => true
        ]);
    }
    
    /**
     * Log wallet activity for monitoring
     */
    private function logWalletActivity($user, $ip, $request, $response)
    {
        $responseData = json_decode($response->getContent(), true);
        $status = $responseData['status'] ?? $response->getStatusCode();
        
        Log::info("Wallet activity", [
            'user_id' => $user->user_id ?? null,
            'ip' => $ip,
            'endpoint' => $request->path(),
            'method' => $request->method(),
            'request_data' => $request->all(),
            'response_status' => $status,
            'user_agent' => $request->userAgent(),
            'timestamp' => now()->toISOString()
        ]);
        
        // Track rate limit violations
        if ($status == 429) {
            $userId = $user->user_id ?? null;
            if ($userId) {
                $violations = Cache::get("rate_violations:{$userId}", 0);
                Cache::put("rate_violations:{$userId}", $violations + 1, 3600);
            }
        }
    }
} 