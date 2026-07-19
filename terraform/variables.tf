# shared / resource group 

variable "resource_group_name" {
  description = "name of the resource group"
  type        = string
}

variable "location" {
  description = "where resources will be deployed"
  type        = string

  validation {
    condition     = contains(["eastus", "eastus2"], var.location)
    error_message = "The location must be eastus or eastus2."
  }
}

# storage module

variable "acr_name" {
  description = "the name of the acr"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{5,50}$", var.acr_name))
    error_message = "the name of the ACR must be between 5-50 chars. See https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftcontainerregistry for more details."
  }
}

variable "acr_sku" {
  description = "the sku of the acr"
  type        = string

  validation {
    condition     = var.environment == "production" ? var.acr_sku == "Premium" : true
    error_message = "acr_sku must be Premium when environment is production"
  }
}

variable "environment" {
  description = "the environment where the resource will deploy to"
  type        = string

  validation {
    condition     = can(regex("^(dev|production)$", var.environment))
    error_message = "Environment must be one of: dev or production."
  }
}

# identity module

variable "identity_name" {
  description = "name of the managed identity (user-assigned)"
  type        = string
}

variable "role_definition_name" {
  description = "name of the role definition assigned to the managed identity"
  type        = string

  validation {
    condition     = contains(["AcrPull"], var.role_definition_name)
    error_message = "Role must be AcrPull"
  }
}

# compute module

variable "container_app_environment_name" {
  description = "the name of the container app environment"
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "the name of the log analytics workspace"
  type        = string
}

variable "log_analytics_workspace_sku" {
  description = "the sku of the log analytics workspace"
  type        = string

  validation {
    condition     = contains(["PerGB2018"], var.log_analytics_workspace_sku)
    error_message = "sku must be pay-as-you-go"
  }
}

variable "log_analytics_workspace_retention" {
  description = "the number value of how long logs should be retained in the workspace"
  type        = number
}

variable "container_app_name" {
  description = "the name of the container app"
  type        = string
}

variable "revision_mode" {
  description = "the mode the container app should run on"
  type        = string

  validation {
    condition     = contains(["Single"], var.revision_mode)
    error_message = "revision mode must be single mode only"
  }
}

variable "container_name" {
  description = "the name of the container"
  type        = string
}

variable "container_image" {
  description = "the name of the image"
  type        = string
}

variable "container_cpu" {
  description = "cpu for the container"
  type        = number

  validation {
    condition     = var.container_cpu >= 0.25 && var.container_cpu <= 2.0
    error_message = "cpu must be between 0.25 and 2.0"
  }
}

variable "container_memory" {
  description = "the memory of the container"
  type        = string

  validation {
    condition = (
      endswith(var.container_memory, "Gi") &&
      tonumber(trimsuffix(var.container_memory, "Gi")) == var.container_cpu * 2
    )
    error_message = "container_memory must be a Gi-suffixed value equal to 2x container_cpu (e.g. cpu=0.5 requires memory=\"1Gi\")."
  }
}

# network module

variable "vnet_name" {
  description = "the name of the vnet"
  type        = string
}

variable "vnet_address_space" {
  description = "CIDR range for the vnet"
  type        = list(string)
}

variable "subnet_name" {
  description = "name of the subnet"
  type        = string
}

variable "subnet_address_prefix" {
  description = "subnet CIDR"
  type        = list(string)
}

variable "nsg_name" {
  description = "name of the network security group"
  type        = string
}