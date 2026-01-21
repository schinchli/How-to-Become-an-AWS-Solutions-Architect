#!/bin/bash
set -e

if [ ! -f lab-config.txt ]; then
  echo "❌ lab-config.txt not found. Run ./deploy.sh first."
  exit 1
fi

source lab-config.txt

echo "🔄 Rotating secret..."

# Generate new password
NEW_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

# Get current secret
CURRENT_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id $SECRET_NAME \
  --region $REGION \
  --query 'SecretString' \
  --output text)

# Update password in secret
UPDATED_SECRET=$(echo $CURRENT_SECRET | jq --arg pwd "$NEW_PASSWORD" '.password = $pwd')

# Update secret in Secrets Manager
aws secretsmanager update-secret \
  --secret-id $SECRET_NAME \
  --secret-string "$UPDATED_SECRET" \
  --region $REGION

echo "✅ Secret updated in Secrets Manager"

# Update RDS master password
echo "🔄 Updating RDS master password..."
aws rds modify-db-instance \
  --db-instance-identifier lab-rds-instance \
  --master-user-password "$NEW_PASSWORD" \
  --apply-immediately \
  --region $REGION

echo "⏳ Waiting for RDS modification..."
aws rds wait db-instance-available \
  --db-instance-identifier lab-rds-instance \
  --region $REGION

echo ""
echo "✅ Secret rotation complete!"
echo ""
echo "🧪 Test the new connection:"
echo "   python3 test-connection.py"
