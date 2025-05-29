variable "azure_location" {
  type    = string
  default = "eastus"
}

variable "azure_main_cidr" {
  type = string
  default = "10.0.0.0/16"
  description = "Azure VNet CIDR"
}

variable "azure_mgmt_cidr" {
  type = string
  default = "10.0.1.0/24"
  description = "Azure management subnet"
}

variable "azure_agent_mgmt_cidr" {
  type = string
  default = "10.0.2.0/24"
  description = "Azure agent management subnet"
}

variable "azure_mgmt_firewall_cidr" {
  type = string
  default = "10.0.3.0/24"
  description = "Azure firewall subnet"
}

variable "azure_cli_test_cidr" {
  type = string
  default = "10.0.4.0/24"
  description = "Azure client test subnet"
}

variable "azure_cli_test_cidr_pan" {
  type = string
  default = "10.0.6.0/24"
  description = "Azure client test subnet"
}

variable "azure_srv_test_cidr" {
  type = string
  default = "10.0.5.0/24"
  description = "Azure server test subnet"
}

variable "azure_srv_test_cidr_pan" {
  type = string
  default = "10.0.7.0/24"
  description = "Azure server test subnet"
}

variable "azure_firewall_cidr" {
  type = string
  default = "10.0.8.0/24"
  description = "Azure firewall subnet"
}

variable "azure_client_id" {
  type = string
  default = "xxxxxxxxxxxx"
  description = "Azure client ID"
}

variable "azure_client_secret" {
  type = string
  default = "xxxxxxxxxxx"
  description = "Azure client secret"
}

variable "azure_tenant_id" {
  type = string
  default = "xxxxxxxxxxxx"
  description = "Azure tenant ID"
}

variable "azure_subscription_id" {
  type = string
  default = "xxxxxxxxxxxx"
  description = "Azure subscription ID"
}

variable "azure_auth_key" {
  type = string
  default = "secret key"
  description = "The key used to SSH into VMs"
}

variable "azure_stack_name" {
  type = string
  default = "cyperftest"
  description = "Stack name or resource group name, prefix for all resources"
}

variable "azure_owner" {
  type = string
  default = "default"
  description = "Owner of the stack"
}

variable "azure_allowed_cidr" {
  type = list(string)
  default = ["0.0.0.0/0"]
  description = "List of IPs allowed to access the deployed machines"
}

variable "azure_mdw_machine_type" {
  type = string
  default = "Standard_F16s_v2"
  description = "MDW instance type"
}

variable "azure_agent_machine_type" {
  type = string
  default = "Standard_F16s_v2"
  description = "Agent machines instance type - Possible options: Standard_F4s_v2 / Standard_F16s_v2 / Standard_D48s_v4 / Standard_D48_v4"
}

variable "azure_panfw_machine_type" {
  type = string
  default = "Standard_D8_v4"
  description = "PANFW instance type"
}

variable "clientagents" {
  type = number
  default = 1
  description = "Number of clients to be deployed for Azure Firewall"
}

variable "serveragents" {
  type = number
  default = 1
  description = "Number of servers to be deployed for Azure Firewall"
}

variable "clientagents_pan" {
  type = number
  default = 1
  description = "Number of clients to be deployed for PANFW"
}

variable "serveragents_pan" {
  type = number
  default = 1
  description = "Number of servers to be deployed for PANFW"
}

variable "controller_username" {
  type        = string
  default     = "admin"
  description = "Controller's authentication username"
}

variable "controller_password" {
  type        = string
  default     = "CyPerf&Keysight#1"
  description = "Controller's authentication password"
}

variable "azure_license_server" {
  type = string
  default = ""
  description = "Azure CyPerf controller license server"
}

variable "tag_ccoe-app" {
  type = string
  default = ""
  description = "PAN mandetory tag ccoe-app"
}

variable "tag_ccoe-group" {
  type = string
  default = ""
  description = "PAN mandetory tag ccoe-group"
}

variable "tag_UserID" {
  type = string
  default = ""
  description = "PAN mandetory tag UserID"
}
