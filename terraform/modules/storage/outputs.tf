output "acr_output" {
  description = "The ID of the ACR."
  value = azurerm_container_registry.ACR.id
}

output "login_server_output" {
  description = "outputs the login server id"
  value = azurerm_container_registry.ACR.login_server
}