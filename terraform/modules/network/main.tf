resource "azurerm_virtual_network" "azappsec-vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space

  subnet {
    name             = var.subnet_name
    address_prefixes = var.subnet_address_prefix
  }
}

resource "azurerm_network_security_group" "azappsec-nsg" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet_network_security_group_association" "azappsec-nsg-association" { # always remember to attach the nsg to a subnet
  subnet_id                 = tolist(azurerm_virtual_network.azappsec-vnet.subnet)[0].id  # converts the set to a list so you can grab the first item with index
  network_security_group_id = azurerm_network_security_group.azappsec-nsg.id
}