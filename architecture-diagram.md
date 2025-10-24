# Architecture Diagram

This file contains the Mermaid diagram for the AWS infrastructure architecture.

```mermaid
graph TB
    subgraph "AWS Account"
        subgraph "VPC - 10.0.0.0/16"
            subgraph "Availability Zone 1a"
                PubSubnet1["Public Subnet<br/>10.0.10.0/24"]
                PrivSubnet1["Private Subnet<br/>10.0.1.0/24"]
                ALB["Application<br/>Load Balancer"]
                NAT1["NAT Gateway"]
                ECS1["ECS Fargate<br/>Task"]
                
                PubSubnet1 --> ALB
                PubSubnet1 --> NAT1
                PrivSubnet1 --> ECS1
            end
            
            subgraph "Availability Zone 1b"
                PubSubnet2["Public Subnet<br/>10.0.20.0/24"]
                PrivSubnet2["Private Subnet<br/>10.0.2.0/24"]
                NAT2["NAT Gateway"]
                ECS2["ECS Fargate<br/>Task"]
                
                PubSubnet2 --> NAT2
                PrivSubnet2 --> ECS2
            end
            
            IGW["Internet Gateway"]
            SG1["Security Group<br/>ECS Tasks"]
            SG2["Security Group<br/>ALB"]
            VPCE1["VPC Endpoint<br/>S3"]
            VPCE2["VPC Endpoint<br/>ECR"]
        end
        
        subgraph "AWS Services"
            S3Main["S3 Bucket<br/>Encrypted + Versioned"]
            S3Logs["S3 Access Logs<br/>Bucket"]
            S3Backup["S3 Backup<br/>Bucket"]
            CWLogs["CloudWatch<br/>Logs"]
            ECR["ECR Public<br/>aws-cli:2.31.21"]
            IAM["IAM Roles<br/>Task + Execution"]
        end
    end
    
    Internet["Internet"] --> IGW
    IGW --> ALB
    ALB --> ECS1
    ALB --> ECS2
    ECS1 -.->|via NAT| NAT1
    ECS2 -.->|via NAT| NAT2
    NAT1 --> IGW
    NAT2 --> IGW
    
    ECS1 -.->|VPC Endpoint| VPCE1
    ECS2 -.->|VPC Endpoint| VPCE1
    ECS1 -.->|VPC Endpoint| VPCE2
    ECS2 -.->|VPC Endpoint| VPCE2
    
    VPCE1 -.->|Private Link| S3Main
    VPCE2 -.->|Private Link| ECR
    
    ECS1 --> CWLogs
    ECS2 --> CWLogs
    S3Main --> S3Logs
    S3Main -.->|Replication| S3Backup
    
    IAM -.->|Permissions| ECS1
    IAM -.->|Permissions| ECS2
    
    classDef awsService fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#fff
    classDef network fill:#147EBA,stroke:#232F3E,stroke-width:2px,color:#fff
    classDef compute fill:#ED7100,stroke:#232F3E,stroke-width:2px,color:#fff
    classDef security fill:#DD344C,stroke:#232F3E,stroke-width:2px,color:#fff
    
    class S3Main,S3Logs,S3Backup,CWLogs,ECR awsService
    class PubSubnet1,PubSubnet2,PrivSubnet1,PrivSubnet2,IGW,NAT1,NAT2,VPCE1,VPCE2 network
    class ECS1,ECS2,ALB compute
    class SG1,SG2,IAM security
```

## Viewing the Diagram

This Mermaid diagram will render on GitHub and other Markdown viewers that support Mermaid syntax. 

For the best viewing experience:
- View on GitHub (native Mermaid support)
- Use the Mermaid Live Editor: https://mermaid.live/
- Use VS Code with the Mermaid extension

