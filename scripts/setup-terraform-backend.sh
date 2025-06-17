#!/bin/bash
# Script to set up Terraform backend resources (S3 bucket and DynamoDB table)

# Configuration
REGION="eu-north-1"
BUCKET_NAME="terraform-state-eks-blueprint"
DYNAMODB_TABLE="terraform-state-lock"

# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

echo -e "${YELLOW}Setting up Terraform backend resources...${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if the S3 bucket already exists
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo -e "${GREEN}S3 bucket '$BUCKET_NAME' already exists.${NC}"
else
    echo "Creating S3 bucket '$BUCKET_NAME'..."
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION"
    
    # Enable versioning on the S3 bucket
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled
    
    # Enable server-side encryption on the S3 bucket
    aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
    
    echo -e "${GREEN}S3 bucket created and configured successfully.${NC}"
fi

# Check if the DynamoDB table already exists
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$REGION" 2>/dev/null; then
    echo -e "${GREEN}DynamoDB table '$DYNAMODB_TABLE' already exists.${NC}"
else
    echo "Creating DynamoDB table '$DYNAMODB_TABLE'..."
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$REGION"
    
    echo -e "${GREEN}DynamoDB table created successfully.${NC}"
fi

echo -e "${GREEN}Terraform backend resources are ready!${NC}"
echo -e "You can now run 'terraform init' to initialize your Terraform configuration."