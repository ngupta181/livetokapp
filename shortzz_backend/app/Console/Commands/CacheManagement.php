<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Services\CacheInvalidationService;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Redis;

class CacheManagement extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'cache:manage 
                            {action : The action to perform (stats|clear|test|invalidate-user|invalidate-post|clear-user-videos|debug-cache|force-clean)}
                            {--user-id= : User ID for user-specific operations}
                            {--post-id= : Post ID for post-specific operations}
                            {--hashtags= : Hashtags for post invalidation}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Manage Redis cache operations for debugging and maintenance';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $action = $this->argument('action');

        switch ($action) {
            case 'stats':
                $this->showCacheStats();
                break;
                
            case 'clear':
                $this->clearAllCache();
                break;
                
            case 'test':
                $this->testCacheConnection();
                break;
                
            case 'invalidate-user':
                $this->invalidateUserCache();
                break;
                
            case 'invalidate-post':
                $this->invalidatePostCache();
                break;
                
            case 'clear-user-videos':
                $this->clearUserVideosCache();
                break;
                
            case 'debug-cache':
                $this->debugCache();
                break;
                
            case 'force-clean':
                $this->forceCleanCache();
                break;
                
            default:
                $this->error('Invalid action. Available actions: stats, clear, test, invalidate-user, invalidate-post, clear-user-videos, debug-cache, force-clean');
                return 1;
        }

        return 0;
    }

    /**
     * Show cache statistics
     */
    private function showCacheStats()
    {
        $this->info('Redis Cache Statistics:');
        $this->line('========================');
        
        $stats = CacheInvalidationService::getCacheStats();
        
        if (isset($stats['error'])) {
            $this->error('Error getting cache stats: ' . $stats['error']);
            return;
        }
        
        foreach ($stats as $key => $value) {
            $this->line(ucfirst(str_replace('_', ' ', $key)) . ': ' . $value);
        }
        
        // Show some sample keys for Redis
        if (config('cache.default') === 'redis') {
            try {
                $redis = Redis::connection();
                $keys = $redis->scan(0, ['COUNT' => 10])[1];
                
                $this->line('');
                $this->info('Sample Cache Keys:');
                $this->line('==================');
                
                foreach (array_slice($keys, 0, 10) as $key) {
                    $this->line('- ' . $key);
                }
                
            } catch (\Exception $e) {
                $this->error('Error getting sample keys: ' . $e->getMessage());
            }
        }
    }

    /**
     * Clear all cache
     */
    private function clearAllCache()
    {
        if ($this->confirm('Are you sure you want to clear ALL cache? This cannot be undone.')) {
            CacheInvalidationService::clearAllCache();
            $this->info('All cache cleared successfully.');
        } else {
            $this->info('Cache clear cancelled.');
        }
    }

    /**
     * Test cache connection
     */
    private function testCacheConnection()
    {
        $cacheDriver = config('cache.default');
        $this->info("Testing cache connection (Driver: {$cacheDriver})...");
        
        try {
            if ($cacheDriver === 'redis') {
                // Test basic Redis connection
                $redis = Redis::connection();
                $pong = $redis->ping();
                $this->info('✓ Redis connection successful: ' . $pong);
                
                // Test cache prefix
                $prefix = config('database.redis.options.prefix', 'No prefix set');
                $this->info('Cache prefix: ' . $prefix);
            } else {
                $this->info("✓ Using {$cacheDriver} cache driver");
            }
            
            // Test Laravel Cache facade
            $testKey = 'cache_test_' . time();
            $testValue = 'test_value_' . rand(1000, 9999);
            
            Cache::put($testKey, $testValue, 60);
            $retrieved = Cache::get($testKey);
            
            if ($retrieved === $testValue) {
                $this->info('✓ Laravel Cache facade working correctly');
                Cache::forget($testKey);
            } else {
                $this->error('✗ Laravel Cache facade not working correctly');
            }
            
        } catch (\Exception $e) {
            $this->error('✗ Cache connection failed: ' . $e->getMessage());
        }
    }

    /**
     * Invalidate user cache
     */
    private function invalidateUserCache()
    {
        $userId = $this->option('user-id');
        
        if (!$userId) {
            $userId = $this->ask('Enter User ID to invalidate cache for:');
        }
        
        if (!$userId) {
            $this->error('User ID is required');
            return;
        }
        
        $this->info("Invalidating cache for user: {$userId}");
        CacheInvalidationService::invalidateUserCache($userId);
        $this->info('User cache invalidated successfully.');
    }

    /**
     * Invalidate post cache
     */
    private function invalidatePostCache()
    {
        $postId = $this->option('post-id');
        $userId = $this->option('user-id');
        $hashtags = $this->option('hashtags');
        
        if (!$postId) {
            $postId = $this->ask('Enter Post ID to invalidate cache for:');
        }
        
        if (!$userId) {
            $userId = $this->ask('Enter User ID (post owner):');
        }
        
        if (!$postId || !$userId) {
            $this->error('Both Post ID and User ID are required');
            return;
        }
        
        $this->info("Invalidating cache for post: {$postId}, user: {$userId}");
        CacheInvalidationService::invalidatePostCache($postId, $userId, $hashtags);
        $this->info('Post cache invalidated successfully.');
    }
    
    /**
     * Clear user videos cache specifically
     */
    private function clearUserVideosCache()
    {
        $userId = $this->option('user-id');
        
        if (!$userId) {
            $userId = $this->ask('Enter User ID to clear video cache for:');
        }
        
        if (!$userId) {
            $this->error('User ID is required');
            return;
        }
        
        $this->info("Clearing user videos cache for user: {$userId}");
        
        // Clear user videos cache using the service
        CacheInvalidationService::invalidateUserCache($userId);
        
        // Also clear any remaining user video caches manually
        $cacheDriver = config('cache.default');
        if ($cacheDriver === 'file') {
            $cacheDir = storage_path('framework/cache/data');
            if (is_dir($cacheDir)) {
                $files = glob($cacheDir . '/*');
                $deletedCount = 0;
                
                foreach ($files as $file) {
                    if (is_file($file)) {
                        $content = file_get_contents($file);
                        if (strpos($content, 'user:videos:' . $userId) !== false) {
                            unlink($file);
                            $deletedCount++;
                        }
                    }
                }
                
                $this->info("Deleted {$deletedCount} user video cache files.");
            }
        }
        
        $this->info('User videos cache cleared successfully.');
    }
    
    /**
     * Debug cache contents
     */
    private function debugCache()
    {
        $cacheDriver = config('cache.default');
        $this->info("Debugging cache contents (Driver: {$cacheDriver})");
        
        if ($cacheDriver === 'file') {
            $cacheDir = storage_path('framework/cache/data');
            if (is_dir($cacheDir)) {
                $files = glob($cacheDir . '/*');
                $this->info("Found " . count($files) . " cache files:");
                
                foreach (array_slice($files, 0, 10) as $file) {
                    if (is_file($file)) {
                        $content = file_get_contents($file);
                        $filename = basename($file);
                        
                        // Try to extract the cache key from the content
                        if (preg_match('/s:\d+:"([^"]+)"/', $content, $matches)) {
                            $this->line("File: {$filename} -> Key: {$matches[1]}");
                        } else {
                            $this->line("File: {$filename} -> Content length: " . strlen($content));
                        }
                    }
                }
                
                if (count($files) > 10) {
                    $this->line("... and " . (count($files) - 10) . " more files");
                }
            } else {
                $this->error("Cache directory not found: {$cacheDir}");
            }
        } else {
            $this->info("Debug not implemented for {$cacheDriver} driver");
        }
    }
    
    /**
     * Force clean all cache files
     */
    private function forceCleanCache()
    {
        if ($this->confirm('This will delete ALL cache files. Are you sure?')) {
            CacheInvalidationService::forceCleanFileCache();
            $this->info('All cache files have been deleted.');
        } else {
            $this->info('Force clean cancelled.');
        }
    }
}