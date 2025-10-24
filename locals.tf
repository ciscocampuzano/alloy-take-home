# Local values for infrastructure configuration
# This approach is ideal for monorepo structures where configuration is version-controlled

locals {
  # Project configuration
  aws_region   = "us-east-1"
  environment  = "dev"
  project_name = "take-home"

  # Resource naming convention: alloy-{environment}-{project-name}
  resource_prefix = join("-", ["alloy", local.environment, local.project_name])

  # VPC configuration
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnet_cidrs  = ["10.0.10.0/24", "10.0.20.0/24"]

  # Container configuration
  container_image  = "544668197233.dkr.ecr.us-east-1.amazonaws.com/alloy-cloud-security-demo:latest"
  container_port   = 80
  container_cpu    = 256
  container_memory = 512
  desired_count    = 1

  # Common tags
  common_tags = {
    Project     = "alloy-cloud-security"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

