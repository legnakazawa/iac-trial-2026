# Shared Private DNS zone for all participants (one zone per RG; participant VNets link to it).
resource "azurerm_private_dns_zone" "workshop_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.workshop.name
  tags                = local.tags
}
