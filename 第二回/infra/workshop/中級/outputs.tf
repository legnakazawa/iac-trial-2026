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

output "private_dns_zone_name" {
  description = "Shared private DNS zone for blob private link."
  value       = data.azurerm_private_dns_zone.blob.name
}

# TODO: 追記したリソースに応じて output を自分で定義する（../完成形/outputs.tf を参考）
