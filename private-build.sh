#!/bin/bash
set -e

DOCKER_REPO="docker-local-isg.artifactory.it.keysight.com"
wget 'https://bitbucket.it.keysight.com/projects/ISGAPPSEC/repos/cyperf-pan-demo/raw/certificates-handling/host-certs.zip?at=refs%2Fheads%2Fmain' -O host-certs.zip
unzip host-certs.zip
docker build --tag $DOCKER_REPO/tiger/pan-demo-tool:local "$@" -f docker/deploy.Dockerfile .
mkdir -p publish/
docker save "$DOCKER_REPO/tiger/pan-demo-tool:local" > publish/pan_demo_setup.tar
cp pan_demo_setup.sh publish/
cp terraform-*.tfvars publish/
echo "Successfully built publish/pan_demo_setup.tar"
echo "To share with others, share all of the files in publish/"
