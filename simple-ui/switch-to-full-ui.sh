#!/bin/bash

echo "Switching to regular CyPerf workflow ..."

ORIGINAL_UI_VERSION=2.60.317-appsec
ORIGINAL_REST_STATS_VERSION=1.0.14215-releasecyperf60
DOCKER_CMD=docker

# Switch to full UI container
if test -f simple-ui.tar; then
	if test -f wap-ui-original.tar; then
		$DOCKER_CMD load < wap-ui-original.tar
	else
		echo "    ... backup of full UI not found - optimistically continuing the restore process"
	fi
	echo "    ... reverting to full UI"
	kubectl -n keysight-wap set image deployment/wapui wap-ui=docker-virtual-wap.artifactorylbj.it.keysight.com/wap-ui:$ORIGINAL_UI_VERSION
	kubectl -n keysight-wap rollout restart deployment  wapui
	kubectl -n keysight-wap wait --for=condition=available deployments/wapui --timeout 120s
	echo "    ... full UI enabled"
else
	echo "    ... UI switch not enabled"
fi


# Undo patches
if test -f rest-stats-service-patch.tar; then
	if test -f rest-stats-service-original.tar; then
		$DOCKER_CMD load < rest-stats-service-original.tar
	else
		echo "    ... backup of patches services not found - optimistically continuing the restore process"
	fi
	echo "    ... reverting patches"
	kubectl -n keysight-wap set image deployment/rest-stats-service rest-stats-service=docker-virtual-wap.artifactorylbj.it.keysight.com/rest-stats-service:$ORIGINAL_REST_STATS_VERSION
	kubectl -n keysight-wap rollout restart deployment  rest-stats-service
	kubectl -n keysight-wap wait --for=condition=available deployments/rest-stats-service --timeout 120s
	echo "    ...  patches reverted"
else
	echo "    ... no private patches to undo"
fi

echo "... switch to regular workflow completed"
