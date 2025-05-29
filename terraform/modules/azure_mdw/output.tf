output "mdw_detail" {
  value = {
    "name"       : azurerm_linux_virtual_machine.az_mdw.name,
    "private_ip" : azurerm_network_interface.az_mdw_interface.private_ip_address,
    "public_ip"  : azurerm_public_ip.mdw_public_ip.ip_address
  }
}

output "name" {
  value = azurerm_linux_virtual_machine.az_mdw.name
}

output "private_ip" {
  value = azurerm_network_interface.az_mdw_interface.private_ip_address
}

output "public_ip" {
  value = azurerm_public_ip.mdw_public_ip.ip_address
}
