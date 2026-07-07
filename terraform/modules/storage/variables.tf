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