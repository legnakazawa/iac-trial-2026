locals {
  prefix = "${var.project}-${random_string.suffix.result}"
  participant_names = [
    for i in range(var.participant_count) : format("user%02d", i + 1)
  ]
  azuredevops_project_name = var.azuredevops_project_name != "" ? var.azuredevops_project_name : "iac-handson-${random_string.suffix.result}"
  azuredevops_org_url      = trimsuffix(var.azuredevops_org_url, "/")

  tags = {
    project = var.project
    purpose = "workshop3-cicd-platform"
  }
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

# Platform RG: hosts the workshop VM and Terraform remote state storage.
resource "azurerm_resource_group" "platform" {
  name     = "rg-platform-${local.prefix}"
  location = var.location
  tags     = local.tags
}

# Workshop RG: participant pipelines deploy Azure resources here.
resource "azurerm_resource_group" "workshop" {
  name     = "rg-workshop-${local.prefix}"
  location = var.location
  tags     = merge(local.tags, { scope = "participant-pipeline-terraform" })
}

# -------------------------
# Network (platform)
# -------------------------

resource "azurerm_virtual_network" "platform" {
  name                = "vnet-platform-${local.prefix}"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  address_space       = ["10.20.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "vm" {
  name                 = "snet-vm"
  resource_group_name  = azurerm_resource_group.platform.name
  virtual_network_name = azurerm_virtual_network.platform.name
  address_prefixes     = ["10.20.1.0/24"]
}

resource "azurerm_public_ip" "vm" {
  name                = "pip-vm-${local.prefix}"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_security_group" "vm" {
  name                = "nsg-vm-${local.prefix}"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  tags                = local.tags

  security_rule {
    name                       = "AllowSSHOrganizer"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.organizer_allowed_source_address_prefixes
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowCodeServer"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "${var.base_port}-${var.base_port + var.participant_count - 1}"
    source_address_prefixes    = var.participant_allowed_source_address_prefixes
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "vm" {
  name                = "nic-vm-${local.prefix}"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}

resource "azurerm_network_interface_security_group_association" "vm" {
  network_interface_id      = azurerm_network_interface.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

# -------------------------
# Workshop VM
# -------------------------

resource "azurerm_linux_virtual_machine" "workshop" {
  name                = "vm-workshop-${local.prefix}"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.vm.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  # Code-server containers running on this VM authenticate Terraform via this
  # managed identity (IMDS at 169.254.169.254 is reachable from the containers).
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vm.id]
  }

  os_disk {
    name                 = "osdisk-workshop-${local.prefix}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.vm_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/templates/cloud-init.yaml.tpl", {
    admin_username = var.admin_username
  }))

  tags = local.tags
}
