# ECS Fargate Stack with ALB and VPC

The infrastructure includes:
- VPC with public and private subnets across 2 AZs
- Application Load Balancer (ALB)
- ECS Fargate cluster
- Auto Scaling
- CloudWatch Logs
- NAT Gateway for private subnet internet access
- Security Groups and IAM roles

# AWS VPC Infrastructure Explained
The Basics
Think of a VPC as your private cloud data center. We're building it with these IPs: 10.0.0.0/16 (gives us 65,536 addresses to work with).
Network Layout
Public Areas (Public Subnets)

Two zones: 10.0.1.0/24 and 10.0.2.0/24
Direct internet access
Perfect for web servers and public APIs
Automatically gives public IPs to servers

Private Areas (Private Subnets)

Two zones: 10.0.3.0/24 and 10.0.4.0/24
No direct internet access
Great for databases and internal services
Extra security by being isolated

Internet Connectivity
For Public Resources

Internet Gateway: The main door to the internet
Lets your public servers talk directly to the internet
Used by load balancers and public APIs

For Private Resources

NAT Gateway: The secure messenger
Lets private servers download updates and packages
One-way street: can reach out, but no one can reach in
Located in public subnet but serves private ones

Traffic Control
Public Routes

Direct path to internet via Internet Gateway
Used by your public-facing services
Think of it as the highway to the internet

Private Routes

All internet traffic goes through NAT Gateway
More controlled and secure
Think of it as a secure tunnel

Availability & Redundancy

Everything is doubled across two zones
If one zone fails, the other keeps running
Critical for keeping your services online

Naming Convention

Everything is tagged with environment names (dev/prod)
Makes it easy to identify resources
Example: dev-public-subnet-1, prod-private-subnet-2

Cost Considerations

NAT Gateway costs hourly
Consider costs when choosing regions
Each subnet can handle 256 IPs

Security Features

DNS support enabled
Private subnets are truly private
Public subnets can be locked down with security groups

### Components
- **ECS Fargate Cluster**: Serverless compute for Docker containers
- **Application Load Balancer**: HTTP/80 traffic routing
- **Auto Scaling**: CPU-based (70% target)
- **CloudWatch Logs**: 30-day retention

### Security
- ALB Security Group: Inbound HTTP/80
- ECS Security Group: Inbound from ALB/3000
- IAM Roles:
  - ECSTaskExecutionRole
  - AutoScalingRole

## Prerequisites

1. AWS CLI installation:
```bash
aws configure
```

## Deployment

1. Clone repository:
```bash
git clone https://github.com/your-username/your-repo-name.git
cd your-repo-name
```

2. Make script executable:
```bash
chmod +x deploy.sh
```

3. Deploy:
```bash
./deploy.sh
```
![Logo](/images/deploy.png)
![Logo](/images/running.png)

## ⚙️ Configuration Options

### Auto Scaling
- Minimum instances: 2
- Maximum instances: 4
- Scale up when CPU > 70%

### Health Checks
- Path: /health
- Interval: 15 seconds
- Timeout: 3 seconds
- Healthy threshold: 2
- Unhealthy threshold: 2

## 📝 Notes

- Initial deployment takes ~10-15 minutes
- Subsequent updates are faster (~3-5 minutes)
- NAT Gateway incurs hourly charges
- Private subnets ensure better security for ECS tasks
- Rolling deployments ensure zero-downtime updates


## Cleanup

Remove resources:
```bash
aws cloudformation delete-stack --stack-name moziostack
aws ecr delete-repository --repository-name mozioecr --force
```

## Troubleshooting

### Docker Build Issues
- Verify Dockerfile configuration
- Check network connectivity

### ECR Push Failures
- Verify AWS_ACCOUNT_ID
- Check IAM permissions

### ALB Health Check Issues
- Verify container port configuration
- Ensure /health endpoint returns 200

### CloudFormation Rollback
- Review CloudFormation events
- Verify resource availability
