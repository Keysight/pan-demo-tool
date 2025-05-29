variable "resource_group" {
  type = object({
    azure_agent_security_group = string,
    azure_ControllerManagementSubnet = string,
    azure_AgentTestSubnet = string,
    user_assigned_identity = string,
    resource_group_name = string
  })
  description = "Azure resource group where you want to deploy in"
}

variable "tags" {
  type = object({
    azure_owner = string,
    project_tag = string,
    options_tag = string,
    tag_ccoe-app = string,
    tag_ccoe-group = string,
    tag_UserID = string
  })
  description = "Azure tags"
}

variable "azure_location" {
  type    = string
}

variable "azure_stack_name" {
  type = string
  description = "Stack name, prefix for all resources"
}

variable "azure_auth_key" {
  type = string
  description = "The key used to SSH into VMs"
}

variable "azure_agent_machine_type" {
  type = string
  description = "Agent machines instance type"
}

variable "agent_role" {
  type = string
  description = "Agent role: server or client"
}

variable "agent_init_cli" {
  type = string
  description = "Init script"
}

variable "agent_version" {
  type        = string
  default     = "keysight-cyperf-agent-60"
  description = "Version for the CyPerf agent"
}

variable "cyperf_version" {
  type        = string
  default     = "0.6.0"
  description = "Version for the CyPerf agent"
}

variable "agent_image_name" {
  type        = string
  default     = "cyperf-agent-image"
  description = "Name of the CyPerf agent image in Azure"
}
