output "agents_detail" {
  value = {
    "instanceId" : azurerm_linux_virtual_machine.az_cli_agent.id,
    "name"       : azurerm_linux_virtual_machine.az_cli_agent.name,
    "private_ip" : azurerm_network_interface.az_mgmt_interface.private_ip_address
  }
}

output "name" {
  value = azurerm_linux_virtual_machine.az_cli_agent.name
}

output "private_ip" {
  value = azurerm_network_interface.az_mgmt_interface.private_ip_address
}
