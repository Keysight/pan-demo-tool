#!/bin/bash

echo "Switching to regular CyPerf workflow ..."

DOCKER_CMD=docker
NERDCTL_CMD=nerdctl
# Switch between Docker and containerd runtime
CONTAINER_CMD=$NERDCTL_CMD

if [[ -f /home/cyperf/.kube/config ]] ; then
   export KUBECONFIG=/home/cyperf/.kube/config
else
   export KUBECONFIG=/etc/kubernetes/admin.conf
fi

if test -f original-versions.env; then
   . ./original-versions.env
fi

# Switch to full UI container
if test -f simple-ui.tar; then
	if test -f wap-ui-original.tar; then
		$CONTAINER_CMD load < wap-ui-original.tar
	else
		echo "    ... backup of full UI not found - optimistically continuing the restore process"
	fi
	echo "    ... reverting to full UI"
	echo "    ... restoring wapui configmap and ingress to /cyperf base path"
	kubectl -n keysight-wap patch configmap wapui-configmap --type merge -p "$(kubectl -n keysight-wap get configmap wapui-configmap -o json | jq -c '{data: {"config.json": (.data."config.json" | sub("\"appBasePath\": *\"/\""; "\"appBasePath\": \"/cyperf\""))}}')"
	WAPUI_INGRESS=$(kubectl -n keysight-wap get ingress -l app.kubernetes.io/name=wap-ui -o jsonpath='{.items[0].metadata.name}')
	kubectl -n keysight-wap patch ingress "$WAPUI_INGRESS" --type=json -p='[{"op":"replace","path":"/spec/rules/0/http/paths/0/path","value":"/cyperf"},{"op":"add","path":"/metadata/annotations/nginx.ingress.kubernetes.io~1app-root","value":"/cyperf/"}]'
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
		$CONTAINER_CMD load < rest-stats-service-original.tar
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
