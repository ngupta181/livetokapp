<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Redis;
use Illuminate\Support\Facades\Log;
use App\CacheKeys;

class CacheInvalidationService
{
    /**
     * Invalidate user-related caches
     * 
     * @param int $userId
     * @return void
     */
    public static function invalidateUserCache($userId)
    {
        try {
            $userId = (string) $userId;
            Log::info("Starting cache invalidation for user: " . $userId);

            // Direct cache key deletions (more reliable than pattern matching)
            $keysToDelete = [
                // User profile caches
                CacheKeys::USER_PROFILE . $userId,
                'user:' . $userId,
                
                // User stats
                'followers_count:' . $userId,
                'following_count:' . $userId,
                'user:post_likes:' . $userId,
                
                // Profile category
                'profile_category:' . $userId,
                
                // Follow relationships (we'll need to clear these separately)
                'is_follow:*:' . $userId,
                'is_block:*:' . $userId,
            ];

            // Delete direct keys
            foreach ($keysToDelete as $key) {
                if (strpos($key, '*') === false) {
                    Cache::forget($key);
                    Log::debug("Deleted cache key: " . $key);
                }
            }

            // Handle cache clearing based on driver type
            $cacheDriver = config('cache.default');
            if ($cacheDriver === 'file' || $cacheDriver === 'database') {
                // For file cache, clear specific common cache keys
                $additionalKeys = [
                    // User profile variations
                    CacheKeys::USER_PROFILE . $userId . ':' . $userId,
                    CacheKeys::USER_PROFILE . $userId . ':0',
                    
                    // User videos with common pagination
                    CacheKeys::USER_VIDEOS . $userId . ':0:10',
                    CacheKeys::USER_VIDEOS . $userId . ':0:20',
                    CacheKeys::USER_VIDEOS . $userId . ':10:10',
                    CacheKeys::USER_VIDEOS . $userId . ':20:10',
                    
                    // Follow relationships - common patterns
                    'is_follow:' . $userId . ':*',
                    'follow:' . $userId . ':*',
                ];
                
                foreach ($additionalKeys as $key) {
                    if (strpos($key, '*') === false) {
                        Cache::forget($key);
                        Log::debug("Deleted additional cache key: " . $key);
                    }
                }
            } else {
                // For Redis, use pattern-based deletion
                self::deleteKeysByPattern('is_follow:*:' . $userId);
                self::deleteKeysByPattern('follow:' . $userId . ':*');
                self::deleteKeysByPattern('follow:*:' . $userId);
                self::deleteKeysByPattern('is_block:*:' . $userId);
                self::deleteKeysByPattern(CacheKeys::USER_VIDEOS . $userId . ':*');
                self::deleteKeysByPattern(CacheKeys::USER_PROFILE . $userId . ':*');
            }

            Log::info("Successfully invalidated user cache for user: " . $userId);
            
        } catch (\Exception $e) {
            Log::error("Error invalidating user cache for user {$userId}: " . $e->getMessage());
            Log::error("Stack trace: " . $e->getTraceAsString());
        }
    }

    /**
     * Invalidate post-related caches
     * 
     * @param mixed $postId
     * @param mixed $userId
     * @param string|null $hashtags
     * @return void
     */
    public static function invalidatePostCache($postId, $userId, $hashtags = null)
    {
        try {
            // Handle different data types for postId and userId
            if (is_array($postId)) {
                $postId = isset($postId['post_id']) ? $postId['post_id'] : (string) $postId[0];
            } elseif (is_object($postId)) {
                $postId = isset($postId->post_id) ? $postId->post_id : (string) $postId;
            } else {
                $postId = (string) $postId;
            }
            
            if (is_array($userId)) {
                $userId = isset($userId['user_id']) ? $userId['user_id'] : (string) $userId[0];
            } elseif (is_object($userId)) {
                $userId = isset($userId->user_id) ? $userId->user_id : (string) $userId;
            } else {
                $userId = (string) $userId;
            }
            
            Log::info("Starting cache invalidation for post: {$postId}, user: {$userId}");

            // Direct post-related cache deletions
            $keysToDelete = [
                CacheKeys::POST_DETAIL . $postId,
                CacheKeys::POST_COMMENTS . $postId,
                CacheKeys::POST_LIKES . $postId,
                'post_comments:' . $postId,
                'post_likes:' . $postId,
            ];

            foreach ($keysToDelete as $key) {
                Cache::forget($key);
                Log::debug("Deleted post cache key: " . $key);
            }

            // For file cache driver, we need to manually clear specific user video cache keys
            // since pattern matching doesn't work
            $cacheDriver = config('cache.default');
            if ($cacheDriver === 'file' || $cacheDriver === 'database') {
                // For file cache, we need to scan and delete files that match the pattern
                self::clearFileCacheByPattern(CacheKeys::USER_VIDEOS . $userId . ':');
                
                // Clear trending posts
                self::clearFileCacheByPattern(CacheKeys::TRENDING_POSTS);
                
                // Clear recommendation caches
                self::clearFileCacheByPattern(CacheKeys::RECOMMENDATION_FOR_USER . $userId . ':');
            } else {
                // For Redis, use pattern-based deletion
                self::deleteKeysByPattern(CacheKeys::USER_VIDEOS . $userId . ':*');
                self::deleteKeysByPattern(CacheKeys::TRENDING_POSTS . '*');
                self::deleteKeysByPattern(CacheKeys::RECOMMENDATION_FOR_USER . $userId . ':*');
            }
            
            // Clear hashtag caches if provided
            if (!empty($hashtags)) {
                self::invalidateHashtagCaches($hashtags);
            }

            Log::info("Successfully invalidated post cache for post: {$postId}");
            
        } catch (\Exception $e) {
            Log::error("Error invalidating post cache for post " . (is_scalar($postId) ? $postId : 'non-scalar') . ": " . $e->getMessage());
            Log::error("Stack trace: " . $e->getTraceAsString());
        }
    }

    /**
     * Invalidate hashtag-related caches
     * 
     * @param string $hashtagString
     * @return void
     */
    public static function invalidateHashtagCaches($hashtagString)
    {
        try {
            $hashtags = explode(',', $hashtagString);
            
            foreach ($hashtags as $hashtag) {
                $hashtag = trim($hashtag);
                if (!empty($hashtag)) {
                    Cache::forget(CacheKeys::POST_BY_TAG . $hashtag);
                    Log::debug("Deleted hashtag cache: " . CacheKeys::POST_BY_TAG . $hashtag);
                }
            }
            
            // Clear trending hashtags
            Cache::forget(CacheKeys::HASHTAG_TRENDING);
            
        } catch (\Exception $e) {
            Log::error("Error invalidating hashtag caches: " . $e->getMessage());
        }
    }

    /**
     * Invalidate recommendation caches
     * 
     * @param int $userId
     * @return void
     */
    public static function invalidateRecommendationCache($userId)
    {
        try {
            $userId = (string) $userId;
            
            // Clear user-specific recommendations
            self::deleteKeysByPattern(CacheKeys::RECOMMENDATION_FOR_USER . $userId . ':*');
            
            // Clear trending posts that might affect recommendations
            self::deleteKeysByPattern(CacheKeys::TRENDING_POSTS . '*');
            
            Log::info("Successfully invalidated recommendation cache for user: {$userId}");
            
        } catch (\Exception $e) {
            Log::error("Error invalidating recommendation cache for user {$userId}: " . $e->getMessage());
        }
    }

    /**
     * Delete cache keys by pattern using SCAN instead of KEYS for better performance
     * 
     * @param string $pattern
     * @return void
     */
    private static function deleteKeysByPattern($pattern)
    {
        $cacheDriver = config('cache.default');
        
        // For Redis cache driver
        if ($cacheDriver === 'redis') {
            try {
                $redis = Redis::connection();
                $prefix = config('database.redis.options.prefix', '');
                $fullPattern = $prefix . $pattern;
                
                // Use SCAN instead of KEYS for better performance
                $cursor = 0;
                $deletedCount = 0;
                
                do {
                    $result = $redis->scan($cursor, ['MATCH' => $fullPattern, 'COUNT' => 100]);
                    $cursor = $result[0];
                    $keys = $result[1];
                    
                    if (!empty($keys)) {
                        // Remove prefix from keys before deletion if using Laravel's cache
                        $keysToDelete = [];
                        foreach ($keys as $key) {
                            if ($prefix && strpos($key, $prefix) === 0) {
                                $keysToDelete[] = substr($key, strlen($prefix));
                            } else {
                                $keysToDelete[] = $key;
                            }
                        }
                        
                        // Delete keys in batches
                        foreach ($keysToDelete as $key) {
                            Cache::forget($key);
                            $deletedCount++;
                        }
                    }
                    
                } while ($cursor != 0);
                
                if ($deletedCount > 0) {
                    Log::debug("Deleted {$deletedCount} keys matching pattern: {$pattern}");
                }
                
            } catch (\Exception $e) {
                Log::error("Error deleting Redis keys by pattern {$pattern}: " . $e->getMessage());
                
                // Fallback to the old method if SCAN fails
                try {
                    $redis = app('redis')->connection();
                    $prefix = Cache::getPrefix();
                    $fullPattern = $prefix . $pattern;
                    
                    $keys = $redis->keys($fullPattern);
                    if (!empty($keys)) {
                        foreach ($keys as $key) {
                            $keyWithoutPrefix = $prefix ? substr($key, strlen($prefix)) : $key;
                            Cache::forget($keyWithoutPrefix);
                        }
                        Log::debug("Fallback: Deleted " . count($keys) . " keys matching pattern: {$pattern}");
                    }
                } catch (\Exception $fallbackException) {
                    Log::error("Fallback method also failed for pattern {$pattern}: " . $fallbackException->getMessage());
                }
            }
        } else {
            // For file cache driver or other drivers, we can't use pattern matching
            // So we'll just log that pattern-based deletion is not supported
            Log::info("Pattern-based cache deletion not supported for {$cacheDriver} driver. Pattern: {$pattern}");
            
            // For file cache, we could potentially scan the cache directory
            // but it's not as efficient, so we'll skip pattern matching for now
            // Individual cache keys will still be deleted via Cache::forget()
        }
    }

    /**
     * Clear all application caches (use with caution)
     * 
     * @return void
     */
    public static function clearAllCache()
    {
        try {
            Cache::flush();
            Log::info("All application caches cleared");
        } catch (\Exception $e) {
            Log::error("Error clearing all caches: " . $e->getMessage());
        }
    }

    /**
     * Get cache statistics
     * 
     * @return array
     */
    public static function getCacheStats()
    {
        $cacheDriver = config('cache.default');
        
        try {
            if ($cacheDriver === 'redis') {
                $redis = Redis::connection();
                $info = $redis->info('memory');
                
                return [
                    'driver' => 'redis',
                    'used_memory' => $info['used_memory'] ?? 'N/A',
                    'used_memory_human' => $info['used_memory_human'] ?? 'N/A',
                    'used_memory_peak' => $info['used_memory_peak'] ?? 'N/A',
                    'used_memory_peak_human' => $info['used_memory_peak_human'] ?? 'N/A',
                ];
            } else {
                // For file cache or other drivers
                $cacheDir = storage_path('framework/cache');
                $stats = [
                    'driver' => $cacheDriver,
                    'cache_directory' => $cacheDir,
                ];
                
                if (is_dir($cacheDir)) {
                    $files = glob($cacheDir . '/data/*');
                    $stats['cache_files_count'] = count($files);
                    
                    $totalSize = 0;
                    foreach ($files as $file) {
                        if (is_file($file)) {
                            $totalSize += filesize($file);
                        }
                    }
                    $stats['total_cache_size'] = $totalSize;
                    $stats['total_cache_size_human'] = self::formatBytes($totalSize);
                } else {
                    $stats['cache_files_count'] = 0;
                    $stats['total_cache_size'] = 0;
                }
                
                return $stats;
            }
        } catch (\Exception $e) {
            Log::error("Error getting cache stats: " . $e->getMessage());
            return [
                'driver' => $cacheDriver,
                'error' => $e->getMessage()
            ];
        }
    }
    
    /**
     * Format bytes to human readable format
     * 
     * @param int $bytes
     * @return string
     */
    private static function formatBytes($bytes)
    {
        $units = ['B', 'KB', 'MB', 'GB', 'TB'];
        
        for ($i = 0; $bytes > 1024 && $i < count($units) - 1; $i++) {
            $bytes /= 1024;
        }
        
        return round($bytes, 2) . ' ' . $units[$i];
    }
    
    /**
     * Clear file cache entries that match a pattern
     * 
     * @param string $pattern
     * @return void
     */
    private static function clearFileCacheByPattern($pattern)
    {
        try {
            $cacheDir = storage_path('framework/cache/data');
            
            if (!is_dir($cacheDir)) {
                Log::debug("Cache directory not found: {$cacheDir}");
                return;
            }
            
            $files = glob($cacheDir . '/*');
            $deletedCount = 0;
            
            foreach ($files as $file) {
                if (is_file($file)) {
                    $content = file_get_contents($file);
                    
                    // Laravel file cache format: expiration_timestamp + serialized_data
                    // The cache key is embedded in the serialized data
                    if (strpos($content, $pattern) !== false) {
                        unlink($file);
                        $deletedCount++;
                        Log::debug("Deleted cache file matching pattern '{$pattern}': " . basename($file));
                    }
                }
            }
            
            if ($deletedCount > 0) {
                Log::info("Deleted {$deletedCount} cache files matching pattern: {$pattern}");
            } else {
                Log::info("No cache files found matching pattern: {$pattern}");
            }
            
        } catch (\Exception $e) {
            Log::error("Error clearing file cache by pattern '{$pattern}': " . $e->getMessage());
        }
    }
    
    /**
     * Force clear all cache files (for file driver)
     * 
     * @return void
     */
    public static function forceCleanFileCache()
    {
        try {
            $cacheDriver = config('cache.default');
            
            if ($cacheDriver !== 'file') {
                Log::info("Force clean only works with file cache driver, current driver: {$cacheDriver}");
                return;
            }
            
            $cacheDir = storage_path('framework/cache/data');
            
            if (!is_dir($cacheDir)) {
                Log::debug("Cache directory not found: {$cacheDir}");
                return;
            }
            
            $files = glob($cacheDir . '/*');
            $deletedCount = 0;
            
            foreach ($files as $file) {
                if (is_file($file)) {
                    unlink($file);
                    $deletedCount++;
                }
            }
            
            Log::info("Force deleted {$deletedCount} cache files");
            
        } catch (\Exception $e) {
            Log::error("Error force cleaning file cache: " . $e->getMessage());
        }
    }
}