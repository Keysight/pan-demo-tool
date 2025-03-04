#!/bin/bash
DOCKER_REPO="docker-local-isg.artifactory.it.keysight.com"
docker build --tag $DOCKER_REPO/tiger/pan-demo-tool:local "$@" -f docker/deploy.Dockerfile .
docker save "$DOCKER_REPO/tiger/pan-demo-tool:local" -o pan_demo_setup.tar
