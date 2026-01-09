# =============================================================================
# AWS S3 Static Website with CloudFront CDN and OAI
# Terraform Configuration
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# -----------------------------------------------------------------------------
# S3 Bucket - Private storage for website files
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "website" {
  bucket        = var.bucket_name
  force_destroy = true # Allows terraform destroy to delete non-empty bucket

  tags = {
    Name        = "Static Website"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Block ALL public access - Security best practice
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# CloudFront Origin Access Identity (OAI)
# Secure bridge between CloudFront and private S3 bucket
# -----------------------------------------------------------------------------

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.bucket_name}"
}

# -----------------------------------------------------------------------------
# S3 Bucket Policy - Allow only CloudFront OAI
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAI"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.website]
}

# -----------------------------------------------------------------------------
# CloudFront Distribution - Global CDN
# -----------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Static website CDN - ${var.bucket_name}"
  default_root_object = "index.html"
  price_class         = var.cloudfront_price_class
  http_version        = "http2"

  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "S3-${var.bucket_name}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.bucket_name}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400    # 24 hours
    max_ttl     = 31536000 # 1 year
  }

  # Custom 404 error page
  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/error.html"
    error_caching_min_ttl = 300
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "Static Website CDN"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  depends_on = [aws_s3_bucket_policy.website]
}

# -----------------------------------------------------------------------------
# Upload Website Files to S3
# -----------------------------------------------------------------------------

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  source       = "${path.module}/../website/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/../website/index.html")
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.website.id
  key          = "error.html"
  source       = "${path.module}/../website/error.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/../website/error.html")
}

resource "aws_s3_object" "css" {
  bucket       = aws_s3_bucket.website.id
  key          = "css/style.css"
  source       = "${path.module}/../website/css/style.css"
  content_type = "text/css"
  etag         = filemd5("${path.module}/../website/css/style.css")
}

resource "aws_s3_object" "js" {
  bucket       = aws_s3_bucket.website.id
  key          = "js/main.js"
  source       = "${path.module}/../website/js/main.js"
  content_type = "application/javascript"
  etag         = filemd5("${path.module}/../website/js/main.js")
}
