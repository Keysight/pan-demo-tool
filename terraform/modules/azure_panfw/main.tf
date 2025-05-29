locals {
    panfw_name = "${var.azure_stack_name}-panfw-${var.panfw_version}"
}

resource "azurerm_public_ip" "panfw_public_ip" {
    name                = "${var.azure_stack_name}-panfw-public-ip"
    location            = var.azure_location
    resource_group_name = var.resource_group.resource_group_name
    allocation_method   = "Static"
}

resource "azurerm_network_interface" "az_panfw_interface" {
    name                = "${var.azure_stack_name}-panfw-mgmt-interface"
    location         = var.azure_location
    resource_group_name = var.resource_group.resource_group_name


    ip_configuration {
        name                          = "primary"
        subnet_id                     = var.resource_group.management_subnet
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.panfw_public_ip.id
    }

    tags = {
        Owner = var.azure_owner
        ccoe-app = var.tag_ccoe-app
        ccoe-group = var.tag_ccoe-group
        UserID = var.tag_UserID
    }
}

resource "azurerm_network_interface" "az_panfw_cli_interface" {
    name                = "${var.azure_stack_name}-panfw-cli-interface"
    location            = var.azure_location
    resource_group_name = var.resource_group.resource_group_name

    ip_configuration {
        name                          = "primary"
        subnet_id                     = var.resource_group.client_subnet
        private_ip_address_allocation = "Dynamic"
    }

    tags = {
        Owner = var.azure_owner
        ccoe-app = var.tag_ccoe-app
        ccoe-group = var.tag_ccoe-group
        UserID = var.tag_UserID
    }
}

resource "azurerm_network_interface" "az_panfw_srv_interface" {
    name                = "${var.azure_stack_name}-panfw-srv-interface"
    location            = var.azure_location
    resource_group_name = var.resource_group.resource_group_name

    ip_configuration {
        name                          = "primary"
        subnet_id                     = var.resource_group.server_subnet
        private_ip_address_allocation = "Dynamic"
    }

    tags = {
        Owner = var.azure_owner
        ccoe-app = var.tag_ccoe-app
        ccoe-group = var.tag_ccoe-group
        UserID = var.tag_UserID
    }
}

resource "azurerm_linux_virtual_machine" "az_panfw" {
    name                  = local.panfw_name
    location              = var.azure_location
    resource_group_name = var.resource_group.resource_group_name
    network_interface_ids = [
        azurerm_network_interface.az_panfw_interface.id,
        azurerm_network_interface.az_panfw_cli_interface.id,
        azurerm_network_interface.az_panfw_srv_interface.id
    ]
    size               = var.azure_panfw_machine_type
    admin_username        = "cyperf"
    admin_ssh_key {
        username   = "cyperf"
        public_key = var.azure_auth_key
    }

    os_disk {
        name              = "${local.panfw_name}-osdisk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
        disk_size_gb      = 100
    }
    
    plan {
        name = var.panfw_sku
        publisher = var.panfw_publisher
        product = var.panfw_offer
    }
    
    source_image_reference {
        publisher = var.panfw_publisher
        offer     = var.panfw_offer
        sku       = var.panfw_sku
        version   = var.panfw_version
    }
    
    custom_data = base64encode(var.panfw_init_cli)

    tags = {
        Owner = var.azure_owner
        ccoe-app = var.tag_ccoe-app
        ccoe-group = var.tag_ccoe-group
        UserID = var.tag_UserID
    }
}
