terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # bucket + dynamodb_table are injected via -backend-config by
  # scripts/bootstrap-state.sh (bucket name embeds the account id).
  backend "s3" {
    key    = "norn/dev/terraform.tfstate"
    region = "us-east-1"
  }
}
