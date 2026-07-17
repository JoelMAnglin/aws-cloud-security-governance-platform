variable "attach_guardrails" { type = bool }
variable "organization_id" { type = string }
variable "workload_ou_ids" { type = set(string) }
variable "tags" { type = map(string) }

