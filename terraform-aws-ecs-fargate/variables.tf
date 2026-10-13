variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  description = "cidr_block of VPC"
  default     = "10.10.0.0/16"
}

variable "public1_cidr" {
  description = "cidr_block of public1 subnet"
  default     = "10.10.10.0/24"
}

variable "public2_cidr" {
  description = "cidr_block of public2 subnet"
  default     = "10.10.20.0/24"
}

variable "private1_cidr" {
  description = "cidr_block of private1 subnet"
  default     = "10.10.50.0/24"
}

variable "private2_cidr" {
  description = "cidr_block of private2 subnet"
  default     = "10.10.60.0/24"
}

