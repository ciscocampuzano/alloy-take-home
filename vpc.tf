# VPC Module
# Source: https://github.com/terraform-aws-modules/terraform-aws-vpc
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.5.0"

  name = "${local.resource_prefix}-vpc"
  cidr = local.vpc_cidr

  azs             = local.availability_zones
  private_subnets = local.private_subnet_cidrs
  public_subnets  = local.public_subnet_cidrs

  # Enable NAT Gateway for private subnets
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  # Enable DNS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags
  tags = {
    Name        = "${local.resource_prefix}-vpc"
    Environment = local.environment
  }

  public_subnet_tags = {
    Name = "${local.resource_prefix}-public-subnet"
    Type = "Public"
  }

  private_subnet_tags = {
    Name = "${local.resource_prefix}-private-subnet"
    Type = "Private"
  }
}

# Security Group for ECS Tasks
module "ecs_tasks_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.resource_prefix}-ecs-tasks"
  description = "Security group for ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = local.container_port
      to_port                  = local.container_port
      protocol                 = "tcp"
      description              = "Allow inbound traffic from ALB"
      source_security_group_id = module.alb_sg.security_group_id
    }
  ]

  egress_rules = ["all-all"]

  tags = {
    Name = "${local.resource_prefix}-ecs-tasks-sg"
  }
}

# Security Group for ALB
module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.resource_prefix}-alb"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Allow HTTP traffic"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Allow HTTPS traffic"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_rules = ["all-all"]

  tags = {
    Name = "${local.resource_prefix}-alb-sg"
  }
}

# Security Group for VPC Endpoints
module "vpc_endpoints_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.resource_prefix}-vpc-endpoints"
  description = "Security group for VPC endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Allow HTTPS traffic from VPC"
      cidr_blocks = local.vpc_cidr
    }
  ]

  egress_rules = ["all-all"]

  tags = {
    Name = "${local.resource_prefix}-vpc-endpoints-sg"
  }
}

# VPC Endpoints for ECR
module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.0"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.vpc_endpoints_sg.security_group_id]

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags            = { Name = "${local.resource_prefix}-s3-endpoint" }
    }
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "${local.resource_prefix}-ecr-dkr-endpoint" }
    }
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "${local.resource_prefix}-ecr-api-endpoint" }
    }
  }

  tags = {
    Environment = local.environment
  }
}
