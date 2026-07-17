locals {
  guardrails = {
    protect_security_services = {
      name        = "ProtectSecurityServices"
      description = "Prevent workload administrators from disabling centralized security services."
      content = {
        Version = "2012-10-17"
        Statement = [{
          Sid    = "DenyDisablingSecurityServices"
          Effect = "Deny"
          Action = [
            "cloudtrail:DeleteTrail",
            "cloudtrail:StopLogging",
            "config:DeleteConfigurationRecorder",
            "config:StopConfigurationRecorder",
            "guardduty:DeleteDetector",
            "guardduty:DisassociateFromAdministratorAccount",
            "guardduty:StopMonitoringMembers",
            "securityhub:DisableSecurityHub",
            "securityhub:DisassociateFromAdministratorAccount"
          ]
          Resource = "*"
          Condition = {
            ArnNotLike = {
              "aws:PrincipalArn" = [
                "arn:aws:iam::*:role/OrganizationAccountAccessRole",
                "arn:aws:iam::*:role/AWSControlTowerExecution"
              ]
            }
          }
        }]
      }
    }
    restrict_regions = {
      name        = "RestrictRegions"
      description = "Deny non-global services outside approved regions. Customize before attachment."
      content = {
        Version = "2012-10-17"
        Statement = [{
          Sid    = "DenyOutsideApprovedRegions"
          Effect = "Deny"
          NotAction = [
            "a4b:*", "acm:*", "aws-marketplace-management:*", "aws-marketplace:*",
            "aws-portal:*", "budgets:*", "ce:*", "chime:*", "cloudfront:*",
            "config:*", "cur:*", "directconnect:*", "ec2:DescribeRegions",
            "ec2:DescribeTransitGateways", "ec2:DescribeVpnGateways", "fms:*",
            "globalaccelerator:*", "health:*", "iam:*", "importexport:*",
            "kms:*", "mobileanalytics:*", "networkmanager:*", "organizations:*",
            "pricing:*", "route53:*", "route53domains:*", "s3:GetAccountPublic*",
            "s3:ListAllMyBuckets", "s3:ListMultiRegionAccessPoints", "shield:*",
            "sts:*", "support:*", "trustedadvisor:*", "waf-regional:*", "waf:*",
            "wafv2:*", "wellarchitected:*"
          ]
          Resource  = "*"
          Condition = { StringNotEquals = { "aws:RequestedRegion" = ["us-east-1", "us-west-2"] } }
        }]
      }
    }
    data_perimeter = {
      name        = "DataPerimeter"
      description = "Deny untrusted principals from accessing organization-owned resources."
      content = {
        Version = "2012-10-17"
        Statement = [{
          Sid      = "DenyAccessFromOutsideOrganization"
          Effect   = "Deny"
          Action   = ["s3:*", "secretsmanager:*", "kms:*"]
          Resource = "*"
          Condition = {
            StringNotEqualsIfExists = { "aws:PrincipalOrgID" = var.organization_id }
            BoolIfExists            = { "aws:PrincipalIsAWSService" = "false" }
          }
        }]
      }
    }
  }

  attachments = var.attach_guardrails ? {
    for pair in setproduct(keys(local.guardrails), var.workload_ou_ids) : "${pair[0]}:${pair[1]}" => {
      policy = pair[0]
      target = pair[1]
    }
  } : {}
}

resource "aws_organizations_policy" "guardrail" {
  for_each = local.guardrails

  name        = each.value.name
  description = each.value.description
  type        = "SERVICE_CONTROL_POLICY"
  content     = jsonencode(each.value.content)
  tags        = var.tags
}

resource "aws_organizations_policy_attachment" "guardrail" {
  for_each = local.attachments

  policy_id = aws_organizations_policy.guardrail[each.value.policy].id
  target_id = each.value.target
}

