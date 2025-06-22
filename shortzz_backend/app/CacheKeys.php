<?php

namespace App;

class CacheKeys
{
    // User related cache keys
    const USER_PROFILE = 'user:profile:';
    const USER_VIDEOS = 'user:videos:';
    const USER_LIKES = 'user:likes:';
    const USER_FOLLOWERS = 'user:followers:';
    const USER_FOLLOWING = 'user:following:';
    
    // Post related cache keys
    const POST_DETAIL = 'post:detail:';
    const POST_COMMENTS = 'post:comments:';
    const POST_LIKES = 'post:likes:';
    const POST_LIST = 'post:list:';
    const POST_BY_TAG = 'post:by:tag:';
    const POST_BY_SOUND = 'post:by:sound:';
    
    // Recommendation related cache keys
    const RECOMMENDATION_FOR_USER = 'recommendation:user:';
    const TRENDING_POSTS = 'trending:posts:';
    
    // Sound related cache keys
    const SOUND_LIST = 'sound:list:';
    const SOUND_BY_CATEGORY = 'sound:by:category:';
    const SOUND_DETAIL = 'sound:detail:';
    
    // Hash tag related cache keys
    const HASHTAG_LIST = 'hashtag:list:';
    const HASHTAG_TRENDING = 'hashtag:trending';
    
    // TTL values in seconds
    const TTL_MINUTE = 60;
    const TTL_HOUR = 3600;
    const TTL_DAY = 86400;
    const TTL_WEEK = 604800;
} 