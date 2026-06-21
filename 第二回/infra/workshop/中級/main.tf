# =============================================================================
# 【中級】初級の内容 + ネットワーク。一部を自分で調べて追記
#
# TODO 一覧（リソース定義は自分で調べて記述すること）:
#   1. azurerm_private_endpoint（Storage Blob 用 Private Endpoint）
#   2. azurerm_application_insights
#
# ヒント:
#   - 完成形は ../完成形/main.tf を参照
#   - Private DNS ゾーンは主催者が RG 内に作成済み（data.azurerm_private_dns_zone.blob）
#   - Private Endpoint 用サブネットは azurerm_subnet.private_endpoint
# =============================================================================

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

  storage_account_name = "st${var.owner}${random_string.suffix.result}"

  tags = {
    project      = var.project
    environment  = var.environment
    owner        = var.owner
    display_name = var.display_name
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
# Private DNS Zone for Blob（共有ゾーン / 主催者が作成済み）
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

# -------------------------
# TODO 1: Private Endpoint
# -------------------------

# -------------------------
# TODO 2: Application Insights
# -------------------------
