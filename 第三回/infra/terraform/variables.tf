variable "project" {
  type        = string
  description = "Project name prefix for Azure resource naming."
  default     = "iac-workshop3"
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "japaneast"
}

variable "participant_count" {
  type        = number
  description = "Number of code-server containers and Azure Repos repositories."
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
  description = "Inbound source CIDRs allowed for code-server ports. Use [\"*\"] alone to allow all."
  default     = ["*"]

  validation {
    condition     = length(var.participant_allowed_source_address_prefixes) > 0
    error_message = "participant_allowed_source_address_prefixes must contain at least one CIDR or \"*\"."
  }

  validation {
    condition = !contains(var.participant_allowed_source_address_prefixes, "*") || (
      length(var.participant_allowed_source_address_prefixes) == 1
      && var.participant_allowed_source_address_prefixes[0] == "*"
    )
    error_message = "participant_allowed_source_address_prefixes: \"*\" must be the only entry."
  }
}

variable "organizer_allowed_source_address_prefixes" {
  type        = list(string)
  description = "Inbound source CIDRs allowed for SSH port 22. Use [\"*\"] alone to allow all."
  default     = ["*"]

  validation {
    condition     = length(var.organizer_allowed_source_address_prefixes) > 0
    error_message = "organizer_allowed_source_address_prefixes must contain at least one CIDR or \"*\"."
  }

  validation {
    condition = !contains(var.organizer_allowed_source_address_prefixes, "*") || (
      length(var.organizer_allowed_source_address_prefixes) == 1
      && var.organizer_allowed_source_address_prefixes[0] == "*"
    )
    error_message = "organizer_allowed_source_address_prefixes: \"*\" must be the only entry."
  }
}

variable "vm_disk_size_gb" {
  type        = number
  description = "OS disk size in GB."
  default     = 128
}

variable "azuredevops_org_url" {
  type        = string
  description = "Azure DevOps organization URL, e.g. https://dev.azure.com/example-org."
}

variable "azuredevops_pat" {
  type        = string
  description = "Organizer PAT used by Terraform to create Azure DevOps resources."
  sensitive   = true
}

variable "azuredevops_git_pat" {
  type        = string
  description = "PAT injected into code-server for participant git clone/push. Use a least-privileged workshop bot PAT when possible."
  sensitive   = true
}

variable "azuredevops_project_name" {
  type        = string
  description = "Azure DevOps project name. If empty, a unique name is generated."
  default     = ""
}

variable "azuredevops_repo_prefix" {
  type        = string
  description = "Prefix for participant repositories."
  default     = "iac-handson"
}

variable "terraform_version" {
  type        = string
  description = "Terraform version installed in Azure Pipelines."
  default     = "1.8.5"
}
