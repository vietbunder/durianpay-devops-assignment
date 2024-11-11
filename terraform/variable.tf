variable "aws_region" {
  description = "AWS region for resources"
  default     = "ap-southeast-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  default     = "10.0.2.0/24"
}

variable "backend_bucket_name" {
  description = "Name of the S3 bucket for Terraform state storage"
  default     = "durianpay-tf-bucket"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances"
  default     = "ami-047126e50991d067b"
}

variable "instance_type" {
  description = "Instance type for EC2 instances"
  default     = "t2.micro"  # Free Tier eligible
}

variable "key_name" {
  description = "Name of the SSH key pair"
  default     = "terraform-key-pair"
}

variable "eip_alloc_id" {
  description = "Elastic IP Allocation ID"
  default     = "eipalloc-0c834aa7fbc1a5962"
}