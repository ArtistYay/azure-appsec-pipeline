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

variable "identity_name" {
  description = "name of the managed identity (user-assigned)."
  type        = string
}

variable "acr_id" {
  description = "ID number of the created ACR."
  type        = string
}

variable "role_definition_name" {
  description = "Name of the role definintion"
  type        = string

  validation {
  condition = contains(["AcrPull"], var.role_definition_name)
  error_message = "Role must be AcrPull"
}
}