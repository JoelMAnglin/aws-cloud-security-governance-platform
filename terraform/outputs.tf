output "guardrail_policy_ids" {
  description = "Created SCP policy IDs."
  value       = module.organization_guardrails.policy_ids
}

output "permissions_boundary_arn" {
  description = "Managed policy ARN used as the workload role permissions boundary."
  value       = module.identity_governance.permissions_boundary_arn
}

output "security_admin_permission_set_arn" {
  description = "Security administrator permission set ARN when Identity Center is configured."
  value       = module.identity_governance.security_admin_permission_set_arn
}

