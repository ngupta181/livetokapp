<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Http\Request;
use App\BlockedIp;
use App\SuspiciousActivity;

class SecurityMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @return mixed
     */
    public function handle(Request $request, Closure $next, ...$guards)
    {
        $ip = $request->ip();
        $userAgent = $request->userAgent();
        $route = $request->route()->getName();
        $user = $request->user();

        // 1. Check for blocked IPs
        if ($this->isIpBlocked($ip)) {
            Log::warning("Blocked IP attempted access", [
                'ip' => $ip,
                'user_agent' => $userAgent,
                'route' => $route
            ]);
            
            return response()->json([
                'status' => 403,
                'message' => 'Access denied'
            ], 403);
        }

        // 2. Rate limiting based on route type
        $rateLimit = $this->getRateLimitForRoute($route);
        $rateLimitKey = $this->getRateLimitKey($request, $user);

        if (RateLimiter::tooManyAttempts($rateLimitKey, $rateLimit['attempts'])) {
            $this->logSuspiciousActivity($ip, $user?->user_id, 'rate_limit_exceeded', [
                'route' => $route,
                'attempts' => RateLimiter::attempts($rateLimitKey)
            ]);

            return response()->json([
                'status' => 429,
                'message' => 'Too many requests. Please try again later.',
                'retry_after' => RateLimiter::availableIn($rateLimitKey)
            ], 429);
        }

        // 3. Financial operations security
        if ($this->isFinancialOperation($route)) {
            $securityCheck = $this->performFinancialSecurityCheck($request);
            if (!$securityCheck['passed']) {
                return response()->json([
                    'status' => 403,
                    'message' => $securityCheck['message']
                ], 403);
            }
        }

        // 4. Device fingerprinting
        if ($user && $this->isNewDevice($request, $user)) {
            $this->logSuspiciousActivity($ip, $user->user_id, 'new_device_detected', [
                'user_agent' => $userAgent,
                'route' => $route
            ]);
        }

        // 5. Increment rate limiter
        RateLimiter::hit($rateLimitKey, $rateLimit['decay']);

        $response = $next($request);

        // 6. Log successful requests for high-value operations
        if ($this->shouldLogRequest($route)) {
            Log::info("Security middleware: Request processed", [
                'user_id' => $user?->user_id,
                'ip' => $ip,
                'route' => $route,
                'status' => $response->getStatusCode()
            ]);
        }

        return $response;
    }

    /**
     * Check if IP is blocked
     */
    private function isIpBlocked($ip)
    {
        // Check cache first for performance
        $cacheKey = "blocked_ip:{$ip}";
        if (Cache::has($cacheKey)) {
            return Cache::get($cacheKey);
        }

        // Check database
        $blocked = BlockedIp::where('ip_address', $ip)
            ->where('is_active', true)
            ->where(function($query) {
                $query->whereNull('expires_at')
                      ->orWhere('expires_at', '>', now());
            })
            ->exists();

        // Cache result for 5 minutes
        Cache::put($cacheKey, $blocked, 300);

        return $blocked;
    }

    /**
     * Get rate limit configuration for route
     */
    private function getRateLimitForRoute($route)
    {
        $limits = [
            // Financial operations - very strict
            'wallet.purchaseCoin' => ['attempts' => 5, 'decay' => 60],
            'wallet.sendCoin' => ['attempts' => 10, 'decay' => 60],
            'wallet.redeemRequest' => ['attempts' => 3, 'decay' => 300],
            'wallet.addCoin' => ['attempts' => 20, 'decay' => 60],
            
            // Authentication - moderate
            'login' => ['attempts' => 5, 'decay' => 300],
            'User.Registration' => ['attempts' => 3, 'decay' => 600],
            
            // General API - lenient
            'default' => ['attempts' => 100, 'decay' => 60]
        ];

        return $limits[$route] ?? $limits['default'];
    }

    /**
     * Generate rate limit key
     */
    private function getRateLimitKey($request, $user)
    {
        $route = $request->route()->getName();
        $ip = $request->ip();
        $userId = $user?->user_id ?? 'anonymous';

        return "rate_limit:{$route}:{$userId}:{$ip}";
    }

    /**
     * Check if route is financial operation
     */
    private function isFinancialOperation($route)
    {
        $financialRoutes = [
            'wallet.purchaseCoin',
            'wallet.sendCoin',
            'wallet.redeemRequest',
            'wallet.addCoin'
        ];

        return in_array($route, $financialRoutes);
    }

    /**
     * Perform security checks for financial operations
     */
    private function performFinancialSecurityCheck($request)
    {
        $user = $request->user();
        $ip = $request->ip();
        $route = $request->route()->getName();

        // Check for unusual patterns
        $recentTransactions = \App\Transaction::where('user_id', $user->user_id)
            ->where('created_at', '>=', now()->subMinutes(10))
            ->count();

        if ($recentTransactions > 10) {
            $this->logSuspiciousActivity($ip, $user->user_id, 'rapid_transactions', [
                'transaction_count' => $recentTransactions,
                'route' => $route
            ]);

            return [
                'passed' => false,
                'message' => 'Unusual activity detected. Please contact support.'
            ];
        }

        // Check for amount anomalies
        if ($route === 'wallet.purchaseCoin') {
            $amount = $request->get('amount', 0);
            $userHistory = \App\Transaction::where('user_id', $user->user_id)
                ->where('transaction_type', 'purchase')
                ->avg('amount');

            if ($userHistory && $amount > ($userHistory * 10)) {
                $this->logSuspiciousActivity($ip, $user->user_id, 'unusual_amount', [
                    'current_amount' => $amount,
                    'average_amount' => $userHistory,
                    'route' => $route
                ]);

                // Don't block but log for review
            }
        }

        return ['passed' => true, 'message' => 'Security check passed'];
    }

    /**
     * Check if request is from new device
     */
    private function isNewDevice($request, $user)
    {
        $deviceFingerprint = $this->generateDeviceFingerprint($request);
        $cacheKey = "device:{$user->user_id}:{$deviceFingerprint}";

        if (Cache::has($cacheKey)) {
            return false;
        }

        // Store device fingerprint for 30 days
        Cache::put($cacheKey, true, 43200); // 30 days in minutes

        return true;
    }

    /**
     * Generate device fingerprint
     */
    private function generateDeviceFingerprint($request)
    {
        $components = [
            $request->userAgent(),
            $request->header('Accept-Language'),
            $request->header('Accept-Encoding'),
            $request->header('Accept'),
        ];

        return hash('sha256', implode('|', array_filter($components)));
    }

    /**
     * Log suspicious activity
     */
    private function logSuspiciousActivity($ip, $userId, $activityType, $details = [])
    {
        try {
            SuspiciousActivity::create([
                'user_id' => $userId,
                'ip_address' => $ip,
                'activity_type' => $activityType,
                'details' => json_encode($details),
                'created_at' => now()
            ]);

            Log::warning("Suspicious activity detected", [
                'user_id' => $userId,
                'ip' => $ip,
                'type' => $activityType,
                'details' => $details
            ]);
        } catch (\Exception $e) {
            Log::error("Failed to log suspicious activity: " . $e->getMessage());
        }
    }

    /**
     * Check if request should be logged
     */
    private function shouldLogRequest($route)
    {
        $loggedRoutes = [
            'wallet.purchaseCoin',
            'wallet.sendCoin',
            'wallet.redeemRequest',
            'User.Registration',
            'login'
        ];

        return in_array($route, $loggedRoutes);
    }
} 