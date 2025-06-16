<?php

namespace App\Http\Controllers\API;

use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Auth;
use Validator;
use DB;
use Log;
use App\User;
use App\Post;
use App\UserProfile;
use App\ContentProfile;
use App\UserInteraction;
use App\Like;
use App\Comments;
use App\Followers;
use App\BlockUser;

class RecommendationController extends Controller
{
    /**
     * Track user interaction with content
     */
    public function trackInteraction(Request $request)
    {
        // Try to get user from auth, fallback to request body
        if ($request->user()) {
            $user_id = $request->user()->user_id;
        } else {
            // For development/testing, allow user_id to be passed in the request
            $user_id = $request->input('user_id');
            
            // Log the attempt for debugging
            Log::info('trackInteraction: Auth failed, using user_id from request', [
                'user_id' => $user_id,
                'headers' => $request->headers->all(),
                'body' => $request->all()
            ]);
        }
        
        // If user_id is still empty, try to get it from the request directly
        if (empty($user_id)) {
            // Try with different possible parameter names
            if ($request->has('user_id')) {
                $user_id = $request->get('user_id');
            } elseif ($request->has('userId')) {
                $user_id = $request->get('userId');
            }
            
            Log::info('trackInteraction: Trying alternative user_id sources', [
                'user_id' => $user_id,
                'request_all' => $request->all()
            ]);
        }
        
        if (empty($user_id)) {
            return response()->json(['status' => 401, 'message' => "User ID is required"]);
        }
        
        $rules = [
            'post_id' => 'required',
            'interaction_type' => 'required|in:view,like,comment,share,follow,skip',
        ];
        
        $validator = Validator::make($request->all(), $rules);
        
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => 401, 'message' => $msg]);
        }
        
        $post_id = $request->get('post_id');
        $interaction_type = $request->get('interaction_type');
        $duration = $request->get('duration'); // Optional, for view interactions
        
        // Save the interaction
        $interaction = new UserInteraction();
        $interaction->user_id = $user_id;
        $interaction->post_id = $post_id;
        $interaction->interaction_type = $interaction_type;
        $interaction->duration = $duration;
        $interaction->save();
        
        // Update user profile
        $this->updateUserProfile($user_id, $post_id, $interaction_type, $duration);
        
        // Update content profile
        $this->updateContentProfile($post_id);
        
        return response()->json(['status' => 200, 'message' => 'Interaction tracked successfully']);
    }
    
    /**
     * Update user profile based on interactions
     */
    private function updateUserProfile($user_id, $post_id, $interaction_type, $duration = null)
    {
        // Get or create user profile
        $userProfile = UserProfile::firstOrCreate(['user_id' => $user_id]);
        
        // Get post data
        $post = Post::where('post_id', $post_id)->first();
        if (!$post) return;
        
        // Update user profile based on interaction
        if ($interaction_type == 'view' && $duration) {
            // Update average watch duration
            $currentAvg = $userProfile->avg_watch_duration;
            $interactionCount = UserInteraction::where('user_id', $user_id)
                ->where('interaction_type', 'view')
                ->count();
            
            $newAvg = ($currentAvg * $interactionCount + $duration) / ($interactionCount + 1);
            $userProfile->avg_watch_duration = $newAvg;
            
            // Extract categories from the post if available
            $soundCategory = DB::table('tbl_sound_category')
                ->join('tbl_sound', 'tbl_sound.sound_category_id', '=', 'tbl_sound_category.sound_category_id')
                ->where('tbl_sound.sound_id', $post->sound_id)
                ->value('tbl_sound_category.sound_category_name');
            
            if ($soundCategory) {
                $userProfile->updateWatchedCategory($soundCategory);
            }
        }
        
        // Extract and save hashtags if available
        if (!empty($post->post_hash_tag) && ($interaction_type == 'like' || $interaction_type == 'share')) {
            $hashtags = ContentProfile::extractHashtags($post->post_hash_tag);
            foreach ($hashtags as $hashtag) {
                $userProfile->addFavoriteHashtag($hashtag);
            }
        }
        
        // Save sound preference if the user likes or shares the post
        if (($interaction_type == 'like' || $interaction_type == 'share') && $post->sound_id) {
            $userProfile->addFavoriteSound($post->sound_id);
        }
        
        $userProfile->save();
    }
    
    /**
     * Update content profile based on interactions
     */
    private function updateContentProfile($post_id)
    {
        // Get or create content profile
        $contentProfile = ContentProfile::firstOrCreate(['post_id' => $post_id]);
        
        // Get post data
        $post = Post::where('post_id', $post_id)->first();
        if (!$post) return;
        
        // Extract hashtags if not already done
        if (empty($contentProfile->extracted_hashtags) && !empty($post->post_hash_tag)) {
            $contentProfile->extracted_hashtags = ContentProfile::extractHashtags($post->post_hash_tag);
        }
        
        // Update engagement metrics
        $likesCount = Like::where('post_id', $post_id)->count();
        $commentsCount = Comments::where('post_id', $post_id)->count();
        $viewCount = UserInteraction::where('post_id', $post_id)
            ->where('interaction_type', 'view')
            ->count();
        
        $contentProfile->updateEngagementRate($likesCount, $commentsCount, $viewCount);
        
        // Update average watch duration
        $avgDuration = UserInteraction::where('post_id', $post_id)
            ->where('interaction_type', 'view')
            ->whereNotNull('duration')
            ->avg('duration');
        
        if ($avgDuration) {
            $contentProfile->avg_watch_duration = $avgDuration;
        }
        
        // Find similar posts
        $contentProfile->findSimilarPosts();
        
        $contentProfile->save();
    }
    
    /**
     * Get personalized recommendations for a user
     * Enhanced to provide a combined feed of trending and personalized content
     */
    public function getRecommendations(Request $request)
    {
        $rules = [
            'limit' => 'required',
            'user_id' => 'required',
        ];
        
        $validator = Validator::make($request->all(), $rules);
        
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => 401, 'message' => $msg]);
        }
        
        $limit = $request->get('limit') ? $request->get('limit') : 20;
        $user_id = $request->get('user_id');
        
        // Check user's interaction count to determine personalization level
        $interactionCount = UserInteraction::where('user_id', $user_id)->count();
        
        // Get user profile
        $userProfile = UserProfile::where('user_id', $user_id)->first();
        
        // Log for debugging
        Log::info('Recommendation request', [
            'user_id' => $user_id,
            'interaction_count' => $interactionCount,
            'has_profile' => ($userProfile ? 'yes' : 'no')
        ]);
        
        // Determine ratio of trending vs personalized content based on interaction history
        if ($interactionCount < 10) {
            // New user: 90% trending, 10% personalized
            $trendingLimit = ceil($limit * 0.9);
            $personalizedLimit = $limit - $trendingLimit;
        } else if ($interactionCount < 50) {
            // Engaged user: 50% trending, 50% personalized
            $trendingLimit = ceil($limit * 0.5);
            $personalizedLimit = $limit - $trendingLimit;
        } else {
            // Power user: 20% trending, 80% personalized
            $trendingLimit = ceil($limit * 0.2);
            $personalizedLimit = $limit - $trendingLimit;
        }
        
        // Get trending videos (always get some trending content)
        $trendingVideos = $this->getTrendingPosts($trendingLimit, $user_id);
        
        // If user has no profile or is very new, just return trending
        if (!$userProfile || $personalizedLimit <= 0) {
            return $trendingVideos;
        }
        
        // Get personalized recommendations
        $personalizedVideos = $this->getPersonalizedPosts($userProfile, $personalizedLimit, $user_id);
        
        // Combine results, with personalized videos dispersed among trending
        $combinedFeed = $this->interleavePosts($trendingVideos, $personalizedVideos);
        
        return $combinedFeed;
    }
    
    /**
     * Get trending posts for new users
     */
    private function getTrendingPosts($limit, $user_id)
    {
        // Get posts with highest engagement rate
        $trendingPostIds = ContentProfile::orderBy('engagement_rate', 'DESC')
            ->limit($limit * 2) // Get more than needed to filter out blocked users
            ->pluck('post_id')
            ->toArray();
            
        // If no content profiles yet, fall back to trending posts or random
        if (empty($trendingPostIds)) {
            $post_list = Post::where('is_trending', 1)
                ->inRandomOrder()
                ->limit($limit)
                ->get();
                
            if ($post_list->isEmpty()) {
                $post_list = Post::inRandomOrder()
                    ->limit($limit)
                    ->get();
            }
        } else {
            $post_list = Post::whereIn('post_id', $trendingPostIds)
                ->limit($limit)
                ->get();
        }
        
        return $this->formatPostResponse($post_list, $user_id);
    }
    
    /**
     * Get personalized posts based on user profile
     */
    private function getPersonalizedPosts($userProfile, $limit, $user_id)
    {
        // Collaborative filtering: Find users with similar interests
        $similarUserIds = $this->getSimilarUsers($user_id);
        
        // Content-based filtering: Find posts with similar hashtags and sounds
        $favoriteHashtags = $userProfile->favorite_hashtags ?? [];
        $favoriteSounds = $userProfile->favorite_sounds ?? [];
        $watchedCategories = $userProfile->watched_categories ?? [];
        
        // Build query for personalized posts
        $query = Post::select('tbl_post.*')
            ->leftJoin('tbl_content_profiles', 'tbl_post.post_id', '=', 'tbl_content_profiles.post_id')
            ->leftJoin('tbl_sound', 'tbl_post.sound_id', '=', 'tbl_sound.sound_id');
        
        // Exclude posts from blocked users
        $blockedUserIds = BlockUser::where('from_user_id', $user_id)
            ->pluck('block_user_id')
            ->toArray();
            
        if (!empty($blockedUserIds)) {
            $query->whereNotIn('tbl_post.user_id', $blockedUserIds);
        }
        
        // Instead of excluding all interacted posts, only exclude posts viewed too many times
        $overViewedPosts = DB::table('tbl_user_interactions')
            ->select('post_id', DB::raw('count(*) as view_count'))
            ->where('user_id', $user_id)
            ->where('interaction_type', 'view')
            ->groupBy('post_id')
            ->having('view_count', '>', 5)  // Only exclude posts viewed more than 5 times
            ->pluck('post_id')
            ->toArray();
        
        // Also exclude posts the user has skipped
        $skippedPosts = UserInteraction::where('user_id', $user_id)
            ->where('interaction_type', 'skip')
            ->pluck('post_id')
            ->toArray();
        
        // Combine posts to exclude
        $excludePostIds = array_unique(array_merge($overViewedPosts, $skippedPosts));
        
        if (!empty($excludePostIds)) {
            $query->whereNotIn('tbl_post.post_id', $excludePostIds);
        }
        
        // Log for debugging
        Log::info('Personalized feed query', [
            'user_id' => $user_id,
            'excluded_posts' => $excludePostIds,
            'over_viewed_posts' => $overViewedPosts,
            'skipped_posts' => $skippedPosts
        ]);
        
        // Add content-based filtering criteria with weighted scoring
        $scoreQuery = "(CASE ";
        
        // Hashtag matching
        if (!empty($favoriteHashtags)) {
            foreach ($favoriteHashtags as $hashtag) {
                $scoreQuery .= " WHEN tbl_post.post_hash_tag LIKE '%$hashtag%' THEN 5 ";
            }
        }
        
        // Sound matching
        if (!empty($favoriteSounds)) {
            $soundList = implode(',', $favoriteSounds);
            $scoreQuery .= " WHEN tbl_post.sound_id IN ($soundList) THEN 4 ";
        }
        
        // User similarity (collaborative filtering)
        if (!empty($similarUserIds)) {
            $userList = implode(',', $similarUserIds);
            $scoreQuery .= " WHEN tbl_post.user_id IN ($userList) THEN 3 ";
        }
        
        // Posts with high engagement
        $scoreQuery .= " WHEN tbl_content_profiles.engagement_rate > 0.5 THEN 2 ";
        
        // Default score
        $scoreQuery .= " ELSE 1 END) as recommendation_score";
        
        $query->selectRaw($scoreQuery);
        
        // Get final list of recommended posts
        $recommendedPosts = $query->orderBy('recommendation_score', 'DESC')
            ->orderBy(DB::raw('RAND()'))
            ->limit($limit)
            ->get();
            
        // If not enough recommendations, add some random trending posts
        if ($recommendedPosts->count() < $limit) {
            $additionalCount = $limit - $recommendedPosts->count();
            $additionalPosts = Post::where('is_trending', 1)
                ->whereNotIn('post_id', $recommendedPosts->pluck('post_id')->toArray())
                ->inRandomOrder()
                ->limit($additionalCount)
                ->get();
                
            $recommendedPosts = $recommendedPosts->merge($additionalPosts);
        }
        
        return $this->formatPostResponse($recommendedPosts, $user_id);
    }
    
    /**
     * Get similar users based on interactions
     */
    private function getSimilarUsers($user_id)
    {
        // Find users who liked the same posts
        $likedPostIds = Like::where('user_id', $user_id)
            ->pluck('post_id')
            ->toArray();
            
        if (empty($likedPostIds)) {
            return [];
        }
        
        $similarUserIds = Like::whereIn('post_id', $likedPostIds)
            ->where('user_id', '!=', $user_id)
            ->groupBy('user_id')
            ->orderByRaw('COUNT(*) DESC')
            ->limit(10)
            ->pluck('user_id')
            ->toArray();
            
        return $similarUserIds;
    }
    
    /**
     * Format post response in the same way as getPostList
     */
    private function formatPostResponse($post_list, $user_id)
    {
        $i = 0;
        $postData = [];
        
        if (count($post_list) > 0) {
            foreach ($post_list as $post_data_value) {
                $userData = User::where('user_id', $post_data_value['user_id'])->first();
                $soundData = DB::table('tbl_sound')->where('sound_id', $post_data_value['sound_id'])->first();
                $post_comments_count = Comments::where('post_id', $post_data_value['post_id'])->count();
                $post_likes_count = Like::where('post_id', $post_data_value['post_id'])->count();
                $is_video_like = Like::where('post_id', $post_data_value['post_id'])->where('user_id', $user_id)->first();
                $follow_or_not = Followers::where('to_user_id', $post_data_value['user_id'])->where('from_user_id', $user_id)->first();
                $is_bookmark = DB::table('tbl_bookmark')->where('post_id', $post_data_value['post_id'])->where('user_id', $user_id)->first();
                $profile_category_data = DB::table('tbl_profile_category')
                    ->select('tbl_profile_category.*')
                    ->leftJoin('tbl_users as u', 'u.profile_category', '=', 'tbl_profile_category.profile_category_id')
                    ->where('u.user_id', $post_data_value['user_id'])
                    ->first();

                $postData[$i]['post_id'] = (int)$post_data_value['post_id'];
                $postData[$i]['user_id'] = (int)$post_data_value['user_id'];
                $postData[$i]['full_name'] = $userData['full_name'];
                $postData[$i]['user_name'] = $userData['user_name'];
                $postData[$i]['user_profile'] = $userData['user_profile'] ? $userData['user_profile'] : "";
                $postData[$i]['is_verify'] = (int)$userData['is_verify'];
                $postData[$i]['is_trending'] = (int)$post_data_value['is_trending'];
                $postData[$i]['post_description'] = $post_data_value['post_description'];
                $postData[$i]['post_hash_tag'] = $post_data_value['post_hash_tag'];
                $postData[$i]['post_video'] = $post_data_value['post_video'];
                $postData[$i]['post_image'] = $post_data_value['post_image'];
                $postData[$i]['profile_category_id'] = ($profile_category_data && $profile_category_data->profile_category_id) ? (int)$profile_category_data->profile_category_id : "";
                $postData[$i]['profile_category_name'] = ($profile_category_data && $profile_category_data->profile_category_name) ? $profile_category_data->profile_category_name : "";
                $postData[$i]['sound_id'] = (int)$soundData->sound_id;
                $postData[$i]['sound_title'] = $soundData->sound_title;
                $postData[$i]['duration'] = $soundData->duration;
                $postData[$i]['singer'] = $soundData->singer ? $soundData->singer : "";
                $postData[$i]['sound_image'] = $soundData->sound_image ? $soundData->sound_image : "";
                $postData[$i]['sound'] = $soundData->sound ? $soundData->sound : "";
                $postData[$i]['post_likes_count'] = (int)$post_likes_count;
                $postData[$i]['post_comments_count'] = (int)$post_comments_count;
                $postData[$i]['post_view_count'] = (int)$post_data_value['video_view_count'];
                $postData[$i]['created_date'] = date('Y-m-d h:i:s', strtotime($post_data_value['created_at']));
                $postData[$i]['video_likes_or_not'] = !empty($is_video_like) ? 1 : 0;
                $postData[$i]['follow_or_not'] = !empty($follow_or_not) ? 1 : 0;
                $postData[$i]['is_bookmark'] = !empty($is_bookmark) ? 1 : 0;
                $postData[$i]['can_comment'] = $post_data_value['can_comment'] ? 1 : 0;
                $postData[$i]['can_duet'] = $post_data_value['can_duet'] ? 1 : 0;
                $postData[$i]['can_save'] = $post_data_value['can_save'] ? 1 : 0;
                $i++;
            }

            return response()->json(['status' => 200, 'message' => "Post List Get Successfully.", 'data' => $postData]);
        } else {
            return response()->json(['status' => 401, 'message' => "No Data Found.", 'data' => $postData]);
        }
    }
    
    /**
     * Helper method to interleave trending and personalized posts
     * Creates a mixed feed with both types of content
     */
    private function interleavePosts($trendingPosts, $personalizedPosts)
    {
        // Extract data arrays from responses
        $trendingData = json_decode($trendingPosts->getContent(), true);
        $personalizedData = json_decode($personalizedPosts->getContent(), true);
        
        // Check if we have valid data
        if (!isset($trendingData['data']) || empty($trendingData['data'])) {
            return $personalizedPosts; // If no trending data, return just personalized
        }
        
        if (!isset($personalizedData['data']) || empty($personalizedData['data'])) {
            return $trendingPosts; // If no personalized data, return just trending
        }
        
        $trendingVideos = $trendingData['data'];
        $personalizedVideos = $personalizedData['data'];
        
        // Log for debugging
        Log::info('Interleaving posts', [
            'trending_count' => count($trendingVideos),
            'personalized_count' => count($personalizedVideos)
        ]);
        
        // Interleave videos - 2 trending, then 1 personalized as a pattern
        // This ratio can be adjusted based on what works best for engagement
        $result = [];
        $tIndex = 0;
        $pIndex = 0;
        $pattern = 0; // Used to track position in pattern
        
        while ($tIndex < count($trendingVideos) || $pIndex < count($personalizedVideos)) {
            // Add trending video if available
            if ($pattern < 2 && $tIndex < count($trendingVideos)) {
                $result[] = $trendingVideos[$tIndex++];
                $pattern++;
            }
            // Add personalized video if available
            else if ($pIndex < count($personalizedVideos)) {
                $result[] = $personalizedVideos[$pIndex++];
                $pattern = 0; // Reset pattern
            }
            // If we've run out of personalized but still have trending
            else if ($tIndex < count($trendingVideos)) {
                $result[] = $trendingVideos[$tIndex++];
                $pattern++;
            }
            // Failsafe to prevent infinite loop
            else {
                break;
            }
        }
        
        // Apply freshness boost to newer content
        $result = $this->applyFreshnessBoost($result);
        
        // Return combined results in same format
        return response()->json([
            'status' => 200,
            'message' => 'Post get successfully',
            'data' => $result
        ]);
    }
    
    /**
     * Apply freshness boost to reorder content slightly
     * Newer content gets a higher position in the feed
     */
    private function applyFreshnessBoost($videos) 
    {
        // Convert all dates to timestamps for comparison
        foreach ($videos as &$video) {
            if (isset($video['created_at'])) {
                $video['_timestamp'] = strtotime($video['created_at']);
                $video['_freshness_score'] = 0;
                
                // Calculate days since creation
                $daysSinceCreation = (time() - $video['_timestamp']) / 86400; // 86400 seconds in a day
                
                // Apply freshness boost (higher for newer content)
                if ($daysSinceCreation < 1) { // Less than a day old
                    $video['_freshness_score'] = 3;
                } else if ($daysSinceCreation < 3) { // Less than 3 days old
                    $video['_freshness_score'] = 2;
                } else if ($daysSinceCreation < 7) { // Less than a week old
                    $video['_freshness_score'] = 1;
                }
            }
        }
        
        // Sort first 10 videos by freshness score
        if (count($videos) > 10) {
            $firstTen = array_slice($videos, 0, 10);
            $rest = array_slice($videos, 10);
            
            // Sort first 10 by freshness
            usort($firstTen, function($a, $b) {
                return $b['_freshness_score'] - $a['_freshness_score'];
            });
            
            // Merge back together
            $videos = array_merge($firstTen, $rest);
        }
        
        // Remove temporary fields
        foreach ($videos as &$video) {
            unset($video['_timestamp']);
            unset($video['_freshness_score']);
        }
        
        return $videos;
    }
}
