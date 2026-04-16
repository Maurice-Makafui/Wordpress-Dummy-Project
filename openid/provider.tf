provider "aws" {
  region = var.region
}

terraform {
  required_version = ">= 1.6.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40.0"
    }
  }

  backend "s3" {
    bucket         = "cloudsec-terraform-state"
    key            = "openid/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "cloudsec-terraform-locks"
    encrypt        = true
  }
}
