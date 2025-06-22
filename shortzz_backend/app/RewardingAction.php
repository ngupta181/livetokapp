<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class RewardingAction extends Model
{
    protected $table = 'tbl_rewarding_action';
    protected $primaryKey = 'rewarding_action_id';
    public $timestamps = false;  // If your table doesn't have created_at and updated_at columns
    
    protected $fillable = [
        'action_name',
        'coin',
        'status'
    ];

    protected $casts = [
        'coin' => 'integer',
        'status' => 'boolean'
    ];
} 