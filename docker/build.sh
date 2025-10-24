#!/bin/bash

# Build script for Cloud Security Demo Docker image

set -e

# Configuration
IMAGE_NAME="alloy-cloud-security-demo"
TAG="latest"
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPOSITORY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_NAME}"

echo "=== Building Cloud Security Demo Docker Image ==="
echo "Image Name: ${IMAGE_NAME}"
echo "Tag: ${TAG}"
echo "AWS Account ID: ${AWS_ACCOUNT_ID}"
echo "ECR Repository: ${ECR_REPOSITORY}"
echo ""

# Build the Docker image
echo "Building Docker image..."
docker build -t ${IMAGE_NAME}:${TAG} .

# Tag for ECR
echo "Tagging image for ECR..."
docker tag ${IMAGE_NAME}:${TAG} ${ECR_REPOSITORY}:${TAG}

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPOSITORY}

# Create ECR repository if it doesn't exist (public for take-home exercise)
echo "Creating ECR repository if it doesn't exist..."
aws ecr describe-repositories --repository-names ${IMAGE_NAME} --region ${AWS_REGION} 2>/dev/null || \
aws ecr create-repository --repository-name ${IMAGE_NAME} --region ${AWS_REGION} --image-scanning-configuration scanOnPush=true

# Make repository public for take-home exercise
echo "Making repository public..."
aws ecr set-repository-policy --repository-name ${IMAGE_NAME} --region ${AWS_REGION} --policy-text '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPublicPull",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ]
    }
  ]
}'

# Push to ECR
echo "Pushing image to ECR..."
docker push ${ECR_REPOSITORY}:${TAG}

echo ""
echo "=== Build Complete ==="
echo "Image URI: ${ECR_REPOSITORY}:${TAG}"
echo ""
echo "To use this image in Terraform, update your locals.tf:"
echo "container_image = \"${ECR_REPOSITORY}:${TAG}\""
