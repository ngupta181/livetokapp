<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class AppVersion extends Model
{
    protected $fillable = [
        'minimum_version',
        'latest_version',
        'update_message',
        'force_update',
        'play_store_url',
        'app_store_url',
    ];

    protected $casts = [
        'force_update' => 'boolean',
    ];


} 