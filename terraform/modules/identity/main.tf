resource "azurerm_user_assigned_identity" "managed_identity" {
  location            = var.location
  name                = var.identity_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "assign_to_identity" {
  scope                = var.acr_id
  role_definition_name = var.role_definition_name
  principal_id         = azurerm_user_assigned_identity.managed_identity.principal_id
  # Managed identities are service principals. This has to be stated explicitly because the
  # pipeline's "RBAC Administrator" role is limited by a condition that checks the principal
  # type of every role assignment it creates (see README bootstrap step 4).
  principal_type = "ServicePrincipal"
  # The identity is created in the same apply, and Entra ID can take a minute to replicate a
  # brand new service principal. Skipping that lookup avoids a "principal not found" failure.
  skip_service_principal_aad_check = true
}
