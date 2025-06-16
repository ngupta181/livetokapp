<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class UserInteraction extends Model
{
    protected $table = 'tbl_user_interactions';
    protected $primaryKey = 'interaction_id';

    protected $fillable = [
        'user_id', 
        'post_id', 
        'interaction_type', 
        'duration'
    ];

    /**
     * Get the user that owns the interaction.
     */
    public function user()
    {
        return $this->belongsTo('App\User', 'user_id', 'user_id');
    }

    /**
     * Get the post that the interaction is for.
     */
    public function post()
    {
        return $this->belongsTo('App\Post', 'post_id', 'post_id');
    }
}
