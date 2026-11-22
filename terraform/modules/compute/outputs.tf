output "container_id" {
  description = "the ID of the container app"
  value       = azurerm_container_app.azure_appsec_container_app.id
}

output "container_app_url" {
  description = "the stable URL/FQDN of the container app ingress"
  value       = azurerm_container_app.azure_appsec_container_app.ingress[0].fqdn
}

output "log_analytics_workspace_id" {
  description = "resource ID of the Log Analytics workspace, consumed by the monitoring module (Sentinel sits on top of it)"
  value       = azurerm_log_analytics_workspace.azure_appsec_workspace.id
}
