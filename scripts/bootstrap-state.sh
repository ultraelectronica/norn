#!/usr/bin/env bash
# One-time bootstrap for Terraform remote state (S3 + DynamoDB lock).
# Creates resources OUTSIDE terraform — the chicken-and-egg solver.
# Idempotent: safe to re-run.

set -euo pipefail

PROJECT="${PROJECT:-norn}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
REGION="${REGION:-us-east-1}"

die() { echo "ERROR: $*" >&2; exit 1; }

command -v aws >/dev/null 2>&1 || die "aws CLI not found in PATH"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
[ -n "$ACCOUNT_ID" ] || die "could not determine AWS account id"

BUCKET="${PROJECT}-tfstate-${ACCOUNT_ID}-${ENVIRONMENT}"
TABLE="${PROJECT}-tflock-${ENVIRONMENT}"

echo "==> State bucket: ${BUCKET} (${REGION})"
if aws s3api head-bucket --bucket "$BUCKET" >/dev/null 2>&1; then
  echo "    already exists, skipping"
else
  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
  else
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi
  aws s3api put-bucket-versioning --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled
  aws s3api put-bucket-encryption --bucket "$BUCKET" \
    --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
  aws s3api put-public-access-block --bucket "$BUCKET" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
  aws s3api put-bucket-policy --bucket "$BUCKET" --policy "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [{
      \"Sid\": \"DenyInsecureTransport\",
      \"Effect\": \"Deny\",
      \"Principal\": \"*\",
      \"Action\": \"s3:*\",
      \"Resource\": [\"arn:aws:s3:::${BUCKET}\", \"arn:aws:s3:::${BUCKET}/*\"],
      \"Condition\": {\"Bool\": {\"aws:SecureTransport\": \"false\"}}
    }]
  }"
  echo "    created (versioning + SSE + public block + TLS-only)"
fi

echo "==> Lock table: ${TABLE}"
if aws dynamodb describe-table --table-name "$TABLE" >/dev/null 2>&1; then
  echo "    already exists, skipping"
else
  aws dynamodb create-table --table-name "$TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
  aws dynamodb wait table-exists --table-name "$TABLE"
  echo "    created (PAY_PER_REQUEST)"
fi

cat <<EOF

Bootstrap complete. Initialize terraform with:

  terraform -chdir=infra init \\
    -backend-config="bucket=${BUCKET}" \\
    -backend-config="key=${PROJECT}/${ENVIRONMENT}/terraform.tfstate" \\
    -backend-config="region=${REGION}" \\
    -backend-config="dynamodb_table=${TABLE}"

Then plan/apply (CI role needs the repo identity):

  TF_VAR_github_repository=<owner>/norn terraform -chdir=infra plan
EOF
