resource "azurerm_user_assigned_identity" "managed_identity" {
  location            = var.location
  name                = var.identity_name
  resource_group_name = var.resource_group_name
}
resource "azurerm_role_assignment" "assign_to_identity" {
  scope                = var.acr_id
  role_definition_name = var.role_definition_name
  principal_id         = azurerm_user_assigned_identity.managed_identity.principal_id
}