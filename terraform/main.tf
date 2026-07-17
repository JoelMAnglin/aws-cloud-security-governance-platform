module "organization_guardrails" {
  source = "./modules/organization-guardrails"

  attach_guardrails = var.attach_guardrails
  organization_id   = var.organization_id
  workload_ou_ids   = var.workload_ou_ids
  tags              = var.tags
}

module "identity_governance" {
  source = "./modules/identity-governance"

  identity_center_instance_arn = var.identity_center_instance_arn
  identity_store_id            = var.identity_store_id
  security_admin_group_id      = var.security_admin_group_id
  target_account_ids           = var.target_account_ids
  tags                         = var.tags
}

module "security_operations" {
  source = "./modules/security-operations"

  enable_automatic_remediation = var.enable_automatic_remediation
  notification_email           = var.notification_email
  tags                         = var.tags
}
