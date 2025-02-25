# Terraform deployments

# Introduction

This Terraform sciprt deploy CyPerf Controller, CyPerf Agents, AWS Network firewall, PAN FW in aws cloud providers.
All the necessary resources will be created from scratch, including VPC, subnets, route table, Security group, Internet Gateway, PAN FW, NGFW etc.

# Prerequisites

- Linux box
- Install latest version of Terraform https://learn.hashicorp.com/tutorials/terraform/install-cli
- git clone https://github.com/Keysight/pan-demo-tool.git
- AWS CLI Credentials.
- s3 bucket where PAN config stored.
- update terraform.tfvars flies with below parameters
```
aws_stack_name="<stack name eg. cyperftest>"
aws_region="<AWS region eg. us-west-2>"
aws_access_key_id="XXXXXXXXXXXXX"
aws_secret_access_key="XXXXXXXXXXXXXXX"
aws_session_token="XXXXXXXX"
panfw_bootstrap_bucket="<s3 bucket where PAN config stored>"
```

# How to use:

A python script 'cyperf_e2e.py' will deploy entire topology and retrun CyPerf controller IP.

```
python3 cyperf_e2e.py
```
# Destroy the setup

```
terraform -chdir=./terraform destroy -auto-approve
```




 


