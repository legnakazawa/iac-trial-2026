locals {
  azuredevops_service_connection_name = "sc-${local.prefix}"
}

resource "azuredevops_project" "workshop" {
  name               = local.azuredevops_project_name
  visibility         = "private"
  version_control    = "Git"
  work_item_template = "Agile"
  description        = "IaC workshop session 3: Azure Repos + Azure Pipelines + Terraform."

  features = {
    repositories = "enabled"
    pipelines    = "enabled"
  }
}

resource "azuredevops_git_repository" "workshop" {
  for_each   = toset(local.participant_names)
  project_id = azuredevops_project.workshop.id
  name       = "${var.azuredevops_repo_prefix}-${each.key}"

  initialization {
    init_type = "Clean"
  }
}

resource "azuredevops_serviceendpoint_azurerm" "workshop" {
  project_id            = azuredevops_project.workshop.id
  service_endpoint_name = local.azuredevops_service_connection_name
  description           = "Service connection used by workshop Terraform pipelines."

  credentials {
    serviceprincipalid  = azuread_application.workshop.client_id
    serviceprincipalkey = azuread_service_principal_password.workshop.value
  }

  azurerm_spn_tenantid      = data.azurerm_client_config.current.tenant_id
  azurerm_subscription_id   = data.azurerm_client_config.current.subscription_id
  azurerm_subscription_name = data.azurerm_subscription.current.display_name

  depends_on = [
    azurerm_role_assignment.workshop_contributor,
    azurerm_role_assignment.tfstate_blob_contributor,
  ]
}

resource "azuredevops_variable_group" "workshop" {
  for_each     = toset(local.participant_names)
  project_id   = azuredevops_project.workshop.id
  name         = "${var.azuredevops_repo_prefix}-${each.key}"
  description  = "Terraform variables for ${each.key} workshop pipeline."
  allow_access = true

  variable {
    name  = "AZURE_SERVICE_CONNECTION"
    value = local.azuredevops_service_connection_name
  }

  variable {
    name  = "TF_VAR_resource_group_name"
    value = azurerm_resource_group.workshop.name
  }

  variable {
    name  = "TF_VAR_owner"
    value = each.key
  }

  variable {
    name  = "TF_STATE_RESOURCE_GROUP_NAME"
    value = azurerm_resource_group.platform.name
  }

  variable {
    name  = "TF_STATE_STORAGE_ACCOUNT_NAME"
    value = azurerm_storage_account.tfstate.name
  }

  variable {
    name  = "TF_STATE_CONTAINER_NAME"
    value = azurerm_storage_container.tfstate.name
  }

  variable {
    name  = "TF_STATE_KEY"
    value = "${each.key}/terraform.tfstate"
  }

  variable {
    name  = "TERRAFORM_VERSION"
    value = var.terraform_version
  }
}

resource "azuredevops_build_definition" "workshop" {
  for_each   = azuredevops_git_repository.workshop
  project_id = azuredevops_project.workshop.id
  name       = "pipeline-${each.key}"
  path       = "\\"

  repository {
    repo_type   = "TfsGit"
    repo_id     = each.value.id
    branch_name = "refs/heads/main"
    yml_path    = "azure-pipelines.yml"
  }

  ci_trigger {
    use_yaml = true
  }

  variable {
    name  = "AZURE_SERVICE_CONNECTION"
    value = local.azuredevops_service_connection_name
  }

  variable {
    name  = "TF_VAR_resource_group_name"
    value = azurerm_resource_group.workshop.name
  }

  variable {
    name  = "TF_VAR_owner"
    value = each.key
  }

  variable {
    name  = "TF_STATE_RESOURCE_GROUP_NAME"
    value = azurerm_resource_group.platform.name
  }

  variable {
    name  = "TF_STATE_STORAGE_ACCOUNT_NAME"
    value = azurerm_storage_account.tfstate.name
  }

  variable {
    name  = "TF_STATE_CONTAINER_NAME"
    value = azurerm_storage_container.tfstate.name
  }

  variable {
    name  = "TF_STATE_KEY"
    value = "${each.key}/terraform.tfstate"
  }

  variable {
    name  = "TERRAFORM_VERSION"
    value = var.terraform_version
  }
}

resource "azuredevops_resource_authorization" "service_connection" {
  for_each      = azuredevops_build_definition.workshop
  project_id    = azuredevops_project.workshop.id
  resource_id   = azuredevops_serviceendpoint_azurerm.workshop.id
  definition_id = each.value.id
  authorized    = true
  type          = "endpoint"
}
