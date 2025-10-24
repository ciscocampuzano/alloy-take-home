# Docker Setup for Cloud Security Demo

This directory contains the Docker configuration for a custom container image that serves HTML content from S3 using nginx.

## Files

- `Dockerfile` - Container image using nginx:alpine with Python and boto3
- `startup.sh` - Startup script that fetches HTML from S3 and starts nginx
- `build.sh` - Build script that creates and pushes the image to ECR
- `.dockerignore` - Excludes unnecessary files from Docker build context

## Architecture

The container uses nginx:alpine as the base image with Python and boto3 added for S3 integration:

1. **Startup Process**: Fetches HTML content from S3 using boto3 and serves it via nginx
2. **Authentication**: Uses ECS task role for S3 access (no credentials required)
3. **Volume Mounts**: Requires ECS volume mounts for `/var/run`, `/var/cache/nginx`, and `/tmp/nginx-html`
4. **Environment Variables**:
   - `AWS_DEFAULT_REGION` - AWS region
   - `S3_BUCKET_NAME` - S3 bucket name

## Building and Deploying

### Prerequisites

- Docker installed
- AWS CLI configured with appropriate permissions
- ECR repository access

### Build and Push

```bash
cd docker
./build.sh
```

This will:
1. Build the Docker image
2. Tag it for ECR
3. Create ECR repository if it doesn't exist
4. Make the repository public (for take-home exercise)
5. Push the image to ECR

### Using in Terraform

The build script outputs the ECR image URI. Update `locals.tf`:

```hcl
container_image = "544668197233.dkr.ecr.us-east-1.amazonaws.com/alloy-cloud-security-demo:latest"
```

## Benefits

- **Clean Separation**: Docker handles application logic, Terraform handles infrastructure
- **Production Ready**: Proper nginx configuration and error handling
- **Maintainable**: Easy to update HTML content or add features
- **Secure**: Uses IAM roles for S3 access, no hardcoded credentials
- **Scalable**: Can be easily deployed to multiple environments

## Security Features

- **Least Privilege**: Container only has S3 read access via IAM role
- **VPC Isolation**: Runs in private subnets
- **Encrypted Storage**: S3 bucket uses AES-256 encryption
- **Secure Transport**: HTTPS enforced for S3 access
- **No Secrets**: Uses IAM roles instead of access keys

## Public Repository

**Note**: This ECR repository is made public for the take-home exercise, allowing anyone to pull the image without authentication. In production, you would typically keep repositories private and use proper access controls.
