#!/bin/bash
DOCKER_REPO="docker-local-isg.artifactory.it.keysight.com"
BASE_CONTAINER="pan_demo_setup.tar"
if [[ ! -f $BASE_CONTAINER ]]; then
    echo "Missing the $BASE_CONTAINER container required for public builds. Please contact Keysight to request a copy. "
    echo "If running in Keysight network, please run ./private-build.sh to generate the required file."
    exit 1
fi
docker load -i $BASE_CONTAINER
docker build --tag $DOCKER_REPO/tiger/pan-demo-tool:local "$@" -f docker/public-build.Dockerfile .
mkdir -p publish/
docker save "$DOCKER_REPO/tiger/pan-demo-tool:local" -o publish/pan_demo_setup.tar
cp pan_demo_setup publish/
cp terraform.tfvars publish/
echo "Successfully built publish/pan_demo_setup.tar"
echo "To share with others, share all of the files in publish/"
