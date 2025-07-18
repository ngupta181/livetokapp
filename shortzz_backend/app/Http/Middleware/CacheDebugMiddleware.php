<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

class CacheDebugMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @return mixed
     */
    public function handle(Request $request, Closure $next)
    {
        // Only enable cache debugging if APP_DEBUG is true and specific header is present
        if (config('app.debug') && $request->header('X-Cache-Debug') === 'true') {
            $startTime = microtime(true);
            
            // Log the request
            Log::info('Cache Debug - Request started', [
                'method' => $request->method(),
                'url' => $request->fullUrl(),
                'user_id' => $request->user() ? $request->user()->user_id : 'guest'
            ]);
            
            $response = $next($request);
            
            $endTime = microtime(true);
            $executionTime = ($endTime - $startTime) * 1000; // Convert to milliseconds
            
            // Log the response
            Log::info('Cache Debug - Request completed', [
                'execution_time_ms' => round($executionTime, 2),
                'status_code' => $response->getStatusCode()
            ]);
            
            // Add cache debug headers to response
            $response->headers->set('X-Cache-Debug-Time', round($executionTime, 2) . 'ms');
            
            return $response;
        }
        
        return $next($request);
    }
}