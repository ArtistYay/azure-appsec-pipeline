# Dev environment values. Nothing in here is a secret, so this file is committed.
# Secrets (like the Discord webhook URL) are passed as TF_VAR_ environment variables instead.

# ---- shared / resource group ----
resource_group_name = "rg-appsec-dev"
location            = "eastus"

# ---- storage module ----
acr_name    = "appsecdevacr01"
acr_sku     = "Basic"
environment = "dev"

# ---- identity module ----
identity_name        = "id-appsec-dev"
role_definition_name = "AcrPull"

# ---- compute module ----
container_app_environment_name    = "cae-appsec-dev"
log_analytics_workspace_name      = "log-appsec-dev"
log_analytics_workspace_sku       = "PerGB2018"
log_analytics_workspace_retention = 30
container_app_name                = "ca-appsec-dev"
revision_mode                     = "Single"
container_name                    = "appsec-app"
container_cpu                     = 0.5
container_memory                  = "1Gi"

# ---- network module ----
vnet_name             = "vnet-appsec-dev"
vnet_address_space    = ["10.0.0.0/16"]
subnet_name           = "snet-appsec-dev"
subnet_address_prefix = ["10.0.0.0/23"]
nsg_name              = "nsg-appsec-dev"

# ---- monitoring module ----
logic_app_name    = "logic-appsec-discord-dev"
action_group_name = "ag-appsec-dev"
probe_threshold   = 10
