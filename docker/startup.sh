#!/bin/bash

echo "=== Cloud Security Demo - Starting ==="
echo "Region: $AWS_DEFAULT_REGION"
echo "Bucket: $S3_BUCKET_NAME"

# Function to fetch HTML from S3 using boto3
fetch_html_from_s3() {
    echo "Fetching HTML from S3 using boto3..."
    
    # Use Python with boto3 to fetch the HTML file
    python3 -c "
import boto3
import os

try:
    # Create S3 client (will use ECS task role automatically)
    s3 = boto3.client('s3', region_name='$AWS_DEFAULT_REGION')
    
    # Fetch HTML from S3
    response = s3.get_object(Bucket='$S3_BUCKET_NAME', Key='index.html')
    html_content = response['Body'].read().decode('utf-8')
    
    # Create nginx html directory and write file
    import os
    os.makedirs('/tmp/nginx-html', exist_ok=True)
    with open('/tmp/nginx-html/index.html', 'w') as f:
        f.write(html_content)
    
    print('✓ Successfully fetched HTML from S3')
    exit(0)
    
except Exception as e:
    print(f'⚠ Failed to fetch HTML from S3: {str(e)}')
    exit(1)
"
    
    if [ $? -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Function to create fallback HTML
create_fallback_html() {
    echo "Creating fallback HTML..."
    mkdir -p /tmp/nginx-html
    cat > /tmp/nginx-html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cloud Security Demo - Fallback</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0;
            padding: 20px;
        }
        .container {
            background: #fff;
            border-radius: 12px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            max-width: 600px;
            width: 100%;
            padding: 40px;
            text-align: center;
        }
        h1 { color: #2d3748; margin-bottom: 20px; }
        .status {
            background: #fed7d7;
            border-left: 4px solid #f56565;
            padding: 18px;
            border-radius: 8px;
            margin: 20px 0;
        }
        .status-title {
            font-size: 18px;
            font-weight: 600;
            color: #f56565;
            margin: 0 0 8px;
        }
        .status-msg {
            color: #4a5568;
            font-size: 14px;
            margin: 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🛡️ Cloud Security Demo</h1>
        <div class="status">
            <div class="status-title">⚠ Fallback Mode</div>
            <div class="status-msg">Using fallback HTML. S3 access may be unavailable.</div>
        </div>
        <p>This is a fallback page served when S3 access fails.</p>
        <p><strong>Bucket:</strong> $S3_BUCKET_NAME</p>
        <p><strong>Region:</strong> $AWS_DEFAULT_REGION</p>
    </div>
</body>
</html>
EOF
}

# Try to fetch HTML from S3, fallback if it fails
if ! fetch_html_from_s3; then
    create_fallback_html
fi

# Verify the HTML file exists
if [ -f "/tmp/nginx-html/index.html" ]; then
    echo "✓ HTML file created successfully"
    ls -la /tmp/nginx-html/
else
    echo "✗ HTML file not found, creating emergency fallback"
    mkdir -p /tmp/nginx-html
    echo "<html><body><h1>Emergency Fallback</h1><p>Container is running but HTML file is missing.</p></body></html>" > /tmp/nginx-html/index.html
fi

# Start nginx in the foreground
echo "Starting nginx..."
exec nginx -g "daemon off;"
