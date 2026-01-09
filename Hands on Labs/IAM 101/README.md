# IAM 101: User Access Matrix and Best Practices

> Understanding AWS IAM users, permissions, and the principle of least privilege

---

## Overview

This lab creates 5 IAM users with different permission levels to demonstrate:
- Principle of Least Privilege
- Service-specific vs Administrative access
- When to use each type of user
- Root account best practices

---

## Quick Start (Terraform)

```bash
# 1. Navigate to terraform directory
cd terraform

# 2. Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars if needed

# 3. Deploy
terraform init
terraform plan
terraform apply

# 4. View created users
terraform output user_names

# 5. Cleanup (when done)
terraform destroy
```

---

## What Gets Created

| User | Role | AWS Managed Policy | Access Level |
|------|------|-------------------|--------------|
| user1 | S3 Administrator | AmazonS3FullAccess | S3 Only |
| user2 | EC2 Administrator | AmazonEC2FullAccess | EC2 Only |
| user3 | DynamoDB Administrator | AmazonDynamoDBFullAccess | DynamoDB Only |
| user4 | Full Administrator | AdministratorAccess | All Services |
| user5 | Super Administrator | AdministratorAccess + Billing | All + Billing |

**Note:** No console access is enabled. Users have programmatic access only.

---

## Access Matrix

### Service Access by User

| Service / Permission | user1 | user2 | user3 | user4 | user5 | Root |
|---------------------|:-----:|:-----:|:-----:|:-----:|:-----:|:----:|
| **S3** (Buckets, Objects) | Full | - | - | Full | Full | Full |
| **EC2** (Instances, VPC, EBS) | - | Full | - | Full | Full | Full |
| **DynamoDB** (Tables, Items) | - | - | Full | Full | Full | Full |
| **Lambda** | - | - | - | Full | Full | Full |
| **RDS** | - | - | - | Full | Full | Full |
| **IAM** (Users, Roles, Policies) | - | - | - | Full | Full | Full |
| **CloudFormation** | - | - | - | Full | Full | Full |
| **All Other AWS Services** | - | - | - | Full | Full | Full |
| **Billing & Cost Management** | - | - | - | - | Full | Full |
| **Account Settings** | - | - | - | - | - | Full |
| **Close AWS Account** | - | - | - | - | - | Full |
| **Change Root Email** | - | - | - | - | - | Full |

**Legend:** Full = Full Access | - = No Access

---

## When to Use Each User

### user1 (S3 Administrator)

**Use When:**
- Managing S3 buckets and objects
- Setting up static website hosting
- Configuring S3 lifecycle policies
- Managing S3 replication

**Example Tasks:**
```bash
# Create bucket
aws s3 mb s3://my-bucket

# Upload files
aws s3 cp file.txt s3://my-bucket/

# List buckets
aws s3 ls
```

---

### user2 (EC2 Administrator)

**Use When:**
- Launching and managing EC2 instances
- Configuring VPCs, subnets, security groups
- Managing EBS volumes and snapshots

**Example Tasks:**
```bash
# Launch instance
aws ec2 run-instances --image-id ami-xxx --instance-type t2.micro

# List instances
aws ec2 describe-instances

# Stop instance
aws ec2 stop-instances --instance-ids i-xxx
```

---

### user3 (DynamoDB Administrator)

**Use When:**
- Creating and managing DynamoDB tables
- Configuring read/write capacity
- Setting up DynamoDB streams

**Example Tasks:**
```bash
# Create table
aws dynamodb create-table --table-name MyTable ...

# List tables
aws dynamodb list-tables

# Put item
aws dynamodb put-item --table-name MyTable --item '{"id":{"S":"1"}}'
```

---

### user4 (Full Administrator)

**Use When:**
- Managing multiple AWS services
- Setting up cross-service integrations
- Creating IAM roles and policies
- Day-to-day administration

**Cannot Do:**
- Access billing information
- Modify account settings

---

### user5 (Super Administrator)

**Use When:**
- Need full administrative access PLUS billing
- Managing costs and budgets
- Viewing invoices and payment methods

**Cannot Do:**
- Close AWS account
- Change root email/password
- Enable/disable regions

---

### Root Account

**Use ONLY When:**
- Changing root account email or password
- Changing AWS support plan
- Closing the AWS account
- Restoring IAM user permissions (if locked out)
- Enabling MFA on root
- Creating first IAM admin user

**Best Practices:**
- Enable MFA on root account
- Do NOT create access keys for root
- Use root only for tasks that require it
- Lock away root credentials securely

---

## Principle of Least Privilege

```
┌─────────────────────────────────────────────────────────────────┐
│                     PERMISSION HIERARCHY                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Root Account        ████████████████████████████████  100%     │
│  (Account Owner)     All permissions + Account controls         │
│                                                                 │
│  user5 (Super)       ██████████████████████████████░░  ~95%     │
│                      Admin + Billing (no account controls)      │
│                                                                 │
│  user4 (Admin)       ████████████████████████████░░░░  ~85%     │
│                      All services (no billing)                  │
│                                                                 │
│  user1-3 (Service)   ██████░░░░░░░░░░░░░░░░░░░░░░░░░░  ~15%     │
│                      Single service only                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Why Least Privilege?

| Benefit | Description |
|---------|-------------|
| **Security** | Limits blast radius if credentials are compromised |
| **Compliance** | Meets regulatory requirements (SOC2, HIPAA, PCI) |
| **Auditability** | Clear accountability for actions |
| **Simplicity** | Easier to troubleshoot permission issues |

---

## Terraform Configuration

### Files Structure

```
terraform/
├── main.tf                  # User and policy resources
├── variables.tf             # Input variables
├── outputs.tf               # Output values
├── terraform.tfvars.example # Example configuration
└── .gitignore              # Ignore sensitive files
```

### Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `region` | us-east-1 | AWS region |
| `environment` | training | Environment tag |
| `user_prefix` | "" | Prefix for user names |
| `create_access_keys` | false | Create programmatic access keys |
| `create_user_group` | false | Group all users together |

### Outputs

After deployment, view outputs with:

```bash
# List all users created
terraform output user_names

# View full access matrix
terraform output access_matrix

# View access keys (if created)
terraform output -json access_keys
```

---

## Deployment Guide

### Prerequisites

```bash
# Required tools
terraform --version  # v1.0+
aws --version        # AWS CLI v2

# Verify AWS credentials
aws sts get-caller-identity
```

### Step 1: Initialize

```bash
cd terraform
terraform init
```

### Step 2: Configure

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars as needed
```

### Step 3: Plan

```bash
terraform plan
```

Expected: 5 users + 6 policy attachments = 11 resources

### Step 4: Apply

```bash
terraform apply
```

Type `yes` when prompted.

### Step 5: Verify

```bash
# List created users
terraform output user_names

# Or via AWS CLI
aws iam list-users --query 'Users[?contains(UserName, `user`)].UserName'
```

---

## Decommission / Cleanup

### Option 1: Terraform Destroy (Recommended)

```bash
cd terraform
terraform destroy
```

Type `yes` when prompted. This will:
- Delete all 5 IAM users
- Detach all policies
- Delete access keys (if created)
- Delete user group (if created)

### Option 2: AWS CLI Cleanup

```bash
# Delete all lab users
for user in user1 user2 user3 user4 user5; do
  echo "Deleting $user..."

  # Delete access keys
  keys=$(aws iam list-access-keys --user-name $user --query 'AccessKeyMetadata[].AccessKeyId' --output text 2>/dev/null)
  for key in $keys; do
    aws iam delete-access-key --user-name $user --access-key-id $key
  done

  # Detach all policies
  policies=$(aws iam list-attached-user-policies --user-name $user --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null)
  for policy in $policies; do
    aws iam detach-user-policy --user-name $user --policy-arn $policy
  done

  # Delete user
  aws iam delete-user --user-name $user 2>/dev/null && echo "Deleted $user" || echo "$user not found"
done

echo "Cleanup complete!"
```

### Option 3: AWS Console

1. Go to IAM Console → Users
2. Select each user (user1-user5)
3. Click "Delete user"
4. Confirm deletion

---

## Security Considerations

### What This Lab Does NOT Do

| Security Feature | Status | Reason |
|-----------------|--------|--------|
| Console login | Disabled | Programmatic access only |
| Access keys | Not created by default | Security best practice |
| MFA | Not configured | Demo purposes only |
| Password policy | N/A | No console access |

### Production Recommendations

For production environments:

1. **Enable MFA** for all users
2. **Use IAM Roles** instead of users where possible
3. **Rotate access keys** regularly
4. **Use AWS Organizations** for multi-account setups
5. **Enable CloudTrail** for audit logging
6. **Use IAM Access Analyzer** to review permissions

---

## Quick Reference

### Common AWS CLI Commands

```bash
# List all users
aws iam list-users

# View user's policies
aws iam list-attached-user-policies --user-name <username>

# Create access key
aws iam create-access-key --user-name <username>

# Delete access key
aws iam delete-access-key --user-name <username> --access-key-id <key-id>

# Enable console access
aws iam create-login-profile --user-name <username> --password <password> --password-reset-required

# Check for console access
aws iam get-login-profile --user-name <username>
```

---

## Summary

| User | Scope | Use Case | Risk Level |
|------|-------|----------|------------|
| user1-3 | Single Service | Day-to-day service tasks | Low |
| user4 | All Services | General administration | Medium |
| user5 | All + Billing | Cost management + admin | High |
| Root | Account Level | Critical tasks only | Critical |

**Golden Rule:** Always use the user with the LEAST permissions needed for the task.

---

## Related Resources

- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Principle of Least Privilege](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege)
- [IAM Policy Simulator](https://policysim.aws.amazon.com/)
- [AWS Managed Policies Reference](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_managed-vs-inline.html)

---

**Created**: January 2026 | **Terraform**: v1.0+ | **AWS Provider**: v5.0+
