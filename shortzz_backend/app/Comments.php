<?php

namespace App;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Passport\HasApiTokens;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Comments extends Authenticatable
{
	use HasApiTokens;
	protected $table = 'tbl_comments';
	public $primaryKey = 'comments_id';
	public $timestamps = true;
	public $incrementing = false;
	
	/**
	 * The attributes that are mass assignable.
	 *
	 * @var array
	 */
	protected $fillable = [
		'post_id',
		'parent_id',
		'user_id',
		'comment',
		'is_edited'
	];
	
	/**
	 * Get the post that owns the comment.
	 */
	public function post()
	{
		return $this->belongsTo(Post::class, 'post_id', 'post_id');
	}
	
	/**
	 * Get the user that owns the comment.
	 */
	public function user()
	{
		return $this->belongsTo(User::class, 'user_id', 'user_id');
	}
	
	/**
	 * Get the parent comment.
	 */
	public function parent()
	{
		return $this->belongsTo(Comments::class, 'parent_id', 'comments_id');
	}
	
	/**
	 * Get the replies for the comment.
	 */
	public function replies()
	{
		return $this->hasMany(Comments::class, 'parent_id', 'comments_id');
	}
	
	/**
	 * Get the likes for the comment.
	 */
	public function likes()
	{
		return $this->hasMany(CommentLike::class, 'comments_id', 'comments_id');
	}
	
	/**
	 * Check if a specific user has liked this comment.
	 *
	 * @param int $userId
	 * @return bool
	 */
	public function isLikedByUser($userId)
	{
		return $this->likes()->where('user_id', $userId)->exists();
	}
	
	/**
	 * Get the likes count for the comment.
	 *
	 * @return int
	 */
	public function getLikesCountAttribute()
	{
		return $this->likes()->count();
	}
}
