<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class SuspiciousActivity extends Model
{
    protected $table = 'tbl_suspicious_activities';
    protected $primaryKey = 'id';
    public $timestamps = true;
    
    protected $fillable = [
        'user_id',
        'ip_address',
        'activity_type',
        'details',
        'severity',
        'is_reviewed',
        'reviewed_by',
        'action_taken',
        'created_at',
        'updated_at'
    ];

    protected $casts = [
        'details' => 'array',
        'is_reviewed' => 'boolean'
    ];

    /**
     * Get the user associated with this activity
     */
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'user_id');
    }

    /**
     * Get the admin who reviewed this activity
     */
    public function reviewedBy()
    {
        return $this->belongsTo(User::class, 'reviewed_by', 'user_id');
    }

    /**
     * Scope for high severity activities
     */
    public function scopeHighSeverity($query)
    {
        return $query->where('severity', 'high');
    }

    /**
     * Scope for unreviewed activities
     */
    public function scopeUnreviewed($query)
    {
        return $query->where('is_reviewed', false);
    }

    /**
     * Scope for activities within time range
     */
    public function scopeWithinHours($query, $hours)
    {
        return $query->where('created_at', '>=', now()->subHours($hours));
    }
} 