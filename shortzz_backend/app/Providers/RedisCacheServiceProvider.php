<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Redis;
use Illuminate\Support\Facades\Log;

class RedisCacheServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     *
     * @return void
     */
    public function register()
    {
        //
    }

    /**
     * Bootstrap services.
     *
     * @return void
     */
    public function boot()
    {
        // First check if the Predis\Client class exists
        if (!class_exists('Predis\Client')) {
            Log::warning('Predis client not found. Please run: composer require predis/predis');
            // Fallback to file driver
            config(['cache.default' => 'file']);
            config(['session.driver' => 'file']);
            config(['queue.default' => 'sync']);
            return;
        }
        
        // Then check if Redis is connected
        try {
            Redis::connection()->ping();
            // Redis is available, continue using Redis driver
            Log::info('Redis connection successful');
        } catch (\Exception $e) {
            // Redis is not available, fallback to file driver
            Log::warning('Redis connection failed: ' . $e->getMessage());
            config(['cache.default' => 'file']);
            config(['session.driver' => 'file']);
            config(['queue.default' => 'sync']);
        }
    }
} 