
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
aws_stack_name="<short name for your setup>"
aws_region="us-west-2"
aws_access_key_id="XXXXXXXXXXXXX"
aws_secret_access_key="XXXXXXXXXXXXXXX"
aws_session_token="XXXXXXXX"
aws_auth_key="<name of AWS key pair for SSH access>"
aws_allowed_cidr=["<enter the subnet you want to allow for accessing the controller>"]
aws_license_server="<IP or hostname of CyPerf license server>"
```
# IAM role

This script needs to create an IAM role with the policy below.
This is required to upload and download from the newly created s3 bucket.
Please note, that the AWS user must have the privilege to create an IAM role with the below policy.
```
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Action": "s3:ListBucket",
			"Effect": "Allow",
			"Resource": "arn:aws:s3:::<bucket name>"
		},
		{
			"Action": "s3:GetObject",
			"Effect": "Allow",
			"Resource": "arn:aws:s3:::<bucket name>/*"
		}
	]
}
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




 


