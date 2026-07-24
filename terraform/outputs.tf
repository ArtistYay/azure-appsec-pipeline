output "resource_group_id" {
  description = "the ID of the resource group all resources are deployed into"
  value       = data.azurerm_resource_group.rg.id
}

output "acr_id" {
  description = "the ID of the ACR, consumed by identity (role assignment scope) and compute (image registry)"
  value       = module.storage.acr_output
}

output "acr_login_server" {
  description = "the login server URL for the ACR, consumed by compute for the image reference"
  value       = module.storage.login_server_output
}

output "managed_identity_id" {
  description = "the ID of the user-assigned managed identity, consumed by compute"
  value       = module.identity.user_assigned_identity_output
}

output "container_app_id" {
  description = "the ID of the deployed container app"
  value       = module.compute.container_id
}

output "container_app_url" {
  description = "the URL/FQDN of the deployed container app"
  value       = module.compute.container_app_url
}

output "vnet_id" {
  description = "the ID of the vnet; not currently consumed by compute, exposed for visibility (see devlog note on VNet integration gap)"
  value       = module.network.vnet_output
}

output "subnet_id" {
  description = "the ID of the subnet; not currently consumed by compute, exposed for visibility (see devlog note on VNet integration gap)"
  value       = module.network.subnet_output
}

output "nsg_id" {
  description = "the ID of the network security group; not currently consumed by compute, exposed for visibility"
  value       = module.network.nsg_output
}

output "location_policy_id" {
  description = "resource ID of the location policy definition; not consumed by other modules, exposed for visibility via terraform output"
  value       = module.policy.location_policy_id
}

output "acr_sku_policy_id" {
  description = "resource ID of the ACR SKU policy definition; not consumed by other modules, exposed for visibility via terraform output"
  value       = module.policy.acr_sku_policy_id
}

output "container_ratio_policy_id" {
  description = "resource ID of the container CPU/memory ratio policy definition; not consumed by other modules, exposed for visibility via terraform output"
  value       = module.policy.container_ratio_policy_id
}