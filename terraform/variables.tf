variable "aws_region" {
  default = "us-east-1"

}

variable "vpc_cidr" {
  description = "cidr_block of VPC"
  default     = "10.1.0.0/16"

}

variable "public1_cidr" {
  description = "cidr_block of public1 subnet"
  default     = "10.1.10.0/24"
}

variable "public2_cidr" {
  description = "cidr_block of public2 subnet"
  default     = "10.1.20.0/24"
}

variable "private1_cidr" {
  description = "cidr_block of private1 subnet"
  default     = "10.1.50.0/24"

}

variable "private2_cidr" {
  description = "cidr_block of private2 subnet"
  default     = "10.1.60.0/24"

}

variable "aws_ami_pattern" {
  default = ["al2023-ami-2023.*-x86_64"]

}

variable "app_instance_type" {
  default = "t3.micro"

}

variable "db_instance_type" {
  default = "t3.micro"

}

variable "db_name" {
  description = "Name of the application database"
  type        = string
  default     = "djangoapp"
}

variable "db_user" {
  description = "Name of the application database user"
  type        = string
  default     = "djangoapp_user"
}

resource "random_password" "db_password" {
  length  = 16
  special = false

}

variable "github_token" {
  description = "GitHub token for downloading Ansible playbooks via SSM"
  type        = string
  sensitive   = true
}