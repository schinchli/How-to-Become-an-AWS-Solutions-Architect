# IAM Access Key Example: Demonstrating Least Privilege

> A hands-on example showing how IAM access keys work and how least privilege restricts access

---

## Overview

This example demonstrates:
1. How to create IAM access keys
2. How to use access keys with AWS CLI
3. How least privilege allows/denies access based on user permissions

---

## Step 1: Create Access Key

```bash
# Create access key for user1 (S3 Admin)
aws iam create-access-key --user-name user1
```

**Output:**
```json
{
    "AccessKey": {
        "UserName": "user1",
        "AccessKeyId": "AKIAXXXXXXXXXXXXXXXXX",
        "Status": "Active",
        "SecretAccessKey": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
        "CreateDate": "2026-01-09T12:18:57+00:00"
    }
}
```

**Important:** Save the `SecretAccessKey` immediately - it's only shown once!

---

## Step 2: Configure AWS CLI

### Option A: Environment Variables (Temporary)

```bash
export AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
export AWS_DEFAULT_REGION=us-east-1
```

### Option B: Named Profile (Persistent)

```bash
aws configure --profile user1-demo
# Enter Access Key ID: AKIAXXXXXXXXXXXXXXXXX
# Enter Secret Access Key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# Enter Region: us-east-1
# Enter Output format: json
```

Then use with: `aws s3 ls --profile user1-demo`

### Option C: Inline (One-time)

```bash
AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXXX \
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx \
aws s3 ls
```

---

## Step 3: Test Access (Least Privilege Demo)

### Test 1: S3 Access (user1 = S3 Admin)

```bash
# List S3 buckets - SHOULD WORK
aws s3 ls
```

**Result:** ✅ Success - Returns list of buckets

```
2026-01-09 10:30:45 my-bucket-1
2026-01-09 11:20:33 my-bucket-2
```

### Test 2: EC2 Access (user1 has NO EC2 permission)

```bash
# List EC2 instances - SHOULD FAIL
aws ec2 describe-instances
```

**Result:** ❌ Access Denied

```
An error occurred (UnauthorizedOperation) when calling the DescribeInstances
operation: You are not authorized to perform this operation.
User: arn:aws:iam::999999999999:user/user1 is not authorized to perform:
ec2:DescribeInstances because no identity-based policy allows the
ec2:DescribeInstances action
```

### Test 3: DynamoDB Access (user1 has NO DynamoDB permission)

```bash
# List DynamoDB tables - SHOULD FAIL
aws dynamodb list-tables
```

**Result:** ❌ Access Denied

```
An error occurred (AccessDeniedException) when calling the ListTables
operation: User: arn:aws:iam::999999999999:user/user1 is not authorized
to perform: dynamodb:ListTables on resource:
arn:aws:dynamodb:us-east-1:999999999999:table/* because no identity-based
policy allows the dynamodb:ListTables action
```

---

## Results Summary

| Service | Command | user1 (S3 Admin) | Why |
|---------|---------|:----------------:|-----|
| **S3** | `aws s3 ls` | ✅ Allowed | Has `AmazonS3FullAccess` |
| **EC2** | `aws ec2 describe-instances` | ❌ Denied | No EC2 policy attached |
| **DynamoDB** | `aws dynamodb list-tables` | ❌ Denied | No DynamoDB policy attached |

---

## This Proves Least Privilege Works

```
┌─────────────────────────────────────────────────────────────────┐
│                    user1 Permission Boundary                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│    ┌─────────────────────────────────────────────────────┐     │
│    │                     S3 ACCESS                        │     │
│    │                                                      │     │
│    │    ✅ s3:ListBucket       ✅ s3:GetObject           │     │
│    │    ✅ s3:PutObject        ✅ s3:DeleteObject        │     │
│    │    ✅ s3:CreateBucket     ✅ s3:DeleteBucket        │     │
│    │                                                      │     │
│    └─────────────────────────────────────────────────────┘     │
│                                                                 │
│    ┌─────────────────────────────────────────────────────┐     │
│    │               EVERYTHING ELSE                        │     │
│    │                                                      │     │
│    │    ❌ ec2:*              ❌ dynamodb:*               │     │
│    │    ❌ lambda:*           ❌ rds:*                    │     │
│    │    ❌ iam:*              ❌ cloudformation:*         │     │
│    │                                                      │     │
│    └─────────────────────────────────────────────────────┘     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Step 4: Cleanup - Delete Access Key

**Always delete access keys when no longer needed!**

```bash
# List access keys for user
aws iam list-access-keys --user-name user1

# Delete the access key
aws iam delete-access-key --user-name user1 --access-key-id AKIAXXXXXXXXXXXXXXXXX
```

---

## Security Best Practices for Access Keys

| Practice | Why |
|----------|-----|
| **Delete unused keys** | Reduces attack surface |
| **Rotate keys regularly** | Limits exposure time if compromised |
| **Never commit to git** | Keys in repos are easily found |
| **Use IAM roles instead** | Temporary credentials are safer |
| **Use AWS Secrets Manager** | Secure storage and rotation |
| **Enable MFA** | Extra layer of protection |

---

## Complete Demo Script

```bash
#!/bin/bash
# IAM Access Key Demo Script
# This script demonstrates least privilege with IAM access keys

USER="user1"

echo "=== Creating Access Key for $USER ==="
KEY_OUTPUT=$(aws iam create-access-key --user-name $USER --output json)
ACCESS_KEY_ID=$(echo $KEY_OUTPUT | jq -r '.AccessKey.AccessKeyId')
SECRET_KEY=$(echo $KEY_OUTPUT | jq -r '.AccessKey.SecretAccessKey')

echo "Access Key ID: $ACCESS_KEY_ID"
echo ""

echo "=== Testing S3 Access (Should WORK) ==="
AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$SECRET_KEY \
  aws s3 ls 2>&1 | head -3
echo ""

echo "=== Testing EC2 Access (Should FAIL) ==="
AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$SECRET_KEY \
  aws ec2 describe-instances 2>&1 | head -3
echo ""

echo "=== Testing DynamoDB Access (Should FAIL) ==="
AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$SECRET_KEY \
  aws dynamodb list-tables 2>&1 | head -3
echo ""

echo "=== Cleaning Up - Deleting Access Key ==="
aws iam delete-access-key --user-name $USER --access-key-id $ACCESS_KEY_ID
echo "Access key deleted!"
```

---

## Try It Yourself

### Test with Different Users

| User | Expected S3 | Expected EC2 | Expected DynamoDB |
|------|:-----------:|:------------:|:-----------------:|
| user1 | ✅ | ❌ | ❌ |
| user2 | ❌ | ✅ | ❌ |
| user3 | ❌ | ❌ | ✅ |
| user4 | ✅ | ✅ | ✅ |
| user5 | ✅ | ✅ | ✅ |

```bash
# Create key for user2 (EC2 Admin)
aws iam create-access-key --user-name user2

# Test - EC2 should work, S3 should fail
AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... aws ec2 describe-instances  # ✅
AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... aws s3 ls                   # ❌
```

---

## Related Files

- [README.md](./README.md) - Full IAM 101 guide
- [terraform/](./terraform/) - Terraform code to create users

---

**Created**: January 2026 | **Security Note**: Always delete demo access keys after use!
