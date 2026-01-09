# =============================================================================
# Outputs for S3 Static Website with CloudFront
# =============================================================================

output "website_url" {
  description = "CloudFront website URL (HTTPS)"
  value       = "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidation)"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.website.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.website.arn
}

output "oai_id" {
  description = "Origin Access Identity ID"
  value       = aws_cloudfront_origin_access_identity.oai.id
}

output "oai_iam_arn" {
  description = "Origin Access Identity IAM ARN"
  value       = aws_cloudfront_origin_access_identity.oai.iam_arn
}

# Useful commands output
output "useful_commands" {
  description = "Useful commands for managing the deployment"
  value = {
    invalidate_cache = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.website.id} --paths '/*'"
    sync_files       = "aws s3 sync ../website/ s3://${aws_s3_bucket.website.id}/"
    view_bucket      = "aws s3 ls s3://${aws_s3_bucket.website.id}/"
  }
}
