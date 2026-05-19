# =============================================================================
# 【初級】Terraform でデプロイする体験に集中
# - このファイルは Storage Account まで完成しています
# - variables.tf の display_name を自分の名前に変更してから apply してください
# - 中級以降で Network / App Service などを追記していきます
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
# Storage Account（初級のゴール）
# -------------------------

resource "azurerm_storage_account" "main" {
  name                            = local.storage_account_name
  resource_group_name             = data.azurerm_resource_group.workshop.name
  location                        = data.azurerm_resource_group.workshop.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true

  tags = local.tags
}

resource "azurerm_storage_container" "main" {
  name                  = "contents"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}
