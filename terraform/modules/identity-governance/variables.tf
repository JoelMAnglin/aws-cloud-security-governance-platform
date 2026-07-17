variable "identity_center_instance_arn" {
  type     = string
  default  = null
  nullable = true
}
variable "identity_store_id" {
  type     = string
  default  = null
  nullable = true
}
variable "security_admin_group_id" {
  type     = string
  default  = null
  nullable = true
}
variable "target_account_ids" {
  type    = set(string)
  default = []
}
variable "tags" { type = map(string) }
