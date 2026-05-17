output "storage_account_name" {
  description = "Created storage account name."
  value       = azurerm_storage_account.handson.name
}

output "container_name" {
  description = "Created blob container name."
  value       = azurerm_storage_container.handson.name
}

output "resource_group_name" {
  description = "Target resource group name."
  value       = data.azurerm_resource_group.workshop.name
}
