# Cache Invalidation Troubleshooting Guide

## Overview

This guide helps you diagnose and fix cache invalidation issues in the LiveTok backend application.

## Quick Diagnosis

### 1. Test Cache System
```bash
php artisan cache:manage test
```

### 2. Check Cache Statistics
```bash
php artisan cache:manage stats
```

### 3. View Recent Logs
```bash
tail -f storage/logs/laravel.log | grep -i cache
```

## Common Issues and Solutions

### Issue 1: Cache Not Being Invalidated

**Symptoms:**
- Old data still appears after updates
- User profile changes not reflected
- Post updates not visible

**Diagnosis:**
```bash
# Check if cache invalidation is being called
php artisan cache:manage stats

# Test specific user cache invalidation
php artisan cache:manage invalidate-user --user-id=123
```

**Solutions:**

1. **Check Cache Driver Configuration**
   ```bash
   # In .env file, ensure correct cache driver
   CACHE_DRIVER=redis  # or file
   ```

2. **Verify Cache Keys**
   - Check that cache keys being set match those being cleared
   - Review `app/CacheKeys.php` for consistent key patterns

3. **Manual Cache Clear**
   ```bash
   # Clear specific user cache
   php artisan cache:manage invalidate-user --user-id=USER_ID
   
   # Clear specific post cache
   php artisan cache:manage invalidate-post --post-id=POST_ID --user-id=USER_ID
   
   # Clear user videos cache specifically
   php artisan cache:manage clear-user-videos --user-id=USER_ID
   
   # Debug cache contents
   php artisan cache:manage debug-cache
   
   # Force clean all cache files (file driver only)
   php artisan cache:manage force-clean
   
   # Clear all cache (use with caution)
   php artisan cache:manage clear
   ```

### Issue 2: Redis Connection Problems

**Symptoms:**
- "Connection refused" errors
- Cache operations failing silently
- Performance degradation

**Diagnosis:**
```bash
# Test Redis connection
redis-cli ping  # Should return PONG

# Check Redis status
sudo systemctl status redis  # Linux
# or check Task Manager for redis-server.exe on Windows
```

**Solutions:**

1. **Install Redis (if not installed)**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install redis-server
   
   # CentOS/RHEL
   sudo yum install redis
   
   # Windows: Download from https://github.com/microsoftarchive/redis/releases
   ```

2. **Start Redis Service**
   ```bash
   # Linux
   sudo systemctl start redis
   sudo systemctl enable redis
   
   # Windows
   redis-server.exe
   ```

3. **Fallback to File Cache**
   ```bash
   # Update .env file
   CACHE_DRIVER=file
   SESSION_DRIVER=file
   QUEUE_CONNECTION=sync
   ```

### Issue 3: Performance Issues

**Symptoms:**
- Slow API responses
- High memory usage
- Cache operations timing out

**Diagnosis:**
```bash
# Check cache statistics
php artisan cache:manage stats

# Monitor Redis memory usage
redis-cli info memory

# Check for large cache keys
redis-cli --bigkeys
```

**Solutions:**

1. **Optimize Cache TTL Values**
   ```php
   // In app/CacheKeys.php, adjust TTL values
   const TTL_MINUTE = 60;      // For frequently changing data
   const TTL_HOUR = 3600;      // For moderately stable data
   const TTL_DAY = 86400;      // For stable data
   ```

2. **Clear Unused Cache**
   ```bash
   # Clear all cache
   php artisan cache:manage clear
   
   # Or clear specific patterns
   php artisan cache:manage invalidate-user --user-id=INACTIVE_USER_ID
   ```

3. **Monitor Cache Usage**
   ```bash
   # Set up regular monitoring
   php artisan cache:manage stats
   ```

### Issue 4: GeoIP Cache Tagging Error

**Symptoms:**
- Error: "This cache store does not support tagging"
- 500 server errors on API requests
- GeoIP functionality failing

**Diagnosis:**
```bash
# Check current cache driver
php artisan config:show cache.default

# Check GeoIP configuration
php artisan config:show geoip.cache_tags
```

**Solutions:**

1. **Automatic Fix (Recommended)**
   - The `GeoIPCacheServiceProvider` automatically disables cache tags for file/database drivers
   - Ensure the provider is registered in `config/app.php`

2. **Manual Fix**
   ```bash
   # Update config/geoip.php
   'cache_tags' => env('CACHE_DRIVER') === 'redis' ? ['torann-geoip-location'] : [],
   
   # Clear config cache
   php artisan config:clear
   ```

3. **Switch to Redis (if available)**
   ```bash
   # Update .env
   CACHE_DRIVER=redis
   
   # Clear config cache
   php artisan config:clear
   ```

### Issue 5: Inconsistent Data

**Symptoms:**
- Different data returned on subsequent requests
- User sees old profile information
- Post counts don't match

**Diagnosis:**
```bash
# Enable cache debugging
# Add header: X-Cache-Debug: true to API requests

# Check logs for cache operations
tail -f storage/logs/laravel.log | grep "Cache Debug"
```

**Solutions:**

1. **Force Cache Refresh**
   ```bash
   # Clear specific caches
   php artisan cache:manage invalidate-user --user-id=AFFECTED_USER_ID
   ```

2. **Check Cache Key Consistency**
   - Verify that cache keys used in `Cache::remember()` match those in invalidation
   - Review controller methods for proper cache invalidation calls

3. **Implement Cache Versioning**
   ```php
   // Add version to cache keys
   $cacheKey = CacheKeys::USER_PROFILE . $userId . ':v2';
   ```

## Debugging Tools

### 1. Cache Debug Middleware

Add to API requests:
```
X-Cache-Debug: true
```

This enables detailed logging when `APP_DEBUG=true`.

### 2. Cache Management Commands

```bash
# View all available commands
php artisan cache:manage

# Test cache functionality
php artisan cache:manage test

# View cache statistics
php artisan cache:manage stats

# Clear all cache
php artisan cache:manage clear

# Invalidate specific user cache
php artisan cache:manage invalidate-user --user-id=123

# Invalidate specific post cache
php artisan cache:manage invalidate-post --post-id=456 --user-id=123
```

### 3. Log Analysis

```bash
# Monitor cache operations
tail -f storage/logs/laravel.log | grep -E "(Cache|cache)"

# Check for errors
tail -f storage/logs/laravel.log | grep -E "(ERROR|error)"

# Monitor specific user operations
tail -f storage/logs/laravel.log | grep "user_id:123"
```

## Best Practices

### 1. Cache Key Naming
- Use consistent prefixes from `CacheKeys.php`
- Include relevant IDs in cache keys
- Use descriptive names for cache keys

### 2. Cache Invalidation
- Always invalidate cache after data updates
- Use the `CacheInvalidationService` for consistent invalidation
- Test cache invalidation in development

### 3. Monitoring
- Regularly check cache statistics
- Monitor Redis memory usage
- Set up alerts for cache failures

### 4. Error Handling
- Implement fallback mechanisms
- Log cache errors for debugging
- Don't let cache failures break the application

## Emergency Procedures

### Complete Cache Reset
```bash
# Stop application (if possible)
# Clear all cache
php artisan cache:manage clear

# Restart Redis (if using Redis)
sudo systemctl restart redis

# Clear Laravel caches
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Restart application
```

### Switch to File Cache (Emergency Fallback)
```bash
# Update .env
CACHE_DRIVER=file
SESSION_DRIVER=file
QUEUE_CONNECTION=sync

# Clear config cache
php artisan config:clear

# Test cache functionality
php artisan cache:manage test
```

## Getting Help

If issues persist:

1. Check the application logs: `storage/logs/laravel.log`
2. Run cache diagnostics: `php artisan cache:manage test`
3. Review cache statistics: `php artisan cache:manage stats`
4. Check Redis logs (if using Redis): `/var/log/redis/redis-server.log`
5. Verify environment configuration in `.env` file

For additional support, include the following information:
- Cache driver being used (Redis/File)
- Error messages from logs
- Output of `php artisan cache:manage stats`
- Steps to reproduce the issue