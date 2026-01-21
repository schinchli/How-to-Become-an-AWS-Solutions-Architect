# aws:CalledVia Condition Key Demo

> Restricting access based on which AWS service makes the request

---

## What is aws:CalledVia?

The `aws:CalledVia` condition key allows you to **restrict access based on which AWS service called your resource**. This is useful when you want to:

- Allow CloudFormation to create S3 buckets, but block direct user access
- Permit Athena to query S3, but prevent direct S3 API calls
- Enable service-to-service calls while blocking direct access

---

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                    REQUEST FLOW COMPARISON                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  DIRECT CALL (aws:CalledVia = empty):                          │
│                                                                 │
│    User ──────────────────────────────► S3 Bucket              │
│           Direct API call                                       │
│           aws:CalledVia NOT present                            │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  SERVICE CALL (aws:CalledVia = cloudformation.amazonaws.com):  │
│                                                                 │
│    User ────► CloudFormation ────► S3 Bucket                   │
│               creates stack         creates bucket              │
│               aws:CalledVia = ["cloudformation.amazonaws.com"] │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  CHAINED CALL (aws:CalledVia = [service1, service2]):          │
│                                                                 │
│    User ────► Athena ────► S3 Bucket                           │
│               query         read data                           │
│               aws:CalledViaFirst = "athena.amazonaws.com"      │
│               aws:CalledViaLast  = "athena.amazonaws.com"      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## CalledVia Condition Keys

| Condition Key | Type | Description |
|---------------|------|-------------|
| `aws:CalledVia` | Multivalued | Full chain of services that made the request |
| `aws:CalledViaFirst` | Single-valued | First (outermost) service in the chain |
| `aws:CalledViaLast` | Single-valued | Last (innermost) service that made the call |
| `aws:ViaAWSService` | Boolean | True if request was made by any AWS service |

---

## Demo 1: Allow S3 Access ONLY via CloudFormation

### Policy: Deny Direct S3 Access

This policy **allows S3 access only when called through CloudFormation**:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowS3ViaCloudFormationOnly",
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:DeleteBucket",
                "s3:PutObject",
                "s3:GetObject"
            ],
            "Resource": "*",
            "Condition": {
                "ForAnyValue:StringEquals": {
                    "aws:CalledVia": ["cloudformation.amazonaws.com"]
                }
            }
        },
        {
            "Sid": "DenyDirectS3Access",
            "Effect": "Deny",
            "Action": "s3:*",
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:CalledVia": "true"
                }
            }
        }
    ]
}
```

### Test Results

| Action | Method | Result |
|--------|--------|--------|
| `aws s3 ls` | Direct CLI | ❌ Denied |
| `aws s3 mb s3://bucket` | Direct CLI | ❌ Denied |
| CloudFormation creates S3 bucket | Via CFN | ✅ Allowed |

---

## Demo 2: Create Test User with CalledVia Policy

### Step 1: Create the Policy

```bash
# Create policy file
cat > /tmp/calledvia-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowS3OnlyViaCloudFormation",
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:DeleteBucket",
                "s3:PutBucketTagging",
                "s3:GetBucketTagging",
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": "*",
            "Condition": {
                "ForAnyValue:StringEquals": {
                    "aws:CalledVia": ["cloudformation.amazonaws.com"]
                }
            }
        },
        {
            "Sid": "AllowCloudFormationFullAccess",
            "Effect": "Allow",
            "Action": "cloudformation:*",
            "Resource": "*"
        },
        {
            "Sid": "DenyDirectS3WhenNotViaService",
            "Effect": "Deny",
            "Action": "s3:*",
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:CalledVia": "true"
                }
            }
        }
    ]
}
EOF

# Create the IAM policy
aws iam create-policy \
    --policy-name CalledVia-S3-CloudFormation-Only \
    --policy-document file:///tmp/calledvia-policy.json
```

### Step 2: Create Test User

```bash
# Create user
aws iam create-user --user-name calledvia-demo-user

# Attach the policy (replace ACCOUNT_ID)
aws iam attach-user-policy \
    --user-name calledvia-demo-user \
    --policy-arn arn:aws:iam::ACCOUNT_ID:policy/CalledVia-S3-CloudFormation-Only

# Create access key
aws iam create-access-key --user-name calledvia-demo-user
```

### Step 3: Test Direct S3 Access (Should FAIL)

```bash
# Set credentials
export AWS_ACCESS_KEY_ID=AKIAXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=xxxxxxxxxx

# Try direct S3 access - SHOULD FAIL
aws s3 ls
# Error: Access Denied

aws s3 mb s3://test-calledvia-bucket-123
# Error: Access Denied
```

### Step 4: Test via CloudFormation (Should SUCCEED)

```bash
# Create CloudFormation template
cat > /tmp/s3-bucket.yaml << 'EOF'
AWSTemplateFormatVersion: '2010-09-09'
Description: Test S3 bucket via CalledVia
Resources:
  TestBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub 'calledvia-test-${AWS::AccountId}'
      Tags:
        - Key: CreatedBy
          Value: CloudFormation
        - Key: Purpose
          Value: CalledVia-Demo
Outputs:
  BucketName:
    Value: !Ref TestBucket
EOF

# Deploy via CloudFormation - SHOULD SUCCEED
aws cloudformation create-stack \
    --stack-name calledvia-demo \
    --template-body file:///tmp/s3-bucket.yaml

# Check stack status
aws cloudformation describe-stacks --stack-name calledvia-demo
```

---

## Demo 3: Real-World Use Cases

### Use Case 1: Data Lake Security

Only allow S3 access through Athena (for queries) and Glue (for ETL):

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowS3ViaAnalyticsServices",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::data-lake-bucket",
                "arn:aws:s3:::data-lake-bucket/*"
            ],
            "Condition": {
                "ForAnyValue:StringEquals": {
                    "aws:CalledVia": [
                        "athena.amazonaws.com",
                        "glue.amazonaws.com"
                    ]
                }
            }
        }
    ]
}
```

### Use Case 2: Infrastructure as Code Only

Only allow resource creation through CloudFormation or Terraform (via CloudFormation):

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowOnlyViaIaC",
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "s3:*",
                "rds:*"
            ],
            "Resource": "*",
            "Condition": {
                "ForAnyValue:StringEquals": {
                    "aws:CalledVia": ["cloudformation.amazonaws.com"]
                }
            }
        },
        {
            "Sid": "AllowCloudFormation",
            "Effect": "Allow",
            "Action": "cloudformation:*",
            "Resource": "*"
        }
    ]
}
```

### Use Case 3: Lambda Execution Only

Allow DynamoDB access only when called via Lambda:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowDynamoDBViaLambda",
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:Query"
            ],
            "Resource": "arn:aws:dynamodb:*:*:table/MyTable",
            "Condition": {
                "ForAnyValue:StringEquals": {
                    "aws:CalledVia": ["lambda.amazonaws.com"]
                }
            }
        }
    ]
}
```

---

## Common AWS Service Principals for CalledVia

| Service | Principal |
|---------|-----------|
| CloudFormation | `cloudformation.amazonaws.com` |
| Athena | `athena.amazonaws.com` |
| Glue | `glue.amazonaws.com` |
| Lambda | `lambda.amazonaws.com` |
| Step Functions | `states.amazonaws.com` |
| CodePipeline | `codepipeline.amazonaws.com` |
| CodeBuild | `codebuild.amazonaws.com` |
| EMR | `elasticmapreduce.amazonaws.com` |
| SageMaker | `sagemaker.amazonaws.com` |

---

## Condition Key Comparison

| Scenario | aws:CalledVia | aws:CalledViaFirst | aws:CalledViaLast |
|----------|:-------------:|:------------------:|:-----------------:|
| Direct user call | Empty/Null | Empty/Null | Empty/Null |
| User → CFN → S3 | `[cloudformation.amazonaws.com]` | `cloudformation.amazonaws.com` | `cloudformation.amazonaws.com` |
| User → Athena → S3 | `[athena.amazonaws.com]` | `athena.amazonaws.com` | `athena.amazonaws.com` |
| User → Step Functions → Lambda → DynamoDB | `[states.amazonaws.com, lambda.amazonaws.com]` | `states.amazonaws.com` | `lambda.amazonaws.com` |

---

## Cleanup

```bash
# Delete CloudFormation stack
aws cloudformation delete-stack --stack-name calledvia-demo

# Wait for deletion
aws cloudformation wait stack-delete-complete --stack-name calledvia-demo

# Detach policy from user
aws iam detach-user-policy \
    --user-name calledvia-demo-user \
    --policy-arn arn:aws:iam::ACCOUNT_ID:policy/CalledVia-S3-CloudFormation-Only

# Delete access keys
ACCESS_KEY=$(aws iam list-access-keys --user-name calledvia-demo-user \
    --query 'AccessKeyMetadata[0].AccessKeyId' --output text)
aws iam delete-access-key --user-name calledvia-demo-user --access-key-id $ACCESS_KEY

# Delete user
aws iam delete-user --user-name calledvia-demo-user

# Delete policy
aws iam delete-policy \
    --policy-arn arn:aws:iam::ACCOUNT_ID:policy/CalledVia-S3-CloudFormation-Only
```

---

## Key Takeaways

| Point | Description |
|-------|-------------|
| **Service Control** | `aws:CalledVia` lets you restrict access based on calling service |
| **Security Layer** | Add defense-in-depth by requiring IaC for infrastructure changes |
| **Audit Trail** | Combined with CloudTrail, shows exactly how resources were accessed |
| **Null Check** | Use `"Null": {"aws:CalledVia": "true"}` to detect direct calls |
| **Multivalued** | Use `ForAnyValue:StringEquals` for list comparison |

---

## AWS Documentation

- [AWS Global Condition Context Keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html)
- [IAM Policy Condition Operators](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_condition_operators.html)
- [Multivalued Context Keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-single-vs-multi-valued-context-keys.html)

## Recommended Reading

- [How to define least-privileged permissions for actions called by AWS services](https://aws.amazon.com/blogs/security/how-to-define-least-privileged-permissions-for-actions-called-by-aws-services/) - AWS Security Blog

---

**Created**: January 2026 | **Condition Key**: `aws:CalledVia`
