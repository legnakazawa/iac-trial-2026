variable "resource_group_name" {
  type        = string
  description = "Pre-created workshop resource group name (set via TF_VAR_resource_group_name)."
}

variable "owner" {
  type        = string
  description = "Unique participant identifier for resource naming (set via TF_VAR_owner)."
}
