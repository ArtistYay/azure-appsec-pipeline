terraform {
  # 1.9+ is required because acr_sku's validation references another variable (environment)
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.14.0"
    }
  }

  # partial backend config: storage account, container and auth method are passed at
  # terraform init time (backend-local.conf locally, -backend-config flags in GitHub Actions)
  backend "azurerm" {}
}

provider "azurerm" {
  features {}

  # The pipeline identity is scoped to one resource group, so it can't register resource
  # providers (a subscription-level action). They're registered once during bootstrap instead.
  resource_provider_registrations = "none"
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# storage first no module dependencies, everything else in the chain needs its outputs
module "storage" {
  source = "./modules/storage"

  resource_group_name = var.resource_group_name
  location            = var.location
  acr_name            = var.acr_name
  acr_sku             = var.acr_sku
  environment         = var.environment
}

# identity needs storage's acr_output for the role assignment scope
module "identity" {
  source = "./modules/identity"

  resource_group_name  = var.resource_group_name
  location             = var.location
  identity_name        = var.identity_name
  acr_id               = module.storage.acr_output
  role_definition_name = var.role_definition_name
}

# compute needs storage's acr login server and identity's identity id
module "compute" {
  source = "./modules/compute"

  resource_group_name               = var.resource_group_name
  location                          = var.location
  container_app_environment_name    = var.container_app_environment_name
  log_analytics_workspace_name      = var.log_analytics_workspace_name
  log_analytics_workspace_sku       = var.log_analytics_workspace_sku
  log_analytics_workspace_retention = var.log_analytics_workspace_retention
  container_app_name                = var.container_app_name
  revision_mode                     = var.revision_mode
  container_name                    = var.container_name
  container_cpu                     = var.container_cpu
  container_memory                  = var.container_memory
  user_assigned_identity_id         = [module.identity.user_assigned_identity_output]
  acr_login_server                  = module.storage.login_server_output
}

# network module independent, no module inputs required
# known gap: the container app environment is NOT deployed into this VNet yet (see README)
module "network" {
  source = "./modules/network"

  resource_group_name   = var.resource_group_name
  location              = var.location
  vnet_name             = var.vnet_name
  vnet_address_space    = var.vnet_address_space
  subnet_name           = var.subnet_name
  subnet_address_prefix = var.subnet_address_prefix
  nsg_name              = var.nsg_name
}

# policy module independent, only needs the resource group scope
module "policy" {
  source = "./modules/policy"

  assignment_scope = data.azurerm_resource_group.rg.id
}

# monitoring needs compute's workspace (Sentinel sits on top of it) and the app name to filter logs
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name        = var.resource_group_name
  location                   = var.location
  log_analytics_workspace_id = module.compute.log_analytics_workspace_id
  container_app_name         = var.container_app_name
  probe_threshold            = var.probe_threshold
  discord_webhook_url        = var.discord_webhook_url
  logic_app_name             = var.logic_app_name
  action_group_name          = var.action_group_name
}
