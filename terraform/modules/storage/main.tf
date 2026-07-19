resource "azurerm_container_registry" "ACR" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.acr_sku
  tags = {
    environment = var.environment
  }
}