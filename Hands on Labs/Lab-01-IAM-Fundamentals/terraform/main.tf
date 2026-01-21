# =============================================================================
# IAM 101: Terraform Configuration for Demo IAM Users
# Creates 5 users with different permission levels for training purposes
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

# =============================================================================
# Local Variables
# =============================================================================

locals {
  common_tags = {
    Environment = var.environment
    Purpose     = "IAM-101-Training"
    ManagedBy   = "Terraform"
    CreatedBy   = var.created_by
  }

  # User definitions with their roles and policies
  users = {
    user1 = {
      role        = "S3-Admin"
      description = "S3 Administrator - Bucket and object management"
      policies    = ["arn:aws:iam::aws:policy/AmazonS3FullAccess"]
    }
    user2 = {
      role        = "EC2-Admin"
      description = "EC2 Administrator - Instance and VPC management"
      policies    = ["arn:aws:iam::aws:policy/AmazonEC2FullAccess"]
    }
    user3 = {
      role        = "DynamoDB-Admin"
      description = "DynamoDB Administrator - Table management"
      policies    = ["arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"]
    }
    user4 = {
      role        = "Full-Admin"
      description = "Full Administrator - All AWS services"
      policies    = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }
    user5 = {
      role        = "Super-Admin"
      description = "Super Administrator - All services + Billing"
      policies = [
        "arn:aws:iam::aws:policy/AdministratorAccess",
        "arn:aws:iam::aws:policy/job-function/Billing"
      ]
    }
  }
}

# =============================================================================
# IAM Users
# =============================================================================

resource "aws_iam_user" "users" {
  for_each = local.users

  name = "${var.user_prefix}${each.key}"

  tags = merge(local.common_tags, {
    Name        = "${var.user_prefix}${each.key}"
    Role        = each.value.role
    Description = each.value.description
  })
}

# =============================================================================
# IAM User Policy Attachments
# =============================================================================

# Flatten the user-policy combinations for attachment
locals {
  user_policy_attachments = flatten([
    for user_key, user_config in local.users : [
      for policy_arn in user_config.policies : {
        user_key   = user_key
        policy_arn = policy_arn
        unique_key = "${user_key}-${replace(policy_arn, "/", "-")}"
      }
    ]
  ])
}

resource "aws_iam_user_policy_attachment" "user_policies" {
  for_each = { for attachment in local.user_policy_attachments : attachment.unique_key => attachment }

  user       = aws_iam_user.users[each.value.user_key].name
  policy_arn = each.value.policy_arn
}

# =============================================================================
# Optional: Create Access Keys (disabled by default for security)
# =============================================================================

resource "aws_iam_access_key" "user_keys" {
  for_each = var.create_access_keys ? local.users : {}

  user = aws_iam_user.users[each.key].name
}

# =============================================================================
# IAM Group for all demo users (optional, for easier management)
# =============================================================================

resource "aws_iam_group" "demo_users" {
  count = var.create_user_group ? 1 : 0
  name  = "${var.user_prefix}demo-users-group"
}

resource "aws_iam_group_membership" "demo_users" {
  count = var.create_user_group ? 1 : 0
  name  = "${var.user_prefix}demo-users-membership"
  group = aws_iam_group.demo_users[0].name
  users = [for user in aws_iam_user.users : user.name]
}
