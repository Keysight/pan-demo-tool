#!/bin/bash

echo "Switching to simple UI ..."

DOCKER_CMD=docker
NERDCTL_CMD=nerdctl
# Switch between Docker and containerd runtime
CONTAINER_CMD=$NERDCTL_CMD

if [[ -f /home/cyperf/.kube/config ]] ; then
   export KUBECONFIG=/home/cyperf/.kube/config
else
   export KUBECONFIG=/etc/kubernetes/admin.conf
fi


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
		CURRENT_REST_STATS_IMAGE=$(kubectl -n keysight-wap get deployment/rest-stats-service -o jsonpath='{.spec.template.spec.containers[?(@.name=="rest-stats-service")].image}')
		ORIGINAL_REST_STATS_VERSION=${CURRENT_REST_STATS_IMAGE##*:}
		echo "ORIGINAL_REST_STATS_VERSION=$ORIGINAL_REST_STATS_VERSION" >> original-versions.env
		$CONTAINER_CMD save docker-virtual-wap.artifactorylbj.it.keysight.com/rest-stats-service:$ORIGINAL_REST_STATS_VERSION --output rest-stats-service-original.tar
		echo "    ... done backing up"
	fi
	echo "    ... applying patches"
	$CONTAINER_CMD load < rest-stats-service-patch.tar
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
		CURRENT_UI_IMAGE=$(kubectl -n keysight-wap get deployment/wapui -o jsonpath='{.spec.template.spec.containers[?(@.name=="wap-ui")].image}')
		ORIGINAL_UI_VERSION=${CURRENT_UI_IMAGE##*:}
		echo "ORIGINAL_UI_VERSION=$ORIGINAL_UI_VERSION" >> original-versions.env
		$CONTAINER_CMD save docker-virtual-wap.artifactorylbj.it.keysight.com/wap-ui:$ORIGINAL_UI_VERSION --output wap-ui-original.tar
		echo "    ... done backing up UI"
	fi
	echo "    ... switching to simple UI"
	echo "    ... updating wapui configmap and ingress to root base path"
	kubectl -n keysight-wap patch configmap wapui-configmap --type merge -p "$(kubectl -n keysight-wap get configmap wapui-configmap -o json | jq -c '{data: {"config.json": (.data."config.json" | sub("\"appBasePath\": *\"/cyperf\""; "\"appBasePath\": \"/\""))}}')"
	WAPUI_INGRESS=$(kubectl -n keysight-wap get ingress -l app.kubernetes.io/name=wap-ui -o jsonpath='{.items[0].metadata.name}')
	if kubectl -n keysight-wap get ingress "$WAPUI_INGRESS" -o jsonpath='{.metadata.annotations.nginx\.ingress\.kubernetes\.io/app-root}' | grep -q .; then
		kubectl -n keysight-wap patch ingress "$WAPUI_INGRESS" --type=json -p='[{"op":"replace","path":"/spec/rules/0/http/paths/0/path","value":"/"},{"op":"remove","path":"/metadata/annotations/nginx.ingress.kubernetes.io~1app-root"}]'
	else
		kubectl -n keysight-wap patch ingress "$WAPUI_INGRESS" --type=json -p='[{"op":"replace","path":"/spec/rules/0/http/paths/0/path","value":"/"}]'
	fi
	$CONTAINER_CMD load < simple-ui.tar
	kubectl -n keysight-wap set image deployment/wapui wap-ui=docker-virtual-wap.artifactorylbj.it.keysight.com/simple-ui:1.0.0-pan
	kubectl -n keysight-wap rollout restart deployment  wapui
	kubectl -n keysight-wap wait --for=condition=available deployments/wapui --timeout 120s
	echo "    ... simple UI enabled"
else
	echo "    ... no UI to switch to"
fi

echo "... switch to simple workflow completed"
