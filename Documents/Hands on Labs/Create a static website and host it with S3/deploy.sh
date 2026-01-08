#!/bin/bash
# AWS S3 Static Website Deployment Script with CloudFront and OAI
# This script deploys a static website to S3 with CloudFront CDN

set -e

# Configuration
BUCKET_NAME="${BUCKET_NAME:-s3-static-website-demo-$(date +%s)}"
REGION="${AWS_REGION:-us-east-1}"
WEBSITE_DIR="./website"

echo "=============================================="
echo "AWS S3 Static Website Deployment"
echo "=============================================="
echo "Bucket Name: $BUCKET_NAME"
echo "Region: $REGION"
echo "=============================================="

# Step 1: Create S3 Bucket
echo ""
echo "[Step 1/6] Creating S3 bucket..."
aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    $(if [ "$REGION" != "us-east-1" ]; then echo "--create-bucket-configuration LocationConstraint=$REGION"; fi)

echo "Bucket created: $BUCKET_NAME"

# Step 2: Block all public access (we'll use CloudFront OAI)
echo ""
echo "[Step 2/6] Configuring bucket security (blocking public access)..."
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "Public access blocked - CloudFront OAI will provide access"

# Step 3: Create CloudFront Origin Access Identity (OAI)
echo ""
echo "[Step 3/6] Creating CloudFront Origin Access Identity..."
OAI_RESULT=$(aws cloudfront create-cloud-front-origin-access-identity \
    --cloud-front-origin-access-identity-config \
    "CallerReference=$(date +%s),Comment=OAI for $BUCKET_NAME")

OAI_ID=$(echo "$OAI_RESULT" | jq -r '.CloudFrontOriginAccessIdentity.Id')
OAI_S3_CANONICAL_USER=$(echo "$OAI_RESULT" | jq -r '.CloudFrontOriginAccessIdentity.S3CanonicalUserId')

echo "OAI created: $OAI_ID"

# Step 4: Update bucket policy to allow CloudFront OAI
echo ""
echo "[Step 4/6] Updating bucket policy for CloudFront OAI..."
cat > /tmp/bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowCloudFrontOAI",
            "Effect": "Allow",
            "Principal": {
                "CanonicalUser": "$OAI_S3_CANONICAL_USER"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOF

aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --policy file:///tmp/bucket-policy.json
echo "Bucket policy updated"

# Step 5: Upload website files
echo ""
echo "[Step 5/6] Uploading website files to S3..."
aws s3 sync "$WEBSITE_DIR" "s3://$BUCKET_NAME/" \
    --delete \
    --cache-control "max-age=86400"

# Set correct content types
aws s3 cp "s3://$BUCKET_NAME/" "s3://$BUCKET_NAME/" \
    --recursive \
    --exclude "*" \
    --include "*.html" \
    --content-type "text/html" \
    --metadata-directive REPLACE \
    --cache-control "max-age=3600"

aws s3 cp "s3://$BUCKET_NAME/" "s3://$BUCKET_NAME/" \
    --recursive \
    --exclude "*" \
    --include "*.css" \
    --content-type "text/css" \
    --metadata-directive REPLACE \
    --cache-control "max-age=86400"

aws s3 cp "s3://$BUCKET_NAME/" "s3://$BUCKET_NAME/" \
    --recursive \
    --exclude "*" \
    --include "*.js" \
    --content-type "application/javascript" \
    --metadata-directive REPLACE \
    --cache-control "max-age=86400"

echo "Website files uploaded"

# Step 6: Create CloudFront Distribution
echo ""
echo "[Step 6/6] Creating CloudFront distribution..."
cat > /tmp/cloudfront-config.json << EOF
{
    "CallerReference": "$(date +%s)",
    "Comment": "CloudFront distribution for $BUCKET_NAME",
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3-$BUCKET_NAME",
        "ViewerProtocolPolicy": "redirect-to-https",
        "TrustedSigners": {
            "Enabled": false,
            "Quantity": 0
        },
        "ForwardedValues": {
            "QueryString": false,
            "Cookies": {
                "Forward": "none"
            }
        },
        "MinTTL": 0,
        "DefaultTTL": 86400,
        "MaxTTL": 31536000,
        "Compress": true,
        "AllowedMethods": {
            "Quantity": 2,
            "Items": ["GET", "HEAD"],
            "CachedMethods": {
                "Quantity": 2,
                "Items": ["GET", "HEAD"]
            }
        }
    },
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "S3-$BUCKET_NAME",
                "DomainName": "$BUCKET_NAME.s3.$REGION.amazonaws.com",
                "S3OriginConfig": {
                    "OriginAccessIdentity": "origin-access-identity/cloudfront/$OAI_ID"
                }
            }
        ]
    },
    "Enabled": true,
    "DefaultRootObject": "index.html",
    "CustomErrorResponses": {
        "Quantity": 1,
        "Items": [
            {
                "ErrorCode": 404,
                "ResponsePagePath": "/error.html",
                "ResponseCode": "404",
                "ErrorCachingMinTTL": 300
            }
        ]
    },
    "PriceClass": "PriceClass_100",
    "HttpVersion": "http2"
}
EOF

CF_RESULT=$(aws cloudfront create-distribution \
    --distribution-config file:///tmp/cloudfront-config.json)

CF_DOMAIN=$(echo "$CF_RESULT" | jq -r '.Distribution.DomainName')
CF_ID=$(echo "$CF_RESULT" | jq -r '.Distribution.Id')

echo ""
echo "=============================================="
echo "DEPLOYMENT COMPLETE!"
echo "=============================================="
echo ""
echo "CloudFront Distribution ID: $CF_ID"
echo "CloudFront Domain: https://$CF_DOMAIN"
echo "S3 Bucket: $BUCKET_NAME"
echo "OAI ID: $OAI_ID"
echo ""
echo "Note: CloudFront distribution may take 10-15 minutes to deploy."
echo "Check status with: aws cloudfront get-distribution --id $CF_ID --query 'Distribution.Status'"
echo ""
echo "=============================================="

# Save deployment info
cat > deployment-info.json << EOF
{
    "bucketName": "$BUCKET_NAME",
    "region": "$REGION",
    "cloudfrontDomain": "$CF_DOMAIN",
    "cloudfrontId": "$CF_ID",
    "oaiId": "$OAI_ID",
    "deployedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo "Deployment info saved to deployment-info.json"
