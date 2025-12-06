#!/bin/bash

# Get ALB DNS from Terraform output
ALB_DNS=$(terraform output -raw alb_dns)

echo "Testing API..."
curl http://$ALB_DNS/       # Check home page
curl http://$ALB_DNS/health # Check health endpoint
