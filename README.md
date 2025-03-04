
# Introduction

This document describes how user can deploy the Keysight CyPerf controller, and agents, along with the Palo Alto VM series firewall and AWS Network Firewall, inside a Docker Container. The following sections contain information about the prerequisites, deployment, and destruction of setups and config using a sample bash script.

All the necessary resources will be created from scratch, including VPC, subnets, route table, Security group, Internet Gateway, PAN FW, NGFW etc.

# Prerequisites

- Linux box
- git clone https://github.com/Keysight/pan-demo-tool.git
- Install Docker Engine in your desired host platform if not already. Refer [Install Docker Engine Server](https://docs.docker.com/engine/install/#server) for more details.
- AWS CLI Credentials.
- update terraform.tfvars flies with below parameters
```
aws_stack_name="pan-demo"
aws_region="us-west-2"
aws_access_key_id="XXXXXXXXXXXXX"
aws_secret_access_key="XXXXXXXXXXXXXXX"
aws_session_token="XXXXXXXX"
aws_auth_key="<optional>"
aws_allowed_cidr=["<allowed cidr for accessing resources>"]
aws_license_server="x.x.x.x"
```

# Deploy the setup

A shell script 'pan_demo_setup.sh' will deploy entire topology and configure test for ready to run.

```
pan_demo_setup.sh --deploy
```
# Destroy the setup

```
pan_demo_setup.sh --destroy
```




 


