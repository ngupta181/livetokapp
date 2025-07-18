<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Log;

class GeoIPCacheServiceProvider extends ServiceProvider
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
        // Configure GeoIP cache settings based on the cache driver
        $cacheDriver = config('cache.default');
        
        if ($cacheDriver === 'file' || $cacheDriver === 'database') {
            // File and database cache drivers don't support tagging
            config(['geoip.cache_tags' => []]);
            Log::info("GeoIP cache tags disabled for {$cacheDriver} driver");
        } else {
            // Redis and other drivers support tagging
            config(['geoip.cache_tags' => ['torann-geoip-location']]);
            Log::info("GeoIP cache tags enabled for {$cacheDriver} driver");
        }
    }
}