variable "resource_group" {
  type = object({
    security_group       = string,
    security_group_test  = string,
    management_subnet    = string,
    client_subnet        = string,
    server_subnet        = string,
    user_assigned_identity = string,
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

variable "azure_panfw_machine_type" {
  type = string
  description = "PANFW instance type"
}

variable "panfw_init_cli" {
  type = string
  description = "PANFW init script"
}

variable "panfw_version" {
  type        = string
  default     = "11.2.5"
  description = "Version for the PAN FW"
}

variable "panfw_publisher" {
  type        = string
  default     = "paloaltonetworks"
  description = "Publisher name for the PAN FW"
}

variable "panfw_offer" {
  type        = string
  default     = "vmseries-flex"
  description = "Offer name for the PAN FW"
}

variable "panfw_sku" {
  type        = string
  default     = "bundle2"
  description = "sku name for the PAN FW"
}

variable "admin_username" {
  type        = string
  default     = "cyperf"
  description = "admin username for the PAN FW"
}

