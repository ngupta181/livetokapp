<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class UserProfile extends Model
{
    protected $table = 'tbl_user_profiles';
    protected $primaryKey = 'profile_id';

    protected $fillable = [
        'user_id',
        'interests',
        'favorite_hashtags',
        'favorite_sounds',
        'watched_categories',
        'avg_watch_duration'
    ];

    protected $casts = [
        'interests' => 'array',
        'favorite_hashtags' => 'array',
        'favorite_sounds' => 'array',
        'watched_categories' => 'array'
    ];

    /**
     * Get the user that owns the profile.
     */
    public function user()
    {
        return $this->belongsTo('App\User', 'user_id', 'user_id');
    }

    /**
     * Add a hashtag to user's favorites
     */
    public function addFavoriteHashtag($hashtag)
    {
        $hashtags = $this->favorite_hashtags ?? [];
        if (!in_array($hashtag, $hashtags)) {
            $hashtags[] = $hashtag;
            $this->favorite_hashtags = $hashtags;
            $this->save();
        }
    }

    /**
     * Add a sound to user's favorites
     */
    public function addFavoriteSound($soundId)
    {
        $sounds = $this->favorite_sounds ?? [];
        if (!in_array($soundId, $sounds)) {
            $sounds[] = $soundId;
            $this->favorite_sounds = $sounds;
            $this->save();
        }
    }
    
    /**
     * Update watched category
     */
    public function updateWatchedCategory($category)
    {
        $categories = $this->watched_categories ?? [];
        if (!isset($categories[$category])) {
            $categories[$category] = 1;
        } else {
            $categories[$category]++;
        }
        $this->watched_categories = $categories;
        $this->save();
    }
}
