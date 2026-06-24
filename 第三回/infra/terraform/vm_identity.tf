# Role assignments for the workshop VM's user-assigned managed identity.
# Participants run `terraform init/plan/apply` directly inside their code-server
# container; the azurerm provider/backend authenticate through this identity via
# IMDS (ARM_USE_MSI=true + ARM_CLIENT_ID), so no service principal secret is
# injected. A user-assigned identity is used (instead of system-assigned) so its
# principal_id/client_id are known at plan time and role assignments resolve
# deterministically.
resource "azurerm_user_assigned_identity" "vm" {
  name                = "id-vm-${local.prefix}"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  tags                = local.tags
}

# Deploy participant resources into the workshop RG.
resource "azurerm_role_assignment" "vm_workshop_contributor" {
  scope                = azurerm_resource_group.workshop.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.vm.principal_id
}

# Read/write the Terraform remote state blobs (AAD data-plane auth).
resource "azurerm_role_assignment" "vm_tfstate_blob_contributor" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.vm.principal_id
}
