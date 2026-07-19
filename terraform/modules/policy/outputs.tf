output "location_policy_id" {
  description = "resource ID of the location policy definition; not consumed by other modules, exposed for visibility via terraform output"
  value       = azurerm_policy_definition.location_policy.id
}

output "acr_sku_policy_id" {
  description = "resource ID of the ACR SKU policy definition; not consumed by other modules, exposed for visibility via terraform output"
  value       = azurerm_policy_definition.acr_sku_policy.id
}

output "container_ratio_policy_id" {
  description = "resource ID of the container CPU/memory ratio policy definition; not consumed by other modules, exposed for visibility via terraform output"
  value       = azurerm_policy_definition.container_ratio_policy.id
}