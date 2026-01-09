# IAM 101: Complete Guide to AWS Identity and Access Management

> A hands-on lab for understanding AWS IAM users, permissions, root account best practices, and the principle of least privilege

---

## Table of Contents

1. [What is AWS IAM?](#what-is-aws-iam)
2. [IAM Users and Permissions](#iam-users-and-permissions)
3. [When to Use Root User](#when-to-use-root-user)
4. [Principle of Least Privilege](#principle-of-least-privilege)
5. [What We Built in This Lab](#what-we-built-in-this-lab)
6. [Terraform Deployment](#terraform-deployment)
7. [Cleanup / Decommission](#cleanup--decommission)
8. [AWS Documentation Links](#aws-documentation-links)

---

## What is AWS IAM?

**AWS Identity and Access Management (IAM)** is a web service that helps you securely control access to AWS resources. With IAM, you can centrally manage:

- **Authentication** - Who can sign in (identity)
- **Authorization** - What they can do (permissions)

### IAM Components

| Component | Description | Example |
|-----------|-------------|---------|
| **Users** | Individual identities with long-term credentials | `developer-john`, `admin-sarah` |
| **Groups** | Collection of users with shared permissions | `developers`, `admins` |
| **Roles** | Temporary identities assumable by users/services | `EC2-S3-Access-Role` |
| **Policies** | JSON documents defining permissions | `AmazonS3FullAccess` |

---

## IAM Users and Permissions

### What is an IAM User?

An **IAM user** is an identity within your AWS account that represents a person or application. Each user has:

- A unique name within the account
- Security credentials (password and/or access keys)
- Permissions defined by attached policies

### Types of Credentials

| Credential Type | Use Case | Best Practice |
|-----------------|----------|---------------|
| **Console Password** | AWS Management Console login | Enable MFA, enforce strong passwords |
| **Access Keys** | CLI/SDK/API access | Rotate regularly, never commit to code |
| **SSH Keys** | CodeCommit access | Use for git operations |

### Permission Types

```
┌─────────────────────────────────────────────────────────────────┐
│                    IAM PERMISSION TYPES                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────┐    ┌─────────────────────┐            │
│  │  Identity-Based     │    │  Resource-Based     │            │
│  │  Policies           │    │  Policies           │            │
│  │                     │    │                     │            │
│  │  Attached to:       │    │  Attached to:       │            │
│  │  • Users            │    │  • S3 Buckets       │            │
│  │  • Groups           │    │  • SQS Queues       │            │
│  │  • Roles            │    │  • KMS Keys         │            │
│  └─────────────────────┘    └─────────────────────┘            │
│                                                                 │
│  ┌─────────────────────┐    ┌─────────────────────┐            │
│  │  AWS Managed        │    │  Customer Managed   │            │
│  │  Policies           │    │  Policies           │            │
│  │                     │    │                     │            │
│  │  • Pre-built by AWS │    │  • Created by you   │            │
│  │  • Common use cases │    │  • Specific to your │            │
│  │  • Cannot modify    │    │    requirements     │            │
│  └─────────────────────┘    └─────────────────────┘            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### IAM Users vs IAM Roles

| Aspect | IAM Users | IAM Roles |
|--------|-----------|-----------|
| **Credentials** | Long-term (password, access keys) | Temporary (auto-rotated) |
| **Use Case** | Human users needing persistent access | Applications, services, cross-account |
| **Best For** | Individual developers, admins | EC2, Lambda, federated users |
| **Security** | Requires manual key rotation | Automatic credential rotation |

**AWS Recommendation:** Use IAM roles for workloads and federated access. Use IAM users only when long-term credentials are absolutely required.

---

## When to Use Root User

### What is the Root User?

The **root user** is the identity that has complete access to all AWS services and resources in the account. It's created when you first create an AWS account using an email address and password.

### Root User Best Practices

| Practice | Why |
|----------|-----|
| **Enable MFA** | Protects against credential theft |
| **Don't create access keys** | Reduces risk of key exposure |
| **Use only when required** | Limits exposure of root credentials |
| **Store credentials securely** | Prevent unauthorized access |
| **Monitor root activity** | CloudTrail logs all root actions |

### Tasks That REQUIRE Root User

Based on [AWS Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/root-user-tasks.html), only root can:

#### Account Management
- Change account settings (email, root password)
- Close your AWS account
- Restore IAM user permissions (if admin locked out)

#### Billing
- Activate IAM access to Billing console
- View certain tax invoices (VAT)

#### AWS GovCloud
- Sign up for AWS GovCloud (US)
- Request GovCloud root user access keys

#### Amazon S3
- Configure MFA Delete on S3 bucket
- Edit/delete S3 bucket policy that denies all principals

#### Amazon SQS
- Edit/delete SQS policy that denies all principals

#### Other Services
- Register as seller in Reserved Instance Marketplace
- Recover unmanageable AWS KMS key
- Link AWS account to Mechanical Turk

### When NOT to Use Root

**Never use root for:**
- Day-to-day administrative tasks
- Creating or managing resources
- Running applications
- Any task an IAM user/role can do

```
┌─────────────────────────────────────────────────────────────────┐
│                     ROOT USER DECISION TREE                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Is this task on the "Root Required" list?                      │
│           │                                                     │
│     ┌─────┴─────┐                                               │
│     │           │                                               │
│    YES          NO                                              │
│     │           │                                               │
│     ▼           ▼                                               │
│  Use Root    Use IAM User/Role                                  │
│  (with MFA)  (with least privilege)                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Principle of Least Privilege

### Definition

The **Principle of Least Privilege** means granting only the minimum permissions necessary for users, roles, and services to perform their required tasks—nothing more.

### Why It Matters

| Risk Without Least Privilege | Impact |
|------------------------------|--------|
| Compromised credentials | Attacker gains excessive access |
| Accidental deletions | User deletes critical resources |
| Compliance violations | Fails SOC2, HIPAA, PCI audits |
| Audit complexity | Hard to track who did what |

### Implementation Strategy

#### 1. Start with Zero Permissions
```json
{
  "Version": "2012-10-17",
  "Statement": []
}
```
Add permissions incrementally as needed.

#### 2. Use AWS Managed Policies as Starting Point
- `AmazonS3ReadOnlyAccess` instead of `AmazonS3FullAccess`
- `AmazonEC2ReadOnlyAccess` for monitoring-only users

#### 3. Create Custom Policies for Specific Needs
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-specific-bucket",
        "arn:aws:s3:::my-specific-bucket/*"
      ]
    }
  ]
}
```

#### 4. Use IAM Access Analyzer
- Generates least-privilege policies from CloudTrail logs
- Identifies unused permissions
- Validates policies against best practices

#### 5. Add Conditions for Extra Security
```json
{
  "Condition": {
    "IpAddress": {"aws:SourceIp": "203.0.113.0/24"},
    "Bool": {"aws:SecureTransport": "true"}
  }
}
```

### Least Privilege Hierarchy

```
┌─────────────────────────────────────────────────────────────────┐
│                  PERMISSION LEVELS (Least to Most)              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Level 1: Read-Only          ██░░░░░░░░░░░░░░░░░░  10%         │
│           View resources, no changes                            │
│                                                                 │
│  Level 2: Service-Specific   ██████░░░░░░░░░░░░░░  30%         │
│           Full access to ONE service (our user1-3)              │
│                                                                 │
│  Level 3: Power User         ████████████░░░░░░░░  60%         │
│           Most services, no IAM                                 │
│                                                                 │
│  Level 4: Administrator      ██████████████████░░  90%         │
│           All services (our user4)                              │
│                                                                 │
│  Level 5: Admin + Billing    ████████████████████  95%         │
│           All services + cost (our user5)                       │
│                                                                 │
│  Level 6: Root               ████████████████████  100%        │
│           Everything + account controls                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## What We Built in This Lab

### Overview

In this lab, we created **5 IAM users** demonstrating different permission levels:

| User | Role | AWS Policy | Permission Scope |
|------|------|------------|------------------|
| **user1** | S3 Administrator | `AmazonS3FullAccess` | S3 buckets and objects only |
| **user2** | EC2 Administrator | `AmazonEC2FullAccess` | EC2, VPC, EBS only |
| **user3** | DynamoDB Administrator | `AmazonDynamoDBFullAccess` | DynamoDB tables only |
| **user4** | Full Administrator | `AdministratorAccess` | All AWS services |
| **user5** | Super Administrator | `AdministratorAccess` + `Billing` | All services + billing |

### Access Matrix

| Service | user1 | user2 | user3 | user4 | user5 | Root |
|---------|:-----:|:-----:|:-----:|:-----:|:-----:|:----:|
| S3 | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ |
| EC2 | ❌ | ✅ | ❌ | ✅ | ✅ | ✅ |
| DynamoDB | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| Lambda | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| IAM | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| All Services | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| Billing | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Close Account | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

### Security Configuration

| Setting | Value | Reason |
|---------|-------|--------|
| Console Access | Disabled | Programmatic access only |
| Access Keys | Not created | Security best practice |
| MFA | Not configured | Demo environment |

### Why This Demonstrates Least Privilege

1. **user1-3**: Can ONLY manage their specific service
   - If user1's credentials leak → attacker can only access S3
   - Cannot escalate to other services

2. **user4**: Full admin but NO billing access
   - Can manage all services
   - Cannot view costs or make purchases

3. **user5**: Admin WITH billing
   - Only for users who need cost visibility
   - Still cannot close account or change root email

4. **Root**: Reserved for account-level tasks only

---

## Terraform Deployment

### Quick Start

```bash
# 1. Navigate to terraform directory
cd terraform

# 2. Configure variables
cp terraform.tfvars.example terraform.tfvars

# 3. Deploy
terraform init
terraform plan    # Shows 11 resources
terraform apply   # Type 'yes'

# 4. View outputs
terraform output user_names
terraform output access_matrix
```

### Files Structure

```
terraform/
├── main.tf                  # IAM users and policy attachments
├── variables.tf             # Configurable options
├── outputs.tf               # User list and access matrix
├── terraform.tfvars.example # Example configuration
└── .gitignore              # Excludes sensitive files
```

### Configuration Options

| Variable | Default | Description |
|----------|---------|-------------|
| `region` | us-east-1 | AWS region |
| `user_prefix` | "" | Prefix for user names (e.g., "demo-") |
| `create_access_keys` | false | Generate access keys (sensitive) |
| `create_user_group` | false | Group all users together |

### Resources Created

| Resource Type | Count |
|---------------|-------|
| IAM Users | 5 |
| Policy Attachments | 6 |
| **Total** | **11** |

---

## Cleanup / Decommission

### Option 1: Terraform Destroy (Recommended)

```bash
cd terraform
terraform destroy
```

Type `yes` when prompted. Deletes all users and policies.

### Option 2: AWS CLI

```bash
#!/bin/bash
for user in user1 user2 user3 user4 user5; do
  echo "Deleting $user..."

  # Delete access keys
  for key in $(aws iam list-access-keys --user-name $user \
    --query 'AccessKeyMetadata[].AccessKeyId' --output text 2>/dev/null); do
    aws iam delete-access-key --user-name $user --access-key-id $key
  done

  # Detach policies
  for policy in $(aws iam list-attached-user-policies --user-name $user \
    --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null); do
    aws iam detach-user-policy --user-name $user --policy-arn $policy
  done

  # Delete user
  aws iam delete-user --user-name $user
done
echo "Cleanup complete!"
```

### Option 3: AWS Console

1. Go to **IAM Console** → **Users**
2. Select users (user1-user5)
3. Click **Delete**
4. Confirm deletion

---

## AWS Documentation Links

### Official AWS Documentation

| Topic | Link |
|-------|------|
| **IAM User Guide** | [docs.aws.amazon.com/IAM/latest/UserGuide/](https://docs.aws.amazon.com/IAM/latest/UserGuide/) |
| **IAM Best Practices** | [docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html) |
| **Root User Tasks** | [docs.aws.amazon.com/IAM/latest/UserGuide/root-user-tasks.html](https://docs.aws.amazon.com/IAM/latest/UserGuide/root-user-tasks.html) |
| **Root User Best Practices** | [docs.aws.amazon.com/IAM/latest/UserGuide/root-user-best-practices.html](https://docs.aws.amazon.com/IAM/latest/UserGuide/root-user-best-practices.html) |
| **Least Privilege** | [docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege) |
| **IAM Access Analyzer** | [docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html](https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html) |
| **IAM Policy Reference** | [docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html) |

### Additional Resources

| Resource | Link |
|----------|------|
| **IAM Policy Simulator** | [policysim.aws.amazon.com](https://policysim.aws.amazon.com/) |
| **AWS Managed Policies** | [docs.aws.amazon.com/aws-managed-policy/latest/reference/policy-list.html](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/policy-list.html) |
| **Security Best Practices** | [docs.aws.amazon.com/wellarchitected/latest/security-pillar/](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/) |
| **IAM Identity Center** | [docs.aws.amazon.com/singlesignon/latest/userguide/](https://docs.aws.amazon.com/singlesignon/latest/userguide/) |

### AWS Training

| Course | Link |
|--------|------|
| **AWS Security Fundamentals** | [aws.amazon.com/training/learn-about/security/](https://aws.amazon.com/training/learn-about/security/) |
| **IAM Foundations** | [explore.skillbuilder.aws](https://explore.skillbuilder.aws/learn/course/internal/view/elearning/120/introduction-to-aws-identity-and-access-management-iam) |

---

## Summary

### Key Takeaways

1. **IAM Users** have long-term credentials; use **IAM Roles** for applications
2. **Root User** should only be used for account-level tasks that require it
3. **Principle of Least Privilege** = minimum permissions needed for the task
4. **Start restrictive**, add permissions as needed
5. **Use IAM Access Analyzer** to identify unused permissions
6. **Enable MFA** on all accounts, especially root

### Permission Recommendation by Role

| Role Type | Recommended Approach |
|-----------|---------------------|
| Developers | Service-specific access (like user1-3) |
| DevOps | Power user or scoped admin |
| Administrators | Full admin (like user4) |
| Finance/Billing | Admin + Billing (like user5) |
| Account Management | Root user (rarely, with MFA) |

### Golden Rule

> **Always use the user with the LEAST permissions needed for the task.**

---

**Created**: January 2026 | **Terraform**: v1.0+ | **AWS Provider**: v5.0+

**Sources**: [AWS IAM Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/), [AWS Security Best Practices](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/)
