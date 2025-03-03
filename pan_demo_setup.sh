#!/bin/bash

DOCKER_REPO="docker-local-isg.artifactory.it.keysight.com"
CURRENT_DIR="$(pwd)"
mkdir -p terraform-state/.terraform
touch terraform-state/terraform.tfstate
touch terraform-state/terraform.tfstate.backup
cp terraform.tfvars terraform-state/terraform.tfvars
docker login $DOCKER_REPO
docker run --rm -it \
       -v $CURRENT_DIR/terraform-state:/pan-demo/terraform-state \
       $DOCKER_REPO/tiger/pan-demo-tool:local "$@"
