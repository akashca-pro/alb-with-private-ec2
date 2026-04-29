terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# VPC Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "task-3-46-vpc"
  cidr = "10.0.0.0/16"

  azs = ["ap-south-1a", "ap-south-1b"]

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name   = "task-3-46-alb-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Security Group
resource "aws_security_group" "ec2_sg" {
  name   = "task-3-46-ec2-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]  
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

locals {
  ec2_instances = {
    ec2_1 = {
      subnet_index = 0
      name_suffix  = "1"
      user_label   = "Instance 1"
    }
    ec2_2 = {
      subnet_index = 1
      name_suffix  = "2"
      user_label   = "Instance 2"
    }
  }
}

module "ec2" {
  for_each = local.ec2_instances

  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.0.0"

  name           = "task-3-46-nginx-${each.value.name_suffix}"
  instance_type  = "t2.micro"
  ami            = data.aws_ami.amazon_linux.id
  subnet_id      = module.vpc.private_subnets[each.value.subnet_index]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  associate_public_ip_address = false

  user_data = <<-EOF
#!/bin/bash
yum update -y
yum install -y nginx
systemctl start nginx
systemctl enable nginx
echo "${each.value.user_label}" > /usr/share/nginx/html/index.html
  EOF
}

# ALB Module
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.0.0"

  name = "task-3-46-alb"

  vpc_id = module.vpc.vpc_id

  load_balancer_type = "application"
  enable_deletion_protection = false
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.alb_sg.id]

  target_groups = {
    tg = {
      name          = "task-3-46-tg"
      target_type  = "instance"
      target_id    = module.ec2["ec2_1"].id
      port          = 80
      protocol      = "HTTP"

      health_check = {
        path = "/"
      }
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"

      weighted_forward = {
        target_groups = [
          { target_group_key = "tg", weight = 1 }
        ]
      }
    }
  }
}

# Add the second EC2 instance to the same target group.
resource "aws_lb_target_group_attachment" "ec2_2_to_tg" {
  target_group_arn = module.alb.target_groups["tg"].arn
  target_id         = module.ec2["ec2_2"].id
  port              = 80
}