# Rationale for Alloy Cloud Security Assessment

## Summary

The proposed architecture is designed to demonstrate secure, containerized access to a data store using AWS services. Specifically, an AWS ECS Fargate Task is configured to pull a Docker image, which then securely loads an index.html file from AWS S3 and publishes it via a simple web server. The publicly accessible endpoint will be provided in the Terraform outputs upon successful deployment.

To ensure the exercise is fully self-contained, the S3 object (the index.html file) is uploaded as an integral part of the Terraform deployment process.

Future Improvements: In a real-world scenario, the immediate next step would be to implement HTTPS for the Load Balancer using Route53 and AWS Certificate Manager (ACM). This was omitted here only because it requires a live domain, which adds external dependency and complexity to the exercise.

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

## Choice of Compute and Data Store

I chose serverless options for both the compute (ECS Fargate) and the data store (S3) to best showcase how security features are managed, defined, and enforced via Terraform.

While an EC2 instance could be used for compute,  that would introduce additional complexity around host level security. In an EC2 deployment, we would also need to account for: using encrypted and hardened AMIs, managing patching, configuring host firewalls, and utilizing a Configuration Management tool (like Ansible or Chef) to deploy a security baseline and essential agents, such as a Secure Access Service Edge (SASE).

The data store uses S3 to host a static index.html. This choice allows me to focus the Terraform security configuration on S3’s native settings. While an RDS database was a possible alternative, the deployment time (often 20+ minutes for Multi-AZ) would be too long.

## Terraform Architecture

The code is organized with a dedicated file for each AWS service, which facilitates navigation and managementof the  resources. I utilize locals.tf to manage  values, it streamlines multi-account management in a mono-repo structure and simplifies integration into CI/CD pipelines. This setup can easily be converted to use variables.tf if a different patterns is required.

For operational efficiency, I implemented a simple tagging strategy across all resources for cost tracking via AWS Cost Center and compliance auditing using AWS Config. A consistent naming convention is also applied to help automation across CI/CD tasks.

To keep the repository clean and avoid boilerplate, I used established and community-maintained Terraform modules from terraform-aws-modules for complex resources, adhering to the DRY (Don’t Repeat Yourself) principle. In a production setting, I would typically write custom modules tailored to company policy and specific environmental standards.

Finally, while I would normally use an S3 hosted backend for state management (unless HashiCorp Cloud Platform is available), I have used a local backend for this exercise, as provisioning a remote backend within the same stack creates a "chicken and egg"  situation.

Note: In order to implement policy as code and some basic security checks, I am using a github workflows to run scans: Checkov, semgrep.

## Resources

### VPC

I provisioned a new VPC because we cannot assume an existing one is available. The network architecture adheres to the AWS Well-Architected Framework:

Isolation: Private and public subnets are provisioned to isolate resources.

Outbound Access: A NAT Gateway allows outbound internet access from the private subnets.

High Availability (HA): Subnets are distributed across multiple Availability Zones.

Data Traffic Control: A VPC Endpoint for S3 ensures traffic remains entirely within the AWS network, improving security and reducing egress costs.

Firewall: Security Groups are strictly defined to enforce the Principle of Least Privilege access.

### IAM

To ensure our compute resources adhere to the Principle of Least Privilege, I provisioned specific IAM Roles with carefully scoped policies. These policies narrow down the permissible actions and resources to only what is strictly necessary for the application to function.

### S3

Although called  Simple Storage Service, S3 is an excellent service for demonstrating advanced security settings, as its security model is often overlooked. I implemented tight security controls on the bucket:

Access Control: Public access is blocked entirely at the bucket level.

Auditability: A separate bucket is provisioned for access logs, which is vital for audit trails.

Origin Validation: Cross-Origin Resource Sharing (CORS) is configured to ensure only our provisioned compute resource can access the files.

Cost Management: Lifecycle policies are implemented to control data retention and reduce cost over time.

Network Security: A strict Bucket Policy prevents insecure connections and specifically permits connections only from the S3 VPC Endpoint within our network.

### ECS Fargate

I chose ECS Fargate because it offers a straightforward and reliable way to run the compute workload while providing security advantages inherent in its design: lighter-weight isolation, faster deployment, and shorter lifespans all reduce the attack surface. I have set specific port mappings and ensured read-only filesystems are used where possible. For monitoring and auditability, a dedicated CloudWatch log group is configured.
There is also an Application Load Balancer used to front the workload and give us HA.

### KMS

We are using KMS for S3 and Logs encryption. AWS managed keys don't allow sharing cross account, so we are using Customer Managed Keys (CMK) in case the data store needs to be backed up to a different account for Disaster Recovery. 
