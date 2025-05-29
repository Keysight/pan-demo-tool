output "panfw_detail" {
  value = {
    "name"                : azurerm_linux_virtual_machine.az_panfw.name,
    "private_ip"          : azurerm_network_interface.az_panfw_interface.private_ip_address,
    "public_ip"           : azurerm_public_ip.panfw_public_ip.ip_address,
    "panfw_cli_private_ip": azurerm_network_interface.az_panfw_cli_interface.private_ip_address,
    "panfw_srv_private_ip": azurerm_network_interface.az_panfw_srv_interface.private_ip_address
  }
}

output "name" {
  value = azurerm_linux_virtual_machine.az_panfw.name
}

output "private_ip" {
  value = azurerm_network_interface.az_panfw_interface.private_ip_address
}

output "public_ip" {
  value = azurerm_public_ip.panfw_public_ip.ip_address
}

output "panfw_cli_private_ip" {
  value = azurerm_network_interface.az_panfw_cli_interface.private_ip_address
}

output "panfw_srv_private_ip" {
  value = azurerm_network_interface.az_panfw_srv_interface.private_ip_address
}
