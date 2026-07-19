output "container_id" {
  description = "the ID of the container app"
  value = azurerm_container_app.azure_appsec_container_app.id
}

output "container_app_url" {
  description = "the URL/FQDN of the container app"
  value = azurerm_container_app.azure_appsec_container_app.latest_revision_fqdn
}