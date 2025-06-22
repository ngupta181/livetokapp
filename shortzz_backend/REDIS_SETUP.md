# Redis Setup Guide

## Resolving "Class Predis\Client not found" Error

If you're seeing the error `Class "Predis\Client" not found`, follow these steps to resolve it:

## Option 1: Install Predis Package

The predis package is already listed in composer.json, but you may need to install it:

```bash
composer require predis/predis
```

If you encounter dependency issues with PHP extensions (like imagick), you have several options:

### Option 2: Install Required PHP Extensions

For production environments, install the required PHP extensions:

```bash
# For Ubuntu/Debian
sudo apt-get install php-imagick

# For CentOS/RHEL
sudo yum install php-imagick

# For Windows
# Enable the extension in your php.ini file
```

### Option 3: Modify composer.json for Development

For development environments, you can temporarily modify composer.json:

1. Create a copy of your composer.json:
```bash
cp composer.json composer.json.bak
```

2. Edit composer.json to move ext-imagick to "suggest" instead of "require":
```json
{
    "require": {
        "php": "^7.3|^8.0|^8.2",
        // Remove or comment out the next line
        // "ext-imagick": "*",
        ...
    },
    "suggest": {
        "ext-imagick": "Required for image processing in production"
    },
    ...
}
```

3. Update dependencies:
```bash
composer update
```

4. Restore the original composer.json when deploying to production:
```bash
cp composer.json.bak composer.json
```

### Option 4: Use PhpRedis Instead

You can use the PhpRedis extension instead of Predis:

1. Install the PhpRedis extension:
```bash
# For Ubuntu/Debian
sudo apt-get install php-redis

# For CentOS/RHEL
sudo yum install php-redis

# For Windows
# Enable the extension in your php.ini file
```

2. Update your .env file:
```
REDIS_CLIENT=phpredis
```

## Environment Configuration

Ensure your .env file has the following Redis configuration:

```
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379
REDIS_CLIENT=predis
REDIS_PREFIX=shortzz_
REDIS_DB=0
REDIS_CACHE_DB=1

CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
```

## Verifying Redis Connection

To verify that Redis is properly connected:

1. Check Redis server status:
```bash
# For Linux
sudo systemctl status redis

# For Windows
# Check Task Manager for redis-server.exe
```

2. Test Redis connection:
```bash
redis-cli ping
```
Should return "PONG" if Redis is running correctly.

3. Check application logs for Redis connection issues:
```bash
tail -f storage/logs/laravel.log
```

## Fallback Mechanism

The RedisCacheServiceProvider has been updated to automatically fall back to file-based caching if Redis is not available. This ensures your application will continue to function even if Redis is not properly configured. 