terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Remote state — S3 bucket must exist before running terraform init
  # Create it first with: scripts/bootstrap-state.sh
  backend "s3" {
    bucket         = "cryptoscope-tfstate-757760338065"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "cryptoscope-tfstate-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "cryptoscope"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
