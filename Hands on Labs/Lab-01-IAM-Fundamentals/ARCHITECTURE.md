# Architecture Diagram

## Overview
AWS Identity and Access Management (IAM) with 5 users demonstrating the Principle of Least Privilege.

## Architecture

```mermaid
graph TB
    ROOT[Root User<br/>Complete Access<br/>MFA Enabled]
    
    USER1[User1: S3 Admin<br/>AmazonS3FullAccess]
    USER2[User2: EC2 Admin<br/>AmazonEC2FullAccess]
    USER3[User3: DynamoDB Admin<br/>AmazonDynamoDBFullAccess]
    USER4[User4: Full Admin<br/>AdministratorAccess]
    USER5[User5: Super Admin<br/>Admin + Billing]
    
    S3[Amazon S3]
    EC2[Amazon EC2]
    DDB[DynamoDB]
    LAMBDA[Lambda]
    IAM[IAM]
    BILLING[Billing]
    
    CT[CloudTrail<br/>Audit Logs]
    IAA[IAM Access Analyzer]
    
    USER1 -->|Full Access| S3
    USER2 -->|Full Access| EC2
    USER3 -->|Full Access| DDB
    USER4 -->|Full Access| S3 & EC2 & DDB & LAMBDA & IAM
    USER5 -->|Full Access| S3 & EC2 & DDB & LAMBDA & IAM & BILLING
    ROOT -->|Emergency Only| S3 & EC2 & DDB & LAMBDA & IAM & BILLING
    
    USER1 & USER2 & USER3 & USER4 & USER5 & ROOT -->|Logged| CT
    IAA -.->|Analyzes| USER1 & USER2 & USER3 & USER4 & USER5
```

## Permission Matrix

| Service | user1 | user2 | user3 | user4 | user5 | Root |
|---------|:-----:|:-----:|:-----:|:-----:|:-----:|:----:|
| S3 | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ |
| EC2 | ❌ | ✅ | ❌ | ✅ | ✅ | ✅ |
| DynamoDB | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| Lambda | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| IAM | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| Billing | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |

## Key Concepts

### Principle of Least Privilege
Each user has ONLY the minimum permissions needed for their role:
- **user1**: S3 operations only
- **user2**: EC2 operations only
- **user3**: DynamoDB operations only
- **user4**: Full AWS access (no billing)
- **user5**: Full AWS access + billing

### Security Best Practices
- ✅ No access keys created
- ✅ Least privilege permissions
- ✅ CloudTrail logging enabled
- ✅ IAM Access Analyzer for policy review
- ✅ Root user reserved for emergencies

## Deployment

```bash
# Deploy with Terraform
cd terraform
terraform init
terraform apply

# Or deploy with AWS CLI
./deploy.sh
```

## Cost
**FREE** - IAM has no charges

## Duration
**20 minutes**
