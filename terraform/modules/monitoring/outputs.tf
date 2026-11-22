output "sentinel_rule_id" {
  description = "resource ID of the Sentinel scheduled analytics rule; not consumed by other modules, exposed for visibility"
  value       = azurerm_sentinel_alert_rule_scheduled.recon_probing.id
}

output "discord_notifications_enabled" {
  description = "whether the Discord notification path was built (true only when a webhook URL was supplied)"
  value       = local.discord_enabled
}
