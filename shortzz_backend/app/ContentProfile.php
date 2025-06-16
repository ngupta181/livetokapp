<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class ContentProfile extends Model
{
    protected $table = 'tbl_content_profiles';
    protected $primaryKey = 'content_profile_id';

    protected $fillable = [
        'post_id',
        'extracted_hashtags',
        'categories',
        'engagement_rate',
        'avg_watch_duration',
        'completion_rate',
        'similar_posts'
    ];

    protected $casts = [
        'extracted_hashtags' => 'array',
        'categories' => 'array',
        'similar_posts' => 'array'
    ];

    /**
     * Get the post associated with the content profile.
     */
    public function post()
    {
        return $this->belongsTo('App\Post', 'post_id', 'post_id');
    }

    /**
     * Extract hashtags from post description
     */
    public static function extractHashtags($postDescription)
    {
        $hashtags = [];
        preg_match_all('/#([^\s#]+)/', $postDescription, $matches);
        if (isset($matches[1]) && !empty($matches[1])) {
            $hashtags = $matches[1];
        }
        return $hashtags;
    }

    /**
     * Update engagement rate based on likes, comments, shares
     */
    public function updateEngagementRate($likesCount, $commentsCount, $viewCount)
    {
        if ($viewCount > 0) {
            // Calculate engagement as (likes + comments) / views
            $this->engagement_rate = ($likesCount + $commentsCount) / $viewCount;
            $this->save();
        }
    }

    /**
     * Find similar posts based on hashtags and categories
     */
    public function findSimilarPosts($limit = 10)
    {
        $hashtags = $this->extracted_hashtags ?? [];
        $categories = $this->categories ?? [];
        
        // Find posts with similar hashtags or categories
        $similarPosts = self::whereHas('post', function($query) use ($hashtags, $categories) {
            if (!empty($hashtags)) {
                foreach ($hashtags as $hashtag) {
                    $query->orWhere('post_hash_tag', 'LIKE', "%$hashtag%");
                }
            }
        })
        ->where('post_id', '!=', $this->post_id)
        ->orderBy('engagement_rate', 'DESC')
        ->limit($limit)
        ->pluck('post_id')
        ->toArray();
        
        $this->similar_posts = $similarPosts;
        $this->save();
        
        return $similarPosts;
    }
}
