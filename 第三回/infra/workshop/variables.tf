variable "resource_group_name" {
  type        = string
  description = "Pre-created workshop resource group (set by Azure Pipeline variable TF_VAR_resource_group_name)."
}

variable "owner" {
  type        = string
  description = "Unique seat identifier, e.g. user01 (set by Azure Pipeline variable TF_VAR_owner)."

  validation {
    condition     = can(regex("^user[0-9]{2}$", var.owner))
    error_message = "owner must match user01, user02, ... (injected by the workshop pipeline)."
  }
}

variable "project" {
  type        = string
  description = "Project name prefix."
  default     = "iac-handson"
}

variable "environment" {
  type        = string
  description = "Environment name."
  default     = "dev"
}

variable "display_name" {
  type        = string
  description = "Handson: set your name here (used in resource tags and workshop change)."
  default     = "unset"
}
