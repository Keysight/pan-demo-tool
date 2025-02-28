#!/bin/bash
DOCKER_REPO="docker-local-isg.artifactory.it.keysight.com"
docker build --tag $DOCKER_REPO/tiger/pan-demo-tool:local "$@" -f docker/Dockerfile .
