#!/bin/bash

DOCKER_REPO="docker-local-isg.artifactory.it.keysight.com"
CURRENT_DIR="$(pwd)"
mkdir -p $CURRENT_DIR/.terraform
touch $CURRENT_DIR/terraform.tfstate
touch $CURRENT_DIR/terraform.tfstate.backup
touch $CURRENT_DIR/terraform.tfvars
docker login $DOCKER_REPO
docker run --rm -it \
       -v $CURRENT_DIR/terraform.tfvars:/pan-demo/terraform.tfvars \
       -v $CURRENT_DIR/terraform.tfstate:/pan-demo/terraform/terraform.tfstate \
       -v $CURRENT_DIR/terraform.tfstate.backup:/pan-demo/terraform/terraform.tfstate.backup \
       -v $CURRENT_DIR/.terraform:/pan-demo/terraform/.terraform \
       $DOCKER_REPO/tiger/pan-demo-tool:local "$@"
