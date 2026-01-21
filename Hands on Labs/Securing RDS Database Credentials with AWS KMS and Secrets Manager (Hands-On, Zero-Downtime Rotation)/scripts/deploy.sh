#!/bin/bash
set -e

REGION="us-east-1"
DB_NAME="labdb"
DB_USERNAME="admin"
SECRET_NAME="rds-db-credentials"
KMS_KEY_ALIAS="alias/rds-secrets-key"

echo "🚀 Starting RDS Secrets Manager KMS Lab Deployment..."

# Create KMS Key
echo "📦 Creating KMS key..."
KMS_KEY_ID=$(aws kms create-key \
  --description "RDS Secrets Encryption Key" \
  --region $REGION \
  --query 'KeyMetadata.KeyId' \
  --output text)

aws kms create-alias \
  --alias-name $KMS_KEY_ALIAS \
  --target-key-id $KMS_KEY_ID \
  --region $REGION

echo "✅ KMS Key created: $KMS_KEY_ID"

# Create RDS instance
echo "📦 Creating RDS instance..."
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

aws rds create-db-instance \
  --db-instance-identifier lab-rds-instance \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --master-username $DB_USERNAME \
  --master-user-password "$DB_PASSWORD" \
  --allocated-storage 20 \
  --publicly-accessible \
  --region $REGION

echo "⏳ Waiting for RDS instance to be available (this may take 5-10 minutes)..."
aws rds wait db-instance-available \
  --db-instance-identifier lab-rds-instance \
  --region $REGION

# Get RDS endpoint
DB_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier lab-rds-instance \
  --region $REGION \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

echo "✅ RDS instance created: $DB_ENDPOINT"

# Create secret in Secrets Manager
echo "📦 Creating secret in Secrets Manager..."
SECRET_STRING=$(cat <<EOF
{
  "username": "$DB_USERNAME",
  "password": "$DB_PASSWORD",
  "engine": "mysql",
  "host": "$DB_ENDPOINT",
  "port": 3306,
  "dbname": "$DB_NAME"
}
EOF
)

SECRET_ARN=$(aws secretsmanager create-secret \
  --name $SECRET_NAME \
  --description "RDS database credentials" \
  --kms-key-id $KMS_KEY_ID \
  --secret-string "$SECRET_STRING" \
  --region $REGION \
  --query 'ARN' \
  --output text)

echo "✅ Secret created: $SECRET_ARN"

# Save configuration
cat > lab-config.txt <<EOF
REGION=$REGION
KMS_KEY_ID=$KMS_KEY_ID
DB_ENDPOINT=$DB_ENDPOINT
SECRET_NAME=$SECRET_NAME
SECRET_ARN=$SECRET_ARN
EOF

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📝 Configuration saved to lab-config.txt"
echo ""
echo "🧪 Test the connection:"
echo "   python3 test-connection.py"
echo ""
echo "🔄 Rotate the secret:"
echo "   ./rotate-secret.sh"
echo ""
echo "🧹 Cleanup resources:"
echo "   ./cleanup.sh"
