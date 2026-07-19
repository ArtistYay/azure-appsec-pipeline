resource "azurerm_log_analytics_workspace" "azure_appsec_workspace" {
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_workspace_sku
  retention_in_days   = var.log_analytics_workspace_retention
}

resource "azurerm_container_app_environment" "azure_appsec_container_app_environment" {
  name                       = var.container_app_environment_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.azure_appsec_workspace.id
}

resource "azurerm_container_app" "azure_appsec_container_app" {
  name                         = var.container_app_name
  container_app_environment_id = azurerm_container_app_environment.azure_appsec_container_app_environment.id
  resource_group_name          = var.resource_group_name
  revision_mode                = var.revision_mode

  template {
    container {
      name   = var.container_name
      image  = "${var.acr_login_server}/${var.container_image}"
      cpu    = var.container_cpu
      memory = var.container_memory
    }
  }

  identity {
    type = "UserAssigned"
    identity_ids = var.user_assigned_identity_id
  }

  registry {
    server = var.acr_login_server
    identity = var.user_assigned_identity_id[0]
  }

}