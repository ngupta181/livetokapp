<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Delete Account - LiveTok</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Inter', sans-serif;
            margin: 0;
            padding: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 600px;
            padding: 2rem;
            text-align: center;
            background: white;
            border-radius: 12px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            margin: 1rem;
        }
        .message {
            color: #333;
            font-size: 1.1rem;
            line-height: 1.6;
            margin-bottom: 2rem;
        }
        .btn {
            display: inline-block;
            background: #fe2c55;
            color: white;
            padding: 12px 32px;
            border-radius: 24px;
            text-decoration: none;
            font-weight: 600;
            font-size: 1.1rem;
            transition: background-color 0.3s;
            border: none;
            cursor: pointer;
        }
        .btn:hover {
            background: #e6254c;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="message">
            Click the button to enter the LiveTok and delete your account.
        </div>
        <a href="{{ $appLink }}" class="btn">Open the LiveTok</a>
    </div>

    <script>
        document.querySelector('.btn').addEventListener('click', function(e) {
            // Check if the app is installed using deep linking
            setTimeout(function() {
                // If timeout triggers, app is not installed, redirect to Play Store
                window.location.href = '{{ $playStoreLink }}';
            }, 2500); // 2.5 seconds timeout
        });
    </script>
</body>
</html> 