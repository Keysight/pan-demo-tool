FROM docker-remote.artifactorylbj.it.keysight.com/debian:12-slim AS base
RUN apt update && apt install -y git gpg wget lsb-release python3 python3-pip python3-venv && \
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" \
    | tee /etc/apt/sources.list.d/hashicorp.list && \
    apt update && apt install -y terraform
COPY ./requirements.txt /pan-demo/requirements.txt
WORKDIR /pan-demo
RUN DISABLE_CACHE=1 git clone "https://bitbucket.it.keysight.com/scm/isgappsec/cyperf-api-wrapper.git"
RUN python3 -m venv /pan-demo/py3 && \
    . /pan-demo/py3/bin/activate && \
    pip install --no-cache --upgrade pip setuptools wheel && \
    pip install --no-cache -U -r /pan-demo/requirements.txt && \
    pip install --no-cache /pan-demo/cyperf-api-wrapper
RUN wget -P ./simple-ui https://artifactorylbj.it.keysight.com:443/artifactory/generic-local-wap/pan-demo-tool/simple-ui.tar
RUN wget -P ./simple-ui https://artifactorylbj.it.keysight.com:443/artifactory/generic-local-wap/pan-demo-tool/rest-stats-service-patch.tar
RUN wget -P ./simple-ui https://artifactorylbj.it.keysight.com:443/artifactory/generic-local-wap/pan-demo-tool/pan-demo-tool-report.mrt
COPY . .
# Get the simple UI and any other patches needed for MDW and make sure they are all in the simple-ui folder
RUN chmod +x ./entrypoint.sh
RUN mkdir -p /temp/terraform
ENTRYPOINT ["./entrypoint.sh"]
