variable "project" {
  type        = string
  default     = "norn"
  description = "Project name, used as a name prefix for resources."
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Deployment environment (dev, staging, prod)."
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region."
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC CIDR block."
}

variable "azs" {
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
  description = "Availability zones to spread subnets across."
}

variable "github_repository" {
  type        = string
  default     = ""
  description = "GitHub repo as owner/name. Enables the CI role when non-empty."
}

variable "db_instance_class" {
  type        = string
  default     = "db.t4g.micro"
  description = "RDS instance class."
}

variable "redis_node_type" {
  type        = string
  default     = "cache.t4g.micro"
  description = "ElastiCache node type."
}

variable "container_image" {
  type        = string
  default     = ""
  description = "Container image override. Empty = ECR repo :latest."
}

variable "desired_count" {
  type        = number
  default     = 0
  description = "ECS service desired count. 0 until the first image is pushed to ECR."
}

variable "task_cpu" {
  type        = number
  default     = 256
  description = "Fargate task CPU units."
}

variable "task_memory" {
  type        = number
  default     = 512
  description = "Fargate task memory MiB."
}
