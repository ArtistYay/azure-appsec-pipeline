locals {
  # One detection query, used by BOTH the Sentinel rule (creates the incident) and the
  # Azure Monitor alert (sends the Discord message), so the two can never drift apart.
  #
  # The empty datatable in the union is a known trick: ContainerAppConsoleLogs_CL doesn't
  # exist until the app writes its first log line, and Sentinel refuses to save a rule
  # whose table is missing. isfuzzy=true lets the query validate before any logs arrive.
  recon_probe_query = <<-QUERY
    union isfuzzy=true
        (datatable(TimeGenerated: datetime, ContainerAppName_s: string, Log_s: string)[]),
        (ContainerAppConsoleLogs_CL)
    | where TimeGenerated > ago(5m)
    | where ContainerAppName_s == "${var.container_app_name}"
    | where Log_s startswith "{"
    | extend AppEvent = parse_json(Log_s)
    | extend EventName = tostring(AppEvent.event),
             ClientIP = tostring(AppEvent.client_ip),
             RequestPath = tostring(AppEvent.path),
             RequestMethod = tostring(AppEvent.method)
    | where EventName in ("not_found", "method_not_allowed")
    | summarize Attempts = count(),
                DistinctPaths = dcount(RequestPath),
                SamplePaths = make_set(RequestPath, 10),
                Methods = make_set(RequestMethod, 5),
                FirstSeen = min(TimeGenerated),
                LastSeen = max(TimeGenerated)
          by ClientIP
    | where Attempts >= ${var.probe_threshold}
  QUERY

  # count can't use a sensitive value directly. nonsensitive() here only reveals
  # whether a webhook was provided (true/false), never the URL itself.
  discord_enabled = nonsensitive(var.discord_webhook_url != "")
}

# ---- Sentinel ----

# Sentinel isn't a separate workspace, it's switched on over the Log Analytics workspace
# the compute module already creates.
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "sentinel" {
  workspace_id = var.log_analytics_workspace_id
}

resource "azurerm_sentinel_alert_rule_scheduled" "recon_probing" {
  name                       = "web-recon-probing"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.sentinel.workspace_id
  display_name               = "Web recon: repeated 404/405 probes against ${var.container_app_name}"
  description                = "One client IP hit ${var.probe_threshold}+ paths that don't exist, or used disallowed HTTP methods, within 5 minutes. Usually a scanner, directory brute force, or method tampering."
  severity                   = "Medium"
  query                      = local.recon_probe_query
  query_frequency            = "PT5M"
  query_period               = "PT5M"
  trigger_operator           = "GreaterThan"
  trigger_threshold          = 0
  tactics                    = ["Reconnaissance", "Discovery"]

  # one alert per attacking IP, so two scanners show up as two alerts
  event_grouping {
    aggregation_method = "AlertPerResult"
  }

  # tells Sentinel the ClientIP column is an IP entity, so incidents can be pivoted on it
  entity_mapping {
    entity_type = "IP"
    field_mapping {
      identifier  = "Address"
      column_name = "ClientIP"
    }
  }
}

# ---- Discord notification (optional, only built when a webhook URL is supplied) ----

# Logic App with an HTTP trigger: Azure Monitor calls it, it reformats the alert and posts to Discord.
resource "azurerm_logic_app_workflow" "discord_notifier" {
  count               = local.discord_enabled ? 1 : 0
  name                = var.logic_app_name
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_logic_app_trigger_http_request" "alert_in" {
  count        = local.discord_enabled ? 1 : 0
  name         = "azure-monitor-alert"
  logic_app_id = azurerm_logic_app_workflow.discord_notifier[0].id
  schema       = jsonencode({ type = "object", properties = {} })
}

resource "azurerm_logic_app_action_http" "post_to_discord" {
  count        = local.discord_enabled ? 1 : 0
  name         = "post-to-discord"
  logic_app_id = azurerm_logic_app_workflow.discord_notifier[0].id
  method       = "POST"
  uri          = var.discord_webhook_url
  headers      = { "Content-Type" = "application/json" }

  # @{...} is Logic Apps expression syntax, filled in at run time from the alert payload
  # (Azure Monitor common alert schema).
  body = jsonencode({
    content = "**Alert:** @{triggerBody()?['data']?['essentials']?['alertRule']}\n**Severity:** @{triggerBody()?['data']?['essentials']?['severity']}\n**Fired:** @{triggerBody()?['data']?['essentials']?['firedDateTime']}\nOpen Microsoft Sentinel > Incidents for the client IP and the paths it probed."
  })
}

resource "azurerm_monitor_action_group" "discord" {
  count               = local.discord_enabled ? 1 : 0
  name                = var.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = "appsecalert"

  logic_app_receiver {
    name                    = "discord-logic-app"
    resource_id             = azurerm_logic_app_workflow.discord_notifier[0].id
    callback_url            = azurerm_logic_app_trigger_http_request.alert_in[0].callback_url
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "recon_probing" {
  count                = local.discord_enabled ? 1 : 0
  name                 = "web-recon-probing-notify"
  resource_group_name  = var.resource_group_name
  location             = var.location
  description          = "Same query as the Sentinel rule web-recon-probing. Sentinel creates the incident, this alert sends the Discord message."
  severity             = 2
  scopes               = [var.log_analytics_workspace_id]
  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"

  criteria {
    query                   = local.recon_probe_query
    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.discord[0].id]
  }
}
