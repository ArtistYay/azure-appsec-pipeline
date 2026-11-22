resource "azurerm_container_registry" "ACR" {
  # Checkov skips: every check below needs the Premium SKU (or Defender for Containers).
  # This project runs Basic on purpose to stay around $5/month. Each skip is a documented,
  # accepted risk for dev, not something I missed. A production environment would use
  # Premium (enforced by the acr_sku validation) and these checks should NOT be skipped there.
  #checkov:skip=CKV_AZURE_139:Public network access, private endpoints need Premium
  #checkov:skip=CKV_AZURE_233:Zone redundancy needs Premium
  #checkov:skip=CKV_AZURE_237:Dedicated data endpoints need Premium
  #checkov:skip=CKV_AZURE_164:Content trust (signed images) needs Premium
  #checkov:skip=CKV_AZURE_165:Geo-replication needs Premium, single-region dev project
  #checkov:skip=CKV_AZURE_166:Quarantine needs Premium, Grype scans images in the pipeline instead
  #checkov:skip=CKV_AZURE_167:Untagged manifest retention policy needs Premium
  #checkov:skip=CKV_AZURE_163:Registry vulnerability scanning needs Defender for Containers, Grype covers it in the pipeline
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.acr_sku
  admin_enabled       = false # no shared username/password, pulls use the managed identity

  tags = {
    environment = var.environment
  }
}
