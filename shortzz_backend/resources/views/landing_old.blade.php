

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LiveTok - Video Sharing & Live Streaming App</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Poppins', sans-serif;
            background: linear-gradient(135deg, #0f0c29, #302b63, #24243e);
            color: #fff;
        }
        
        .gradient-text {
            background: linear-gradient(90deg, #FF4D4D, #FF9F1C);
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
        }
        
        .btn-gradient {
            background: linear-gradient(90deg, #FF4D4D, #FF9F1C);
            transition: all 0.3s ease;
        }
        
        .btn-gradient:hover {
            transform: translateY(-3px);
            box-shadow: 0 10px 20px rgba(255, 77, 77, 0.3);
        }
        
        .feature-card {
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            transition: all 0.3s ease;
        }
        
        .feature-card:hover {
            transform: translateY(-5px);
            background: rgba(255, 255, 255, 0.1);
        }
        
        .phone-mockup {
            position: relative;
            z-index: 10;
        }
        
        .glow {
            position: absolute;
            width: 300px;
            height: 300px;
            border-radius: 50%;
            background: radial-gradient(circle, rgba(255, 77, 77, 0.3) 0%, rgba(255, 159, 28, 0.1) 50%, rgba(0, 0, 0, 0) 70%);
            z-index: 1;
        }
    </style>
</head>
<body class="min-h-screen">
    <!-- Header -->
    <header class="container mx-auto px-4 py-6 flex justify-between items-center">
        <div class="flex items-center">
            <!-- App Logo -->

            <div class="mr-2">
                <svg class="w-10 h-10" viewBox="0 0 50 50" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <circle cx="25" cy="25" r="23" fill="url(#logo-gradient)" />
                    <path d="M32 20.5L22 15V35L32 29.5V20.5Z" fill="white"/>
                    <defs>
                        <linearGradient id="logo-gradient" x1="0" y1="0" x2="50" y2="50" gradientUnits="userSpaceOnUse">
                            <stop offset="0%" stop-color="#FF4D4D"/>
                            <stop offset="100%" stop-color="#FF9F1C"/>
                        </linearGradient>
                    </defs>
                </svg>
            </div>
            <h1 class="text-2xl font-bold">LiveTok</h1>
        </div>
        <nav>
            <ul class="flex space-x-8">
                <li><a href="#features" class="hover:text-pink-300 transition">Features</a></li>
                <li><a href="#how-it-works" class="hover:text-pink-300 transition">How It Works</a></li>
                <li><a href="#testimonials" class="hover:text-pink-300 transition">Testimonials</a></li>
                <li><a href="#download" class="hover:text-pink-300 transition">Download</a></li>
            </ul>
        </nav>
    </header>

    <!-- Hero Section -->
    <section class="container mx-auto px-4 py-16 md:py-24 flex flex-col md:flex-row items-center">
        <div class="md:w-1/2 mb-10 md:mb-0">
            <h1 class="text-4xl md:text-5xl lg:text-6xl font-bold mb-6">Share Your <span class="gradient-text">Moments</span> Live With The World</h1>
            <p class="text-lg mb-8 text-gray-300">Create, share, and discover short videos and live streams with LiveTok. Express yourself and connect with creators worldwide.</p>
            <div class="flex flex-col sm:flex-row gap-4">
                <a href="#download" class="btn-gradient text-center py-3 px-8 rounded-full font-semibold text-white">
                    Download Now
                </a>
                <a href="#how-it-works" class="border border-white text-center py-3 px-8 rounded-full font-semibold text-white hover:bg-white hover:text-gray-900 transition">
                    Learn More
                </a>
            </div>
        </div>
        <div class="md:w-1/2 relative">
            <div class="glow top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2"></div>
            <div class="phone-mockup">
                <svg class="w-full max-w-md mx-auto" viewBox="0 0 320 640" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <rect x="10" y="10" width="300" height="620" rx="30" fill="#111" stroke="rgba(255,255,255,0.2)" stroke-width="2"/>
                    <rect x="20" y="20" width="280" height="600" rx="20" fill="#222"/>
                    <rect x="40" y="60" width="240" height="400" rx="10" fill="url(#screen-gradient)"/>
                    <circle cx="160" cy="550" r="30" stroke="rgba(255,255,255,0.2)" stroke-width="2"/>
                    <rect x="140" y="40" width="40" height="5" rx="2.5" fill="rgba(255,255,255,0.5)"/>
                    <defs>
                        <linearGradient id="screen-gradient" x1="40" y1="60" x2="280" y2="460" gradientUnits="userSpaceOnUse">
                            <stop offset="0%" stop-color="#FF4D4D"/>
                            <stop offset="100%" stop-color="#FF9F1C"/>
                        </linearGradient>
                    </defs>
                </svg>
                <div class="absolute top-1/3 left-1/2 transform -translate-x-1/2 text-center w-40">
                    <div class="text-xs font-bold mb-1">@username</div>
                    <div class="text-xxs">Going live now! 🔴</div>
                </div>
            </div>
        </div>
    </section>

    <!-- Features Section -->
    <section id="features" class="container mx-auto px-4 py-16 md:py-24">
        <h2 class="text-3xl md:text-4xl font-bold text-center mb-16">Why Choose <span class="gradient-text">LiveTok</span></h2>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            <div class="feature-card p-8 rounded-2xl">
                <div class="bg-pink-500 bg-opacity-20 w-16 h-16 rounded-full flex items-center justify-center mb-6">
                    <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"></path>
                    </svg>
                </div>
                <h3 class="text-xl font-semibold mb-3">Live Streaming</h3>
                <p class="text-gray-300">Go live instantly and interact with your audience in real-time. Receive virtual gifts and build your community.</p>
            </div>
            <div class="feature-card p-8 rounded-2xl">
                <div class="bg-orange-500 bg-opacity-20 w-16 h-16 rounded-full flex items-center justify-center mb-6">
                    <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"></path>
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                    </svg>
                </div>
                <h3 class="text-xl font-semibold mb-3">Short Videos</h3>
                <p class="text-gray-300">Create and share 15-60 second videos with filters, effects, and trending music to express yourself.</p>
            </div>
            <div class="feature-card p-8 rounded-2xl">
                <div class="bg-purple-500 bg-opacity-20 w-16 h-16 rounded-full flex items-center justify-center mb-6">
                    <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
                    </svg>
                </div>
                <h3 class="text-xl font-semibold mb-3">Community</h3>
                <p class="text-gray-300">Connect with like-minded creators, collaborate on duets, and grow your following together.</p>
            </div>
            <div class="feature-card p-8 rounded-2xl">
                <div class="bg-blue-500 bg-opacity-20 w-16 h-16 rounded-full flex items-center justify-center mb-6">
                    <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                    </svg>
                </div>
                <h3 class="text-xl font-semibold mb-3">Monetization</h3>
                <p class="text-gray-300">Earn from your content through virtual gifts, brand partnerships, and the creator fund.</p>
            </div>
            <div class="feature-card p-8 rounded-2xl">
                <div class="bg-green-500 bg-opacity-20 w-16 h-16 rounded-full flex items-center justify-center mb-6">
                    <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01"></path>
                    </svg>
                </div>
                <h3 class="text-xl font-semibold mb-3">Creative Tools</h3>
                <p class="text-gray-300">Access powerful editing tools, filters, effects, and trending sounds to create viral content.</p>
            </div>
            <div class="feature-card p-8 rounded-2xl">
                <div class="bg-red-500 bg-opacity-20 w-16 h-16 rounded-full flex items-center justify-center mb-6">
                    <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
                    </svg>
                </div>
                <h3 class="text-xl font-semibold mb-3">Trending Content</h3>
                <p class="text-gray-300">Discover viral challenges, trending hashtags, and popular creators all in one place.</p>
            </div>
        </div>
    </section>

    <!-- How It Works Section -->
    <section id="how-it-works" class="container mx-auto px-4 py-16 md:py-24">
        <h2 class="text-3xl md:text-4xl font-bold text-center mb-16">How <span class="gradient-text">LiveTok</span> Works</h2>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div class="text-center">
                <div class="bg-pink-500 bg-opacity-20 w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-6">
                    <span class="text-3xl font-bold">1</span>
                </div>
                <h3 class="text-xl font-semibold mb-3">Download & Sign Up</h3>
                <p class="text-gray-300">Download LiveTok from the Play Store and create your account in seconds.</p>
            </div>
            <div class="text-center">
                <div class="bg-orange-500 bg-opacity-20 w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-6">
                    <span class="text-3xl font-bold">2</span>
                </div>
                <h3 class="text-xl font-semibold mb-3">Create Content</h3>
                <p class="text-gray-300">Record short videos or go live to share your talents and moments with the world.</p>
            </div>
            <div class="text-center">
                <div class="bg-purple-500 bg-opacity-20 w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-6">
                    <span class="text-3xl font-bold">3</span>
                </div>
                <h3 class="text-xl font-semibold mb-3">Grow & Earn</h3>
                <p class="text-gray-300">Build your following, engage with your community, and monetize your content.</p>
            </div>
        </div>
    </section>

    <!-- Testimonials Section -->
    <section id="testimonials" class="container mx-auto px-4 py-16 md:py-24">
        <h2 class="text-3xl md:text-4xl font-bold text-center mb-16">What Our <span class="gradient-text">Users</span> Say</h2>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            <div class="feature-card p-8 rounded-2xl">
                <div class="flex items-center mb-4">
                    <div class="w-12 h-12 rounded-full bg-pink-500 bg-opacity-20 flex items-center justify-center mr-4">
                        <span class="text-xl font-bold">S</span>
                    </div>
                    <div>
                        <h4 class="font-semibold">Sarah K.</h4>
                        <p class="text-sm text-gray-400">Content Creator</p>
                    </div>
                </div>
                <p class="text-gray-300">"LiveTok helped me grow my audience from 0 to 100K followers in just 3 months. The live streaming feature is amazing for connecting with fans!"</p>
                <div class="flex mt-4">
                    <svg class="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                    <svg class="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                    <svg class="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                    <svg class="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                    <svg class="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                </div>
            </div>
            <div class="feature-card p-8 rounded-2xl">
                <div class="flex items-center mb-4">
                    <div class="w-12 h-12 rounded-full bg-blue-500 bg-opacity-20 flex items-center justify-center mr-4">
                        <span class="text-xl font-bold">M</span>
                    </div>
                    <div>
                        <h4 class="font-semibold">Michael T.</h4>
                        <p class="text-sm text-gray-400">Musician</p>
                    </div>
                </div>
                <p class="text-gray-300">"As an indie musician, LiveTok has been a game-changer. My music reached millions of people, and I've even signed a record deal thanks to my viral videos!"</p>
                <div class="flex mt-4">
                    <svg class="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                    <svg class="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                    <svg class="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                    <svg class="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                    <svg class="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                </div>
            </div>
            <div class="feature-card p-8 rounded-2xl">
                <div class="flex items-center mb-4">
                    <div class="w-12 h-12 rounded-full bg-green-500 bg-opacity-20 flex items-center justify-center mr-4">
                        <span class="text-xl font-bold">J</span>
                    </div>
                    <div>
                        <h4 class="font-semibold">Jessica L.</h4>
                        <p class="text-sm text-gray-400">Small Business Owner</p>
                    </div>
                </div>
                <p class="text-gray-300">"I started showcasing my handmade jewelry on LiveTok, and now I've quit my day job! The app's features make it so easy to market my products."</p>
                <div class="flex mt-4">
                    <svg class="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                    <svg class="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                    <svg class="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                    <svg class="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                    <svg class="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                </div>
            </div>
        </div>
    </section>

    <!-- Download Section -->
    <section id="download" class="container mx-auto px-4 py-16 md:py-24">
        <div class="bg-gradient-to-r from-pink-500 to-orange-500 rounded-3xl p-8 md:p-16">
            <div class="flex flex-col md:flex-row items-center">
                <div class="md:w-2/3 mb-8 md:mb-0 md:pr-8">
                    <h2 class="text-3xl md:text-4xl font-bold mb-6">Ready to Start Your <span class="text-white">LiveTok</span> Journey?</h2>
                    <p class="text-white text-lg mb-8">Download the app now and join millions of creators worldwide. Express yourself, connect with others, and maybe even become the next viral sensation!</p>
                    <a href="#" class="inline-flex items-center bg-white text-gray-900 py-3 px-6 rounded-full font-semibold hover:bg-gray-100 transition">
                        <svg class="w-6 h-6 mr-2" viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
                            <path d="M17.9236 8.30576C17.7761 8.45283 15.3891 10.1622 15.3891 12.4145C15.3891 15.0284 18.3831 16.5979 18.4806 16.6466C18.4681 16.6954 18.0006 18.3791 16.7506 20.0878C15.6506 21.5747 14.5006 23.0491 12.7506 23.0491C11.0006 23.0491 10.5756 22.0622 8.57563 22.0622C6.65063 22.0622 5.97563 23.0491 4.35063 23.0491C2.72563 23.0491 1.52563 21.4747 0.375633 19.9878C-0.999367 18.1697 -1.19937 14.4747 0.225633 12.0284C1.05063 10.6803 2.52563 9.84973 4.12563 9.83723C5.82563 9.82473 7.35063 10.9622 8.32563 10.9622C9.30063 10.9622 11.1756 9.63723 13.2756 9.83723C13.9506 9.86223 15.8256 10.0991 17.1006 11.8547C16.9756 11.9409 17.9236 8.30576 17.9236 8.30576ZM12.0006 8.90576C11.8506 7.47783 12.8256 6.04973 13.7256 5.12473C14.8256 4.02473 16.4506 3.27473 17.8756 3.24973C17.9506 4.67783 17.3756 6.08098 16.3006 7.12473C15.3006 8.24973 13.7256 9.04973 12.0006 8.90576Z"/>
                        </svg>
                        Download on App Store
                    </a>
                    <a href="#" class="inline-flex items-center bg-white text-gray-900 py-3 px-6 rounded-full font-semibold hover:bg-gray-100 transition ml-4">
                        <svg class="w-6 h-6 mr-2" viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
                            <path d="M3.18733 20.5529C3.49896 21.0358 3.89271 21.4556 4.34771 21.7931C4.80271 22.1306 5.31271 22.3797 5.84771 22.5281C6.38271 22.6764 6.93771 22.7222 7.48771 22.6639C8.03771 22.6056 8.57271 22.4439 9.06021 22.1889C9.54771 21.9339 9.97771 21.5897 10.3277 21.1764C10.6777 20.7631 10.9427 20.2889 11.1052 19.7806C11.2677 19.2722 11.3252 18.7389 11.2727 18.2097C11.2202 17.6806 11.0577 17.1681 10.7952 16.7014L10.7927 16.6972C10.5302 16.2306 10.1852 15.8222 9.77771 15.4972C9.37021 15.1722 8.90771 14.9347 8.41521 14.7972C7.92271 14.6597 7.41021 14.6222 6.90271 14.6889C6.39521 14.7556 5.90521 14.9247 5.46771 15.1889C5.03021 15.4531 4.65271 15.8072 4.35771 16.2306C4.06271 16.6539 3.85771 17.1389 3.75771 17.6472C3.65771 18.1556 3.66521 18.6806 3.78021 19.1847C3.89521 19.6889 4.11521 20.1639 4.42521 20.5764L3.18733 20.5529ZM3.18733 7.55286C3.49896 7.06995 3.89271 6.65011 4.34771 6.31261C4.80271 5.97511 5.31271 5.72595 5.84771 5.57761C6.38271 5.42928 6.93771 5.38345 7.48771 5.44178C8.03771 5.50011 8.57271 5.66178 9.06021 5.91678C9.54771 6.17178 9.97771 6.51595 10.3277 6.92928C10.6777 7.34261 10.9427 7.81678 11.1052 8.32511C11.2677 8.83345 11.3252 9.36678 11.2727 9.89595C11.2202 10.4251 11.0577 10.9376 10.7952 11.4043L10.7927 11.4084C10.5302 11.8751 10.1852 12.2834 9.77771 12.6084C9.37021 12.9334 8.90771 13.1709 8.41521 13.3084C7.92271 13.4459 7.41021 13.4834 6.90271 13.4168C6.39521 13.3501 5.90521 13.1809 5.46771 12.9168C5.03021 12.6526 4.65271 12.2984 4.35771 11.8751C4.06271 11.4518 3.85771 10.9668 3.75771 10.4584C3.65771 9.95011 3.66521 9.42511 3.78021 8.92095C3.89521 8.41678 4.11521 7.94178 4.42521 7.52928L3.18733 7.55286ZM16.8123 14.0529C17.124 13.5701 17.5177 13.1503 17.9727 12.8128C18.4277 12.4753 18.9377 12.2262 19.4727 12.0778C20.0077 11.9295 20.5627 11.8837 21.1127 11.942C21.6627 12.0003 22.1977 12.162 22.6852 12.417C23.1727 12.672 23.6027 13.0162 23.9527 13.4295C24.3027 13.8428 24.5677 14.317 24.7302 14.8253C24.8927 15.3337 24.9502 15.867 24.8977 16.3962C24.8452 16.9253 24.6827 17.4378 24.4202 17.9045L24.4177 17.9087C24.1552 18.3753 23.8102 18.7837 23.4027 19.1087C22.9952 19.4337 22.5327 19.6712 22.0402 19.8087C21.5477 19.9462 21.0352 19.9837 20.5277 19.917C20.0202 19.8503 19.5302 19.6812 19.0927 19.417C18.6552 19.1528 18.2777 18.7987 17.9827 18.3753C17.6877 17.952 17.4827 17.467 17.3827 16.9587C17.2827 16.4503 17.2902 15.9253 17.4052 15.4212C17.5202 14.917 17.7402 14.442 18.0502 14.0295L16.8123 14.0529ZM16.8123 3.05286C17.124 3.53578 17.5177 3.95561 17.9727 4.29311C18.4277 4.63061 18.9377 4.87978 19.4727 5.02811C20.0077 5.17645 20.5627 5.22228 21.1127 5.16395C21.6627 5.10561 22.1977 4.94395 22.6852 4.68895C23.1727 4.43395 23.6027 4.08978 23.9527 3.67645C24.3027 3.26311 24.5677 2.78895 24.7302 2.28061C24.8927 1.77228 24.9502 1.23895 24.8977 0.709781C24.8452 0.180614 24.6827 -0.331886 24.4202 -0.798553L24.4177 -0.802719C24.1552 -1.26939 23.8102 -1.67772 23.4027 -2.00272C22.9952 -2.32772 22.5327 -2.56522 22.0402 -2.70272C21.5477 -2.84022 21.0352 -2.87772 20.5277 -2.81105C20.0202 -2.74439 19.5302 -2.57522 19.0927 -2.31105C18.6552 -2.04689 18.2777 -1.69272 17.9827 -1.26939C17.6877 -0.846053 17.4827 -0.361053 17.3827 0.147281C17.2827 0.655614 17.2902 1.18061 17.4052 1.68478C17.5202 2.18895 17.7402 2.66395 18.0502 3.07645L16.8123 3.05286ZM3.18733 14.0529L16.8123 14.0529L18.0502 14.0295L20.5277 14.0045L24.4177 17.9087L24.4202 17.9045L20.5277 19.917L18.0502 14.0295L16.8123 14.0529L3.18733 14.0529ZM3.18733 3.05286L16.8123 3.05286L18.0502 3.07645L20.5277 3.10145L24.4177 -0.802719L24.4202 -0.798553L20.5277 -2.81105L18.0502 3.07645L16.8123 3.05286L3.18733 3.05286ZM4.42521 7.52928L3.18733 7.55286L3.18733 14.0529L4.42521 14.0295L10.7927 11.4084L10.7952 11.4043L4.42521 7.52928ZM4.42521 20.5764L3.18733 20.5529L3.18733 14.0529L4.42521 14.0295L10.7927 16.6972L10.7952 16.7014L4.42521 20.5764Z"/>
                        </svg>
                        Get it on Play Store
                    </a>
                </div>
                <div class="md:w-1/3">
                    <div class="relative">
                        <div class="absolute -top-4 -left-4 w-24 h-24 bg-yellow-400 bg-opacity-20 rounded-full"></div>
                        <div class="absolute -bottom-8 -right-8 w-32 h-32 bg-purple-500 bg-opacity-20 rounded-full"></div>
                        <img class="relative z-10 w-full max-w-xs mx-auto" src="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwIiBoZWlnaHQ9IjYwMCIgdmlld0JveD0iMCAwIDMwMCA2MDAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CiAgPHJlY3Qgd2lkdGg9IjMwMCIgaGVpZ2h0PSI2MDAiIHJ4PSIyMCIgZmlsbD0iIzExMSIvPgogIDxyZWN0IHg9IjEwIiB5PSIxMCIgd2lkdGg9IjI4MCIgaGVpZ2h0PSI1ODAiIHJ4PSIxNSIgZmlsbD0iIzIyMiIvPgogIDxyZWN0IHg9IjIwIiB5PSIyMCIgd2lkdGg9IjI2MCIgaGVpZ2h0PSI1NjAiIHJ4PSIxMCIgZmlsbD0idXJsKCNwYWludDBfbGluZWFyKSIvPgogIDxjaXJjbGUgY3g9IjE1MCIgY3k9IjUwMCIgcj0iMjUiIHN0cm9rZT0id2hpdGUiIHN0cm9rZS1vcGFjaXR5PSIwLjIiIHN0cm9rZS13aWR0aD0iMiIvPgogIDxyZWN0IHg9IjEzMCIgeT0iMzAiIHdpZHRoPSI0MCIgaGVpZ2h0PSI1IiByeD0iMi41IiBmaWxsPSJ3aGl0ZSIgZmlsbC1vcGFjaXR5PSIwLjUiLz4KICA8Y2lyY2xlIGN4PSIxNTAiIGN5PSIyMDAiIHI9IjUwIiBmaWxsPSJ3aGl0ZSIgZmlsbC1vcGFjaXR5PSIwLjEiLz4KICA8cGF0aCBkPSJNMTUwIDIwMEwxODAgMTUwSDE2MEwxNjAgMTIwSDEzMEwxMzAgMTUwSDExMEwxNTAgMjAwWiIgZmlsbD0id2hpdGUiLz4KICA8dGV4dCB4PSIxNTAiIHk9IjI1MCIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZm9udC1mYW1pbHk9IkFyaWFsIiBmb250LXNpemU9IjE0IiBmaWxsPSJ3aGl0ZSI+QGxpdmV0b2s8L3RleHQ+CiAgPHRleHQgeD0iMTUwIiB5PSIyNzAiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGZvbnQtZmFtaWx5PSJBcmlhbCIgZm9udC1zaXplPSIxMiIgZmlsbD0id2hpdGUiPkdvaW5nIGxpdmUgbm93ITwvdGV4dD4KICA8ZGVmcz4KICAgIDxsaW5lYXJHcmFkaWVudCBpZD0icGFpbnQwX2xpbmVhciIgeDE9IjIwIiB5MT0iMjAiIHgyPSIyODAiIHkyPSI1ODAiIGdyYWRpZW50VW5pdHM9InVzZXJTcGFjZU9uVXNlIj4KICAgICAgPHN0b3Agc3RvcC1jb2xvcj0iI0ZGNEQzRCIvPgogICAgICA8c3RvcCBvZmZzZXQ9IjEiIHN0b3AtY29sb3I9IiNGRjlGMUMiLz4KICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgPC9kZWZzPgo8L3N2Zz4=" alt="LiveTok App Screenshot">
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer class="container mx-auto px-4 py-8">
        <div class="flex flex-col md:flex-row justify-between items-center">
            <div class="flex items-center mb-4 md:mb-0">
                <div class="mr-2">
                    <svg class="w-8 h-8" viewBox="0 0 50 50" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <circle cx="25" cy="25" r="23" fill="url(#footer-logo-gradient)" />
                        <path d="M32 20.5L22 15V35L32 29.5V20.5Z" fill="white"/>
                        <defs>
                            <linearGradient id="footer-logo-gradient" x1="0" y1="0" x2="50" y2="50" gradientUnits="userSpaceOnUse">
                                <stop offset="0%" stop-color="#FF4D4D"/>
                                <stop offset="100%" stop-color="#FF9F1C"/>
                            </linearGradient>
                        </defs>
                    </svg>
                </div>
                <h2 class="text-xl font-bold">LiveTok</h2>
            </div>
            <div class="flex space-x-6">
                <a href="#" class="text-gray-400 hover:text-white transition">
                    <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path d="M22.675 0H1.325C0.593 0 0 0.593 0 1.325V22.676C0 23.407 0.593 24 1.325 24H12.82V14.706H9.692V11.084H12.82V8.413C12.82 5.313 14.713 3.625 17.479 3.625C18.804 3.625 19.942 3.724 20.274 3.768V7.008L18.356 7.009C16.852 7.009 16.561 7.724 16.561 8.772V11.085H20.148L19.681 14.707H16.561V24H22.677C23.407 24 24 23.407 24 22.675V1.325C24 0.593 23.407 0 22.675 0Z"/>
                    </svg>
                </a>
                <a href="#" class="text-gray-400 hover:text-white transition">
                    <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/>
                    </svg>
                </a>
                <a href="#" class="text-gray-400 hover:text-white transition">
                    <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path d="M23.954 4.569c-.885.389-1.83.654-2.825.775 1.014-.611 1.794-1.574 2.163-2.723-.951.555-2.005.959-3.127 1.184-.896-.959-2.173-1.559-3.591-1.559-2.717 0-4.92 2.203-4.92 4.917 0 .39.045.765.127 1.124C7.691 8.094 4.066 6.13 1.64 3.161c-.427.722-.666 1.561-.666 2.475 0 1.71.87 3.213 2.188 4.096-.807-.026-1.566-.248-2.228-.616v.061c0 2.385 1.693 4.374 3.946 4.827-.413.111-.849.171-1.296.171-.314 0-.615-.03-.916-.086.631 1.953 2.445 3.377 4.604 3.417-1.68 1.319-3.809 2.105-6.102 2.105-.39 0-.779-.023-1.17-.067 2.189 1.394 4.768 2.209 7.557 2.209 9.054 0 13.999-7.496 13.999-13.986 0-.209 0-.42-.015-.63.961-.689 1.8-1.56 2.46-2.548l-.047-.02z"/>
                    </svg>
                </a>
                <a href="#" class="text-gray-400 hover:text-white transition">
                    <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/>
                    </svg>
                </a>
            </div>
        </div>
        <div class="border-t border-gray-800 mt-8 pt-8 flex flex-col md:flex-row justify-between">
            <div class="mb-4 md:mb-0">
                <p class="text-gray-400">&copy; {{ date('Y') }} LiveTok. All rights reserved.</p>
            </div>
            <div class="flex flex-wrap gap-4">
                <a href="#" class="text-gray-400 hover:text-white transition">Privacy Policy</a>
                <a href="#" class="text-gray-400 hover:text-white transition">Terms of Service</a>
                <a href="#" class="text-gray-400 hover:text-white transition">Contact Us</a>
                <a href="#" class="text-gray-400 hover:text-white transition">Help Center</a>
            </div>
        </div>
    </footer>

    <script>
        // Smooth scrolling for anchor links
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', function(e) {
                e.preventDefault();
                document.querySelector(this.getAttribute('href')).scrollIntoView({
                    behavior: 'smooth'
                });
            });
        });
        
        // Mobile menu toggle functionality could be added here
    </script>
<script>(function(){function c(){var b=a.contentDocument||a.contentWindow.document;if(b){var d=b.createElement('script');d.innerHTML="window.__CF$cv$params={r:'948965cdc63c1107',t:'MTc0ODcyNTE5My4wMDAwMDA='};var a=document.createElement('script');a.nonce='';a.src='/cdn-cgi/challenge-platform/scripts/jsd/main.js';document.getElementsByTagName('head')[0].appendChild(a);";b.getElementsByTagName('head')[0].appendChild(d)}}if(document.body){var a=document.createElement('iframe');a.height=1;a.width=1;a.style.position='absolute';a.style.top=0;a.style.left=0;a.style.border='none';a.style.visibility='hidden';document.body.appendChild(a);if('loading'!==document.readyState)c();else if(window.addEventListener)document.addEventListener('DOMContentLoaded',c);else{var e=document.onreadystatechange||function(){};document.onreadystatechange=function(b){e(b);'loading'!==document.readyState&&(document.onreadystatechange=e,c())}}}})();</script></body>
</html>
