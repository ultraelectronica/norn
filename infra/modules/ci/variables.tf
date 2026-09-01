variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "github_repository" {
  description = "owner/name of the GitHub repo allowed to assume the CI role."
  type        = string
}

variable "state_bucket" {
  type = string
}

variable "state_table" {
  type = string
}

variable "ecr_repository_arn" {
  type = string
}
