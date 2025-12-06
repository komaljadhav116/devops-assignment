# One-Click Deployment: REST API on AWS

This project provides a **one-click deployment solution** to set up a simple REST API server running on **private EC2 instances** behind an **Application Load Balancer (ALB)** and **Auto Scaling Group (ASG)** using Infrastructure as Code (IaC) with **Terraform**.  

### Architecture
Client → ALB (public subnets) → Target Group → ASG → EC2 (private subnets)
                                    |
                              NAT Gateway (egress)
                                    |
                              Internet Gateway


Key components:

- VPC with 2 public and 2 private subnets  
- Internet Gateway (IGW)  
- NAT Gateway in a public subnet  
- Application Load Balancer (HTTP/HTTPS)  
- Target Group with health checks (`/health`)  
- Launch Template for EC2 instances  
- Auto Scaling Group in private subnets  
- Security Groups:
  - ALB SG: allow HTTP/HTTPS from the internet  
  - EC2 SG: allow traffic only from ALB SG
- IAM Role for EC2:
  - CloudWatch Logs
  - SSM (optional) 
---

## 1.Deployment Steps

1. Clone the repository:

```bash
git clone https://github.com/komaljadhav116/devops-assignment.git
cd devops-assignment

## Deploy infrastructure:

cd scripts/
./deploy.sh

This will:
Create VPC, subnets, IGW, NAT Gateway
Launch ALB and Target Group
spin up EC2 instances in private subnets with the REST API
Configure Auto Scaling Group and Security Groups

## 2.REST API Endpoints

Once deployed, the API is accessible via the ALB DNS:
http://<ALB_DNS>/ → Returns a simple text response
http://<ALB_DNS>/health → Returns ok

## 3.Testing

Optional test script:
cd scripts
./test.sh

## 4.Teardown

To avoid AWS charges:
cd scripts
./destroy.sh