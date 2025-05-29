variable "resource_group" {
  type = object({
    security_group    = string,
    management_subnet = string,
    resource_group_name = string
  })
  description = "Azure resource group where you want to deploy in"
}

variable "azure_location" {
  type    = string
}

variable "azure_stack_name" {
  type = string
  description = "Stack name, prefix for all resources"
}

variable "azure_owner" {
  type = string
  description = "Owner of the stack"
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

variable "azure_auth_key" {
  type = string
  description = "The key used to SSH into VMs"
}

variable "azure_mdw_machine_type" {
  type = string
  description = "MDW instance type"
}

variable "mdw_init" {
  type = string
  description = "MDW init script"
}

variable "mdw_version" {
  type        = string
  default     = "keysight-cyperf-controller-60"
  description = "Version for the CyPerf controller"
}

variable "cyperf_version" {
  type        = string
  default     = "0.6.0"
  description = "Version for the CyPerf controller"
}

variable "mdw_image_name" {
  type        = string
  default     = "cyperf-controller-image"
  description = "Name of the CyPerf controller image in Azure"
}
