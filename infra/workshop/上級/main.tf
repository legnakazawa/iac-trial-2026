# =============================================================================
# 【上級】ほぼ一から構築（provider / data のみ用意済み）
#
# 中級までの内容をベースに、以下をすべて自分で作成してください。
#   - random_string, locals
#   - Virtual Network と Subnet（app_integration は delegation 必須）
#   - Storage Account（public_network_access_enabled = false）
#   - Storage Container
#   - data: 共有 Private DNS Zone（privatelink.blob.core.windows.net）
#   - Private DNS Zone Virtual Network Link
#   - Private Endpoint（blob）
#   - Application Insights
#   - App Service Plan（Linux / B1）
#   - Linux Web App（Node 20 / app/ の zip デプロイは ../完成形 を参照）
#   - App Service VNet Swift Connection
#
# 完成形: ../完成形/main.tf
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

# -----------------------------------------------------------------------------
# 以下を作成してください
# -----------------------------------------------------------------------------

# resource "random_string" "suffix" { ... }

# locals { prefix, storage_account_name, tags }

# --- Network ---
# resource "azurerm_virtual_network" "main" { ... }
# resource "azurerm_subnet" "app_integration" { ... delegation ... }
# resource "azurerm_subnet" "private_endpoint" { ... }

# --- Storage ---
# resource "azurerm_storage_account" "main" { ... }
# resource "azurerm_storage_container" "main" { ... }

# --- Private DNS / PE ---
# data "azurerm_private_dns_zone" "blob" { ... }
# resource "azurerm_private_dns_zone_virtual_network_link" "blob" { ... }
# resource "azurerm_private_endpoint" "storage_blob" { ... }

# --- Monitoring ---
# resource "azurerm_application_insights" "main" { ... }

# --- App Service ---
# resource "azurerm_service_plan" "main" { ... }
# resource "azurerm_linux_web_app" "main" { ... }
# resource "azurerm_app_service_virtual_network_swift_connection" "main" { ... }
