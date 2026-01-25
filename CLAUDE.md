# Claude Context for Lab Management

## New Lab Addition Workflow

When adding a new lab to Available Labs table:

### 1. Table Format
```
| # | Lab | Domain | Services | Duration | Level |
```

### 2. Domain Categories
- Identity (IAM labs)
- Storage (S3, EFS labs)
- Compute (ECS, EC2, Lambda labs)
- Security (KMS, Secrets Manager, WAF labs)
- Database (RDS, DynamoDB labs)
- Networking (VPC, CloudFront labs)

### 3. External Labs (from Security-Engineering-on-AWS)
- Link format: `https://github.com/schinchli/Security-Engineering-on-AWS/tree/main/Hands%20on%20Labs/...`
- URL-encode spaces as `%20` and special characters
- Domain = "Security"

### 4. Housekeeping - Validate Hyperlinks
After each update, validate:
- Local README links exist
- External GitHub links return HTTP 200
- Recommended Reading links accessible

### Repository Links
- **This Repo**: https://github.com/schinchli/How-to-Become-an-AWS-Solutions-Architect
- **Security Labs**: https://github.com/schinchli/Security-Engineering-on-AWS

### Current Labs
| # | Lab | Domain |
|---|-----|--------|
| 1 | IAM Fundamentals | Identity |
| 2 | S3 + CloudFront Static Website | Storage |
| 3 | WordPress on ECS Fargate | Compute |
| 4 | Securing RDS Credentials (Zero-Downtime Rotation) | Security |
| 5 | RDS Secrets with KMS | Security |
