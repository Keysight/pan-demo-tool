locals {
    cli_agent_name = "${var.azure_stack_name}-${var.agent_role}-${var.agent_version}"
}

resource "azurerm_network_interface" "az_mgmt_interface" {
    name                = "${var.azure_stack_name}-mgmt-interface-${var.agent_role}"
    location            = var.azure_location
    resource_group_name = var.resource_group.resource_group_name

    ip_configuration {
        name                          = "primary"
        subnet_id                     = var.resource_group.azure_ControllerManagementSubnet
        private_ip_address_allocation = "Dynamic"
    }

    tags = {
        Owner   = var.tags.azure_owner
        Project = var.tags.project_tag
        Options = var.tags.options_tag
        ccoe-app = var.tags.tag_ccoe-app
        ccoe-group = var.tags.tag_ccoe-group
        UserID = var.tags.tag_UserID
    }
}

resource "azurerm_network_interface" "az_cli_test_interface" {
    name                = "${var.azure_stack_name}-cli-test-interface-${var.agent_role}"
    location            = var.azure_location
    resource_group_name = var.resource_group.resource_group_name

    ip_configuration {
        name                          = "primary"
        subnet_id                     = var.resource_group.azure_AgentTestSubnet
        private_ip_address_allocation = "Dynamic"
    }

    tags = {
        Owner   = var.tags.azure_owner
        Project = var.tags.project_tag
        Options = var.tags.options_tag
        ccoe-app = var.tags.tag_ccoe-app
        ccoe-group = var.tags.tag_ccoe-group
        UserID = var.tags.tag_UserID
    }
}


resource "azurerm_linux_virtual_machine" "az_cli_agent" {
    name                  = local.cli_agent_name
    location            = var.azure_location
    resource_group_name = var.resource_group.resource_group_name
    network_interface_ids = [
        azurerm_network_interface.az_mgmt_interface.id,
        azurerm_network_interface.az_cli_test_interface.id
    ]
    size                  = var.azure_agent_machine_type
    admin_username        = "cyperf"
    admin_ssh_key {
        username   = "cyperf"
        public_key = var.azure_auth_key
    }

    os_disk {
        name              = "${local.cli_agent_name}-osdisk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    plan {
        name      = var.agent_version
        product   = "keysight-cyperf"
        publisher = "keysighttechnologies_cyperf"
    }

    source_image_reference {
        publisher = "keysighttechnologies_cyperf"
        offer     = "keysight-cyperf"
        sku       = var.agent_version
        version   = var.cyperf_version
    }

    custom_data = base64encode(var.agent_init_cli)
    tags = {
        Owner   = var.tags.azure_owner
        Project = var.tags.project_tag
        Options = var.tags.options_tag
        ccoe-app = var.tags.tag_ccoe-app
        ccoe-group = var.tags.tag_ccoe-group
        UserID = var.tags.tag_UserID
    }
}
