variable "resource_group" {
  type    = object({
    security_group = string,
    management_subnet = string
  })
  description = "AWS resource group where you want to deploy in"
}

variable "aws_stack_name" {
  type = string
  description = "Stack name, prefix for all resources"
}

variable "aws_owner" {
  type = string
  description = "Stack name, prefix for all resources"
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

variable "aws_auth_key" {
  type = string
  description = "The key used to ssh into VMs"
}

variable "aws_mdw_machine_type"{
  type = string
  description = "MDW instance type"
}

variable "mdw_init" { 
  type = string
  description = "mdw init script"
}

variable "mdw_version" {
  type        = string
  default     = "keysight-cyperf-controller-7-0"
  description = "Version for the cyperf controller"
}

variable "mdw_product_code" {
  type        = string
  default     = "8nmwoluc06w5z6vbutcwyueje"
  description = "Product code from the AWS Marketplace for the cyperf controller"
}

