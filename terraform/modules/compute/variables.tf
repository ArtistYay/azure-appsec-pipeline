variable "location" {
  description = "where the resources will be deployed"
  type        = string

  validation {
    condition     = contains(["eastus", "eastus2"], var.location) # making sure only eastus is the location the resources are deployed in.
    error_message = "The location must be eastus or eastus2."
  }
}

variable "resource_group_name" {
  description = "the name of the resource group"
  type        = string
}

variable "container_app_environment_name" {
  description = "the name of the container app environment"
  type = string
}

variable "log_analytics_workspace_name" {
  description = "the name of the log analytics workspace"
  type = string
}

variable "log_analytics_workspace_sku" {
  description = "the sku of the log analytics workspace"
  type = string

  validation {
    condition = contains(["PerGB2018"], var.log_analytics_workspace_sku)
    error_message = "sku must be pay-as-you-go"
  }
}

variable "log_analytics_workspace_retention" {
  description = "the number value of how long logs should be retained in the workspace"
  type = number
}

variable "container_app_name" {
  description = "the name of the container app"
  type = string
}

variable "revision_mode" {
  description = "the mode the container app should run on"
  type = string

  validation {
    condition = contains(["Single"], var.revision_mode)
    error_message = "revision mode must be single mode only"
  }
}

variable "container_name" {
  description = "the name of the container"
  type = string
}

variable "container_image" {
  description = "the name of the image"
  type = string
}

variable "container_cpu" {
    description = "cpu for the container"
    type = number

    validation {
      condition = var.container_cpu >= 0.25 && var.container_cpu <= 2.0
      error_message = "cpu must be between 0.25 and 2.0"
    }
}

variable "container_memory" {
  description = "the memory of the container"
  type = string

  validation {
    condition     = (
      endswith(var.container_memory, "Gi") &&
      # trimsuffix() strips the literal suffix "Gi" off the string, so "1Gi" becomes "1". It only removes it if it's actually there at the end, so if someone passes "1" with no unit, it just returns "1" unchanged
      tonumber(trimsuffix(var.container_memory, "Gi")) == var.container_cpu * 2
      # tonumber() converts that trimmed string "1" into the actual number 1, so it can be compared/multiplied.
    )
    error_message = "container_memory must be a Gi-suffixed value equal to 2x container_cpu (e.g. cpu=0.5 requires memory=\"1Gi\")."
  }
}

variable "user_assigned_identity_id" {
  description = "the managed identity id"
  type = list(string) #  Container App does expect a list, since a resource can technically have multiple user-assigned identities attached https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app#%C3%ACdentity_id-2:~:text=An%20identity%20block%20supports%20the%20following
}

variable "acr_id" {
  description = "the id of the acr"
  type = string
}

variable "acr_login_server" {
  description = "the url for the acr login server"
  type = string
}