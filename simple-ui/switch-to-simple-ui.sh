#!/bin/bash

echo "Switching to simple UI ..."

ORIGINAL_UI_VERSION=2.60.317-appsec
ORIGINAL_REST_STATS_VERSION=1.0.14215-releasecyperf60
DOCKER_CMD=docker

# Update the PDF template
if test -f pan-demo-tool-report.mrt; then
        TARGET_DIR=$(find / -type d -name "*_pdf-report-templates" 2>/dev/null)
        cp -f pan-demo-tool-report.mrt $TARGET_DIR/ &>/dev/null
        echo "    .... PDF template updated"
else
        echo "    .... no PDF template to update"
fi

# Apply stats patches
if test -f rest-stats-service-patch.tar; then
	if ! test -f rest-stats-service-original.tar; then
		echo "    ... creating backup of patches services"
		$DOCKER_CMD save docker-virtual-wap.artifactorylbj.it.keysight.com/rest-stats-service:$ORIGINAL_REST_STATS_VERSION --output rest-stats-service-original.tar
		echo "    ... done backing up"
	fi
	echo "    ... applying patches"
	$DOCKER_CMD load < rest-stats-service-patch.tar
	kubectl -n keysight-wap set image deployment/rest-stats-service rest-stats-service=docker-virtual-wap.artifactorylbj.it.keysight.com/rest-stats-service:1.0.0-pan
	kubectl -n keysight-wap rollout restart deployment  rest-stats-service
	kubectl -n keysight-wap wait --for=condition=available deployments/rest-stats-service --timeout 120s
	echo "    ... private patches applied"
else
	echo "    ... no private patches to apply"
fi

# Switch to UI container
if test -f simple-ui.tar; then
	if ! test -f wap-ui-original.tar; then
		echo "    ... creating backup of full UI"
		$DOCKER_CMD save docker-virtual-wap.artifactorylbj.it.keysight.com/wap-ui:$ORIGINAL_UI_VERSION --output wap-ui-original.tar
		echo "    ... done backing up UI"
	fi
	echo "    ... switching to simple UI"
	$DOCKER_CMD load < simple-ui.tar
	kubectl -n keysight-wap set image deployment/wapui wap-ui=docker-virtual-wap.artifactorylbj.it.keysight.com/simple-ui:1.0.0-pan
	kubectl -n keysight-wap rollout restart deployment  wapui
	kubectl -n keysight-wap wait --for=condition=available deployments/wapui --timeout 120s
	echo "    ... simple UI enabled"
else
	echo "    ... no UI to switch to"
fi

echo "... switch to simple workflow completed"
