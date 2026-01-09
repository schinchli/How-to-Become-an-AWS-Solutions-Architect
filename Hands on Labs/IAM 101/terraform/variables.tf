# =============================================================================
# Variables for IAM 101 Demo Users
# =============================================================================

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment tag (e.g., training, demo, lab)"
  type        = string
  default     = "training"
}

variable "created_by" {
  description = "Creator identifier for tagging"
  type        = string
  default     = "IAM-101-Lab"
}

variable "user_prefix" {
  description = "Prefix for all user names (useful for multiple deployments)"
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]*$", var.user_prefix))
    error_message = "User prefix can only contain alphanumeric characters, hyphens, and underscores."
  }
}

variable "create_access_keys" {
  description = "Whether to create access keys for programmatic access (SECURITY: disabled by default)"
  type        = bool
  default     = false
}

variable "create_user_group" {
  description = "Whether to create a group containing all demo users"
  type        = bool
  default     = false
}
