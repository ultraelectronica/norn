terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state: configure per environment via `terraform init -backend-config=...`
  # (bucket / key / region / dynamodb_table). See README.md.
}
