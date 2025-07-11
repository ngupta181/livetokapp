<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Wallet Security Configuration
    |--------------------------------------------------------------------------
    |
    | This file contains all security-related configuration for wallet
    | operations, fraud detection, and user protection measures.
    |
    */

    /*
    |--------------------------------------------------------------------------
    | Rate Limiting
    |--------------------------------------------------------------------------
    |
    | Configure rate limits for different wallet operations to prevent abuse.
    |
    */
    'rate_limits' => [
        'coin_transfer' => [
            'max_attempts' => 10,
            'time_window' => 60, // seconds (1 minute)
        ],
        'reward_claims' => [
            'max_attempts' => 5,
            'time_window' => 3600, // seconds (1 hour)
        ],
        'redeem_requests' => [
            'max_attempts' => 3,
            'time_window' => 86400, // seconds (1 day)
        ],
        'level_point_updates' => [
            'max_attempts' => 20,
            'time_window' => 3600, // seconds (1 hour)
        ],
        'purchase_attempts' => [
            'max_attempts' => 5,
            'time_window' => 60, // seconds (1 minute)
        ],
        'global_requests' => [
            'max_attempts' => 100,
            'time_window' => 60, // seconds (1 minute)
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Validation Limits
    |--------------------------------------------------------------------------
    |
    | Define minimum and maximum values for various operations.
    |
    */
    'validation' => [
        'coin_amounts' => [
            'min' => 1,
            'max' => 10000,
        ],
        'redeem_amounts' => [
            'min_usd' => 0.01,
            'max_usd' => 10000,
            'min_coins' => 1,
            'max_coins' => 100000,
        ],
        'level_points' => [
            'min' => 1,
            'max' => 10000,
        ],
        'purchase_amounts' => [
            'min_usd' => 0.01,
            'max_usd' => 999.99,
            'min_coins' => 1,
            'max_coins' => 10000,
        ],
        'account_info' => [
            'min_length' => 5,
            'max_length' => 100,
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Reward System Configuration
    |--------------------------------------------------------------------------
    |
    | Define valid reward actions and their coin amounts.
    |
    */
    'rewards' => [
        'valid_actions' => [1, 2, 3, 4, 5],
        'default_amounts' => [
            1 => 10,  // Sign up
            2 => 5,   // Daily check-in
            3 => 20,  // Video upload
            4 => 15,  // Profile complete
            5 => 25,  // First video
        ],
        'action_types' => [
            'send_gift' => ['min' => 1, 'max' => 5000],
            'receive_gift' => ['min' => 1, 'max' => 1250],
            'video_upload' => ['min' => 10, 'max' => 100],
            'daily_check_in' => ['min' => 5, 'max' => 25],
            'profile_complete' => ['min' => 15, 'max' => 75],
            'first_video' => ['min' => 25, 'max' => 125],
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Payment Methods
    |--------------------------------------------------------------------------
    |
    | Define valid payment and redemption methods.
    |
    */
    'payment_methods' => [
        'valid_purchase_methods' => [
            'in_app_purchase',
            'stripe',
            'paypal',
            'google_pay',
            'apple_pay',
        ],
        'valid_redeem_methods' => [
            'Paypal',
            'paypal',
            'stripe',
            'bank_transfer',
            'crypto',
        ],
        'supported_platforms' => [
            'ios',
            'android',
            'web',
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Fraud Detection
    |--------------------------------------------------------------------------
    |
    | Configure thresholds for detecting suspicious activity.
    |
    */
    'fraud_detection' => [
        'suspicious_thresholds' => [
            'failed_transactions_per_10min' => 3,
            'requests_per_minute' => 30,
            'repeated_requests' => 5,
            'multiple_ips_per_10min' => 5,
        ],
        'highly_suspicious' => [
            'negative_amounts' => true,
            'extreme_amounts' => [
                'coins' => 50000,
                'usd' => 1000,
                'points' => 50000,
            ],
            'rate_violations_threshold' => 3,
        ],
        'auto_block_triggers' => [
            'highly_suspicious_activity' => true,
            'multiple_rate_violations' => true,
            'negative_amount_attempts' => true,
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | IP Blocking
    |--------------------------------------------------------------------------
    |
    | Configure IP blocking rules and known fraud IPs.
    |
    */
    'ip_blocking' => [
        'permanent_blocks' => [
            '113.210.105.163', // Known fraud IP from logs
            // Add more IPs as needed
        ],
        'temporary_block_duration' => [
            'suspicious_ip' => 7200, // 2 hours
            'user_account' => 3600,  // 1 hour
        ],
        'whitelist' => [
            // Add trusted IPs here if needed
            '24.188.50.106', // Your testing IP
        ],
        'testing_mode' => [
            'enabled' => env('WALLET_TESTING_MODE', false),
            'allowed_ips' => [
                '24.188.50.106',
                '127.0.0.1',
                '::1',
                // Add your development IPs here
            ],
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Monitoring and Logging
    |--------------------------------------------------------------------------
    |
    | Configure what activities to log and monitor.
    |
    */
    'monitoring' => [
        'log_all_wallet_activities' => true,
        'log_failed_attempts' => true,
        'log_suspicious_patterns' => true,
        'alert_on_suspicious_activity' => true,
        'track_user_behavior' => true,
        'cache_duration' => [
            'rate_tracking' => 60,        // 1 minute
            'request_patterns' => 300,    // 5 minutes
            'user_ips' => 600,           // 10 minutes
            'blocks' => 3600,            // 1 hour
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Security Responses
    |--------------------------------------------------------------------------
    |
    | Configure response messages and codes.
    |
    */
    'responses' => [
        'rate_limit_exceeded' => [
            'status' => 429,
            'message' => 'Too many attempts. Please wait before trying again.',
        ],
        'ip_blocked' => [
            'status' => 403,
            'message' => 'Access denied. Contact support if you believe this is an error.',
        ],
        'user_blocked' => [
            'status' => 403,
            'message' => 'Account temporarily suspended. Contact support for assistance.',
        ],
        'suspicious_activity' => [
            'status' => 429,
            'message' => 'Suspicious activity detected. Account temporarily restricted.',
        ],
        'invalid_amount' => [
            'status' => 401,
            'message' => 'Invalid amount specified.',
        ],
        'insufficient_funds' => [
            'status' => 401,
            'message' => 'Insufficient wallet balance.',
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Trust Score System
    |--------------------------------------------------------------------------
    |
    | Configure the user trust scoring system.
    |
    */
    'trust_system' => [
        'default_score' => 50,
        'score_adjustments' => [
            'successful_transaction' => +1,
            'failed_transaction' => -2,
            'suspicious_activity' => -5,
            'rate_limit_violation' => -3,
            'account_verification' => +10,
            'long_term_user' => +5,
        ],
        'thresholds' => [
            'trusted_user' => 80,
            'suspicious_user' => 30,
            'auto_block_threshold' => 10,
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Emergency Controls
    |--------------------------------------------------------------------------
    |
    | Emergency shutdown and control settings.
    |
    */
    'emergency' => [
        'enable_emergency_mode' => false,
        'emergency_rate_limits' => [
            'max_transactions_per_hour' => 5,
            'max_amount_per_transaction' => 100,
        ],
        'maintenance_mode' => [
            'enabled' => false,
            'message' => 'Wallet services are temporarily unavailable for maintenance.',
        ],
    ],
]; 