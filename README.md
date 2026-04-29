# task-3-46 Terraform

This Terraform config provisions an AWS setup consisting of:

- A VPC (public + private subnets, NAT gateway)
- An ALB in the public subnets
- Two EC2 instances in the private subnets running Nginx

## Prerequisites

- Terraform >= 1.3.0
- AWS credentials configured for the AWS provider and S3 backend state access
- S3 state backend configured in `backend.tf` (bucket and key are hardcoded there)

## Configure

Set your deployment region in `terraform.tfvars` (copy from the example):

- `region`: AWS region (see `variables.tf`)

Note: `backend.tf` is currently pinned to `ap-south-1` for state operations.

## Deploy

From this directory:

```bash
terraform init
terraform plan
terraform apply
```

After apply, use the outputs (especially `alb_dns`) to reach the load balancer.

## Outputs

- `alb_dns`: DNS name of the ALB
- `vpc_id`: VPC ID
- `ec2_private_ips`: Private IPs of the EC2 instances

