variable "location" {
  description = "where the resources will be deployed"
  type        = string

  validation {
    condition     = contains(["eastus", "eastus2"], var.location)
    error_message = "The location must be eastus or eastus2."
  }
}

variable "resource_group_name" {
  description = "the name of the resource group"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "resource ID of the Log Analytics workspace Sentinel is enabled on"
  type        = string
}

variable "container_app_name" {
  description = "name of the container app whose logs the detection rule watches"
  type        = string
}

variable "probe_threshold" {
  description = "how many 404/405 responses one client IP needs in 5 minutes before it counts as probing"
  type        = number
  default     = 10

  validation {
    condition     = var.probe_threshold >= 3
    error_message = "probe_threshold must be at least 3, lower values alert on normal typos and broken links."
  }
}

variable "discord_webhook_url" {
  description = "Discord webhook URL for alert notifications. Leave empty to skip building the notification path."
  type        = string
  default     = ""
  sensitive   = true

  validation {
    condition     = var.discord_webhook_url == "" || startswith(var.discord_webhook_url, "https://discord.com/api/webhooks/")
    error_message = "discord_webhook_url must be empty or a https://discord.com/api/webhooks/ URL."
  }
}

variable "logic_app_name" {
  description = "name of the Logic App that forwards alerts to Discord"
  type        = string
}

variable "action_group_name" {
  description = "name of the Azure Monitor action group that calls the Logic App"
  type        = string
}
