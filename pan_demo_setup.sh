#!/bin/bash

DOCKER_REPO="docker-local-isg.artifactory.it.keysight.com"
CURRENT_DIR="$(pwd)"
mkdir -p terraform-state-aws/.terraform
touch terraform-state-aws/terraform.tfstate
touch terraform-state-aws/terraform.tfstate.backup
cp terraform-aws.tfvars terraform-state-aws/
mkdir -p terraform-state-azure/.terraform
touch terraform-state-azure/terraform.tfstate
touch terraform-state-azure/terraform.tfstate.backup
cp terraform-azure.tfvars terraform-state-azure/
docker load -i pan_demo_setup.tar
docker run --rm -it \
       -v "$CURRENT_DIR/terraform-state-azure":/pan-demo/terraform-state-azure \
       -v "$CURRENT_DIR/terraform-state-aws":/pan-demo/terraform-state-aws \
       -e CYPERF_EULA_ACCEPTED=$PALOALTONETWORKS_MARKETPLACE_AND_KEYSIGHT_EULA_ACCEPTED \
       $DOCKER_REPO/tiger/pan-demo-tool:local "$@"
