variable "enable_automatic_remediation" { type = bool }
variable "notification_email" { type = string, default = null, nullable = true }
variable "tags" { type = map(string) }

