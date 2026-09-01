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
