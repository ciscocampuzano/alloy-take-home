# S3 Bucket with Comprehensive Security Configurations
# Source: https://github.com/terraform-aws-modules/terraform-aws-s3-bucket

# Random string for unique bucket name
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Main S3 Bucket
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.8.2"

  bucket = "${local.resource_prefix}-${random_string.bucket_suffix.result}"

  # Block all public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Versioning
  versioning = {
    enabled = true
  }

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
      bucket_key_enabled = true
    }
  }

  # Lifecycle rules
  lifecycle_rule = [
    {
      id                                     = "delete_incomplete_multipart_uploads"
      enabled                                = true
      abort_incomplete_multipart_upload_days = 7
    },
    {
      id      = "transition_to_ia"
      enabled = true
      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        },
        {
          days          = 365
          storage_class = "DEEP_ARCHIVE"
        }
      ]
    },
    {
      id      = "delete_old_versions"
      enabled = true
      noncurrent_version_transition = [
        {
          noncurrent_days = 30
          storage_class   = "STANDARD_IA"
        },
        {
          noncurrent_days = 90
          storage_class   = "GLACIER"
        }
      ]
      noncurrent_version_expiration = {
        noncurrent_days = 365
      }
    }
  ]

  # Access logging
  logging = {
    target_bucket = module.s3_bucket_logs.s3_bucket_id
    target_prefix = "access-logs/"
  }

  # CORS configuration
  cors_rule = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
      allowed_origins = ["https://${local.resource_prefix}.com"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]

  # Bucket policy
  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureConnections"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "arn:aws:s3:::${local.resource_prefix}-${random_string.bucket_suffix.result}",
          "arn:aws:s3:::${local.resource_prefix}-${random_string.bucket_suffix.result}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "AllowVPCAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ecs_task_role.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${local.resource_prefix}-${random_string.bucket_suffix.result}",
          "arn:aws:s3:::${local.resource_prefix}-${random_string.bucket_suffix.result}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:SourceVpc" = module.vpc.vpc_id
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${local.resource_prefix}-bucket"
    Environment = local.environment
  }
}

# S3 Bucket for Access Logs
module "s3_bucket_logs" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.0"

  bucket = "${local.resource_prefix}-access-logs-${random_string.bucket_suffix.result}"

  # Block all public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
      bucket_key_enabled = true
    }
  }

  # Allow S3 to write logs
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  tags = {
    Name        = "${local.resource_prefix}-access-logs"
    Environment = local.environment
  }
}

# Upload HTML file to S3
resource "aws_s3_object" "index_html" {
  bucket = module.s3_bucket.s3_bucket_id
  key    = "index.html"
  source = "${path.module}/index.html"

  content_type = "text/html"

  tags = {
    Name        = "${local.resource_prefix}-index-html"
    Environment = local.environment
  }
}
