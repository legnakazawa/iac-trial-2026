output "platform_resource_group_name" {
  description = "Resource group containing the workshop VM."
  value       = azurerm_resource_group.platform.name
}

output "workshop_resource_group_name" {
  description = "Resource group where participants run terraform apply."
  value       = azurerm_resource_group.workshop.name
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
  value = [
    for i in range(var.participant_count) :
    "http://${azurerm_public_ip.vm.ip_address}:${var.base_port + i}"
  ]
}

output "arm_client_id" {
  description = "Service principal client ID for participant Terraform (sensitive)."
  value       = azuread_application.workshop.client_id
  sensitive   = true
}

output "arm_client_secret" {
  description = "Service principal client secret for participant Terraform (sensitive)."
  value       = azuread_service_principal_password.workshop.value
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

data "azurerm_client_config" "current" {}
