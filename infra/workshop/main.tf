terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
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

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

data "azurerm_resource_group" "workshop" {
  name = var.resource_group_name
}

resource "azurerm_storage_account" "handson" {
  name                     = "st${var.owner}${random_string.suffix.result}"
  resource_group_name      = data.azurerm_resource_group.workshop.name
  location                 = data.azurerm_resource_group.workshop.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    owner   = var.owner
    purpose = "iac-handson"
  }
}

resource "azurerm_storage_container" "handson" {
  name                  = "contents"
  storage_account_id    = azurerm_storage_account.handson.id
  container_access_type = "private"
}
