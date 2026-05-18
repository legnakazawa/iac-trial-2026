variable "project" {
  type        = string
  description = "Project name prefix for resource naming."
  default     = "iac-workshop"
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "japaneast"
}

variable "participant_count" {
  type        = number
  description = "Number of code-server containers (one per participant)."
  default     = 10

  validation {
    condition     = var.participant_count >= 1 && var.participant_count <= 50
    error_message = "participant_count must be between 1 and 50."
  }
}

variable "base_port" {
  type        = number
  description = "First host port for code-server (subsequent ports increment by 1)."
  default     = 8001
}

variable "vm_size" {
  type        = string
  description = "Azure VM SKU. Use Standard_D4s_v5 or larger for 10+ participants."
  default     = "Standard_D4s_v5"
}

variable "admin_username" {
  type        = string
  description = "Linux admin username on the workshop VM (organizer SSH only)."
  default     = "azureuser"
}

variable "admin_ssh_public_key" {
  type        = string
  description = "SSH public key for organizer access to the VM."
}

variable "participant_allowed_source_address_prefixes" {
  type        = list(string)
  description = "Inbound source CIDRs allowed for code-server ports (participant browser access). Example: [\"203.0.113.0/24\", \"198.51.100.50/32\"]. Use [\"*\"] to allow all."
  default     = ["*"]

  validation {
    condition     = length(var.participant_allowed_source_address_prefixes) > 0
    error_message = "participant_allowed_source_address_prefixes must contain at least one CIDR or \"*\"."
  }
}

variable "organizer_allowed_source_address_prefixes" {
  type        = list(string)
  description = "Inbound source CIDRs allowed for SSH port 22 (organizer maintenance). Example: [\"203.0.113.10/32\"]. Use [\"*\"] to allow all."
  default     = ["*"]

  validation {
    condition     = length(var.organizer_allowed_source_address_prefixes) > 0
    error_message = "organizer_allowed_source_address_prefixes must contain at least one CIDR or \"*\"."
  }
}

variable "vm_disk_size_gb" {
  type        = number
  description = "OS disk size in GB."
  default     = 128
}
