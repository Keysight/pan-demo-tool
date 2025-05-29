provider "azurerm" {
  features {}

  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

provider "tls" {
  # No configuration required for the TLS provider
}

resource "tls_private_key" "cyperf" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

provider "time" {}

resource "time_sleep" "wait_5_seconds" {
  create_duration = "5s"
}

resource "azurerm_resource_group" "cyperfazuretest-rg" {
  name     = "${var.azure_stack_name}-cyperfazuretest-rg"
  location = var.azure_location
}

resource "azurerm_ssh_public_key" "generated_key" {
  name                = "${var.azure_stack_name}-generated-key"
  resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
  location            = var.azure_location
  public_key          = tls_private_key.cyperf.public_key_openssh
}

locals {
  stackname_lowercase_hypn = replace(lower(var.azure_stack_name), "_", "-")
  storage_account_name = replace(lower(local.stackname_lowercase_hypn), "-", "")
  current_timestamp = timestamp()
  numeric_timestamp = formatdate("YYYYMMDDHHmmss", local.current_timestamp)
  azure_allowed_cidr = var.azure_allowed_cidr
  options_tag = "MANUAL"
  project_tag = "CyPerf"
  cli_agent_tag = "clientagent-azurefw"
  srv_agent_tag = "serveragent-azurefw"
  cli_agent_tag_pan = "clientagent-panfw"
  srv_agent_tag_pan = "serveragent-panfw"
  mdw_init = <<-EOF
    #!/bin/bash
    echo "${tls_private_key.cyperf.public_key_openssh}" >> /home/cyperf/.ssh/authorized_keys
    chown cyperf: /home/cyperf/.ssh/authorized_keys
    chmod 0600 /home/cyperf/.ssh/authorized_keys
  EOF

  agent_init_cli = <<-EOF
    #!/bin/bash
    bash /usr/bin/image_init_azure.sh ${module.mdw.mdw_detail.private_ip} --username "${var.controller_username}" --password "${var.controller_password}" --fingerprint "">> /home/cyperf/azure_image_init_log
    cyperfagent tag set Role=${local.cli_agent_tag}
  EOF

  agent_init_srv = <<-EOF
    #!/bin/bash
    bash /usr/bin/image_init_azure.sh ${module.mdw.mdw_detail.private_ip} --username "${var.controller_username}" --password "${var.controller_password}" --fingerprint "">> /home/cyperf/azure_image_init_log
    cyperfagent tag set Role=${local.srv_agent_tag}
  EOF

  agent_init_cli_pan = <<-EOF
    #!/bin/bash
    bash /usr/bin/image_init_azure.sh ${module.mdw.mdw_detail.private_ip} --username "${var.controller_username}" --password "${var.controller_password}" --fingerprint "">> /home/cyperf/azure_image_init_log
    cyperfagent tag set Role=${local.cli_agent_tag_pan}
  EOF

  agent_init_srv_pan = <<-EOF
    #!/bin/bash
    bash /usr/bin/image_init_azure.sh ${module.mdw.mdw_detail.private_ip} --username "${var.controller_username}" --password "${var.controller_password}" --fingerprint "">> /home/cyperf/azure_image_init_log
    cyperfagent tag set Role=${local.srv_agent_tag_pan}
  EOF

  panfw_init_cli = join(",", [
    "storage-account=${azurerm_storage_account.pan_config_storage.name}",
    "access-key=${data.azurerm_storage_account.pan_config_storage_data.primary_access_key}",
    "file-share=bootstrap",
    "share-directory=None"
  ])
}


resource "azurerm_virtual_network" "main_vnet" {
  name                = "${var.azure_stack_name}-main-vnet"
  address_space       = [var.azure_main_cidr]
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
  dns_servers         = ["8.8.8.8", "8.8.4.4"]
  tags = {
    Owner = var.azure_owner
    Name  = "${var.azure_stack_name}-main-vnet"
  }
}

####### Subnets #######

resource "azurerm_subnet" "management_subnet" {
  name                 = "${var.azure_stack_name}-management-subnet"
  resource_group_name  = azurerm_resource_group.cyperfazuretest-rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = [var.azure_mgmt_cidr]
}

resource "azurerm_subnet" "azure_agent_mgmt_subnet" {
  name                 = "${var.azure_stack_name}-agent-mgmt-subnet"
  resource_group_name  = azurerm_resource_group.cyperfazuretest-rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = [var.azure_agent_mgmt_cidr]
}

resource "azurerm_subnet" "azure_cli_test_subnet" {
  name                 = "${var.azure_stack_name}-cli-test-subnet"
  resource_group_name  = azurerm_resource_group.cyperfazuretest-rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = [var.azure_cli_test_cidr]
}

resource "azurerm_subnet" "azure_cli_test_subnet_pan" {
  name                 = "${var.azure_stack_name}-cli-test-subnet-pan"
  resource_group_name  = azurerm_resource_group.cyperfazuretest-rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = [var.azure_cli_test_cidr_pan]
}

resource "azurerm_subnet" "azure_srv_test_subnet" {
  name                 = "${var.azure_stack_name}-srv-test-subnet"
  resource_group_name  = azurerm_resource_group.cyperfazuretest-rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = [var.azure_srv_test_cidr]
}

resource "azurerm_subnet" "azure_srv_test_subnet_pan" {
  name                 = "${var.azure_stack_name}-srv-test-subnet-pan"
  resource_group_name  = azurerm_resource_group.cyperfazuretest-rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = [var.azure_srv_test_cidr_pan]
}

resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.cyperfazuretest-rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = [var.azure_firewall_cidr]
}

resource "azurerm_subnet" "mgmt_firewall_subnet" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = azurerm_resource_group.cyperfazuretest-rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = [var.azure_mgmt_firewall_cidr]
}

####### Route Tables #######

resource "azurerm_route_table" "public_rt" {
  name                = "${var.azure_stack_name}-public-rt"
  resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
  location            = var.azure_location
  tags = {
    Owner = var.azure_owner
    Name  = "${var.azure_stack_name}-public-rt"
  }
}

resource "azurerm_route_table" "firewall_public_rt" {
  name                = "${var.azure_stack_name}-fw-public-rt"
  resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
  location            = var.azure_location
  
  route {
    name                   = "default-route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type=          "Internet"
  }

  bgp_route_propagation_enabled = false
  tags = {
    Owner = var.azure_owner
    Name  = "${var.azure_stack_name}-fw-public-rt"
  }
}


resource "azurerm_route_table" "ngfw_rt" {
  name                = "${var.azure_stack_name}-ngfw-rt"
  resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
  location            = var.azure_location
  tags = {
    Owner = var.azure_owner
    Name  = "${var.azure_stack_name}-ngfw-rt"
  }
}

resource "azurerm_subnet_route_table_association" "mgmt_rt_association" {
  subnet_id      = azurerm_subnet.management_subnet.id
  route_table_id = azurerm_route_table.public_rt.id
}

resource "azurerm_subnet_route_table_association" "firewall_mgmt_rt_association" {
  subnet_id      = azurerm_subnet.mgmt_firewall_subnet.id
  route_table_id = azurerm_route_table.firewall_public_rt.id
}

resource "azurerm_subnet_route_table_association" "firewall_rt_association" {
  subnet_id      = azurerm_subnet.firewall_subnet.id
  route_table_id = azurerm_route_table.ngfw_rt.id
}

resource "azurerm_route_table" "agent_mgmt_private_rt" {
  name                = "${var.azure_stack_name}-agent-mgmt-private-rt"
  resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
  location            = var.azure_location
  tags = {
    Name = "${var.azure_stack_name}-agent-mgmt-private-rt"
  }
}

resource "azurerm_route_table" "private_rt" {
  name                = "${var.azure_stack_name}-private-rt"
  resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
  location            = var.azure_location
  tags = {
    Name = "${var.azure_stack_name}-private-rt"
  }
}

resource "azurerm_route_table" "private_rt_srv" {
  name                = "${var.azure_stack_name}-private-rt-srv"
  resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
  location            = var.azure_location
  tags = {
    Name = "${var.azure_stack_name}-private-rt-srv"
  }
}

resource "azurerm_route_table" "igw_rt" {
  name                = "${var.azure_stack_name}-igw-rt"
  resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
  location            = var.azure_location
  tags = {
    Name = "${var.azure_stack_name}-igw-rt"
  }
}

resource "azurerm_subnet_route_table_association" "agent_mgmt_rt_association" {
  subnet_id      = azurerm_subnet.azure_agent_mgmt_subnet.id
  route_table_id = azurerm_route_table.agent_mgmt_private_rt.id
}

resource "azurerm_subnet_route_table_association" "cli_test_rt_association" {
  subnet_id      = azurerm_subnet.azure_cli_test_subnet.id
  route_table_id = azurerm_route_table.private_rt.id
}

resource "azurerm_subnet_route_table_association" "srv_test_rt_association" {
  subnet_id      = azurerm_subnet.azure_srv_test_subnet.id
  route_table_id = azurerm_route_table.private_rt_srv.id
}

resource "azurerm_subnet_route_table_association" "cli_test_rt_association_pan" {
  subnet_id      = azurerm_subnet.azure_cli_test_subnet_pan.id
  route_table_id = azurerm_route_table.private_rt.id
}

resource "azurerm_subnet_route_table_association" "srv_test_rt_association_pan" {
  subnet_id      = azurerm_subnet.azure_srv_test_subnet_pan.id
  route_table_id = azurerm_route_table.private_rt_srv.id
}

resource "azurerm_public_ip" "nat_public_ip" {
  name                = "${var.azure_stack_name}-nat-public-ip"
  resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
  location            = var.azure_location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    Owner = var.azure_owner
    Name  = "${var.azure_stack_name}-nat-public-ip"
  }
}

resource "azurerm_nat_gateway" "nat_gateway" {
  name                = "${var.azure_stack_name}-nat-gateway"
  resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
  location            = var.azure_location
  sku_name            = "Standard"
  tags = {
    Owner = var.azure_owner
    Name  = "${var.azure_stack_name}-nat-gateway"
  }
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gateway_publicip" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway.id
  public_ip_address_id = azurerm_public_ip.nat_public_ip.id
}

resource "azurerm_subnet_nat_gateway_association" "nat_gateway_association" {
  subnet_id      = azurerm_subnet.azure_agent_mgmt_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
}

resource "azurerm_route" "route_to_internet" {
  name                   = "${var.azure_stack_name}-route-to-internet"
  resource_group_name    = azurerm_resource_group.cyperfazuretest-rg.name
  route_table_name       = azurerm_route_table.public_rt.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "Internet"
}

resource "azurerm_route" "route_to_ngfw" {
  name                   = "${var.azure_stack_name}-route-to-ngfw"
  resource_group_name    = azurerm_resource_group.cyperfazuretest-rg.name
  route_table_name       = azurerm_route_table.private_rt.name
  address_prefix         = var.azure_srv_test_cidr
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.azure-ngfw.ip_configuration[0].private_ip_address
}

resource "azurerm_route" "route_to_ngfw1" {
  name                   = "${var.azure_stack_name}-route-to-ngfw1"
  resource_group_name    = azurerm_resource_group.cyperfazuretest-rg.name
  route_table_name       = azurerm_route_table.private_rt_srv.name
  address_prefix         = var.azure_cli_test_cidr
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.azure-ngfw.ip_configuration[0].private_ip_address
}

resource "azurerm_route" "route_igw_to_agent1" {
  name                   = "${var.azure_stack_name}-route-igw-to-agent1"
  resource_group_name    = azurerm_resource_group.cyperfazuretest-rg.name
  route_table_name       = azurerm_route_table.igw_rt.name
  address_prefix         = var.azure_cli_test_cidr
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.azure-ngfw.ip_configuration[0].private_ip_address
}

resource "azurerm_route" "route_igw_to_agent2" {
  name                   = "${var.azure_stack_name}-route-igw-to-agent2"
  resource_group_name    = azurerm_resource_group.cyperfazuretest-rg.name
  route_table_name       = azurerm_route_table.igw_rt.name
  address_prefix         = var.azure_srv_test_cidr
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.azure-ngfw.ip_configuration[0].private_ip_address
}

resource "azurerm_route" "route_ngfw_to_igw" {
  name                   = "${var.azure_stack_name}-route-ngfw-to-igw"
  resource_group_name    = azurerm_resource_group.cyperfazuretest-rg.name
  route_table_name       = azurerm_route_table.ngfw_rt.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "Internet"
}

####### Security groups #######

resource "azurerm_network_security_group" "agent_nsg" {
  name                = "${var.azure_stack_name}-agent-nsg"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
  tags = {
    Owner = var.azure_owner
    Name  = "${var.azure_stack_name}-agent-nsg"
  }
}

resource "azurerm_network_security_group" "cyperf_nsg" {
  name                = "${var.azure_stack_name}-cyperf-nsg"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
  tags = {
    Owner = var.azure_owner
    Name  = "${var.azure_stack_name}-cyperf-nsg"
  }
}

####### Firewall Rules #######

resource "azurerm_network_security_rule" "cyperf_agent_ingress" {
  name                        = "cyperf-agent-ingress-80"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.cyperfazuretest-rg.name
  network_security_group_name = azurerm_network_security_group.agent_nsg.name
}

resource "azurerm_network_security_rule" "cyperf_agent_ingress1" {
  name                        = "cyperf-agent-ingress-443"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.cyperfazuretest-rg.name
  network_security_group_name = azurerm_network_security_group.agent_nsg.name
}

resource "azurerm_network_security_rule" "cyperf_agent_ingress2" {
  name                        = "cyperf-agent-ingress-465"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "465"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.cyperfazuretest-rg.name
  network_security_group_name = azurerm_network_security_group.agent_nsg.name
}

resource "azurerm_network_security_rule" "cyperf_agent_ingress3" {
  name                        = "cyperf-agent-ingress-22"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.azure_main_cidr
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.cyperfazuretest-rg.name
  network_security_group_name = azurerm_network_security_group.agent_nsg.name
}

resource "azurerm_network_security_rule" "cyperf_agent_ingress4" {
  name                        = "cyperf-agent-ingress-25"
  priority                    = 140
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "25"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.cyperfazuretest-rg.name
  network_security_group_name = azurerm_network_security_group.agent_nsg.name
}

resource "azurerm_network_security_rule" "cyperf_agent_egress" {
  name                        = "cyperf-agent-egress"
  priority                    = 150
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.cyperfazuretest-rg.name
  network_security_group_name = azurerm_network_security_group.agent_nsg.name
}

resource "azurerm_network_security_rule" "cyperf_ui_ingress" {
  name                        = "cyperf-ui-ingress-443"
  priority                    = 160
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443" 
  source_address_prefixes       = local.azure_allowed_cidr
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.cyperfazuretest-rg.name
  network_security_group_name = azurerm_network_security_group.cyperf_nsg.name
}

resource "azurerm_network_security_rule" "cyperf_ui_ingress1" {
  name                        = "cyperf-ui-ingress-22"
  priority                    = 170
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes       = local.azure_allowed_cidr
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.cyperfazuretest-rg.name
  network_security_group_name = azurerm_network_security_group.cyperf_nsg.name
}

resource "azurerm_network_security_rule" "cyperf_ui_egress" {
  name                        = "cyperf-ui-egress"
  priority                    = 180
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.cyperfazuretest-rg.name
  network_security_group_name = azurerm_network_security_group.cyperf_nsg.name
}
###### Subnet & Security group mapping ##########

resource "azurerm_subnet_network_security_group_association" "az_mgmt_subnet_nsga" {
    subnet_id = azurerm_subnet.management_subnet.id
    network_security_group_id = azurerm_network_security_group.cyperf_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "az_agent_mgmt_subnet_nsga" {
    subnet_id = azurerm_subnet.azure_agent_mgmt_subnet.id
    network_security_group_id = azurerm_network_security_group.agent_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "az_client_test_subnet_nsga" {
    subnet_id = azurerm_subnet.azure_cli_test_subnet.id
    network_security_group_id = azurerm_network_security_group.agent_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "az_server_test_subnet_nsga" {
    subnet_id = azurerm_subnet.azure_srv_test_subnet.id
    network_security_group_id = azurerm_network_security_group.agent_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "az_client_test_subnet_pan_nsga" {
    subnet_id = azurerm_subnet.azure_cli_test_subnet_pan.id
    network_security_group_id = azurerm_network_security_group.agent_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "az_server_test_subnet_pan_nsga" {
    subnet_id = azurerm_subnet.azure_srv_test_subnet_pan.id
    network_security_group_id = azurerm_network_security_group.agent_nsg.id
}

######## Managed Identity ########

resource "azurerm_user_assigned_identity" "instance_identity" {
  name                = "${var.azure_stack_name}-identity"
  resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
  location            = var.azure_location
}

######## Role Assignment ########
resource "azurerm_role_assignment" "instance_role_assignment" {
  principal_id         = azurerm_user_assigned_identity.instance_identity.principal_id
  role_definition_name = "Contributor"
  scope                = azurerm_resource_group.cyperfazuretest-rg.id
}

######## Placement Group ########
resource "azurerm_proximity_placement_group" "placement_group" {
  name                = "${var.azure_stack_name}-pg-cluster"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
}

##### create storage account #####
resource "azurerm_storage_account" "pan_config_storage" {
  name                     = "${local.storage_account_name}60"
  # name                     = "cystrg${local.numeric_timestamp}"
  resource_group_name      = azurerm_resource_group.cyperfazuretest-rg.name
  location                 = var.azure_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    Owner = var.azure_owner
    Name  = "${var.azure_stack_name}-storage-account"
  }
}

data "azurerm_storage_account" "pan_config_storage_data" {
  name = azurerm_storage_account.pan_config_storage.name
  resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
}

##### create storage share #####
resource "azurerm_storage_share" "pan_config_storage_share" {
  name                 = "bootstrap"
  storage_account_id    = azurerm_storage_account.pan_config_storage.id
  quota                = 50
}

resource "azurerm_storage_share_directory" "pan_config_directory" {
  name             = "config"
  storage_share_id = azurerm_storage_share.pan_config_storage_share.url
}

resource "azurerm_storage_share_directory" "pan_config_directory1" {
  name             = "content"
  storage_share_id = azurerm_storage_share.pan_config_storage_share.url
}

resource "azurerm_storage_share_directory" "pan_config_directory2" {
  name             = "license"
  storage_share_id = azurerm_storage_share.pan_config_storage_share.url
}

resource "azurerm_storage_share_directory" "pan_config_directory3" {
  name             = "software"
  storage_share_id = azurerm_storage_share.pan_config_storage_share.url
}

resource "azurerm_storage_share_file" "pan_config_file" {
  name             = "config/bootstrap.xml"
  storage_share_id = azurerm_storage_share.pan_config_storage_share.url
  source           = "pan_config/bootstrap.xml"

  depends_on = [
    azurerm_storage_share_directory.pan_config_directory
  ]
}

resource "azurerm_storage_share_file" "pan_config_file1" {
  name             = "config/init-cfg.txt"
  storage_share_id = azurerm_storage_share.pan_config_storage_share.url
  source           = "pan_config/init-cfg.txt"

  depends_on = [
    azurerm_storage_share_directory.pan_config_directory
  ]
}

######## pan fw Bootstrap role panrofile #######

resource "azurerm_role_definition" "bootstrap_role_definition" {
  name        = "${var.azure_stack_name}_bootstrap_role"
  scope       = azurerm_resource_group.cyperfazuretest-rg.id
  permissions {
    actions = [
      "Microsoft.Storage/storageAccounts/listKeys/action",
      "Microsoft.Storage/storageAccounts/read",
      "Microsoft.Storage/storageAccounts/blobServices/read"
    ]
    not_actions = []
  }
  assignable_scopes = [azurerm_resource_group.cyperfazuretest-rg.id]
}

resource "azurerm_role_assignment" "bootstrap_role_assignment" {
  principal_id   = azurerm_user_assigned_identity.bootstrap_identity.principal_id
  role_definition_name = azurerm_role_definition.bootstrap_role_definition.name
  scope          = azurerm_resource_group.cyperfazuretest-rg.id

  depends_on = [
    azurerm_role_definition.bootstrap_role_definition
  ]

}

resource "azurerm_user_assigned_identity" "bootstrap_identity" {
  name                = "${var.azure_stack_name}_bootstrap_identity"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
}

####### Controller #######

module "mdw" {
  depends_on = [azurerm_virtual_network.main_vnet, time_sleep.wait_5_seconds]
  source     = "./modules/azure_mdw"
  
  resource_group = {
    security_group   = azurerm_network_security_group.cyperf_nsg.id
    management_subnet = azurerm_subnet.management_subnet.id
    resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
  }
  
  azure_stack_name       = var.azure_stack_name
  azure_owner            = var.azure_owner
  azure_auth_key         = var.azure_auth_key
  azure_mdw_machine_type = var.azure_mdw_machine_type
  mdw_init               = local.mdw_init
  azure_location         = var.azure_location
  tag_ccoe-app           = var.tag_ccoe-app
  tag_ccoe-group         = var.tag_ccoe-group
  tag_UserID             = var.tag_UserID
}

####### Agents for azurefw #######

module "clientagents" {
  depends_on = [module.mdw.mdw_detail, time_sleep.wait_5_seconds]
  count      = var.clientagents
  source     = "./modules/azure_agent"
  
  resource_group = {
    azure_agent_security_group = azurerm_network_security_group.agent_nsg.id,
    azure_ControllerManagementSubnet = azurerm_subnet.azure_agent_mgmt_subnet.id,
    azure_AgentTestSubnet = azurerm_subnet.azure_cli_test_subnet.id,
    user_assigned_identity = azurerm_user_assigned_identity.instance_identity.id,
    resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
  }
  
  tags = {
    project_tag = local.project_tag,
    azure_owner = var.azure_owner,
    options_tag = local.options_tag
    tag_ccoe-app = var.tag_ccoe-app
    tag_ccoe-group = var.tag_ccoe-group
    tag_UserID = var.tag_UserID
  }
  
  azure_stack_name       = var.azure_stack_name
  azure_auth_key         = var.azure_auth_key
  azure_agent_machine_type = var.azure_agent_machine_type
  agent_role             = "client-azurefw"
  agent_init_cli         = local.agent_init_cli
  azure_location         = var.azure_location
}

module "serveragents" {
  depends_on = [module.mdw.mdw_detail, time_sleep.wait_5_seconds]
  count      = var.serveragents
  source     = "./modules/azure_agent"
  
  resource_group = {
    azure_agent_security_group = azurerm_network_security_group.agent_nsg.id,
    azure_ControllerManagementSubnet = azurerm_subnet.azure_agent_mgmt_subnet.id,
    azure_AgentTestSubnet = azurerm_subnet.azure_srv_test_subnet.id,
    user_assigned_identity = azurerm_user_assigned_identity.instance_identity.id,
    resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
  }
  
  tags = {
    project_tag = local.project_tag,
    azure_owner = var.azure_owner,
    options_tag = local.options_tag
    tag_ccoe-app = var.tag_ccoe-app
    tag_ccoe-group = var.tag_ccoe-group
    tag_UserID = var.tag_UserID
  }
  
  azure_stack_name       = var.azure_stack_name
  azure_auth_key         = var.azure_auth_key
  azure_agent_machine_type = var.azure_agent_machine_type
  agent_role             = "server-azurefw"
  agent_init_cli         = local.agent_init_srv
  azure_location         = var.azure_location
}

####### Agents for panfw #######

module "clientagents-pan" {
  depends_on = [module.mdw.mdw_detail, time_sleep.wait_5_seconds]
  count      = var.clientagents_pan
  source     = "./modules/azure_agent"
  
  resource_group = {
    azure_agent_security_group = azurerm_network_security_group.agent_nsg.id,
    azure_ControllerManagementSubnet = azurerm_subnet.azure_agent_mgmt_subnet.id,
    azure_AgentTestSubnet = azurerm_subnet.azure_cli_test_subnet_pan.id,
    user_assigned_identity = azurerm_user_assigned_identity.instance_identity.id,
    resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
  }
  
  tags = {
    project_tag = local.project_tag,
    azure_owner = var.azure_owner,
    options_tag = local.options_tag
    tag_ccoe-app = var.tag_ccoe-app
    tag_ccoe-group = var.tag_ccoe-group
    tag_UserID = var.tag_UserID
  }
  
  azure_stack_name       = var.azure_stack_name
  azure_auth_key         = var.azure_auth_key
  azure_agent_machine_type = var.azure_agent_machine_type
  agent_role             = "client-panfw"
  agent_init_cli         = local.agent_init_cli_pan
  azure_location         = var.azure_location
}

module "serveragents-pan" {
  depends_on = [module.mdw.mdw_detail, time_sleep.wait_5_seconds]
  count      = var.serveragents_pan
  source     = "./modules/azure_agent"
  
  resource_group = {
    azure_agent_security_group = azurerm_network_security_group.agent_nsg.id,
    azure_ControllerManagementSubnet = azurerm_subnet.azure_agent_mgmt_subnet.id,
    azure_AgentTestSubnet = azurerm_subnet.azure_srv_test_subnet_pan.id,
    user_assigned_identity = azurerm_user_assigned_identity.instance_identity.id,
    resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
  }
  
  tags = {
    project_tag = local.project_tag,
    azure_owner = var.azure_owner,
    options_tag = local.options_tag
    tag_ccoe-app = var.tag_ccoe-app
    tag_ccoe-group = var.tag_ccoe-group
    tag_UserID = var.tag_UserID
  }
  
  azure_stack_name       = var.azure_stack_name
  azure_auth_key         = var.azure_auth_key
  azure_agent_machine_type = var.azure_agent_machine_type
  agent_role             = "server-panfw"
  agent_init_cli         = local.agent_init_srv_pan
  azure_location         = var.azure_location
}

############ Azure Network Firewall ####################


 resource "azurerm_public_ip" "azure-ngfw-pip" {
   name  = "${local.stackname_lowercase_hypn}-public-ip"
   location = var.azure_location
   resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
   allocation_method   = "Static"
   sku                 = "Standard"
 }

resource "azurerm_public_ip" "azure-ngfw-mgmt-pip" {
  name                = "${local.stackname_lowercase_hypn}-azure-ngfw-mgmt-pip"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
  allocation_method = "Static"
  sku               = "Standard"
}

resource "azurerm_firewall_policy" "azure-ngfw-policy" {
  name                = "${local.stackname_lowercase_hypn}-azure-ngfw-firewall-policy"
  location            = var.azure_location
  sku                 = "Premium"
  resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
  threat_intelligence_mode = "Deny"
  
  intrusion_detection {
      mode = "Deny"
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "azure-ngfw-policy-rule-col-grp" {
  name               = "${local.stackname_lowercase_hypn}-azure-ngfw-firewall-policy-rule-collection-group"
  firewall_policy_id = azurerm_firewall_policy.azure-ngfw-policy.id
  priority           = 100

  network_rule_collection {
    name     = "${local.stackname_lowercase_hypn}-cyperfazuretest-network-rule-collection"
    priority = 100
    action   = "Allow"

      rule {
        name                  = "Client_to_server"
        source_addresses      = [var.azure_cli_test_cidr]
        destination_addresses = [var.azure_srv_test_cidr]
        destination_ports     = ["*"]
        protocols             = ["Any"]
      }

      rule {
        name                 = "Server_to_client"
        source_addresses     = [var.azure_srv_test_cidr]
        destination_addresses = [var.azure_cli_test_cidr]
        destination_ports     = ["*"]
        protocols             = ["Any"]
      }
  }
}

resource "azurerm_firewall" "azure-ngfw" {
  name                = "${local.stackname_lowercase_hypn}-azure-ngfw"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Premium"
  threat_intel_mode   = "Alert"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.azure-ngfw-pip.id
  }
  
  management_ip_configuration {
    name                 = "mgmt-configuration"
    subnet_id            = azurerm_subnet.mgmt_firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.azure-ngfw-mgmt-pip.id
  }
  firewall_policy_id = azurerm_firewall_policy.azure-ngfw-policy.id
}

####### PANFW #######

module "azpanfw" {
    source = "./modules/azure_panfw"
    resource_group = {
        security_group = azurerm_network_security_group.cyperf_nsg.id,
        security_group_test = azurerm_network_security_group.cyperf_nsg.id,
        management_subnet = azurerm_subnet.management_subnet.id,
        client_subnet = azurerm_subnet.azure_cli_test_subnet_pan.id,
        server_subnet = azurerm_subnet.azure_srv_test_subnet_pan.id,
        user_assigned_identity = azurerm_user_assigned_identity.bootstrap_identity.id,
        resource_group_name = azurerm_resource_group.cyperfazuretest-rg.name
    }
    azure_stack_name = var.azure_stack_name
    azure_owner = var.azure_owner
    azure_auth_key = var.azure_auth_key
    panfw_init_cli = local.panfw_init_cli
    azure_location         = var.azure_location
    azure_panfw_machine_type = var.azure_panfw_machine_type
    tag_ccoe-app           = var.tag_ccoe-app
    tag_ccoe-group         = var.tag_ccoe-group
    tag_UserID             = var.tag_UserID
}

##### Output ######

output "storage_account_primary_access_key" {
  value = data.azurerm_storage_account.pan_config_storage_data.primary_access_key
  sensitive = true
}

output "license_server" {
  value = var.azure_license_server
}

output "private_key_pem" {
  value     = tls_private_key.cyperf.private_key_pem
  sensitive = true
}

output "mdw_detail" {
  value = {
    "name"       : module.mdw.mdw_detail.name,
    "public_ip"  : module.mdw.mdw_detail.public_ip,
    "private_ip" : module.mdw.mdw_detail.private_ip
  }
}

output "azpanfw_detail" {
  value = {
    "name"                : module.azpanfw.panfw_detail.name,
    "public_ip"           : module.azpanfw.panfw_detail.public_ip,
    "private_ip"          : module.azpanfw.panfw_detail.private_ip,
    "panfw_cli_private_ip" : module.azpanfw.panfw_detail.panfw_cli_private_ip,
    "panfw_srv_private_ip" : module.azpanfw.panfw_detail.panfw_srv_private_ip
  }
}

output "azfw_client_agent_detail" {
  value = [for x in module.clientagents : {
    "name"       : x.agents_detail.name,
    "private_ip" : x.agents_detail.private_ip
  }]
}

output "azfw_server_agent_detail" {
  value = [for x in module.serveragents : {
    "name"       : x.agents_detail.name,
    "private_ip" : x.agents_detail.private_ip
  }]
}

output "panfw_client_agent_detail" {
  value = [for x in module.clientagents-pan : {
    "name"       : x.agents_detail.name,
    "private_ip" : x.agents_detail.private_ip
  }]
}

output "panfw_server_agent_detail" {
  value = [for x in module.serveragents-pan : {
    "name"       : x.agents_detail.name,
    "private_ip" : x.agents_detail.private_ip
  }]
}
