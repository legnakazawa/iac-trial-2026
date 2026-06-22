output "platform_resource_group_name" {
  description = "Resource group containing the workshop VM and Terraform state storage."
  value       = azurerm_resource_group.platform.name
}

output "workshop_resource_group_name" {
  description = "Resource group where participant pipelines deploy Azure resources."
  value       = azurerm_resource_group.workshop.name
}

output "workshop_private_dns_zone_blob_id" {
  description = "Shared privatelink.blob.core.windows.net zone ID in the workshop RG."
  value       = azurerm_private_dns_zone.workshop_blob.id
}

output "tfstate_resource_group_name" {
  description = "Resource group for Terraform remote state."
  value       = azurerm_resource_group.platform.name
}

output "tfstate_storage_account_name" {
  description = "Storage account for Terraform remote state."
  value       = azurerm_storage_account.tfstate.name
}

output "tfstate_container_names" {
  description = "Blob containers for Terraform remote state by participant."
  value = {
    for name, container in azurerm_storage_container.tfstate :
    name => container.name
  }
}

output "vm_public_ip" {
  description = "Public IP address of the workshop VM."
  value       = azurerm_public_ip.vm.ip_address
}

output "vm_admin_username" {
  description = "SSH username for organizer maintenance."
  value       = var.admin_username
}

output "base_port" {
  description = "First code-server port on the VM."
  value       = var.base_port
}

output "participant_count" {
  description = "Number of code-server instances configured."
  value       = var.participant_count
}

output "participant_urls" {
  description = "Browser URLs for each participant (assign in order)."
  value = {
    for idx, name in local.participant_names :
    name => "http://${azurerm_public_ip.vm.ip_address}:${var.base_port + idx}"
  }
}

output "azuredevops_project_name" {
  description = "Azure DevOps project name."
  value       = data.azuredevops_project.workshop.name
}

output "azuredevops_project_url" {
  description = "Azure DevOps project URL."
  value       = "${local.azuredevops_org_url}/${data.azuredevops_project.workshop.name}"
}

output "participant_repositories" {
  description = "Participant repository clone URLs by owner."
  value = {
    for name, repo in azuredevops_git_repository.workshop :
    name => {
      name       = repo.name
      remote_url = repo.remote_url
      web_url    = repo.web_url
    }
  }
}

output "azuredevops_git_pat" {
  description = "PAT used by code-server containers for git clone/push. Sensitive."
  value       = var.azuredevops_git_pat
  sensitive   = true
}

output "arm_tenant_id" {
  description = "Azure AD tenant ID."
  value       = data.azurerm_client_config.current.tenant_id
}

output "arm_subscription_id" {
  description = "Azure subscription ID."
  value       = data.azurerm_client_config.current.subscription_id
}
