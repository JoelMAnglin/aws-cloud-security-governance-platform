output "security_findings_topic_arn" { value = aws_sns_topic.security_findings.arn }
output "remediation_function_name" { value = aws_lambda_function.remediation.function_name }

