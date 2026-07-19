output "vnet_output" {
  description = "outputs the vnet ID"
  value       = azurerm_virtual_network.azappsec-vnet.id
}

output "subnet_output" {
  description = "outputs the subnet ID"
  value       = tolist(azurerm_virtual_network.azappsec-vnet.subnet)[0].id # since the subnet is inline with the vnet block, I have to specify to look at subnet.
}

output "nsg_output" {
  description = "outputs the nsg ID"
  value       = azurerm_network_security_group.azappsec-nsg.id
}