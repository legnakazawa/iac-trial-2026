output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "web_app_url" {
  value = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "storage_account_name" {
  value = azurerm_storage_account.main.name
}

output "private_dns_zone_name" {
  value = azurerm_private_dns_zone.blob.name
}

output "private_endpoint_name" {
  value = azurerm_private_endpoint.storage_blob.name
}
