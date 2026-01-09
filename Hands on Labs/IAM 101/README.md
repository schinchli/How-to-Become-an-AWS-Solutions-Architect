# IAM 101: User Access Matrix and Best Practices

> Understanding AWS IAM users, permissions, and the principle of least privilege

---

## Users Created

| User | Role | Policy | Console Access |
|------|------|--------|----------------|
| user1 | S3 Administrator | AmazonS3FullAccess | Disabled |
| user2 | EC2 Administrator | AmazonEC2FullAccess | Disabled |
| user3 | DynamoDB Administrator | AmazonDynamoDBFullAccess | Disabled |
| user4 | Full Administrator | AdministratorAccess | Disabled |
| user5 | Super Admin (Root-equivalent) | AdministratorAccess + Billing | Disabled |
| **Root** | Account Owner | **EVERYTHING** | N/A (Account Login) |

---

## Access Matrix

| Service / Permission | user1 | user2 | user3 | user4 | user5 | Root |
|---------------------|:-----:|:-----:|:-----:|:-----:|:-----:|:----:|
| **S3** (Buckets, Objects) | Full | - | - | Full | Full | Full |
| **EC2** (Instances, VPC, EBS) | - | Full | - | Full | Full | Full |
| **DynamoDB** (Tables, Items) | - | - | Full | Full | Full | Full |
| **IAM** (Users, Roles, Policies) | - | - | - | Full | Full | Full |
| **Lambda** | - | - | - | Full | Full | Full |
| **RDS** | - | - | - | Full | Full | Full |
| **CloudFormation** | - | - | - | Full | Full | Full |
| **All Other AWS Services** | - | - | - | Full | Full | Full |
| **Billing & Cost Management** | - | - | - | - | Full | Full |
| **Account Settings** | - | - | - | - | - | Full |
| **Close AWS Account** | - | - | - | - | - | Full |
| **Change Root Email** | - | - | - | - | - | Full |
| **Enable/Disable Regions** | - | - | - | - | - | Full |

**Legend**: Full = Full Access | - = No Access

---

## When to Use Each User

### user1 (S3 Administrator)
**Use When:**
- Managing S3 buckets and objects
- Setting up static website hosting
- Configuring S3 lifecycle policies
- Managing S3 replication

**Example Tasks:**
- Create/delete buckets
- Upload/download files
- Set bucket policies
- Configure CORS

---

### user2 (EC2 Administrator)
**Use When:**
- Launching and managing EC2 instances
- Configuring VPCs, subnets, security groups
- Managing EBS volumes and snapshots
- Setting up load balancers

**Example Tasks:**
- Launch/terminate instances
- Create AMIs
- Configure auto-scaling
- Manage key pairs

---

### user3 (DynamoDB Administrator)
**Use When:**
- Creating and managing DynamoDB tables
- Configuring read/write capacity
- Setting up DynamoDB streams
- Managing backups and restores

**Example Tasks:**
- Create/delete tables
- Configure indexes
- Set up TTL
- Manage global tables

---

### user4 (Full Administrator)
**Use When:**
- Managing multiple AWS services
- Setting up cross-service integrations
- Creating IAM roles and policies
- Day-to-day administration tasks

**Example Tasks:**
- Deploy full applications
- Create IAM users/roles
- Set up CloudWatch alarms
- Configure any AWS service

**Cannot Do:**
- Access billing information
- Modify account settings

---

### user5 (Super Admin)
**Use When:**
- Need full administrative access PLUS billing
- Managing costs and budgets
- Viewing invoices and payment methods
- Reserved instance purchases

**Example Tasks:**
- Everything user4 can do
- View/manage billing
- Set up cost alerts
- Purchase reserved capacity

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
- Viewing certain tax invoices
- Signing up for GovCloud
- Enabling S3 MFA Delete

**Best Practice:**
- Enable MFA on root account
- Do NOT create access keys for root
- Use root only for tasks that require it
- Lock away root credentials securely

---

## Principle of Least Privilege

```
+------------------+     +------------------+     +------------------+
|     user1        |     |     user2        |     |     user3        |
|   S3 Only        |     |   EC2 Only       |     |  DynamoDB Only   |
+------------------+     +------------------+     +------------------+
         |                        |                        |
         v                        v                        v
    S3 Buckets              EC2 Instances           DynamoDB Tables
```

### Why Least Privilege?

| Benefit | Description |
|---------|-------------|
| **Security** | Limits blast radius if credentials are compromised |
| **Compliance** | Meets regulatory requirements (SOC2, HIPAA, PCI) |
| **Auditability** | Clear accountability for actions |
| **Simplicity** | Easier to troubleshoot permission issues |

---

## Quick Reference Commands

```bash
# List all users
aws iam list-users --query 'Users[].UserName'

# View user's policies
aws iam list-attached-user-policies --user-name <username>

# Create access key for programmatic access
aws iam create-access-key --user-name <username>

# Check if user has console access
aws iam get-login-profile --user-name <username>

# Delete a user (must detach policies first)
aws iam detach-user-policy --user-name <username> --policy-arn <policy-arn>
aws iam delete-user --user-name <username>
```

---

## Cleanup Commands

```bash
# Delete all lab users
for user in user1 user2 user3 user4 user5; do
  # List and detach all policies
  policies=$(aws iam list-attached-user-policies --user-name $user --query 'AttachedPolicies[].PolicyArn' --output text)
  for policy in $policies; do
    aws iam detach-user-policy --user-name $user --policy-arn $policy
  done
  # Delete user
  aws iam delete-user --user-name $user
  echo "Deleted $user"
done
```

---

## Summary

| User | Scope | Use Case |
|------|-------|----------|
| user1-3 | Single Service | Day-to-day service-specific tasks |
| user4 | All Services | General administration |
| user5 | All + Billing | Cost management + administration |
| Root | Account Level | Account-critical tasks only |

**Golden Rule:** Always use the user with the LEAST permissions needed for the task.

---

**Created**: January 2026 | **AWS Region**: us-east-1
