output "permissions_boundary_arn" { value = aws_iam_policy.workload_boundary.arn }
output "security_admin_permission_set_arn" { value = try(aws_ssoadmin_permission_set.security_admin[0].arn, null) }

