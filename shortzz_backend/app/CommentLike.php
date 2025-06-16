<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class CommentLike extends Model
{
    protected $table = 'tbl_comment_likes';
    public $primaryKey = 'like_id';
    public $timestamps = true;
    
    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
    protected $fillable = [
        'comments_id',
        'user_id',
    ];
    
    /**
     * Get the comment that owns the like.
     */
    public function comment()
    {
        return $this->belongsTo(Comments::class, 'comments_id', 'comments_id');
    }
    
    /**
     * Get the user that owns the like.
     */
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'user_id');
    }
}
