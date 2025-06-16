<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Download LiveTok App</title>
    <meta property="og:title" content="{{ $post['user_name'] }}'s Video on LiveTok">
    <meta property="og:description" content="{{ $post['post_description'] }}">
    <meta property="og:image" content="{{ $post['post_image'] }}">
    <meta property="og:type" content="video">
    
    <!-- Add Tailwind CSS via CDN for styling -->
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 min-h-screen">
    <div class="container mx-auto px-4 py-8">
        <div class="max-w-2xl mx-auto bg-white rounded-lg shadow-lg overflow-hidden">
            <!-- Video Thumbnail -->
            <!--<div class="relative aspect-w-9 aspect-h-16">-->
            <!--    <img src="{{ $post['post_image'] }}" alt="Video Thumbnail" class="w-full h-full object-cover">-->
            <!--    <div class="absolute inset-0 bg-black bg-opacity-40 flex items-center justify-center">-->
            <!--        <svg class="w-20 h-20 text-white opacity-80" fill="currentColor" viewBox="0 0 20 20">-->
            <!--            <path d="M8 5v10l8-5-8-5z"/>-->
            <!--        </svg>-->
            <!--    </div>-->
            <!--</div>-->
            
            <!-- Video Info -->
            <div class="p-6">
                <!--<div class="flex items-center mb-4">-->
                <!--    <img src="{{ $post['user_profile'] }}" alt="{{ $post['user_name'] }}" class="w-12 h-12 rounded-full">-->
                <!--    <div class="ml-4">-->
                <!--        <h2 class="text-lg font-semibold">{{ $post['user_name'] }}</h2>-->
                <!--        <p class="text-gray-600 text-sm">{{ \Carbon\Carbon::parse($post['created_at'])->diffForHumans() }}</p>-->
                <!--    </div>-->
                <!--</div>-->
                
                <!--<p class="text-gray-700 mb-6">{{ $post['post_description'] }}</p>-->
                
                <!--<div class="flex items-center text-gray-600 text-sm mb-8">-->
                <!--    <span class="mr-4">-->
                <!--        <svg class="w-4 h-4 inline-block mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">-->
                <!--            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>-->
                <!--            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>-->
                <!--        </svg>-->
                <!--        {{ number_format($post['video_view_count']) }} views-->
                <!--    </span>-->
                <!--</div>-->
                
                <!-- Download App Buttons -->
                <div class="space-y-4">
                    <a href="/" class="block w-full bg-black text-white text-center py-3 rounded-lg hover:bg-gray-900 transition duration-200">
                        Get it on Google Play
                    </a>
                  
                </div>
            </div>
        </div>
    </div>
</body>
</html> 