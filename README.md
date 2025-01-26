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

## What is a VPC?
Think of a VPC as your private cloud datacenter. We're using IP range 10.0.0.0/16, giving us 65,536 addresses to work with.

## Network Zones

### Public Areas (The Front Yard)
- Located in two zones: 10.0.1.0/24 and 10.0.2.0/24
- Direct internet access
- Perfect for websites and APIs
- Servers automatically get public IPs

### Private Areas (The Back Yard)
- Located in two zones: 10.0.3.0/24 and 10.0.4.0/24
- No direct internet access
- Ideal for databases and internal services
- Extra security through isolation

## Internet Access

### For Public Resources (Internet Gateway)
- Main door to the internet
- Direct two-way communication
- Used by load balancers and public APIs

### For Private Resources (NAT Gateway)
- Secure one-way internet access
- Allows downloads and updates
- Can reach out, but no incoming traffic
- Placed in public subnet

## Why Two of Everything?
- Two zones = backup plan
- If one fails, the other keeps running
- Critical for 24/7 uptime

## Security Setup
- Public areas: Controlled access through security groups
- Private areas: Extra isolated, limited access
- Load Balancer: Accepts web traffic (port 80)
- Containers: Only accept traffic from load balancer (port 3000)

## Cost Tips
- NAT Gateway charges hourly
- Choose regions carefully
- Each subnet fits 256 IPs
- Plan capacity based on needs

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

1. Configure AWS credentials
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
