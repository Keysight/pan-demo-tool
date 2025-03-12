variable "resource_group" {
  type    = object({
    security_group = string,
    security_group_test = string,
    management_subnet = string,
    client_subnet = string,
    server_subnet = string,
    bootstrap_profile = string
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

variable "aws_auth_key" {
  type = string
  description = "The key used to ssh into VMs"
}

variable "aws_panfw_machine_type"{
  type = string
  description = "PANFW instance type"
}

variable "panfw_init_cli" { 
  type = string
  description = "panfw init script"
}

variable "panfw_version" {
  type        = string
  default     = "PA-VM-AWS-11.2.3-h3"
  description = "Version for the pan fw"
}

variable "panfw_ami_name" {
  type        = string
  default     = "PA-VM-AWS-11.2.5-0825b781-215f-4686-8da2-b95275cc8dd0"
  description = "AMI name for the pan fw"
}

variable "panfw_product_code" {
  type        = string
  default     = "hd44w1chf26uv4p52cdynb2o"
  description = "Product code from the AWS Marketplace for the PAN FW"
}


