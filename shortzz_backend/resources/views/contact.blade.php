<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Contact Us - LiveTok</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Poppins', sans-serif;
            background: #121212;
            color: #fff;
        }
        
        .gradient-border {
            background: linear-gradient(90deg, #fe2c55, #25F4EE);
            padding: 1px;
        }

        h1, h2 {
            background: linear-gradient(90deg, #fe2c55, #25F4EE);
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
        }

        .bg-icon-pink {
            background: rgba(254, 44, 85, 0.2);
        }

        .bg-icon-cyan {
            background: rgba(37, 244, 238, 0.2);
        }

        input:focus, textarea:focus, select:focus {
            border-color: #25F4EE !important;
        }

        button[type="submit"] {
            background: linear-gradient(90deg, #fe2c55, #25F4EE);
        }

        button[type="submit"]:hover {
            opacity: 0.9;
        }
    </style>
</head>
<body class="min-h-screen">
    <div class="container mx-auto px-4 py-8">
        <div class="max-w-4xl mx-auto">
            <h1 class="text-4xl font-bold mb-8">Contact Us</h1>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                <!-- Contact Information -->
                <div class="space-y-6">
                    <section>
                        <h2 class="text-2xl font-semibold mb-4">Get in Touch</h2>
                        <p class="text-gray-300 mb-6">Have questions? We'd love to hear from you. Send us a message and we'll respond as soon as possible.</p>
                        
                        <div class="space-y-4">
                            <div class="flex items-start space-x-4">
                                <div class="bg-pink-500 bg-opacity-20 p-3 rounded-full">
                                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
                                    </svg>
                                </div>
                                <div>
                                    <h3 class="font-semibold">Email</h3>
                                    <p class="text-gray-300">support@livetok.com</p>
                                </div>
                            </div>

                            <div class="flex items-start space-x-4">
                                <div class="bg-orange-500 bg-opacity-20 p-3 rounded-full">
                                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/>
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/>
                                    </svg>
                                </div>
                                <div>
                                    <h3 class="font-semibold">Office</h3>
                                    <p class="text-gray-300">123 LiveTok Street<br>San Francisco, CA 94105</p>
                                </div>
                            </div>

                            <div class="flex items-start space-x-4">
                                <div class="bg-purple-500 bg-opacity-20 p-3 rounded-full">
                                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
                                    </svg>
                                </div>
                                <div>
                                    <h3 class="font-semibold">Phone</h3>
                                    <p class="text-gray-300">+1 (555) 123-4567</p>
                                </div>
                            </div>
                        </div>
                    </section>

                    <section>
                        <h2 class="text-2xl font-semibold mb-4">Follow Us</h2>
                        <div class="flex space-x-4">
                            <a href="#" class="bg-gray-800 p-3 rounded-full hover:bg-gray-700 transition">
                                <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                                    <path d="M22.675 0H1.325C0.593 0 0 0.593 0 1.325V22.676C0 23.407 0.593 24 1.325 24H12.82V14.706H9.692V11.084H12.82V8.413C12.82 5.313 14.713 3.625 17.479 3.625C18.804 3.625 19.942 3.724 20.274 3.768V7.008L18.356 7.009C16.852 7.009 16.561 7.724 16.561 8.772V11.085H20.148L19.681 14.707H16.561V24H22.677C23.407 24 24 23.407 24 22.675V1.325C24 0.593 23.407 0 22.675 0Z"/>
                                </svg>
                            </a>
                            <a href="#" class="bg-gray-800 p-3 rounded-full hover:bg-gray-700 transition">
                                <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                                    <path d="M23.954 4.569c-.885.389-1.83.654-2.825.775 1.014-.611 1.794-1.574 2.163-2.723-.951.555-2.005.959-3.127 1.184-.896-.959-2.173-1.559-3.591-1.559-2.717 0-4.92 2.203-4.92 4.917 0 .39.045.765.127 1.124C7.691 8.094 4.066 6.13 1.64 3.161c-.427.722-.666 1.561-.666 2.475 0 1.71.87 3.213 2.188 4.096-.807-.026-1.566-.248-2.228-.616v.061c0 2.385 1.693 4.374 3.946 4.827-.413.111-.849.171-1.296.171-.314 0-.615-.03-.916-.086.631 1.953 2.445 3.377 4.604 3.417-1.68 1.319-3.809 2.105-6.102 2.105-.39 0-.779-.023-1.17-.067 2.189 1.394 4.768 2.209 7.557 2.209 9.054 0 13.999-7.496 13.999-13.986 0-.209 0-.42-.015-.63.961-.689 1.8-1.56 2.46-2.548l-.047-.02z"/>
                                </svg>
                            </a>
                            <a href="#" class="bg-gray-800 p-3 rounded-full hover:bg-gray-700 transition">
                                <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                                    <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/>
                                </svg>
                            </a>
                        </div>
                    </section>
                </div>

                <!-- Contact Form -->
                <div class="gradient-border rounded-lg">
                    @if(session('success'))
                        <div class="bg-green-500 text-white p-4 mb-4 rounded-lg">
                            {{ session('success') }}
                        </div>
                    @endif
                    @if(session('error'))
                        <div class="bg-red-500 text-white p-4 mb-4 rounded-lg">
                            {{ session('error') }}
                        </div>
                    @endif
                    @if($errors->any())
                        <div class="bg-red-500 text-white p-4 mb-4 rounded-lg">
                            <ul>
                                @foreach($errors->all() as $error)
                                    <li>{{ $error }}</li>
                                @endforeach
                            </ul>
                        </div>
                    @endif
                    <form action="{{ route('contact.submit') }}" method="POST" class="bg-gray-900 bg-opacity-50 p-6 rounded-lg space-y-6">
                        @csrf
                        <div>
                            <label class="block text-sm font-medium mb-2" for="name">Name</label>
                            <input type="text" id="name" name="name" class="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:border-pink-500 text-white" required>
                        </div>

                        <div>
                            <label class="block text-sm font-medium mb-2" for="email">Email</label>
                            <input type="email" id="email" name="email" class="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:border-pink-500 text-white" required>
                        </div>

                        <div>
                            <label class="block text-sm font-medium mb-2" for="subject">Subject</label>
                            <select id="subject" name="subject" class="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:border-pink-500 text-white">
                                <option value="general">General Inquiry</option>
                                <option value="support">Technical Support</option>
                                <option value="billing">Billing Question</option>
                                <option value="partnership">Partnership Opportunity</option>
                            </select>
                        </div>

                        <div>
                            <label class="block text-sm font-medium mb-2" for="message">Message</label>
                            <textarea id="message" name="message" rows="4" class="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:border-pink-500 text-white resize-none" required></textarea>
                        </div>

                        <button type="submit" class="w-full bg-gradient-to-r from-pink-500 to-orange-500 text-white font-semibold py-3 px-6 rounded-lg hover:opacity-90 transition">
                            Send Message
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>
</body>
</html> 