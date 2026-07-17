locals {
  configure_identity_center = (
    var.identity_center_instance_arn != null &&
    var.identity_store_id != null &&
    var.security_admin_group_id != null
  )
}

data "aws_iam_policy_document" "workload_boundary" {
  statement {
    sid       = "AllowApprovedWorkloadServices"
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "cloudwatch:*", "dynamodb:*", "ec2:Describe*", "ecr:Get*", "ecr:BatchGet*",
      "ecr:BatchCheckLayerAvailability", "ecs:*", "events:*", "lambda:*", "logs:*",
      "s3:Get*", "s3:List*", "sns:*", "sqs:*", "ssm:GetParameter*", "xray:*"
    ]
  }

  statement {
    sid       = "DenyPrivilegeEscalation"
    effect    = "Deny"
    resources = ["*"]
    actions = [
      "iam:CreateAccessKey", "iam:CreateLoginProfile", "iam:CreatePolicyVersion",
      "iam:DeleteRolePermissionsBoundary", "iam:PutRolePermissionsBoundary",
      "iam:SetDefaultPolicyVersion", "organizations:*"
    ]
  }
}

resource "aws_iam_policy" "workload_boundary" {
  name        = "WorkloadDeveloperBoundary"
  description = "Maximum permissions for developer-created workload roles. Does not grant access."
  policy      = data.aws_iam_policy_document.workload_boundary.json
  tags        = var.tags
}

resource "aws_ssoadmin_permission_set" "security_admin" {
  count = local.configure_identity_center ? 1 : 0

  name             = "SecurityAdmin"
  description      = "Federated Tier 3 cloud security administration with short sessions."
  instance_arn     = var.identity_center_instance_arn
  session_duration = "PT2H"
  tags             = var.tags
}

resource "aws_ssoadmin_managed_policy_attachment" "security_audit" {
  count = local.configure_identity_center ? 1 : 0

  instance_arn       = var.identity_center_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_admin[0].arn
  managed_policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

resource "aws_ssoadmin_permission_set_inline_policy" "incident_response" {
  count = local.configure_identity_center ? 1 : 0

  instance_arn       = var.identity_center_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_admin[0].arn
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "Investigate"
        Effect   = "Allow"
        Action   = ["guardduty:Get*", "guardduty:List*", "securityhub:Get*", "securityhub:List*", "securityhub:BatchUpdateFindings", "cloudtrail:LookupEvents"]
        Resource = "*"
      },
      {
        Sid      = "ContainInstances"
        Effect   = "Allow"
        Action   = ["ec2:CreateTags", "ec2:ModifyInstanceAttribute", "ec2:Describe*"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_ssoadmin_account_assignment" "security_admin" {
  for_each = local.configure_identity_center ? var.target_account_ids : []

  instance_arn       = var.identity_center_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_admin[0].arn
  principal_id       = var.security_admin_group_id
  principal_type     = "GROUP"
  target_id          = each.value
  target_type        = "AWS_ACCOUNT"
}

