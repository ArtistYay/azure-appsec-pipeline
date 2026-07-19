variable "assignment_scope" {
  description = "the resource ID (subscription or resource group) that policy assignments apply to"
  type        = string
}

variable "allowed_locations" {
  description = "locations permitted for all resources"
  type        = list(string)
  default     = ["eastus", "eastus2"]
}

variable "allowed_acr_skus" {
  description = "ACR SKUs permitted, tied to environment (Basic=dev, Premium=production)"
  type        = list(string)
  default     = ["Basic", "Premium"]
}