# Introduction

This document describes how user can deploy the Keysight CyPerf controller, and agents, along with the Palo Alto VM series firewall and Azure Network Firewall at Azure cloud or AWS Network Firewall, inside a Docker Container. The following sections contain information about the prerequisites, deployment, and destruction of setups and config using a sample bash script.

All the necessary resources will be created from scratch, including Vnet, subnets, route table, Security group, Internet Gateway, PAN FW, NGFW etc.

# Prerequisites

- Linux box
- git clone https://github.com/Keysight/pan-demo-tool.git
- Install Docker Engine in your desired host platform if not already. Refer [Install Docker Engine Server](https://docs.docker.com/engine/install/#server) for more details.
- AWS CLI Credentials and Azure CLI Credentials.
- update terraform-azure.tfvars flies with below parameters
```
azure_stack_name="<short name for your setup>"
azure_location="eastus"
azure_client_id="XXXXXXXXXXXXX"
azure_client_secret="XXXXXXXXXXXXXXX"
azure_tenant_id="XXXXXXXXXXXXXXX"
azure_subscription_id="XXXXXXXXXXXXXXX"
azure_auth_key="<ssh-keygen generated public key content for SSH access>"
azure_allowed_cidr=["<enter your public IP here>"]
azure_license_server="<IP or hostname of CyPerf license server>"
tag_ccoe-app="<tag value for the cccoe-app tag>"
tag_ccoe-group="<tag value for the cccoe-group tag>"
tag_UserID="<tag value for the UserID tag>"
```
- update terraform-aws.tfvars flies with below parameters
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
# (AWS only) IAM role

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

# Deploy the setup (AWS)

A shell script `pan_demo_setup.sh` will deploy entire topology and configure test for ready to run.

```
pan_demo_setup --deploy-aws
```
# Destroy the setup (AWS)

```
pan_demo_setup.sh --destroy-aws
```

# Deploy the setup (Azure)

A shell script `pan_demo_setup.sh` will deploy entire topology and configure test for ready to run.

```
pan_demo_setup --deploy-azure
```
# Destroy the setup (Azure)

```
pan_demo_setup.sh --destroy-azure
```
# Building a new version

## Outside Keysight network 

After modifying any of the files, you can use the `public-build.sh` to build a new container. You will need to start from an initial Keysight-built `pan_demo_setup.tar` file as a base, that you will have to copy to the root of this repo.

If your network uses MITM technologies to secure traffic, you may need to export the trusted certificates from your current system and import them into the container. To do this, you should be able to run `./export_certs.sh`, which will populate the `./host-certs` dir with all trusted certificates from your current system. 

## From inside Keysight network

After modifying any of the files, you can use the `private-build.sh` to build a new container.
