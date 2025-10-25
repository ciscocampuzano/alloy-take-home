# Container Health Check Documentation

## Overview

The custom container includes a health check mechanism that verifies S3 bucket access in real-time. This demonstrates proper security validation and IAM role verification in production workloads.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      ECS Task                               │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Container (AWS CLI Image)                           │  │
│  │                                                      │  │
│  │  ┌────────────────────────────────────────────────┐ │  │
│  │  │  entrypoint.sh                                 │ │  │
│  │  │  - Starts HTTP server on port 8080            │ │  │
│  │  │  - Tests S3 access on startup                 │ │  │
│  │  │  - Serves health check endpoint               │ │  │
│  │  └────────────────────────────────────────────────┘ │  │
│  │                                                      │  │
│  │  ┌────────────────────────────────────────────────┐ │  │
│  │  │  healthcheck.sh                                │ │  │
│  │  │  - Runs every 30 seconds                       │ │  │
│  │  │  - Executes: aws s3 ls s3://bucket-name        │ │  │
│  │  │  - Returns 0 (success) or 1 (failure)         │ │  │
│  │  └────────────────────────────────────────────────┘ │  │
│  │                                                      │  │
│  │  Task IAM Role → S3 Bucket Permissions             │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ECS Health Check monitors exit codes                      │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. entrypoint.sh
The main container entrypoint that:
- Prints startup information (region, bucket name, port)
- Tests S3 access on container startup
- Starts a lightweight HTTP server using netcat
- Serves JSON responses with S3 access status
- Runs continuously to handle health check requests

### 2. healthcheck.sh
The health check script that:
- Runs periodically (every 30 seconds)
- Executes AWS CLI command: `aws s3 ls s3://<bucket-name>`
- Returns exit code 0 on success, 1 on failure
- Used by ECS container health checks

### 3. Dockerfile
Builds a custom image that:
- Uses AWS CLI official image as base (2.31.21)
- Installs netcat for lightweight HTTP server
- Copies health check and entrypoint scripts
- Makes scripts executable
- Exposes port 8080 for health checks

## Health Check Configuration

### ECS Task Definition Settings
```json
{
  "healthCheck": {
    "command": ["CMD-SHELL", "/usr/local/bin/healthcheck.sh"],
    "interval": 30,
    "timeout": 5,
    "retries": 3,
    "startPeriod": 60
  }
}
```

**Parameters:**
- **interval**: 30 seconds between health checks
- **timeout**: 5 seconds max for each check
- **retries**: 3 consecutive failures before marking unhealthy
- **startPeriod**: 60 seconds grace period at startup

### ALB Target Group Settings
```hcl
health_check {
  enabled             = true
  healthy_threshold   = 2
  interval            = 30
  matcher             = "200"
  path                = "/health"
  port                = "traffic-port"
  protocol            = "HTTP"
  timeout             = 5
  unhealthy_threshold = 2
}
```

## Health Check Flow

### Startup Sequence
1. Container starts with `entrypoint.sh`
2. Script prints environment information
3. Initial S3 access test runs
4. HTTP server starts on port 8080
5. Container reports ready to ECS
6. Health checks begin after 60-second grace period

### Health Check Execution
1. ECS runs `healthcheck.sh` every 30 seconds
2. Script executes `aws s3 ls s3://<bucket-name>`
3. AWS SDK uses IAM task role credentials automatically
4. Script returns exit code (0=success, 1=failure)
5. ECS monitors exit codes
6. ALB separately checks HTTP endpoint

### Response Format
```json
{
  "status": "healthy",
  "message": "SUCCESS: S3 bucket <bucket-name> is accessible",
  "bucket": "<bucket-name>",
  "region": "us-east-1"
}
```

**Success Response (HTTP 200):**
- Status: "healthy"
- Message: Confirmation of S3 access
- Includes bucket name and region

**Failure Response (HTTP 503):**
- Status: "unhealthy"
- Message: Unable to access S3 bucket
- Indicates permission or connectivity issues

## Security Considerations

### IAM Permissions Required
The ECS task role must have:
```json
{
  "Effect": "Allow",
  "Action": [
    "s3:ListBucket"
  ],
  "Resource": "arn:aws:s3:::<bucket-name>"
}
```

### Why This Approach?
1. **Least Privilege**: Only requires `ListBucket` permission
2. **Non-Destructive**: Doesn't modify any data
3. **Lightweight**: Minimal CPU and memory overhead
4. **Real-time Validation**: Verifies permissions continuously
5. **Production Ready**: Suitable for actual workloads

### Security Benefits
- Detects IAM role misconfigurations quickly
- Validates VPC endpoint connectivity to S3
- Confirms security group rules allow AWS API calls
- Provides audit trail in CloudWatch Logs

## Testing the Health Check

### Local Testing (Docker)
```bash
# Build the image
docker build -t health-check-test .

# Run with AWS credentials
docker run -e AWS_ACCESS_KEY_ID=xxx \
           -e AWS_SECRET_ACCESS_KEY=yyy \
           -e AWS_DEFAULT_REGION=us-east-1 \
           -e S3_BUCKET_NAME=your-bucket-name \
           -p 8080:8080 \
           health-check-test

# Test the endpoint
curl http://localhost:8080/health
```

### In ECS
```bash
# View container logs
aws logs tail /aws/ecs/alloy-cloud-security --follow

# Check task health status
aws ecs describe-tasks \
  --cluster alloy-cloud-security-cluster \
  --tasks <task-id> \
  --query 'tasks[0].healthStatus'

# Check container health
aws ecs describe-tasks \
  --cluster alloy-cloud-security-cluster \
  --tasks <task-id> \
  --query 'tasks[0].containers[0].healthStatus'
```

## Troubleshooting

### Health Check Failures

**Issue**: Health check always fails
**Causes**:
- IAM role missing S3 permissions
- Bucket doesn't exist
- VPC endpoint misconfigured
- Security group blocking AWS API calls

**Solution**:
1. Check CloudWatch Logs for error messages
2. Verify IAM role has `s3:ListBucket` permission
3. Confirm bucket exists in specified region
4. Test VPC endpoint connectivity

**Issue**: Container starts but fails immediately
**Causes**:
- Scripts not executable
- Netcat not installed
- Environment variables missing

**Solution**:
1. Verify Dockerfile builds correctly
2. Check file permissions in image
3. Confirm all environment variables are set

## Monitoring

### CloudWatch Logs
The container logs include:
- Startup information and configuration
- Initial S3 access test results
- Health check request/response logs
- Error messages for failed checks

### CloudWatch Metrics
Monitor:
- `HealthyHostCount` - Number of healthy targets
- `UnHealthyHostCount` - Number of unhealthy targets
- `TargetResponseTime` - Response time for health checks

### Alarms
Consider creating alarms for:
- All targets unhealthy
- Health check response time > threshold
- High rate of health check failures

## Future Enhancements

Potential improvements:
1. Add more comprehensive S3 operations (GetObject, PutObject)
2. Test multiple buckets or AWS services
3. Add metrics endpoint for Prometheus
4. Implement graceful shutdown handling
5. Add caching to reduce API calls
6. Support custom health check scripts via environment variables

