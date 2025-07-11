<?php

namespace App;

use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class BlockedIp extends Model
{
    protected $table = 'tbl_blocked_ips';
    
    protected $fillable = [
        'ip_address',
        'reason',
        'blocked_by',
        'is_active',
        'expires_at',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'expires_at' => 'datetime',
    ];

    /**
     * Get the user who blocked this IP
     */
    public function blockedBy()
    {
        return $this->belongsTo(User::class, 'blocked_by', 'user_id');
    }

    /**
     * Check if an IP is currently blocked
     */
    public static function isBlocked($ip)
    {
        return self::where('ip_address', $ip)
            ->where('is_active', true)
            ->where(function ($query) {
                $query->whereNull('expires_at')
                    ->orWhere('expires_at', '>', now());
            })
            ->exists();
    }

    /**
     * Block an IP address
     */
    public static function blockIp($ip, $reason = null, $blockedBy = null, $expiresAt = null)
    {
        // First deactivate any existing blocks for this IP
        self::where('ip_address', $ip)->update(['is_active' => false]);
        
        // Create new block
        return self::create([
            'ip_address' => $ip,
            'reason' => $reason,
            'blocked_by' => $blockedBy,
            'is_active' => true,
            'expires_at' => $expiresAt,
        ]);
    }

    /**
     * Unblock an IP address
     */
    public static function unblockIp($ip)
    {
        return self::where('ip_address', $ip)
            ->where('is_active', true)
            ->update(['is_active' => false]);
    }

    /**
     * Get all active blocked IPs
     */
    public static function getActiveBlocks()
    {
        return self::where('is_active', true)
            ->where(function ($query) {
                $query->whereNull('expires_at')
                    ->orWhere('expires_at', '>', now());
            })
            ->with('blockedBy')
            ->orderBy('created_at', 'desc')
            ->get();
    }

    /**
     * Get IP block history
     */
    public static function getIpHistory($ip)
    {
        return self::where('ip_address', $ip)
            ->with('blockedBy')
            ->orderBy('created_at', 'desc')
            ->get();
    }

    /**
     * Clean up expired blocks
     */
    public static function cleanupExpiredBlocks()
    {
        return self::where('is_active', true)
            ->where('expires_at', '<', now())
            ->update(['is_active' => false]);
    }

    /**
     * Get block statistics
     */
    public static function getBlockStats()
    {
        $total = self::count();
        $active = self::where('is_active', true)
            ->where(function ($query) {
                $query->whereNull('expires_at')
                    ->orWhere('expires_at', '>', now());
            })
            ->count();
        
        $temporary = self::where('is_active', true)
            ->whereNotNull('expires_at')
            ->where('expires_at', '>', now())
            ->count();
        
        $permanent = self::where('is_active', true)
            ->whereNull('expires_at')
            ->count();
        
        $expired = self::where('is_active', true)
            ->where('expires_at', '<', now())
            ->count();
        
        return [
            'total' => $total,
            'active' => $active,
            'temporary' => $temporary,
            'permanent' => $permanent,
            'expired' => $expired,
        ];
    }

    /**
     * Scope for active blocks
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true)
            ->where(function ($q) {
                $q->whereNull('expires_at')
                  ->orWhere('expires_at', '>', now());
            });
    }

    /**
     * Scope for expired blocks
     */
    public function scopeExpired($query)
    {
        return $query->where('is_active', true)
            ->where('expires_at', '<', now());
    }

    /**
     * Check if this block is expired
     */
    public function isExpired()
    {
        return $this->expires_at && $this->expires_at->isPast();
    }

    /**
     * Check if this is a permanent block
     */
    public function isPermanent()
    {
        return is_null($this->expires_at);
    }

    /**
     * Get remaining time for temporary blocks
     */
    public function getRemainingTime()
    {
        if ($this->isPermanent()) {
            return 'Permanent';
        }
        
        if ($this->isExpired()) {
            return 'Expired';
        }
        
        return $this->expires_at->diffForHumans();
    }
} 