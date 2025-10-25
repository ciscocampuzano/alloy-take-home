# Data source for AWS account information
data "aws_caller_identity" "current" {}

# KMS Key for Application Encryption (CloudWatch Logs and S3)
resource "aws_kms_key" "application" {
  description             = "KMS key for application encryption (CloudWatch logs and S3 buckets)"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "${local.resource_prefix}-application-key"
    Environment = local.environment
  }
}

# KMS Key Policy for Application Services
resource "aws_kms_key_policy" "application" {
  key_id = aws_kms_key.application.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${local.aws_region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${local.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ecs/${local.resource_prefix}"
          }
        }
      },
      {
        Sid    = "Enable S3"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "Enable ECS Task Role"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ecs_task_role.arn
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}
