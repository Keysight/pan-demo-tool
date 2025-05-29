locals {
    mdw_name = "${var.azure_stack_name}-controller-${var.mdw_version}"
}

resource "azurerm_public_ip" "mdw_public_ip" {
    name                = "${var.azure_stack_name}-mdw-public-ip"
    location            = var.azure_location
    resource_group_name = var.resource_group.resource_group_name
    allocation_method   = "Static"
}

resource "azurerm_network_interface" "az_mdw_interface" {
    name                = "${var.azure_stack_name}-mdw-mgmt-interface"
    location            = var.azure_location
    resource_group_name = var.resource_group.resource_group_name

    ip_configuration {
        name                          = "primary"
        subnet_id                     = var.resource_group.management_subnet
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id = azurerm_public_ip.mdw_public_ip.id
    }

    tags = {
        Owner = var.azure_owner
        ccoe-app = var.tag_ccoe-app
        ccoe-group = var.tag_ccoe-group
        UserID = var.tag_UserID
    }
}

resource "azurerm_linux_virtual_machine" "az_mdw" {
    name                  = local.mdw_name
    location              = var.azure_location
    resource_group_name = var.resource_group.resource_group_name
    network_interface_ids = [azurerm_network_interface.az_mdw_interface.id]
    size                  = var.azure_mdw_machine_type
    admin_username        = "cyperf"
    admin_ssh_key {
        username   = "cyperf"
        public_key = var.azure_auth_key
    }

    os_disk {
        name              = "${local.mdw_name}-osdisk"
        caching           = "ReadWrite"
        storage_account_type  = "StandardSSD_LRS"
    }

    plan { 
        name      = var.mdw_version
        product   = "keysight-cyperf"
        publisher = "keysighttechnologies_cyperf"
    }

    source_image_reference {
        publisher = "keysighttechnologies_cyperf"
        offer     = "keysight-cyperf"
        sku       = var.mdw_version
        version   = var.cyperf_version
    }

    custom_data = base64encode(var.mdw_init)

    tags = {
        Owner = var.azure_owner
        ccoe-app = var.tag_ccoe-app
        ccoe-group = var.tag_ccoe-group
        UserID = var.tag_UserID
    }
}
