#!/bin/bash
DOCKER_REPO="docker-local-isg.artifactory.it.keysight.com"
docker build --tag $DOCKER_REPO/tiger/pan-demo-tool:local "$@" -f docker/deploy.Dockerfile .
mkdir -p publish/
docker save "$DOCKER_REPO/tiger/pan-demo-tool:local" > publish/pan_demo_setup.tar
cp pan_demo_setup.sh publish/
cp terraform-*.tfvars publish/
echo "Successfully built publish/pan_demo_setup.tar"
echo "To share with others, share all of the files in publish/"
