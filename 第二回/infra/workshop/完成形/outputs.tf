output "resource_group_name" {
  description = "Shared workshop resource group."
  value       = data.azurerm_resource_group.workshop.name
}

output "owner" {
  description = "Seat identifier for this workspace."
  value       = var.owner
}

output "web_app_url" {
  description = "App Service default URL."
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "storage_account_name" {
  description = "Created storage account name."
  value       = azurerm_storage_account.main.name
}

output "private_dns_zone_name" {
  description = "Shared private DNS zone for blob private link."
  value       = data.azurerm_private_dns_zone.blob.name
}

output "private_endpoint_name" {
  description = "Storage blob private endpoint name."
  value       = azurerm_private_endpoint.storage_blob.name
}
