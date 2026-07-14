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

variable "acr_name" {
  description = "the name of the acr"
  type        = string

  validation {
    # Use can() to catch regex errors gracefully https://developer.hashicorp.com/terraform/language/functions/can returns true or false.
    condition = can(regex("^[a-z0-9]{5,50}$", var.acr_name)) # check var.acr_name against a pattern of 5 to 50 chars including numbers and letters.
    error_message = "the name of the ACR must be between 5-50 chars. See https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftcontainerregistry for more details."
  }
}

variable "acr_sku" {
  description = "the sku of the acr"
  type        = string

validation {
  condition = var.environment == "production" ? var.acr_sku == "Premium" : true
  error_message = "acr_sku must be Premium when environment is production"
}

}

variable "environment" {
  description = "the environment where the resouce will deploy to"
  type        = string
  validation {
    condition = can(regex("^(dev|production)$", var.environment))
    error_message = "Environment must be one of: dev or production."
  }
}