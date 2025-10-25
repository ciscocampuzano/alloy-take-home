# Terraform Outputs

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways"
  value       = module.vpc.natgw_ids
}

# ECS Outputs
output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs_cluster.id
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs_cluster.arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_cluster.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs_service.name
}

output "ecs_service_id" {
  description = "ID of the ECS service"
  value       = module.ecs_service.id
}

# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.alb.zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.arn
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${module.alb.dns_name}"
}

# S3 Outputs
output "s3_bucket_name" {
  description = "Name of the main S3 bucket"
  value       = module.s3_bucket.s3_bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the main S3 bucket"
  value       = module.s3_bucket.s3_bucket_arn
}

output "s3_bucket_domain_name" {
  description = "Domain name of the main S3 bucket"
  value       = module.s3_bucket.s3_bucket_bucket_domain_name
}

output "s3_bucket_regional_domain_name" {
  description = "Regional domain name of the main S3 bucket"
  value       = module.s3_bucket.s3_bucket_bucket_regional_domain_name
}

output "s3_access_logs_bucket_name" {
  description = "Name of the S3 access logs bucket"
  value       = module.s3_bucket_logs.s3_bucket_id
}

# IAM Outputs
output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_execution_role_name" {
  description = "Name of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.name
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "ecs_task_role_name" {
  description = "Name of the ECS task role"
  value       = aws_iam_role.ecs_task_role.name
}

# CloudWatch Outputs
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs.arn
}

# KMS Outputs
output "application_kms_key_id" {
  description = "ID of the KMS key for application encryption"
  value       = aws_kms_key.application.id
}

output "application_kms_key_arn" {
  description = "ARN of the KMS key for application encryption"
  value       = aws_kms_key.application.arn
}

# Security Group Outputs
output "security_group_ecs_tasks_id" {
  description = "ID of the ECS tasks security group"
  value       = module.ecs_tasks_sg.security_group_id
}

output "security_group_alb_id" {
  description = "ID of the ALB security group"
  value       = module.alb_sg.security_group_id
}

output "security_group_vpc_endpoints_id" {
  description = "ID of the VPC endpoints security group"
  value       = module.vpc_endpoints_sg.security_group_id
}

# VPC Endpoint Outputs
output "vpc_endpoint_s3_id" {
  description = "ID of the S3 VPC endpoint"
  value       = module.vpc_endpoints.endpoints["s3"].id
}

output "vpc_endpoint_ecr_dkr_id" {
  description = "ID of the ECR Docker VPC endpoint"
  value       = module.vpc_endpoints.endpoints["ecr_dkr"].id
}

output "vpc_endpoint_ecr_api_id" {
  description = "ID of the ECR API VPC endpoint"
  value       = module.vpc_endpoints.endpoints["ecr_api"].id
}
