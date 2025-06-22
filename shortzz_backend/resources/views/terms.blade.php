<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Terms of Service - LiveTok</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Poppins', sans-serif;
            background: #121212;
            color: #fff;
        }

        h1, h2 {
            background: linear-gradient(90deg, #fe2c55, #25F4EE);
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
        }

        section {
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 1rem;
            padding: 2rem;
            margin-bottom: 1.5rem;
        }
    </style>
</head>
<body class="min-h-screen">
    <div class="container mx-auto px-4 py-8">
        <div class="max-w-4xl mx-auto">
            <h1 class="text-4xl font-bold mb-8">Terms of Service</h1>
            
            <div class="space-y-6">
                <section>
                    <h2 class="text-2xl font-semibold mb-4">1. Acceptance of Terms</h2>
                    <p class="text-gray-300">By accessing or using LiveTok, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.</p>
                </section>

                <section>
                    <h2 class="text-2xl font-semibold mb-4">2. User Accounts</h2>
                    <ul class="list-disc list-inside text-gray-300 space-y-2">
                        <li>You must be at least 13 years old to use LiveTok</li>
                        <li>You are responsible for maintaining the security of your account</li>
                        <li>You must provide accurate and complete information</li>
                        <li>You may not use another person's account without permission</li>
                    </ul>
                </section>

                <section>
                    <h2 class="text-2xl font-semibold mb-4">3. Content Guidelines</h2>
                    <p class="text-gray-300 mb-4">You agree not to post content that:</p>
                    <ul class="list-disc list-inside text-gray-300 space-y-2">
                        <li>Is illegal, harmful, or offensive</li>
                        <li>Infringes on others' intellectual property rights</li>
                        <li>Contains hate speech or harassment</li>
                        <li>Promotes violence or dangerous activities</li>
                        <li>Contains spam or unauthorized advertising</li>
                    </ul>
                </section>

                <section>
                    <h2 class="text-2xl font-semibold mb-4">4. Intellectual Property</h2>
                    <p class="text-gray-300">LiveTok respects intellectual property rights and expects users to do the same. You retain ownership of your content, but grant LiveTok a license to use, modify, and distribute it within our services.</p>
                </section>

                <section>
                    <h2 class="text-2xl font-semibold mb-4">5. Termination</h2>
                    <p class="text-gray-300">We reserve the right to suspend or terminate your account for violations of these terms or for any other reason at our discretion.</p>
                </section>

                <section>
                    <h2 class="text-2xl font-semibold mb-4">6. Limitation of Liability</h2>
                    <p class="text-gray-300">LiveTok is provided "as is" without warranties of any kind. We are not liable for any damages arising from your use of our services.</p>
                </section>

                <section>
                    <h2 class="text-2xl font-semibold mb-4">7. Changes to Terms</h2>
                    <p class="text-gray-300">We may modify these terms at any time. Continued use of LiveTok after changes constitutes acceptance of the new terms.</p>
                </section>

                <section>
                    <h2 class="text-2xl font-semibold mb-4">8. Governing Law</h2>
                    <p class="text-gray-300">These terms are governed by the laws of the jurisdiction in which LiveTok operates, without regard to its conflict of law provisions.</p>
                </section>

                <section>
                    <h2 class="text-2xl font-semibold mb-4">9. Contact</h2>
                    <p class="text-gray-300">For questions about these Terms of Service, please contact us at contact@livetok.app</p>
                </section>
            </div>

            <div class="mt-8 text-gray-400 text-sm">
                Last updated: {{ date('F d, Y') }}
            </div>
        </div>
    </div>
</body>
</html> 