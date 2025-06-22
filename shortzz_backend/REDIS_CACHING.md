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

Cache invalidation occurs automatically when data is updated:

1. When a user's profile is updated, the `invalidateUserCache()` method clears all related caches
2. When a post is added or deleted, related caches are invalidated
3. When a user interacts with content (likes, comments), relevant caches are updated

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

## Maintenance

- Regularly monitor Redis memory usage
- Consider implementing cache warming for frequently accessed data
- Adjust TTL values based on data volatility and access patterns 