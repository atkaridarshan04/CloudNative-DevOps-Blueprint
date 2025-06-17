# Terraform Backend Configuration
# This file configures Terraform to store state in an S3 bucket with DynamoDB for state locking

# Note: You need to create these resources manually before running terraform init
# 1. Create an S3 bucket
# 2. Create a DynamoDB table with a primary key named "LockID"

terraform {
  backend "s3" {
    bucket         = "terraform-state-eks-blueprint"  # Replace with your S3 bucket name
    key            = "terraform.tfstate"
    region         = "eu-north-1"                    # Match your project region
    encrypt        = true
    dynamodb_table = "terraform-state-lock"         # Replace with your DynamoDB table name
  }
}