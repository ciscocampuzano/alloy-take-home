# Use nginx as base image
FROM nginx:alpine

# Install Python and dependencies
RUN apk add --no-cache \
    python3 \
    py3-pip \
    py3-boto3 \
    bash

# Create app directory
RUN mkdir -p /app

# Copy startup script
COPY startup.sh /app/startup.sh
RUN chmod +x /app/startup.sh

# Use default nginx.conf (we'll mount /var/run as writable)

# Create nginx config that serves from /tmp/nginx-html
RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    location / { \
        root /tmp/nginx-html; \
        index index.html; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

# Set working directory
WORKDIR /app

# Expose port 80
EXPOSE 80

# Start script that fetches HTML from S3 and starts nginx
CMD ["/app/startup.sh"]
