# =============================================================================
# Outputs for IAM 101 Demo Users
# =============================================================================

output "users_created" {
  description = "List of IAM users created"
  value = {
    for key, user in aws_iam_user.users : key => {
      name = user.name
      arn  = user.arn
      role = local.users[key].role
    }
  }
}

output "user_names" {
  description = "Simple list of user names"
  value       = [for user in aws_iam_user.users : user.name]
}

output "access_matrix" {
  description = "Access matrix showing user permissions"
  value = {
    for key, config in local.users : key => {
      user_name   = aws_iam_user.users[key].name
      role        = config.role
      description = config.description
      policies    = config.policies
      s3_access       = contains(config.policies, "arn:aws:iam::aws:policy/AmazonS3FullAccess") || contains(config.policies, "arn:aws:iam::aws:policy/AdministratorAccess")
      ec2_access      = contains(config.policies, "arn:aws:iam::aws:policy/AmazonEC2FullAccess") || contains(config.policies, "arn:aws:iam::aws:policy/AdministratorAccess")
      dynamodb_access = contains(config.policies, "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess") || contains(config.policies, "arn:aws:iam::aws:policy/AdministratorAccess")
      billing_access  = contains(config.policies, "arn:aws:iam::aws:policy/job-function/Billing")
      admin_access    = contains(config.policies, "arn:aws:iam::aws:policy/AdministratorAccess")
    }
  }
}

# Access keys output (only if created)
output "access_keys" {
  description = "Access keys for users (SENSITIVE - only shown if create_access_keys=true)"
  sensitive   = true
  value = var.create_access_keys ? {
    for key, access_key in aws_iam_access_key.user_keys : key => {
      user_name         = access_key.user
      access_key_id     = access_key.id
      secret_access_key = access_key.secret
    }
  } : {}
}

output "group_info" {
  description = "Demo users group information"
  value = var.create_user_group ? {
    group_name = aws_iam_group.demo_users[0].name
    group_arn  = aws_iam_group.demo_users[0].arn
    members    = [for user in aws_iam_user.users : user.name]
  } : null
}

# Useful commands output
output "useful_commands" {
  description = "Useful AWS CLI commands for managing these users"
  value = {
    list_users           = "aws iam list-users --query 'Users[?contains(UserName, `${var.user_prefix}user`)].UserName'"
    view_user_policies   = "aws iam list-attached-user-policies --user-name <username>"
    create_access_key    = "aws iam create-access-key --user-name <username>"
    delete_access_key    = "aws iam delete-access-key --user-name <username> --access-key-id <key-id>"
    enable_console_login = "aws iam create-login-profile --user-name <username> --password <password> --password-reset-required"
  }
}

output "cleanup_command" {
  description = "Command to destroy all resources"
  value       = "terraform destroy -auto-approve"
}
