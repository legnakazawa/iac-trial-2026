resource "azurerm_storage_account" "tfstate" {
  name                            = "sttf${replace(local.prefix, "-", "")}"
  resource_group_name             = azurerm_resource_group.platform.name
  location                        = azurerm_resource_group.platform.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"

  tags = merge(local.tags, { scope = "terraform-state" })
}

resource "azurerm_storage_container" "tfstate" {
  for_each              = toset(local.participant_names)
  name                  = "tfstate-${each.key}"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}
