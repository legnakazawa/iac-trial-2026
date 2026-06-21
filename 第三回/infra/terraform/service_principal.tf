resource "azuread_application" "workshop" {
  display_name = "sp-workshop3-${local.prefix}"
}

resource "azuread_service_principal" "workshop" {
  client_id = azuread_application.workshop.client_id
}

resource "azuread_service_principal_password" "workshop" {
  service_principal_id = azuread_service_principal.workshop.id
}

resource "azurerm_role_assignment" "workshop_contributor" {
  scope                = azurerm_resource_group.workshop.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.workshop.object_id
}

resource "azurerm_role_assignment" "tfstate_blob_contributor" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.workshop.object_id
}
