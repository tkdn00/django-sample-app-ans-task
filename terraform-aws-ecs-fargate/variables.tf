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

variable "db_engine_version" {
  type    = string
  default = "17"
}

variable "db_instance_class" {
  default = "db.t3.micro"
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

variable "cpu_architecture" {
  description = "CPU architecture of the Fargate task, must match the platform the image was built for (ARM64 or X86_64)"
  type        = string
  default     = "ARM64"
}

variable "image_tag" {
  description = "Tag of the application image to deploy"
  type        = string
  default     = "latest"
}

variable "task_cpu" {
  description = "CPU units of the Fargate task"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Memory (MiB) of the Fargate task"
  type        = number
  default     = 1024
}

variable "ecr_repository_name" {
  description = "Name of repository"
  type        = string
  default     = "django-sample-app"

}