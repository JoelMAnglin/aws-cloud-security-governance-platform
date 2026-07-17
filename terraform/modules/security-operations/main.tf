data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_securityhub_account" "this" {
  enable_default_standards  = true
  control_finding_generator = "SECURITY_CONTROL"
}

resource "aws_guardduty_detector" "this" {
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  tags = var.tags
}

resource "aws_guardduty_detector_feature" "this" {
  for_each = toset(["S3_DATA_EVENTS", "EKS_AUDIT_LOGS", "EBS_MALWARE_PROTECTION"])

  detector_id = aws_guardduty_detector.this.id
  name        = each.value
  status      = "ENABLED"
}

data "aws_iam_policy_document" "notification_key" {
  statement {
    sid       = "EnableAccountAdministration"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
  statement {
    sid       = "AllowSnsUse"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey*"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_kms_key" "notifications" {
  description             = "Encrypt high-severity cloud security notifications"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.notification_key.json
  tags                    = var.tags
}

resource "aws_kms_alias" "notifications" {
  name          = "alias/cloud-security-notifications"
  target_key_id = aws_kms_key.notifications.key_id
}

resource "aws_sns_topic" "security_findings" {
  name              = "cloud-security-high-severity-findings"
  kms_master_key_id = aws_kms_key.notifications.arn
  tags              = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  count = var.notification_email == null ? 0 : 1

  topic_arn = aws_sns_topic.security_findings.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

data "archive_file" "remediation" {
  type        = "zip"
  source_file = "${path.root}/../lambda/remediate_public_s3.py"
  output_path = "${path.root}/remediate_public_s3.zip"
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "remediation" {
  name               = "security-hub-s3-remediation"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "remediation" {
  statement {
    sid       = "WriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/security-hub-s3-remediation:*"]
  }
  statement {
    sid       = "BlockPublicS3"
    effect    = "Allow"
    actions   = ["s3:PutAccountPublicAccessBlock", "s3:PutBucketPublicAccessBlock"]
    resources = ["*"]
  }
  statement {
    sid       = "UpdateFinding"
    effect    = "Allow"
    actions   = ["securityhub:BatchUpdateFindings"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "remediation" {
  name   = "least-privilege-remediation"
  role   = aws_iam_role.remediation.id
  policy = data.aws_iam_policy_document.remediation.json
}

resource "aws_lambda_function" "remediation" {
  function_name                  = "security-hub-s3-remediation"
  description                    = "Blocks public access for S3 findings; defaults to dry-run."
  filename                       = data.archive_file.remediation.output_path
  source_code_hash               = data.archive_file.remediation.output_base64sha256
  role                           = aws_iam_role.remediation.arn
  handler                        = "remediate_public_s3.lambda_handler"
  runtime                        = "python3.13"
  timeout                        = 30
  memory_size                    = 256
  reserved_concurrent_executions = 5

  environment {
    variables = { DRY_RUN = tostring(!var.enable_automatic_remediation) }
  }

  tracing_config { mode = "Active" }
  tags = var.tags
}

resource "aws_cloudwatch_log_group" "remediation" {
  name              = "/aws/lambda/${aws_lambda_function.remediation.function_name}"
  retention_in_days = 90
  kms_key_id        = aws_kms_key.logs.arn
  tags              = var.tags
}

resource "aws_kms_key" "logs" {
  description             = "Encrypt security remediation logs"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_kms_alias" "logs" {
  name          = "alias/cloud-security-remediation-logs"
  target_key_id = aws_kms_key.logs.key_id
}

resource "aws_cloudwatch_event_rule" "security_hub_s3" {
  name        = "security-hub-public-s3-remediation"
  description = "Routes new high-severity S3 findings to bounded remediation."
  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = { findings = {
      Severity  = { Label = ["HIGH", "CRITICAL"] }
      Workflow  = { Status = ["NEW", "NOTIFIED"] }
      Resources = { Type = ["AwsS3Bucket"] }
    } }
  })
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "remediation" {
  rule      = aws_cloudwatch_event_rule.security_hub_s3.name
  target_id = "S3RemediationLambda"
  arn       = aws_lambda_function.remediation.arn

  retry_policy {
    maximum_event_age_in_seconds = 3600
    maximum_retry_attempts       = 2
  }
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.remediation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.security_hub_s3.arn
}

resource "aws_cloudwatch_event_rule" "high_severity_findings" {
  name        = "high-severity-cloud-security-findings"
  description = "Routes high-severity GuardDuty and Security Hub findings to security operations."
  event_pattern = jsonencode({
    source = ["aws.guardduty", "aws.securityhub"]
  })
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "notifications" {
  rule      = aws_cloudwatch_event_rule.high_severity_findings.name
  target_id = "SecurityFindingsSns"
  arn       = aws_sns_topic.security_findings.arn
}

data "aws_iam_policy_document" "sns_events" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.security_findings.arn]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.high_severity_findings.arn]
    }
  }
}

resource "aws_sns_topic_policy" "security_findings" {
  arn    = aws_sns_topic.security_findings.arn
  policy = data.aws_iam_policy_document.sns_events.json
}
