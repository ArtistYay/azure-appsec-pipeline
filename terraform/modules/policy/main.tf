resource "azurerm_policy_definition" "location_policy" {
  name         = "enforceAllowedLocations"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Enforce allowed resource locations"
  metadata     = <<METADATA
    { "category": "General" }
METADATA

  policy_rule = <<POLICY_RULE
 {
    "if": {
      "field": "location",
      "notIn": "[parameters('allowedLocations')]"
    },
    "then": { "effect": "deny" }
  }
POLICY_RULE

  parameters = <<PARAMETERS
 {
    "allowedLocations": {
      "type": "Array",
      "defaultValue": ${jsonencode(var.allowed_locations)},
      "metadata": {
        "description": "The list of allowed locations for resources.",
        "displayName": "Allowed locations",
        "strongType": "location"
      }
    }
  }
PARAMETERS
}

resource "azurerm_resource_group_policy_assignment" "location_assignment" {
  name                 = "location-assignment"
  policy_definition_id = azurerm_policy_definition.location_policy.id
  resource_group_id = var.assignment_scope

  parameters = jsonencode({
    allowedLocations = { value = var.allowed_locations }
  })
}

resource "azurerm_policy_definition" "acr_sku_policy" {
  name         = "enforceAcrSku"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Enforce ACR SKU per environment"
  metadata     = <<METADATA
    { "category": "General" }
METADATA

  policy_rule = <<POLICY_RULE
 {
    "if": {
      "allOf": [
        { "field": "type", "equals": "Microsoft.ContainerRegistry/registries" },
        { "field": "Microsoft.ContainerRegistry/registries/sku.name", "notIn": "[parameters('allowedSkus')]" }
      ]
    },
    "then": { "effect": "deny" }
  }
POLICY_RULE

  parameters = <<PARAMETERS
 {
    "allowedSkus": {
      "type": "Array",
      "defaultValue": ${jsonencode(var.allowed_acr_skus)},
      "metadata": {
        "description": "Allowed ACR SKUs: Basic for dev, Premium for production.",
        "displayName": "Allowed SKUs"
      }
    }
  }
PARAMETERS
}

resource "azurerm_resource_group_policy_assignment" "acr_sku_assignment" {
  name                 = "acr-sku-assignment"
  policy_definition_id = azurerm_policy_definition.acr_sku_policy.id
  resource_group_id = var.assignment_scope

  parameters = jsonencode({
    allowedSkus = { value = var.allowed_acr_skus }
  })
}

resource "azurerm_policy_definition" "container_ratio_policy" {
  name         = "enforceContainerCpuMemoryRatio"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Enforce Container App CPU/memory ratio"
  metadata     = <<METADATA
    { "category": "General" }
METADATA

  policy_rule = <<POLICY_RULE
 {
    "if": {
      "allOf": [
        { "field": "type", "equals": "Microsoft.App/containerApps" },
        {
          "not": {
            "anyOf": [
              { "allOf": [
                  { "field": "Microsoft.App/containerApps/template.containers[*].resources.cpu", "equals": 0.25 },
                  { "field": "Microsoft.App/containerApps/template.containers[*].resources.memory", "equals": "0.5Gi" }
              ]},
              { "allOf": [
                  { "field": "Microsoft.App/containerApps/template.containers[*].resources.cpu", "equals": 0.5 },
                  { "field": "Microsoft.App/containerApps/template.containers[*].resources.memory", "equals": "1Gi" }
              ]},
              { "allOf": [
                  { "field": "Microsoft.App/containerApps/template.containers[*].resources.cpu", "equals": 1.0 },
                  { "field": "Microsoft.App/containerApps/template.containers[*].resources.memory", "equals": "2Gi" }
              ]},
              { "allOf": [
                  { "field": "Microsoft.App/containerApps/template.containers[*].resources.cpu", "equals": 2.0 },
                  { "field": "Microsoft.App/containerApps/template.containers[*].resources.memory", "equals": "4Gi" }
              ]}
            ]
          }
        }
      ]
    },
    "then": { "effect": "deny" }
  }
POLICY_RULE

  parameters = "{}"
}

resource "azurerm_resource_group_policy_assignment" "container_ratio_assignment" {
  name                 = "container-ratio-assignment"
  policy_definition_id = azurerm_policy_definition.container_ratio_policy.id
  resource_group_id = var.assignment_scope
}

# JSON is something that is crazy work to learn to write and I honestly created the policy in the GUI and copied and pasted :) 