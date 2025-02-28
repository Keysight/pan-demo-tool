FROM docker-remote.artifactorylbj.it.keysight.com/debian:12-slim
RUN apt update && apt install -y python3 python3-pip python3-venv git gpg wget lsb-release
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" \
    | tee /etc/apt/sources.list.d/hashicorp.list
RUN apt update && apt install -y terraform
WORKDIR /pan-demo
COPY ./requirements.txt /pan-demo/requirements.txt
RUN DISABLE_CACHE=1 git clone "https://bitbucket.it.keysight.com/scm/isgappsec/cyperf-api-wrapper.git"
RUN python3 -m venv /pan-demo/py3 && \
    . /pan-demo/py3/bin/activate && \
    pip install --no-cache --upgrade pip setuptools wheel && \
    pip install --no-cache -U -r requirements.txt && \
    pip install --no-cache ./cyperf-api-wrapper
COPY . .
RUN chmod +x ./entrypoint.sh && \
    ./entrypoint.sh
RUN mkdir -p /temp/terraform && \
    cp -r terraform/.terraform /temp/.terraform && \
    cp terraform/.terraform.lock.hcl /temp/
ENTRYPOINT ["./entrypoint.sh"]