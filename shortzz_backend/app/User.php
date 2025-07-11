<?php

namespace App;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Passport\HasApiTokens;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Facades\Hash;

class User extends Authenticatable
{
    use HasApiTokens, Notifiable;

    protected $table = 'tbl_users';
    protected $primaryKey = 'user_id';
    public $timestamps = true;

    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
    protected $fillable = [
        'user_name', 'email', 'full_name', 'phone', 'user_profile', 
        'my_wallet', 'is_blocked', 'blocked_reason', 'requires_review',
        'review_reason', 'last_login_at', 'last_login_ip', 'email_verified_at',
        'phone_verified_at', 'two_factor_enabled', 'login_attempts', 'blocked_until'
    ];

    /**
     * The attributes that should be hidden for arrays.
     *
     * @var array
     */
    protected $hidden = [
        'password', 'remember_token', 'two_factor_secret', 'two_factor_recovery_codes'
    ];

    /**
     * The attributes that should be cast to native types.
     *
     * @var array
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'phone_verified_at' => 'datetime',
        'last_login_at' => 'datetime',
        'blocked_until' => 'datetime',
        'is_blocked' => 'boolean',
        'requires_review' => 'boolean',
        'two_factor_enabled' => 'boolean',
        'login_attempts' => 'integer',
        'my_wallet' => 'integer'
    ];

    /**
     * Generate random user ID
     */
    public static function get_random_string($field_code = 'user_id')
    {
        $random_unique = sprintf('%04X%04X', mt_rand(0, 65535), mt_rand(0, 65535));

        $user = User::where('user_id', '=', $random_unique)->first();
        if ($user != null) {
            return User::get_random_string();
        }
        return $random_unique;
    }

    /**
     * Check if user is blocked
     */
    public function isBlocked()
    {
        if ($this->is_blocked) {
            return true;
        }

        if ($this->blocked_until && $this->blocked_until->isFuture()) {
            return true;
        }

        return false;
    }

    /**
     * Block user account
     */
    public function blockAccount($reason = null, $duration = null)
    {
        $this->update([
            'is_blocked' => true,
            'blocked_reason' => $reason,
            'blocked_until' => $duration ? now()->addMinutes($duration) : null,
            'blocked_at' => now()
        ]);
    }

    /**
     * Unblock user account
     */
    public function unblockAccount()
    {
        $this->update([
            'is_blocked' => false,
            'blocked_reason' => null,
            'blocked_until' => null,
            'blocked_at' => null
        ]);
    }

    /**
     * Increment login attempts
     */
    public function incrementLoginAttempts()
    {
        $this->increment('login_attempts');
        
        // Block user after 5 failed attempts for 15 minutes
        if ($this->login_attempts >= 5) {
            $this->blockAccount('Too many failed login attempts', 15);
        }
    }

    /**
     * Reset login attempts
     */
    public function resetLoginAttempts()
    {
        $this->update(['login_attempts' => 0]);
    }

    /**
     * Update last login information
     */
    public function updateLastLogin($ip = null)
    {
        $this->update([
            'last_login_at' => now(),
            'last_login_ip' => $ip,
            'login_attempts' => 0
        ]);
    }

    /**
     * Check if user requires review
     */
    public function requiresReview()
    {
        return $this->requires_review;
    }

    /**
     * Flag user for review
     */
    public function flagForReview($reason)
    {
        $this->update([
            'requires_review' => true,
            'review_reason' => $reason,
            'flagged_at' => now()
        ]);
    }

    /**
     * Clear review flag
     */
    public function clearReviewFlag()
    {
        $this->update([
            'requires_review' => false,
            'review_reason' => null,
            'flagged_at' => null
        ]);
    }

    /**
     * Get user's transactions
     */
    public function transactions()
    {
        return $this->hasMany(Transaction::class, 'user_id', 'user_id');
    }

    /**
     * Get user's received transactions
     */
    public function receivedTransactions()
    {
        return $this->hasMany(Transaction::class, 'to_user_id', 'user_id');
    }

    /**
     * Get user's suspicious activities
     */
    public function suspiciousActivities()
    {
        return $this->hasMany(SuspiciousActivity::class, 'user_id', 'user_id');
    }

    /**
     * Check if user has sufficient wallet balance
     */
    public function hasSufficientBalance($amount)
    {
        return $this->my_wallet >= $amount;
    }

    /**
     * Deduct amount from wallet
     */
    public function deductFromWallet($amount)
    {
        if (!$this->hasSufficientBalance($amount)) {
            return false;
        }

        $this->decrement('my_wallet', $amount);
        return true;
    }

    /**
     * Add amount to wallet
     */
    public function addToWallet($amount)
    {
        $this->increment('my_wallet', $amount);
    }

    /**
     * Check if user is verified
     */
    public function isVerified()
    {
        return $this->email_verified_at !== null;
    }

    /**
     * Check if phone is verified
     */
    public function isPhoneVerified()
    {
        return $this->phone_verified_at !== null;
    }

    /**
     * Enable two-factor authentication
     */
    public function enableTwoFactor()
    {
        $this->update(['two_factor_enabled' => true]);
    }

    /**
     * Disable two-factor authentication
     */
    public function disableTwoFactor()
    {
        $this->update([
            'two_factor_enabled' => false,
            'two_factor_secret' => null,
            'two_factor_recovery_codes' => null
        ]);
    }

    /**
     * Scope for active users
     */
    public function scopeActive($query)
    {
        return $query->where('is_blocked', false)
                    ->where(function($q) {
                        $q->whereNull('blocked_until')
                          ->orWhere('blocked_until', '<=', now());
                    });
    }

    /**
     * Scope for blocked users
     */
    public function scopeBlocked($query)
    {
        return $query->where('is_blocked', true)
                    ->orWhere('blocked_until', '>', now());
    }

    /**
     * Scope for users requiring review
     */
    public function scopeRequiringReview($query)
    {
        return $query->where('requires_review', true);
    }
}
