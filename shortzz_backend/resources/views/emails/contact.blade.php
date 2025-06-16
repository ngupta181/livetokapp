<!DOCTYPE html>
<html>
<head>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }
        .header {
            background: linear-gradient(90deg, #fe2c55, #25F4EE);
            color: white;
            padding: 20px;
            text-align: center;
            border-radius: 5px 5px 0 0;
        }
        .content {
            background: #f9f9f9;
            padding: 20px;
            border-radius: 0 0 5px 5px;
        }
        .field {
            margin-bottom: 15px;
        }
        .label {
            font-weight: bold;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>New Contact Form Submission</h1>
        </div>
        <div class="content">
            <div class="field">
                <p class="label">Name:</p>
                <p>{{ $name }}</p>
            </div>
            <div class="field">
                <p class="label">Email:</p>
                <p>{{ $email }}</p>
            </div>
            <div class="field">
                <p class="label">Subject:</p>
                <p>{{ $subject }}</p>
            </div>
            <div class="field">
                <p class="label">Message:</p>
                <p>{{ $messageContent }}</p>
            </div>
        </div>
    </div>
</body>
</html> 