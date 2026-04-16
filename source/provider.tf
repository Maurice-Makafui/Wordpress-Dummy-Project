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
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }

  backend "s3" {
    # Replace with your own S3 bucket name — must be globally unique
    bucket = "cloudsec-terraform-state"
    key    = "infra/terraform.tfstate"
    region = "us-east-2"

    # DynamoDB table for state locking — prevents two pipeline runs from
    # modifying state at the same time and corrupting it.
    # Create the table manually once: aws dynamodb create-table \
    #   --table-name cloudsec-terraform-locks \
    #   --attribute-definitions AttributeName=LockID,AttributeType=S \
    #   --key-schema AttributeName=LockID,KeyType=HASH \
    #   --billing-mode PAY_PER_REQUEST
    dynamodb_table = "cloudsec-terraform-locks"
    encrypt        = true
  }
}
