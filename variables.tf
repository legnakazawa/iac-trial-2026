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

variable "owner" {
  type        = string
  description = "Owner name."
  default     = "handson-user"
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "japaneast"
}
