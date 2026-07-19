variable "vnet_name" {
  description = "the name of the vnet."
  type        = string
}

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

variable "vnet_address_space" {
  description = "CIDR range"
  type        = list(string) # want to be able to pass a list of address spaces if needed.
}

variable "subnet_name" {
  description = "name of the subnet."
  type        = string
}

variable "subnet_address_prefix" {
  description = "subnet CIDR"
  type        = list(string)
}

variable "nsg_name" {
  description = "name of the network security group."
  type        = string
}