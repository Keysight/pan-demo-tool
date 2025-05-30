provider "aws" {
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
  token = var.aws_session_token
  region = var.aws_region
}

provider "aws" {
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
  token = var.aws_session_token
  region = var.aws_region
  alias = "s3access"
}

provider "tls" {
  # No configuration required for the TLS provider
}

resource "tls_private_key" "cyperf" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "${var.aws_stack_name}-generated-key"
  public_key = tls_private_key.cyperf.public_key_openssh
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

locals{
    selected_az = data.aws_availability_zones.available.names[0]
    current_account_id = data.aws_caller_identity.current.account_id
    stackname_lowercase_hypn = replace(lower(var.aws_stack_name),"_", "-")
    current_timestamp = timestamp()
    numeric_timestamp = formatdate("YYYYMMDDHHmmss", local.current_timestamp)
    firewall_cidr = concat(var.aws_allowed_cidr,[var.aws_main_cidr])
    options_tag             = "MANUAL"
    project_tag             = "CyPerf"
    cli_agent_tag           = "clientagent-awsfw"
    srv_agent_tag           = "serveragent-awsfw"
    cli_agent_tag_pan       = "clientagent-panfw"
    srv_agent_tag_pan       = "serveragent-panfw"
    mdw_init = <<-EOF
        #! /bin/bash
        echo "${tls_private_key.cyperf.public_key_openssh}" >> /home/cyperf/.ssh/authorized_keys
        chown cyperf: /home/cyperf/.ssh/authorized_keys
        chmod 0600 /home/cyperf/.ssh/authorized_keys
    EOF
    agent_init_cli = <<-EOF
        #! /bin/bash
        sudo chmod 777 /var/log/
        aws s3 cp s3://${aws_s3_bucket.pan_config_bucket.bucket}/init/Appsec_init_s3 /opt/keysight/tiger/active/bin/Appsec_init_s3
        sudo apt update
        sudo apt install -y dos2unix
        sudo dos2unix /opt/keysight/tiger/active/bin/Appsec_init_s3
        sudo sh /opt/keysight/tiger/active/bin/Appsec_init_s3 ${module.mdw.mdw_detail.private_ip} --username "${var.controller_username}" --password "${var.controller_password}">> /var/log/Appsec_init_s3.log
        cyperfagent tag set Role=${local.cli_agent_tag}
    EOF
    agent_init_srv = <<-EOF
        #! /bin/bash
        sudo chmod 777 /var/log/
        aws s3 cp s3://${aws_s3_bucket.pan_config_bucket.bucket}/init/Appsec_init_s3 /opt/keysight/tiger/active/bin/Appsec_init_s3
        sudo apt update
        sudo apt install -y dos2unix
        sudo dos2unix /opt/keysight/tiger/active/bin/Appsec_init_s3
        sudo sh /opt/keysight/tiger/active/bin/Appsec_init_s3 ${module.mdw.mdw_detail.private_ip} --username "${var.controller_username}" --password "${var.controller_password}">> /var/log/Appsec_init_s3.log
        cyperfagent tag set Role=${local.srv_agent_tag}
    EOF
    agent_init_cli_pan = <<-EOF
        #! /bin/bash
        sudo chmod 777 /var/log/
        aws s3 cp s3://${aws_s3_bucket.pan_config_bucket.bucket}/init/Appsec_init_s3 /opt/keysight/tiger/active/bin/Appsec_init_s3
        sudo apt update
        sudo apt install -y dos2unix
        sudo dos2unix /opt/keysight/tiger/active/bin/Appsec_init_s3
        sudo sh /opt/keysight/tiger/active/bin/Appsec_init_s3 ${module.mdw.mdw_detail.private_ip} --username "${var.controller_username}" --password "${var.controller_password}">> /var/log/Appsec_init_s3.log
        cyperfagent tag set Role=${local.cli_agent_tag_pan}
    EOF
    agent_init_srv_pan = <<-EOF
        #! /bin/bash
        sudo chmod 777 /var/log/
        aws s3 cp s3://${aws_s3_bucket.pan_config_bucket.bucket}/init/Appsec_init_s3 /opt/keysight/tiger/active/bin/Appsec_init_s3
        sudo apt update
        sudo apt install -y dos2unix
        sudo dos2unix /opt/keysight/tiger/active/bin/Appsec_init_s3
        sudo sh /opt/keysight/tiger/active/bin/Appsec_init_s3 ${module.mdw.mdw_detail.private_ip} --username "${var.controller_username}" --password "${var.controller_password}">> /var/log/Appsec_init_s3.log
        cyperfagent tag set Role=${local.srv_agent_tag_pan}
    EOF
    panfw_init_cli = <<-EOF
        vmseries-bootstrap-aws-s3bucket=${aws_s3_bucket.pan_config_bucket.bucket}
    EOF
}

resource "aws_vpc" "aws_main_vpc" {
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-main-vpc"
    }
    enable_dns_hostnames = true
    enable_dns_support = true
    cidr_block = var.aws_main_cidr
}

####### Subnets #######
resource "aws_subnet" "aws_management_subnet" {
    vpc_id     = aws_vpc.aws_main_vpc.id
    cidr_block = var.aws_mgmt_cidr
    availability_zone = local.selected_az
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-management-subnet"
    }
}

resource "aws_subnet" "aws_agent_mgmt_subnet" {
    vpc_id     = aws_vpc.aws_main_vpc.id
    availability_zone = local.selected_az
    cidr_block = var.aws_agent_mgmt_cidr
    tags = {
        Name = "${var.aws_stack_name}-agent-mgmt-subnet"
    }
}

resource "aws_subnet" "aws_cli_test_subnet" {
    vpc_id     = aws_vpc.aws_main_vpc.id
    availability_zone = local.selected_az
    cidr_block = var.aws_cli_test_cidr
    tags = {
        Name = "${var.aws_stack_name}-cli-test-subnet"
    }
}

resource "aws_subnet" "aws_cli_test_subnet_pan" {
    vpc_id     = aws_vpc.aws_main_vpc.id
    availability_zone = local.selected_az
    cidr_block = var.aws_cli_test_cidr_pan
    tags = {
        Name = "${var.aws_stack_name}-cli-test-subnet-pan"
    }
}

resource "aws_subnet" "aws_srv_test_subnet" {
    vpc_id     = aws_vpc.aws_main_vpc.id
    availability_zone = local.selected_az
    cidr_block = var.aws_srv_test_cidr
    tags = {
        Name = "${var.aws_stack_name}-srv-test-subnet"
    }
}

resource "aws_subnet" "aws_srv_test_subnet_pan" {
    vpc_id     = aws_vpc.aws_main_vpc.id
    availability_zone = local.selected_az
    cidr_block = var.aws_srv_test_cidr_pan
    tags = {
        Name = "${var.aws_stack_name}-srv-test-subnet-pan"
    }
}

resource "aws_subnet" "aws_firewall_subnet" {
    vpc_id     = aws_vpc.aws_main_vpc.id
    availability_zone = local.selected_az
    cidr_block = var.aws_firewall_cidr
    tags = {
        Name = "${var.aws_stack_name}-firewall-subnet"
    }
}

####### Route Tables #######

resource "aws_route_table" "aws_public_rt" {
    vpc_id = aws_vpc.aws_main_vpc.id
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-public-rt"
    }        
}

resource "aws_route_table" "aws_ngfw_rt" {
    vpc_id = aws_vpc.aws_main_vpc.id
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-ngfw-rt"
    }        
}


resource "aws_route_table_association" "aws_mgmt_rt_association" {
    subnet_id      = aws_subnet.aws_management_subnet.id
    route_table_id = aws_route_table.aws_public_rt.id
}

resource "aws_route_table_association" "aws_firewall_rt_association" {
    subnet_id      = aws_subnet.aws_firewall_subnet.id
    route_table_id = aws_route_table.aws_ngfw_rt.id
}

resource "aws_route_table" "aws_agent_mgmt_private_rt" {
    vpc_id = aws_vpc.aws_main_vpc.id
    tags = {
        Name = "${var.aws_stack_name}-agent-mgmt-private-rt"
    }    
}

resource "aws_route_table" "aws_private_rt" {
    vpc_id = aws_vpc.aws_main_vpc.id
    tags = {
        Name = "${var.aws_stack_name}-private-rt"
    }    
}

resource "aws_route_table" "aws_private_rt_srv" {
    vpc_id = aws_vpc.aws_main_vpc.id
    tags = {
        Name = "${var.aws_stack_name}-private-rt-srv"
    }    
}

resource "aws_route_table" "aws_igw_rt" {
    vpc_id = aws_vpc.aws_main_vpc.id
    tags = {
        Name = "${var.aws_stack_name}-igw-rt"
    }    
}

resource "aws_route_table_association" "aws_agent_mgmt_rt_association" {
    subnet_id      = aws_subnet.aws_agent_mgmt_subnet.id
    route_table_id = aws_route_table.aws_agent_mgmt_private_rt.id
}

resource "aws_route_table_association" "aws_cli_test_rt_association" {
    subnet_id      = aws_subnet.aws_cli_test_subnet.id
    route_table_id = aws_route_table.aws_private_rt.id
}

resource "aws_route_table_association" "aws_srv_test_rt_association" {
    subnet_id      = aws_subnet.aws_srv_test_subnet.id
    route_table_id = aws_route_table.aws_private_rt_srv.id
}

resource "aws_route_table_association" "aws_cli_test_rt_association_pan" {
    subnet_id      = aws_subnet.aws_cli_test_subnet_pan.id
    route_table_id = aws_route_table.aws_private_rt.id
}

resource "aws_route_table_association" "aws_srv_test_rt_association_pan" {
    subnet_id      = aws_subnet.aws_srv_test_subnet_pan.id
    route_table_id = aws_route_table.aws_private_rt_srv.id
}

resource "aws_internet_gateway" "aws_internet_gateway" {
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-internet-gateway"
    }
    vpc_id = aws_vpc.aws_main_vpc.id  
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "aws_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.aws_management_subnet.id

  tags = {
    Name = "${var.aws_stack_name}-nat-gateway"
  }
}

resource "aws_route_table_association" "aws_igw_rt_association" {
    depends_on = [
      aws_internet_gateway.aws_internet_gateway
    ]
    gateway_id = aws_internet_gateway.aws_internet_gateway.id
    route_table_id = aws_route_table.aws_igw_rt.id
}

resource "aws_route" "aws_route_to_internet" {
    depends_on = [
      aws_route_table_association.aws_mgmt_rt_association
    ]
    route_table_id            = aws_route_table.aws_public_rt.id
    destination_cidr_block    = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aws_internet_gateway.id
}

resource "aws_route" "aws_route_to_nat" {
    depends_on = [
      aws_route_table_association.aws_agent_mgmt_rt_association
    ]
    route_table_id            = aws_route_table.aws_agent_mgmt_private_rt.id
    destination_cidr_block    = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.aws_nat_gateway.id
}

resource "aws_route" "aws_route_to_ngfw" {
    depends_on = [
      aws_route_table_association.aws_cli_test_rt_association,
      aws_route_table_association.aws_srv_test_rt_association
    ]
    route_table_id            = aws_route_table.aws_private_rt.id
    destination_cidr_block    = var.aws_srv_test_cidr
    vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.aws-ngfw.firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == aws_subnet.aws_firewall_subnet.id], 0)
}

resource "aws_route" "aws_route_to_ngfw1" {
    depends_on = [
      aws_route_table_association.aws_cli_test_rt_association,
      aws_route_table_association.aws_srv_test_rt_association
    ]
    route_table_id            = aws_route_table.aws_private_rt_srv.id
    destination_cidr_block    = var.aws_cli_test_cidr
    vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.aws-ngfw.firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == aws_subnet.aws_firewall_subnet.id], 0)
}

resource "aws_route" "aws_route_igw_to_agent1" {
    depends_on = [
      aws_route_table_association.aws_igw_rt_association
    ]
    route_table_id            = aws_route_table.aws_igw_rt.id
    destination_cidr_block    = var.aws_cli_test_cidr
    vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.aws-ngfw.firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == aws_subnet.aws_firewall_subnet.id], 0)
}

resource "aws_route" "aws_route_igw_to_agent2" {
    depends_on = [
      aws_route_table_association.aws_igw_rt_association
    ]
    route_table_id            = aws_route_table.aws_igw_rt.id
    destination_cidr_block    = var.aws_srv_test_cidr
    vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.aws-ngfw.firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == aws_subnet.aws_firewall_subnet.id], 0)
}

resource "aws_route" "aws_route_ngfw_to_igw" {
    depends_on = [
      aws_route_table_association.aws_firewall_rt_association
    ]
    route_table_id            = aws_route_table.aws_ngfw_rt.id
    destination_cidr_block    = "0.0.0.0/0"
    gateway_id                = aws_internet_gateway.aws_internet_gateway.id
}

####### Security groups #######
resource "aws_security_group" "aws_agent_security_group" {
    name = "agent-security-group"
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-agent-security-group"
    }
    description = "Agent security group"
    vpc_id = aws_vpc.aws_main_vpc.id
}

resource "aws_security_group" "aws_cyperf_security_group" {
    name = "mdw-security-group"
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-cyperf-security-group"
    }
    description = "MDW security group"
    vpc_id = aws_vpc.aws_main_vpc.id
}

####### Firewall Rules #######
resource "aws_security_group_rule" "aws_cyperf_agent_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/128"]
  security_group_id = aws_security_group.aws_agent_security_group.id
}
resource "aws_security_group_rule" "aws_cyperf_agent_ingress1" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/128"]
  security_group_id = aws_security_group.aws_agent_security_group.id
}
resource "aws_security_group_rule" "aws_cyperf_agent_ingress2" {
  type              = "ingress"
  from_port         = 465
  to_port           = 465
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/128"]
  security_group_id = aws_security_group.aws_agent_security_group.id
}
resource "aws_security_group_rule" "aws_cyperf_agent_ingress3" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.aws_main_cidr]
  security_group_id = aws_security_group.aws_agent_security_group.id
}
resource "aws_security_group_rule" "aws_cyperf_agent_ingress4" {
  type              = "ingress"
  from_port         = 25
  to_port           = 25
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/128"]
  security_group_id = aws_security_group.aws_agent_security_group.id
}
resource "aws_security_group_rule" "aws_cyperf_agent_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.aws_agent_security_group.id
}
resource "aws_security_group_rule" "aws_cyperf_ui_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = local.firewall_cidr
  ipv6_cidr_blocks  = ["::/128"]
  security_group_id = aws_security_group.aws_cyperf_security_group.id
}
resource "aws_security_group_rule" "aws_cyperf_ui_ingress1" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = local.firewall_cidr
  ipv6_cidr_blocks  = ["::/128"]
  security_group_id = aws_security_group.aws_cyperf_security_group.id
}
resource "aws_security_group_rule" "aws_cyperf_ui_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.aws_cyperf_security_group.id
}

####### DHCP #######
resource "aws_vpc_dhcp_options" "aws_main_vpc_dhcp_options" {
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-dhcp-option"
    }
    domain_name_servers  = ["8.8.8.8",
                            "8.8.4.4",
                            "AmazonProvidedDNS" ]
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
    vpc_id          = aws_vpc.aws_main_vpc.id
    dhcp_options_id = aws_vpc_dhcp_options.aws_main_vpc_dhcp_options.id
}

######## Instance Profile #######
data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
data "aws_iam_policy_document" "inline_policy" {
  statement {
    actions   = ["ec2:CreateNetworkInterface", "ec2:DescribeInstances", "ec2:ModifyNetworkInterfaceAttribute", "ec2:AttachNetworkInterface", "ec2:DescribeSubnets", "ec2:DescribeSecurityGroups", "ec2:DescribeTags", "*"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "instance_iam_role" {
  name               = "${var.aws_stack_name}_instance_role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
}

resource  aws_iam_role_policy "instance_iam_role_policy" {
    name   = "${var.aws_stack_name}-policy"
    role   = aws_iam_role.instance_iam_role.name
    policy = data.aws_iam_policy_document.inline_policy.json
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.aws_stack_name}-instance_profile"
  role = aws_iam_role.instance_iam_role.name
}

resource "time_sleep" "wait_5_seconds" {
  depends_on = [aws_placement_group.aws_placement_group]
  destroy_duration = "5s"
}

resource "aws_placement_group" "aws_placement_group" {
    name     = "${var.aws_stack_name}-pg-cluster"
    strategy = "cluster"
}

##### create s3 bucket #####

resource "aws_s3_bucket" "pan_config_bucket" {
  provider = aws.s3access
  bucket = "${local.stackname_lowercase_hypn}-panfw-bootstrap-${local.numeric_timestamp}"
  force_destroy = true
}

resource "aws_s3_object" "pan_config_file" {
  depends_on = [aws_s3_bucket.pan_config_bucket]
  provider = aws.s3access
  bucket = aws_s3_bucket.pan_config_bucket.bucket
  key    = "config/bootstrap.xml"
  source = "pan_config/bootstrap.xml"
}

resource "aws_s3_object" "pan_config_file1" {
  depends_on = [aws_s3_bucket.pan_config_bucket]
  provider = aws.s3access
  bucket = aws_s3_bucket.pan_config_bucket.bucket
  key    = "config/init-cfg.txt"
  source = "pan_config/init-cfg.txt"
}

resource "aws_s3_object" "appsec_init_file" {
  depends_on = [aws_s3_bucket.pan_config_bucket]
  provider = aws.s3access
  bucket = aws_s3_bucket.pan_config_bucket.bucket
  key    = "init/Appsec_init_s3"
  source = "init_script/Appsec_init_s3"
}

######## pan fw Bootstrap role panrofile #######

data "aws_iam_policy_document" "bootstrap-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
data "aws_iam_policy_document" "bootstrap_inline_policy" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.pan_config_bucket.arn]
    
  }
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.pan_config_bucket.arn}/*"]
  }
}
resource "aws_iam_role" "bootstrap_iam_role" {
  name               = "${var.aws_stack_name}_bootstrap_role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.bootstrap-assume-role-policy.json
}

resource  aws_iam_role_policy bootstrap_iam_role_policy {
    name   = "${var.aws_stack_name}-bootstrap-policy"
    role   = aws_iam_role.bootstrap_iam_role.name
    policy = data.aws_iam_policy_document.bootstrap_inline_policy.json
}

resource "aws_iam_instance_profile" "bootstrap_profile" {
  name = "${var.aws_stack_name}-bootstrap_profile"
  role = aws_iam_role.bootstrap_iam_role.name
}

####### Controller #######
module "mdw" {
    depends_on = [aws_internet_gateway.aws_internet_gateway, time_sleep.wait_5_seconds]
    source = "./modules/aws_mdw"
    resource_group = {
        security_group = aws_security_group.aws_cyperf_security_group.id,
        management_subnet = aws_subnet.aws_management_subnet.id
    }
    aws_stack_name = var.aws_stack_name
    aws_owner = var.aws_owner
    aws_auth_key = var.aws_auth_key
    aws_mdw_machine_type = var.aws_mdw_machine_type
    mdw_init = local.mdw_init
}

####### Agents for awsfw #######
module "clientagents" {
    depends_on = [module.mdw.mdw_detail, time_sleep.wait_5_seconds]
    count = var.clientagents
    source = "./modules/aws_agent"
    resource_group = {
        aws_agent_security_group = aws_security_group.aws_agent_security_group.id,
        aws_ControllerManagementSubnet = aws_subnet.aws_agent_mgmt_subnet.id,
        aws_AgentTestSubnet = aws_subnet.aws_cli_test_subnet.id,
        instance_profile = aws_iam_instance_profile.bootstrap_profile.name
    }
    tags = {
        project_tag = local.project_tag,
        aws_owner   = var.aws_owner,
        options_tag = local.options_tag
    }
    aws_stack_name = var.aws_stack_name
    aws_auth_key   = var.aws_auth_key
    aws_agent_machine_type = var.aws_agent_machine_type
    agent_role = "client-awsfw"
    agent_init_cli = local.agent_init_cli
}

module "serveragents" {
    depends_on = [module.mdw.mdw_detail, time_sleep.wait_5_seconds]
    count = var.serveragents
    source = "./modules/aws_agent"
    resource_group = {
        aws_agent_security_group = aws_security_group.aws_agent_security_group.id,
        aws_ControllerManagementSubnet = aws_subnet.aws_agent_mgmt_subnet.id,
        aws_AgentTestSubnet = aws_subnet.aws_srv_test_subnet.id,
        instance_profile = aws_iam_instance_profile.bootstrap_profile.name
    }
    tags = {
        project_tag = local.project_tag,
        aws_owner   = var.aws_owner,
        options_tag = local.options_tag,
    }
    aws_stack_name = var.aws_stack_name
    aws_auth_key   = var.aws_auth_key
    aws_agent_machine_type = var.aws_agent_machine_type
    agent_role = "server-awsfw"
    agent_init_cli = local.agent_init_srv
}

####### Agents for panfw #######
module "clientagents-pan" {
    depends_on = [module.mdw.mdw_detail, time_sleep.wait_5_seconds]
    count = var.clientagents_pan
    source = "./modules/aws_agent"
    resource_group = {
        aws_agent_security_group = aws_security_group.aws_agent_security_group.id,
        aws_ControllerManagementSubnet = aws_subnet.aws_agent_mgmt_subnet.id,
        aws_AgentTestSubnet = aws_subnet.aws_cli_test_subnet_pan.id,
        instance_profile = aws_iam_instance_profile.bootstrap_profile.name
    }
    tags = {
        project_tag = local.project_tag,
        aws_owner   = var.aws_owner,
        options_tag = local.options_tag
    }
    aws_stack_name = var.aws_stack_name
    aws_auth_key   = var.aws_auth_key
    aws_agent_machine_type = var.aws_agent_machine_type
    agent_role = "client-panfw"
    agent_init_cli = local.agent_init_cli_pan
}

module "serveragents-pan" {
    depends_on = [module.mdw.mdw_detail, time_sleep.wait_5_seconds]
    count = var.serveragents_pan
    source = "./modules/aws_agent"
    resource_group = {
        aws_agent_security_group = aws_security_group.aws_agent_security_group.id,
        aws_ControllerManagementSubnet = aws_subnet.aws_agent_mgmt_subnet.id,
        aws_AgentTestSubnet = aws_subnet.aws_srv_test_subnet_pan.id,
        instance_profile = aws_iam_instance_profile.bootstrap_profile.name
    }
    tags = {
        project_tag = local.project_tag,
        aws_owner   = var.aws_owner,
        options_tag = local.options_tag
    }
    aws_stack_name = var.aws_stack_name
    aws_auth_key   = var.aws_auth_key
    aws_agent_machine_type = var.aws_agent_machine_type
    agent_role = "server-panfw"
    agent_init_cli = local.agent_init_srv_pan
}

##### AWS NGFW ####
resource "aws_networkfirewall_firewall" "aws-ngfw" {
  name              = "${local.stackname_lowercase_hypn}-aws-ngfw"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.aws-ngfw.arn
  vpc_id            = aws_vpc.aws_main_vpc.id
  subnet_mapping {
    subnet_id = aws_subnet.aws_firewall_subnet.id
  }
}
resource "aws_networkfirewall_firewall_policy" "aws-ngfw" {
  name = "${local.stackname_lowercase_hypn}-aws-ngfw-firewall-policy"
  firewall_policy {

      policy_variables {
        rule_variables {
          key = "HOME_NET"
          ip_set {
            definition = [var.aws_cli_test_cidr]
          }
        }
      }

      #stateful_rule_group_reference {
        #resource_arn = aws_networkfirewall_rule_group.aws-ngfw.arn
      #}

      stateless_rule_group_reference {
        resource_arn = aws_networkfirewall_rule_group.aws-ngfw-stateless.arn
        priority     = 1
     }

  stateful_engine_options {
    rule_order = "STRICT_ORDER"
  }

  stateful_rule_group_reference {
    priority = 1
    resource_arn = "arn:aws:network-firewall:${var.aws_region}:aws-managed:stateful-rulegroup/ThreatSignaturesDoSStrictOrder"
  }

  stateful_rule_group_reference {
    priority = 2
    resource_arn = "arn:aws:network-firewall:${var.aws_region}:aws-managed:stateful-rulegroup/AbusedLegitMalwareDomainsStrictOrder"
  }

  stateful_rule_group_reference {
    priority = 3
    resource_arn = "arn:aws:network-firewall:${var.aws_region}:aws-managed:stateful-rulegroup/BotNetCommandAndControlDomainsStrictOrder"
  }

  stateful_rule_group_reference {
    priority = 4
    resource_arn = "arn:aws:network-firewall:${var.aws_region}:aws-managed:stateful-rulegroup/AbusedLegitBotNetCommandAndControlDomainsStrictOrder"
  }

  stateful_rule_group_reference {
    priority = 5
    resource_arn = "arn:aws:network-firewall:${var.aws_region}:aws-managed:stateful-rulegroup/MalwareDomainsStrictOrder"
  }

  stateful_rule_group_reference {
    priority = 6
    resource_arn = "arn:aws:network-firewall:${var.aws_region}:aws-managed:stateful-rulegroup/ThreatSignaturesIOCStrictOrder"
  }

  stateful_rule_group_reference {
    priority = 7
    resource_arn = "arn:aws:network-firewall:${var.aws_region}:aws-managed:stateful-rulegroup/ThreatSignaturesPhishingStrictOrder"
  }

  stateful_rule_group_reference {
    priority = 8
    resource_arn = "arn:aws:network-firewall:${var.aws_region}:aws-managed:stateful-rulegroup/ThreatSignaturesBotnetWebStrictOrder"
  }

  stateful_rule_group_reference {
    priority = 9
    resource_arn = "arn:aws:network-firewall:${var.aws_region}:aws-managed:stateful-rulegroup/ThreatSignaturesEmergingEventsStrictOrder"
  }

  stateful_rule_group_reference {
    priority = 10
    resource_arn = "arn:aws:network-firewall:${var.aws_region}:aws-managed:stateful-rulegroup/ThreatSignaturesMalwareWebStrictOrder"
  }

  stateful_rule_group_reference {
    priority = 11
    resource_arn = "arn:aws:network-firewall:${var.aws_region}:aws-managed:stateful-rulegroup/ThreatSignaturesExploitsStrictOrder"
  }

  stateful_rule_group_reference {
    priority = 12
    resource_arn = "arn:aws:network-firewall:${var.aws_region}:aws-managed:stateful-rulegroup/ThreatSignaturesWebAttacksStrictOrder"
  }

  stateful_rule_group_reference {
    priority = 13
    resource_arn =  "arn:aws:network-firewall:${var.aws_region}:aws-managed:stateful-rulegroup/ThreatSignaturesScannersStrictOrder"
  }

  stateful_rule_group_reference {
    priority = 14
    resource_arn =  "arn:aws:network-firewall:${var.aws_region}:aws-managed:stateful-rulegroup/ThreatSignaturesBotnetStrictOrder"
  }

  stateful_rule_group_reference {
    priority = 15
    resource_arn =  "arn:aws:network-firewall:${var.aws_region}:aws-managed:stateful-rulegroup/ThreatSignaturesMalwareStrictOrder"
  }

  stateful_rule_group_reference {
    priority = 16
    resource_arn =  "arn:aws:network-firewall:${var.aws_region}:aws-managed:stateful-rulegroup/ThreatSignaturesMalwareMobileStrictOrder"
  }

  stateful_rule_group_reference {
    priority = 17
    resource_arn =   "arn:aws:network-firewall:${var.aws_region}:aws-managed:stateful-rulegroup/ThreatSignaturesBotnetWindowsStrictOrder"
  }

  stateful_rule_group_reference {
    priority = 18
    resource_arn =   "arn:aws:network-firewall:${var.aws_region}:aws-managed:stateful-rulegroup/ThreatSignaturesSuspectStrictOrder"
  }

  stateful_rule_group_reference {
    priority = 19
    resource_arn =   "arn:aws:network-firewall:${var.aws_region}:aws-managed:stateful-rulegroup/ThreatSignaturesFUPStrictOrder"
  }
  
# Not adding ThreatSignaturesMalwareCoinminingStrictOrder because of over limit.

    stateless_fragment_default_actions = ["aws:forward_to_sfe"]    
    stateless_default_actions = ["aws:forward_to_sfe"]
    stateful_default_actions = ["aws:alert_strict"]
  }
}

resource "aws_networkfirewall_rule_group" "aws-ngfw-stateless" {
  name     = "${local.stackname_lowercase_hypn}-aws-ngfw-rule-group-stateless"
  capacity = 10
  type     = "STATELESS"

  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 1
          rule_definition {
            actions = ["aws:forward_to_sfe"]
            match_attributes {
              source {
                address_definition = var.aws_srv_test_cidr
              }
              destination {
                address_definition = var.aws_cli_test_cidr
              }
              #protocols =  [0]   # All protocols
            }
          }
        }
        stateless_rule {
          priority = 2
          rule_definition {
            actions = ["aws:forward_to_sfe"]
            match_attributes {
              source {
                address_definition = var.aws_cli_test_cidr
              }
              destination {
                address_definition = var.aws_srv_test_cidr
              }
              #protocols =  [0]  # All protocols
            }
          }
        }
      }
    }
  }

  tags = {
    Name = "cyperf-test-ngfw-stateless"
  }
}

resource "aws_cloudwatch_log_group" "aws-ngfw-log-grp" {
  name              = "/aws/network-firewall/logs/${local.numeric_timestamp}"
  retention_in_days = 30
}

resource "aws_networkfirewall_logging_configuration" "aws-ngfw-cw-log-config" {
  firewall_arn = aws_networkfirewall_firewall.aws-ngfw.arn
  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.aws-ngfw-log-grp.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
  }
}

####### PANFW #######
module "panfw" {
    depends_on = [aws_internet_gateway.aws_internet_gateway, time_sleep.wait_5_seconds]
    source = "./modules/aws_panfw"
    resource_group = {
        security_group = aws_security_group.aws_cyperf_security_group.id,
        security_group_test = aws_security_group.aws_agent_security_group.id,
        management_subnet = aws_subnet.aws_management_subnet.id
        client_subnet = aws_subnet.aws_cli_test_subnet_pan.id
        server_subnet = aws_subnet.aws_srv_test_subnet_pan.id
        bootstrap_profile = aws_iam_instance_profile.bootstrap_profile.name
    }
    aws_stack_name = var.aws_stack_name
    aws_owner = var.aws_owner
    aws_auth_key = var.aws_auth_key
    aws_panfw_machine_type = var.aws_panfw_machine_type
    panfw_init_cli = local.panfw_init_cli
}

##### Output ######

output "license_server" {
  value = var.aws_license_server
}

output "private_key_pem" {
  value     = tls_private_key.cyperf.private_key_pem
  sensitive = true
}

output "mdw_detail"{
  value = {
    "name" : module.mdw.mdw_detail.name,
    "public_ip" : module.mdw.mdw_detail.public_ip,
    "private_ip" : module.mdw.mdw_detail.private_ip
  }
}

output "panfw_detail"{
  value = {
    "name" : module.panfw.panfw_detail.name,
    "public_ip" : module.panfw.panfw_detail.public_ip,
    "private_ip" : module.panfw.panfw_detail.private_ip,
    "panfw_cli_private_ip" : module.panfw.panfw_detail.panfw_cli_private_ip,
    "panfw_srv_private_ip" : module.panfw.panfw_detail.panfw_srv_private_ip
  }
}

output "awsfw_client_agent_detail"{
  value = [for x in module.clientagents :   {
    "name" : x.agents_detail.name,
    "private_ip" : x.agents_detail.private_ip
  }]
}
  output "awsfw_server_agent_detail"{
  value = [for x in module.serveragents :   {
    "name" : x.agents_detail.name,
    "private_ip" : x.agents_detail.private_ip
  }]
}

output "panfw_client_agent_detail"{
  value = [for x in module.clientagents-pan :   {
    "name" : x.agents_detail.name,
    "private_ip" : x.agents_detail.private_ip
  }]
}
  output "panfw_server_agent_detail"{
  value = [for x in module.serveragents-pan :   {
    "name" : x.agents_detail.name,
    "private_ip" : x.agents_detail.private_ip
  }]
}


