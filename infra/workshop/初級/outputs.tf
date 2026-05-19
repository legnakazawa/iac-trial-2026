output "resource_group_name" {
  description = "Shared workshop resource group."
  value       = data.azurerm_resource_group.workshop.name
}

output "owner" {
  description = "Seat identifier for this workspace."
  value       = var.owner
}

output "storage_account_name" {
  description = "Created storage account name."
  value       = azurerm_storage_account.main.name
}

output "container_name" {
  description = "Created blob container name."
  value       = azurerm_storage_container.main.name
}
