# Terraform: S3 Static Website with CloudFront CDN

> **Advanced Users**: Infrastructure as Code deployment using Terraform

This is a continuation of the [CLI-based deployment guide](../README.md). Use Terraform for version-controlled, reproducible infrastructure.

---

## Quick Start

```bash
# 1. Clone and navigate
cd terraform

# 2. Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your bucket name

# 3. Deploy
terraform init
terraform plan
terraform apply

# 4. Get website URL
terraform output website_url

# 5. Cleanup (when done)
terraform destroy
```

---

## Files Structure

```
terraform/
├── main.tf                  # Main resources (S3, CloudFront, OAI)
├── variables.tf             # Input variables with validation
├── outputs.tf               # Output values (URLs, IDs)
├── terraform.tfvars.example # Example configuration
└── README.md                # This file
```

---

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_s3_bucket` | Private S3 bucket for website files |
| `aws_s3_bucket_public_access_block` | Blocks all public access |
| `aws_s3_bucket_policy` | Allows CloudFront OAI access only |
| `aws_cloudfront_origin_access_identity` | Secure S3 access bridge |
| `aws_cloudfront_distribution` | Global CDN distribution |
| `aws_s3_object` (x4) | Website files (HTML, CSS, JS) |

**Total: 9 resources**

---

## Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `bucket_name` | Globally unique S3 bucket name | `my-website-123` |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `region` | `us-east-1` | AWS region |
| `environment` | `production` | Environment tag |
| `cloudfront_price_class` | `PriceClass_100` | Edge locations |

### Price Class Options

| Price Class | Edge Locations | Cost |
|-------------|----------------|------|
| `PriceClass_100` | North America + Europe | Lowest |
| `PriceClass_200` | + Asia, Middle East, Africa | Medium |
| `PriceClass_All` | All locations | Highest |

---

## Deployment

### Step 1: Initialize

```bash
terraform init
```

Expected output:
```
Terraform has been successfully initialized!
```

### Step 2: Plan

```bash
terraform plan
```

Review the plan - should show 9 resources to create.

### Step 3: Apply

```bash
terraform apply
```

Type `yes` when prompted. Deployment takes ~3-4 minutes (CloudFront creation).

### Step 4: Verify

```bash
# Get website URL
terraform output website_url

# Test website
curl -I $(terraform output -raw website_url)
```

Expected: `HTTP/2 200`

---

## Outputs

After deployment, Terraform provides:

```bash
# Website URL
terraform output website_url
# https://d1234567890.cloudfront.net

# CloudFront ID (for cache invalidation)
terraform output cloudfront_distribution_id

# S3 bucket name
terraform output s3_bucket_name

# Useful commands
terraform output useful_commands
```

---

## Managing Updates

### Update Website Files

```bash
# Sync local changes to S3
aws s3 sync ../website/ s3://$(terraform output -raw s3_bucket_name)/

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
    --distribution-id $(terraform output -raw cloudfront_distribution_id) \
    --paths "/*"
```

### Modify Infrastructure

```bash
# Edit main.tf or variables
terraform plan   # Review changes
terraform apply  # Apply changes
```

---

## Cleanup

### Destroy All Resources

```bash
terraform destroy
```

Type `yes` when prompted. Destruction takes ~3-4 minutes.

### What Gets Deleted

- CloudFront distribution
- Origin Access Identity
- S3 bucket (including all objects due to `force_destroy = true`)
- All bucket policies and configurations

---

## Terraform vs CLI Comparison

| Aspect | CLI | Terraform |
|--------|-----|-----------|
| **Setup Time** | Faster first deploy | Slower first deploy |
| **Reproducibility** | Manual recreation | One command |
| **State Tracking** | None | Automatic |
| **Cleanup** | Multiple commands | Single command |
| **Version Control** | Scripts only | Full IaC |
| **Team Collaboration** | Difficult | Easy |
| **Drift Detection** | None | Built-in |

---

## Troubleshooting

### Error: Bucket name already exists

```
Error: creating S3 Bucket: BucketAlreadyExists
```

**Solution**: S3 bucket names are globally unique. Change `bucket_name` in `terraform.tfvars`.

### Error: CloudFront still deploying

```
Error: CloudFront Distribution still deploying
```

**Solution**: Wait for distribution to reach "Deployed" status (~10-15 min for new distributions).

### Error: Access Denied

```
Error: Access Denied for S3 operation
```

**Solution**: Check AWS credentials have S3 and CloudFront permissions.

---

## Best Practices Applied

| Practice | Implementation |
|----------|----------------|
| **State Locking** | Use S3 backend for team environments |
| **Variable Validation** | Bucket name regex validation |
| **Resource Tagging** | `ManagedBy = Terraform` tag |
| **Force Destroy** | Enabled for easy cleanup |
| **Dependency Management** | Explicit `depends_on` for ordering |

---

## Next Steps

1. **Remote State**: Configure S3 backend for team use
2. **Custom Domain**: Add Route 53 and ACM certificate
3. **CI/CD**: Integrate with GitHub Actions
4. **Modules**: Extract reusable module

---

## Related Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [CloudFront Distribution Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution)
- [CLI Deployment Guide](../README.md)

---

**Validated**: January 2026 | **Terraform**: v1.0+ | **AWS Provider**: v5.0+
