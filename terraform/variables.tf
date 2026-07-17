variable "aws_region" {
  description = "Home region for the security operations account."
  type        = string
  default     = "us-east-1"
}

variable "organization_id" {
  description = "AWS Organizations ID used by data perimeter conditions."
  type        = string
  default     = "o-exampleorgid"

  validation {
    condition     = can(regex("^o-[a-z0-9]{10,32}$", var.organization_id))
    error_message = "Use an organization ID such as o-abc123def456."
  }
}

variable "workload_ou_ids" {
  description = "OU IDs that receive SCP guardrails. Empty by default for safe evaluation."
  type        = set(string)
  default     = []
}

variable "attach_guardrails" {
  description = "Explicit safety switch for SCP attachments. Test in a sandbox OU first."
  type        = bool
  default     = false
}

variable "identity_center_instance_arn" {
  description = "IAM Identity Center instance ARN. Leave null to skip permission sets."
  type        = string
  default     = null
  nullable    = true
}

variable "identity_store_id" {
  description = "Identity Store ID associated with IAM Identity Center."
  type        = string
  default     = null
  nullable    = true
}

variable "security_admin_group_id" {
  description = "Existing Identity Store group ID for security administrators."
  type        = string
  default     = null
  nullable    = true
}

variable "target_account_ids" {
  description = "Member accounts receiving the SecurityAdmin permission set."
  type        = set(string)
  default     = []
}

variable "notification_email" {
  description = "Optional email subscription for security findings. Confirmation is required."
  type        = string
  default     = null
  nullable    = true
}

variable "enable_automatic_remediation" {
  description = "When false, Lambda records the proposed action without changing S3."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags applied to supported resources."
  type        = map(string)
  default = {
    Environment = "security"
    Owner       = "cloud-security"
  }
}

