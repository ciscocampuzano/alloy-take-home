# Alloy Cloud Security Take-Home: AWS Infrastructure with Terraform

## Overview

This repository contains Terraform infrastructure code for a secure AWS environment designed to demonstrate cloud security best practices. The infrastructure uses well-established **[terraform-aws-modules](https://github.com/terraform-aws-modules)** community modules for better maintainability, security, and adherence to AWS best practices. The infrastructure includes ECS Fargate compute resources and S3 storage with comprehensive security configurations.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Account                              │
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐                   │
│  │   Public Subnet │    │   Public Subnet │                   │
│  │   (AZ-1a)       │    │   (AZ-1b)       │                   │
│  │                 │    │                 │                   │
│  │ ┌─────────────┐ │    │ ┌─────────────┐ │                   │
│  │ │     ALB     │ │    │ │ NAT Gateway │ │                   │
│  │ └─────────────┘ │    │ └─────────────┘ │                   │
│  └─────────────────┘    └─────────────────┘                   │
│           │                       │                           │
│           │                       │                           │
│  ┌─────────────────┐    ┌─────────────────┐                   │
│  │  Private Subnet  │    │  Private Subnet │                   │
│  │   (AZ-1a)       │    │   (AZ-1b)       │                   │
│  │                 │    │                 │                   │
│  │ ┌─────────────┐ │    │ ┌─────────────┐ │                   │
│  │ │ ECS Service │ │    │ │ ECS Service │ │                   │
│  │ │ (Fargate)   │ │    │ │ (Fargate)   │ │                   │
│  │ └─────────────┘ │    │ └─────────────┘ │                   │
│  └─────────────────┘    └─────────────────┘                   │
│           │                       │                           │
│           └───────────┬───────────┘                           │
│                       │                                       │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                    AWS Services                         │ │
│  │                                                         │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │ │
│  │  │     S3      │  │ CloudWatch  │  │    ECR      │      │ │
│  │  │   Bucket    │  │    Logs     │  │  (Images)   │      │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

> **Note**: For a detailed interactive architecture diagram, see [architecture-diagram.md](architecture-diagram.md)

## Security Features

### Network Security
- **VPC Isolation**: Custom VPC with private and public subnets
- **Private Subnets**: ECS tasks run in private subnets with no direct internet access
- **NAT Gateway**: Secure outbound internet access for private resources
- **Security Groups**: Restrictive firewall rules with least privilege access
- **VPC Endpoints**: Private connectivity to AWS services (S3, ECR) without internet routing

### Compute Security
- **ECS Fargate**: Serverless containers with no EC2 management overhead
- **Secure Base Image**: Uses AWS-maintained container images (`public.ecr.aws/aws-cli/aws-cli:2.31.21`)
- **Container Health Checks**: Built-in health check that verifies S3 bucket access
- **IAM Roles**: Separate execution and task roles with minimal permissions
- **CloudWatch Logs**: Centralized logging with retention policies

### Data Security
- **S3 Encryption**: Server-side encryption with AES-256
- **S3 Versioning**: Object versioning enabled for data protection
- **S3 Access Logging**: Comprehensive access logging to separate bucket
- **S3 Public Access Block**: Complete blocking of public access
- **S3 Bucket Policy**: Restrictive policies requiring HTTPS and VPC access
- **S3 Lifecycle Policies**: Automated data lifecycle management
- **S3 Replication**: Cross-region backup for disaster recovery

### Identity and Access Management
- **Least Privilege**: IAM policies with specific resource and action permissions
- **Role Separation**: Distinct roles for ECS execution vs. application runtime
- **No Wildcards**: Avoided wildcard permissions in IAM policies
- **Resource-based Policies**: S3 bucket policies restrict access to VPC resources

## File Structure

```
├── main.tf                   # Provider configuration and main orchestration
├── locals.tf                 # Local values for all configuration (monorepo-friendly)
├── vpc.tf                    # VPC module with security groups and VPC endpoints
├── iam.tf                    # IAM modules for roles and policies
├── s3.tf                     # S3 bucket modules with comprehensive security
├── ecs.tf                    # ECS and ALB modules with container definitions
├── outputs.tf                # Resource outputs and identifiers
├── startup.sh                # Reference script showing HTML generation (for documentation)
├── .gitignore                # Git ignore file
├── README.md                 # This documentation
├── architecture-diagram.md   # Detailed Mermaid architecture diagram
├── HEALTHCHECK.md            # Detailed health check documentation
├── MODULES.md                # Terraform modules migration documentation
├── RESOURCE_NAMING.md        # Resource naming convention documentation
└── MODULE_UPDATES.md         # Module version updates documentation
```

## Terraform Modules Used

This infrastructure leverages community-maintained Terraform modules for production-grade AWS resources:

- **[terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc)** (~> 5.0) - VPC, subnets, NAT gateways, and VPC endpoints
- **[terraform-aws-security-group](https://github.com/terraform-aws-modules/terraform-aws-security-group)** (~> 5.0) - Security groups with best practices
- **[terraform-aws-s3-bucket](https://github.com/terraform-aws-modules/terraform-aws-s3-bucket)** (~> 5.0) - S3 buckets with comprehensive security features
- **[terraform-aws-iam](https://github.com/terraform-aws-modules/terraform-aws-iam)** (~> 5.0) - IAM roles and policies
- **[terraform-aws-ecs](https://github.com/terraform-aws-modules/terraform-aws-ecs)** (~> 6.0) - ECS cluster and services
- **[terraform-aws-alb](https://github.com/terraform-aws-modules/terraform-aws-alb)** (~> 9.0) - Application Load Balancer

**AWS Provider**: ~> 6.0 (using latest features and security patches)

> 📝 See [MODULE_UPDATES.md](MODULE_UPDATES.md) for detailed information about module version updates and compatibility.

### Benefits of Using Community Modules
- ✅ **Battle-tested**: Used by thousands of organizations worldwide
- ✅ **Best Practices**: Incorporates AWS Well-Architected Framework principles
- ✅ **Maintained**: Regular updates and security patches
- ✅ **Comprehensive**: Extensive configuration options
- ✅ **Documented**: Well-documented with examples
- ✅ **Reduced Code**: Less custom code to maintain

## Configuration Approach

This infrastructure uses **`locals.tf`** instead of `variables.tf` for a monorepo-friendly approach:

### Why Locals Instead of Variables?
- ✅ **Monorepo Compatible**: Configuration is version-controlled and environment-specific
- ✅ **Simpler Deployment**: No need for `terraform.tfvars` files
- ✅ **Single Source of Truth**: All configuration in one place
- ✅ **Easy Duplication**: Copy directory for new environments
- ✅ **No Variable Passing**: Direct access to configuration values

### Configuration Structure
All infrastructure configuration is defined in `locals.tf`:
- Project settings (name, environment, region)
- Network configuration (VPC CIDR, subnets, AZs)
- Container settings (image, CPU, memory, port)
- Common tags applied to all resources
- **Resource naming convention**: All AWS resources follow the pattern `alloy-{environment}-{project-name}`

### Resource Naming Convention
A standardized naming convention is implemented using `local.resource_prefix`:
```hcl
resource_prefix = join("-", ["alloy", local.environment, local.project_name])
# Example: "alloy-dev-take-home"
```

This ensures:
- ✅ **Consistency**: All resources follow the same naming pattern
- ✅ **Environment Clarity**: Environment is clearly identified in resource names
- ✅ **Organization**: Resources are easily identifiable and searchable
- ✅ **No Conflicts**: Different environments don't clash with resource names

**Examples of resource names**:
- VPC: `alloy-dev-take-home-vpc`
- ECS Cluster: `alloy-dev-take-home-cluster`
- S3 Bucket: `alloy-dev-take-home-{random-suffix}`
- IAM Role: `alloy-dev-take-home-ecs-task-role`

To create a new environment, simply duplicate the directory and modify `locals.tf`.

## Key Security Decisions

### 1. ECS Fargate over EC2
**Decision**: Use ECS Fargate instead of EC2 instances
**Rationale**: 
- Eliminates OS patching and security maintenance
- Reduces attack surface by removing EC2 management
- Automatic scaling and resource management
- AWS handles underlying infrastructure security

### 2. S3 as Primary Data Store
**Decision**: Use S3 instead of DynamoDB or RDS
**Rationale**:
- Serverless with automatic scaling
- Rich security features (encryption, versioning, access logging)
- Cost-effective for various data types
- Demonstrates comprehensive S3 security configurations

### 3. VPC Endpoints
**Decision**: Implement VPC endpoints for AWS services
**Rationale**:
- Eliminates internet routing for AWS service calls
- Reduces data transfer costs
- Improves security by keeping traffic within AWS network
- Enables private connectivity to S3 and ECR

### 4. Comprehensive S3 Security
**Decision**: Implement multiple S3 security layers
**Rationale**:
- Encryption at rest with AES-256
- Versioning for data protection and recovery
- Access logging for audit trails
- Lifecycle policies for cost optimization
- Bucket policies restricting access to VPC resources

### 5. Container Health Checks with S3 Access Verification
**Decision**: Use AWS CLI official image with inline health check script
**Rationale**:
- No custom image building required - uses official AWS CLI image directly
- Health check tests S3 bucket permissions at startup
- Generates dynamic HTML showing S3 access status
- Uses Python's built-in HTTP server (lightweight, no additional dependencies)
- Provides real-time verification of IAM role permissions
- Demonstrates security validation in production workloads

## Container Implementation

The infrastructure uses the official AWS CLI image (`public.ecr.aws/aws-cli/aws-cli:2.31.21`) with no custom building required:

### How It Works
1. Container starts with the AWS CLI image
2. Inline startup command tests S3 bucket access using `aws s3 ls`
3. Generates HTML page dynamically based on test results
4. Starts Python's built-in HTTP server on port 8080
5. Serves beautiful HTML page showing S3 access status

### Health Check Endpoint
- **Port**: 8080 (configurable)
- **Main Endpoint**: `http://<alb-dns>/` - Beautiful HTML dashboard
- **Health Endpoint**: `http://<alb-dns>/health` - Simple "OK" response
- **Check Interval**: Every 30 seconds via ECS health checks
- **Functionality**: Tests S3 bucket access and displays results

### Container Features
- ✅ **No Custom Image**: Uses official AWS CLI image directly
- ✅ **Dynamic HTML**: Generates page based on S3 access test
- ✅ **Lightweight Server**: Python built-in HTTP server
- ✅ **Security Validation**: Verifies IAM permissions in real-time
- ✅ **Visual Dashboard**: Shows all security features implemented
- ✅ **Detailed Logging**: All checks logged to CloudWatch

## Deployment Instructions

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- Appropriate AWS permissions for resource creation

### Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd alloy-take-home
   ```

2. **(Optional) Customize configuration**
   ```bash
   # Edit locals.tf to change any configuration values
   # All settings are in one file for easy management
   vim locals.tf
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Review the plan**
   ```bash
   terraform plan
   ```

5. **Deploy the infrastructure**
   ```bash
   terraform apply
   ```

6. **Access the application**
   ```bash
   # Get the ALB DNS name from outputs
   terraform output application_url
   ```

### For Multiple Environments

To deploy multiple environments (dev, staging, prod):

```bash
# Create environment directories
mkdir -p environments/{dev,staging,prod}

# Copy Terraform files to each environment
for env in dev staging prod; do
  cp *.tf environments/$env/
  # Modify locals.tf in each environment directory
  sed -i '' "s/environment  = \"dev\"/environment  = \"$env\"/" environments/$env/locals.tf
done

# Deploy each environment
cd environments/dev && terraform init && terraform apply
cd ../staging && terraform init && terraform apply
cd ../prod && terraform init && terraform apply
```

### Cleanup
```bash
terraform destroy
```

## Security Considerations

### Network Security
- All ECS tasks run in private subnets with no direct internet access
- Security groups implement restrictive firewall rules
- VPC endpoints provide private connectivity to AWS services
- NAT Gateway enables secure outbound internet access

### Data Protection
- S3 buckets use server-side encryption with AES-256
- Object versioning protects against accidental deletion
- Access logging provides comprehensive audit trails
- Cross-region replication ensures disaster recovery

### Access Control
- IAM roles follow least privilege principles
- S3 bucket policies restrict access to VPC resources
- No wildcard permissions in IAM policies
- Separate roles for different functions (execution vs. runtime)

### Monitoring and Logging
- CloudWatch Logs for centralized container logging
- S3 access logging for audit trails
- ALB access logs for application monitoring
- Comprehensive tagging for resource management

## Future Improvements

### Security Enhancements
- Implement AWS WAF for application-level protection
- Add AWS Config for compliance monitoring
- Implement AWS CloudTrail for API call logging
- Add AWS GuardDuty for threat detection

### Operational Improvements
- Implement CI/CD pipeline with GitHub Actions
- Add monitoring and alerting with CloudWatch alarms
- Implement blue-green deployments
- Add multi-region deployment for high availability

### Cost Optimization
- Implement S3 Intelligent Tiering
- Add ECS Spot instances for cost savings
- Implement auto-scaling based on custom metrics
- Add cost allocation tags and budgets

## Compliance and Standards

This infrastructure follows several security standards and best practices:

- **AWS Well-Architected Framework**: Security, Reliability, Performance, Cost Optimization
- **CIS AWS Foundations Benchmark**: Security configuration guidelines
- **NIST Cybersecurity Framework**: Identify, Protect, Detect, Respond, Recover
- **SOC 2 Type II**: Security, availability, processing integrity, confidentiality, privacy

## Troubleshooting

### Common Issues

1. **VPC Endpoint Connection Issues**
   - Ensure security groups allow HTTPS traffic (port 443)
   - Verify VPC endpoint is in the correct subnets
   - Check DNS resolution in private subnets

2. **ECS Task Startup Issues**
   - Verify IAM roles have correct permissions
   - Check CloudWatch logs for container errors
   - Ensure security groups allow necessary traffic

3. **S3 Access Issues**
   - Verify bucket policy allows VPC access
   - Check IAM role permissions
   - Ensure HTTPS is enforced in bucket policy

### Support

For questions or issues with this infrastructure, please refer to:
- AWS documentation for specific services
- Terraform documentation for infrastructure management
- CloudWatch logs for application debugging

## License

This project is created for the Alloy Cloud Security take-home assessment.
