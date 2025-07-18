# Redis Caching Implementation

## Overview

Redis caching has been implemented in the ShortZZ backend to improve performance and reduce database load. This document outlines how Redis caching is implemented and how to maintain it.

## Configuration

Redis is configured in the following files:

1. **config/database.php**: Contains Redis connection settings
2. **config/cache.php**: Configures Redis as the cache driver
3. **app/Providers/RedisCacheServiceProvider.php**: Service provider for Redis caching with fallback

## Key Cache Areas

Redis caching has been implemented in the following areas:

1. **User Profiles**:
   - User profile data is cached for 1 hour
   - Follow/following relationships are cached
   - Profile stats are cached with varying TTLs

2. **Posts/Videos**:
   - User videos are cached for 3 hours
   - Post comments and likes counts are cached for 10 minutes
   - Post details are cached for 1 hour

3. **Recommendations**:
   - Trending posts are cached for 1 hour
   - Personalized recommendations are cached for 15 minutes

## Cache Keys

All cache keys are centralized in the `app/CacheKeys.php` file. This ensures consistent naming across the application and makes it easier to manage cache invalidation.

Cache TTL (Time To Live) values are also defined in this file:
- `TTL_MINUTE`: 60 seconds
- `TTL_HOUR`: 3600 seconds
- `TTL_DAY`: 86400 seconds
- `TTL_WEEK`: 604800 seconds

## Cache Invalidation

Cache invalidation has been improved with a dedicated service class that handles all cache clearing operations:

### CacheInvalidationService

The `App\Services\CacheInvalidationService` provides centralized cache invalidation with the following methods:

1. **`invalidateUserCache($userId)`** - Clears all user-related caches including:
   - User profile data
   - Follower/following counts
   - User statistics
   - Follow relationships

2. **`invalidatePostCache($postId, $userId, $hashtags)`** - Clears all post-related caches including:
   - Post details and metadata
   - Comments and likes counts
   - User's video lists
   - Trending posts
   - Hashtag-related caches

3. **`invalidateRecommendationCache($userId)`** - Clears recommendation caches for a user

4. **`invalidateHashtagCaches($hashtagString)`** - Clears hashtag-related caches

### Automatic Cache Invalidation

Cache invalidation occurs automatically when data is updated:

1. **User Updates**: When a user's profile is updated, all related caches are cleared
2. **Post Operations**: When posts are created, updated, or deleted, related caches are invalidated
3. **User Interactions**: When users like, comment, or share content, relevant caches are updated
4. **Follow Actions**: When users follow/unfollow others, relationship caches are cleared

### Performance Improvements

- Uses Redis SCAN instead of KEYS command for better performance
- Implements batch deletion for multiple cache keys
- Includes fallback mechanisms for reliability
- Provides detailed logging for debugging

## Setup Instructions

1. Install Redis server if not already installed:
   ```
   sudo apt-get install redis-server  # For Ubuntu
   ```
   For Windows, download from [Redis for Windows](https://github.com/microsoftarchive/redis/releases)

2. Install the predis PHP package:
   ```
   composer require predis/predis
   ```

3. Update .env file with Redis configuration:
   ```
   CACHE_DRIVER=redis
   REDIS_HOST=127.0.0.1
   REDIS_PASSWORD=null
   REDIS_PORT=6379
   REDIS_CLIENT=predis
   ```

## Troubleshooting

### Missing Predis Client

If you see errors like `Class "Predis\Client" not found`, follow these steps:

1. Ensure Predis is installed:
   ```
   composer require predis/predis
   ```

2. If you encounter dependency issues with other extensions (like imagick):
   
   a. For development environments, you can temporarily modify composer.json to remove the extension requirement:
   ```
   "require": {
       "php": "^7.3|^8.0|^8.2",
       // Comment out problematic extensions for local development
       // "ext-imagick": "*",
       ...
   }
   ```
   
   b. Then update dependencies:
   ```
   composer update
   ```
   
   c. For production, ensure all required PHP extensions are installed:
   ```
   # For Ubuntu/Debian
   sudo apt-get install php-imagick
   
   # For CentOS/RHEL
   sudo yum install php-imagick
   ```

3. Alternatively, you can use the PhpRedis extension instead of Predis by setting:
   ```
   REDIS_CLIENT=phpredis
   ```
   in your .env file and installing the PhpRedis extension:
   ```
   # For Ubuntu/Debian
   sudo apt-get install php-redis
   
   # For CentOS/RHEL
   sudo yum install php-redis
   ```

### GeoIP Cache Tagging Issues

If you see "This cache store does not support tagging" errors:

1. **Automatic Resolution**: The `GeoIPCacheServiceProvider` automatically handles this by disabling cache tags for file/database drivers.

2. **Manual Fix**: Update `config/geoip.php`:
   ```php
   'cache_tags' => env('CACHE_DRIVER') === 'redis' ? ['torann-geoip-location'] : [],
   ```

3. **Clear Configuration Cache**:
   ```bash
   php artisan config:clear
   ```

### Redis Connection Issues

If Redis fails to connect:

1. Ensure Redis server is running:
   ```
   sudo systemctl status redis  # For Linux
   ```

2. Check if Redis is listening on the expected port:
   ```
   netstat -an | grep 6379
   ```

3. Verify .env configuration matches your Redis setup

## Monitoring

You can monitor Redis caching using the following Redis commands:

1. To see all cache keys:
   ```
   redis-cli KEYS "*"
   ```

2. To monitor memory usage:
   ```
   redis-cli INFO memory
   ```

3. To monitor cache hit rate:
   ```
   redis-cli INFO stats
   ```

## Cache Management Commands

Use the following Artisan commands for cache management and debugging:

### View Cache Statistics
```bash
php artisan cache:manage stats
```

### Test Cache Connection
```bash
php artisan cache:manage test
```

### Clear All Cache
```bash
php artisan cache:manage clear
```

### Invalidate User Cache
```bash
php artisan cache:manage invalidate-user --user-id=123
```

### Invalidate Post Cache
```bash
php artisan cache:manage invalidate-post --post-id=456 --user-id=123 --hashtags="tag1,tag2"
```

## Debugging Cache Issues

### Enable Cache Debug Logging

Add the following header to your API requests to enable detailed cache logging:
```
X-Cache-Debug: true
```

This will log cache operations and execution times when `APP_DEBUG=true`.

### Common Issues and Solutions

1. **Cache keys not being cleared**: 
   - Check Redis connection with `php artisan cache:manage test`
   - Verify cache prefix configuration in `.env`
   - Review logs for cache invalidation errors

2. **Performance issues**:
   - Monitor Redis memory usage with `php artisan cache:manage stats`
   - Consider adjusting TTL values in `CacheKeys.php`
   - Use Redis MONITOR command to watch real-time operations

3. **Inconsistent data**:
   - Clear specific user/post caches using management commands
   - Check if cache invalidation is being called after data updates
   - Verify cache key patterns match between setting and clearing

## Maintenance

- Regularly monitor Redis memory usage with `php artisan cache:manage stats`
- Consider implementing cache warming for frequently accessed data
- Adjust TTL values in `app/CacheKeys.php` based on data volatility and access patterns
- Use the cache management commands for debugging and maintenance
- Monitor application logs for cache-related errors