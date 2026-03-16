#!/usr/bin/env bash
# scripts/bootstrap-state.sh
#
# Run this ONCE before `terraform init` to create the S3 bucket
# and DynamoDB table used for remote Terraform state.
#
# Usage: ./scripts/bootstrap-state.sh

set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="cryptoscope-tfstate-${AWS_ACCOUNT_ID}"
DYNAMODB_TABLE="cryptoscope-tfstate-lock"

echo "==> Creating Terraform state bucket: ${BUCKET_NAME}"

# Create S3 bucket (us-east-1 does NOT accept LocationConstraint)
if [ "$AWS_REGION" = "us-east-1" ]; then
  aws s3api create-bucket \
    --bucket "${BUCKET_NAME}" \
    --region "${AWS_REGION}" 2>/dev/null || echo "    Bucket already exists, continuing..."
else
  aws s3api create-bucket \
    --bucket "${BUCKET_NAME}" \
    --region "${AWS_REGION}" \
    --create-bucket-configuration LocationConstraint="${AWS_REGION}" 2>/dev/null || echo "    Bucket already exists, continuing..."
fi

echo "==> Enabling versioning on state bucket..."
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

echo "==> Enabling server-side encryption on state bucket..."
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

echo "==> Blocking public access on state bucket..."
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "==> Creating DynamoDB table for state locking: ${DYNAMODB_TABLE}"
aws dynamodb create-table \
  --table-name "${DYNAMODB_TABLE}" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "${AWS_REGION}" 2>/dev/null || echo "    Table already exists, continuing..."

echo ""
echo "✓ Remote state backend ready!"
echo ""
echo "  Bucket:   ${BUCKET_NAME}"
echo "  Table:    ${DYNAMODB_TABLE}"
echo "  Region:   ${AWS_REGION}"
echo ""
echo "Next steps:"
echo "  1. Update infra/versions.tf — set bucket = \"${BUCKET_NAME}\""
echo "  2. cd infra && terraform init"
echo "  3. terraform plan -var-file=environments/dev/terraform.tfvars"
