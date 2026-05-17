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

variable "allowed_source_address_prefix" {
  type        = string
  description = "CIDR or * for NSG inbound rule on code-server ports. Restrict to corporate egress IP when possible."
  default     = "*"
}

variable "vm_disk_size_gb" {
  type        = number
  description = "OS disk size in GB."
  default     = 128
}
