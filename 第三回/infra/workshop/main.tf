terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.69"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "workshop" {
  name = var.resource_group_name
}

resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

locals {
  prefix = "${var.owner}-${var.project}-${var.environment}-${random_string.suffix.result}"

  # Storage account: 3-24 chars, lowercase alphanumeric only.
  storage_account_name = "st${var.owner}${random_string.suffix.result}"

  tags = {
    project      = var.project
    environment  = var.environment
    owner        = var.owner
    display_name = var.display_name
    session      = "third"
  }
}

# -------------------------
# Network
# -------------------------

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.prefix}"
  location            = data.azurerm_resource_group.workshop.location
  resource_group_name = data.azurerm_resource_group.workshop.name
  address_space       = ["10.0.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "app_integration" {
  name                 = "snet-app-integration"
  resource_group_name  = data.azurerm_resource_group.workshop.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "delegation-app-service"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "private_endpoint" {
  name                 = "snet-private-endpoint"
  resource_group_name  = data.azurerm_resource_group.workshop.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# -------------------------
# Storage Account
# -------------------------

resource "azurerm_storage_account" "main" {
  name                            = local.storage_account_name
  resource_group_name             = data.azurerm_resource_group.workshop.name
  location                        = data.azurerm_resource_group.workshop.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false

  tags = local.tags
}

resource "azurerm_storage_container" "main" {
  name                  = "contents"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

# -------------------------
# Private DNS Zone for Blob (shared in workshop RG; created by organizer Terraform)
# -------------------------

data "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.workshop.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "pdnslink-blob-${local.prefix}"
  resource_group_name   = data.azurerm_resource_group.workshop.name
  private_dns_zone_name = data.azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_endpoint" "storage_blob" {
  name                = "pe-st-blob-${local.prefix}"
  location            = data.azurerm_resource_group.workshop.location
  resource_group_name = data.azurerm_resource_group.workshop.name
  subnet_id           = azurerm_subnet.private_endpoint.id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-st-blob-${local.prefix}"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.blob.id]
  }
}

# -------------------------
# Application Insights
# -------------------------

resource "azurerm_application_insights" "main" {
  name                = "appi-${local.prefix}"
  location            = data.azurerm_resource_group.workshop.location
  resource_group_name = data.azurerm_resource_group.workshop.name
  application_type    = "web"
  tags                = local.tags
}

# -------------------------
# App Service
# -------------------------

data "archive_file" "app" {
  type        = "zip"
  source_dir  = "${path.module}/app"
  output_path = "${path.module}/app.zip"
}

resource "azurerm_service_plan" "main" {
  name                = "asp-${local.prefix}"
  location            = data.azurerm_resource_group.workshop.location
  resource_group_name = data.azurerm_resource_group.workshop.name

  os_type  = "Linux"
  sku_name = "B1"

  tags = local.tags
}

resource "azurerm_linux_web_app" "main" {
  name                = "app-${replace(local.prefix, "-", "")}"
  location            = data.azurerm_resource_group.workshop.location
  resource_group_name = data.azurerm_resource_group.workshop.name
  service_plan_id     = azurerm_service_plan.main.id

  https_only      = true
  zip_deploy_file = data.archive_file.app.output_path

  site_config {
    vnet_route_all_enabled = true

    application_stack {
      node_version = "20-lts"
    }
  }

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.main.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    "STORAGE_ACCOUNT_NAME"                  = azurerm_storage_account.main.name
    "STORAGE_BLOB_ENDPOINT"                 = azurerm_storage_account.main.primary_blob_endpoint
    "OWNER"                                 = var.owner
    # TODO(session3): feature ブランチで次の行のコメントを外し、main に merge して Pipeline に反映させます。
    # "WORKSHOP_CHANGE"                      = var.display_name
  }

  tags = local.tags
}

resource "azurerm_app_service_virtual_network_swift_connection" "main" {
  app_service_id = azurerm_linux_web_app.main.id
  subnet_id      = azurerm_subnet.app_integration.id
}
