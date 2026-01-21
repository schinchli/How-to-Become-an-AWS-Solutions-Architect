#!/bin/bash
set -e

if [ ! -f lab-config.txt ]; then
  echo "❌ lab-config.txt not found. Run ./deploy.sh first."
  exit 1
fi

source lab-config.txt

FUNCTION_NAME="rds-connection-test"
ROLE_NAME="lambda-rds-secrets-role"

echo "🧹 Starting cleanup..."

# Delete Lambda function
echo "🗑️  Deleting Lambda function..."
aws lambda delete-function \
  --function-name $FUNCTION_NAME \
  --region $REGION 2>/dev/null || echo "Lambda function already deleted"

# Detach and delete IAM role
echo "🗑️  Cleaning up IAM role..."
aws iam detach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole 2>/dev/null || true

aws iam detach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/SecretsManagerReadWrite 2>/dev/null || true

aws iam delete-role-policy \
  --role-name $ROLE_NAME \
  --policy-name kms-decrypt 2>/dev/null || true

aws iam delete-role \
  --role-name $ROLE_NAME 2>/dev/null || echo "IAM role already deleted"

# Delete secret
echo "🗑️  Deleting secret..."
aws secretsmanager delete-secret \
  --secret-id $SECRET_NAME \
  --force-delete-without-recovery \
  --region $REGION 2>/dev/null || echo "Secret already deleted"

# Delete RDS instance
echo "🗑️  Deleting RDS instance..."
aws rds delete-db-instance \
  --db-instance-identifier lab-rds-instance \
  --skip-final-snapshot \
  --region $REGION 2>/dev/null || echo "RDS instance already deleted"

echo "⏳ Waiting for RDS deletion..."
aws rds wait db-instance-deleted \
  --db-instance-identifier lab-rds-instance \
  --region $REGION 2>/dev/null || true

# Schedule KMS key deletion
echo "🗑️  Scheduling KMS key deletion..."
aws kms schedule-key-deletion \
  --key-id $KMS_KEY_ID \
  --pending-window-in-days 7 \
  --region $REGION 2>/dev/null || echo "KMS key already scheduled for deletion"

# Remove config file
rm -f lab-config.txt

echo ""
echo "✅ Cleanup complete!"
echo "⚠️  KMS key will be deleted in 7 days (AWS minimum)"
