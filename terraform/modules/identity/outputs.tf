output "user_assigned_identity_output" {
  description = "outputs the managened identity (user-assigned) id"
  value       = azurerm_user_assigned_identity.managed_identity.id
}