FROM ubuntu:26.04
LABEL MAINTAINER="CD-Minerva"

ENV TERM=xterm
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Amsterdam
ENV PIP_BREAK_SYSTEM_PACKAGES=1

# ENV SONAR_SCANNER_VERSION_ZIP=sonar-scanner-cli-4.0.0.1744-linux.zip
# ENV SONAR_SCANNER_VERSION=sonar-scanner-4.0.0.1744-linux
# ENV E2J2_SEARCHLIST=/etc,/usr/local/bin

ENV K8S_URL=https://dl.k8s.io/release
ENV KUBECTL_VERSION=1.37.2
ENV HELM_VERSION=3.22.1
ENV RANCHER_VERSION=2.15.3
ENV E2J2_VERSION=0.9.0
ENV PLUTO_VERSION=5.24.5
ENV ARGO_VERSION=4.1.6
ENV TRIVY_VERSION=0.76.1

USER root

# Update base system
RUN cat /etc/os-release && \
    apt-get update && \
    apt-get -y install --no-install-recommends apt-utils && \
    apt-get update --fix-missing && \
    apt-get -y upgrade && \
    apt-get -y install --no-install-recommends dialog locales iproute2 && \
    locale-gen en_US.UTF-8 && echo "LANG=en_US.UTF-8" > /etc/default/locale

# Install utility packages
RUN apt-get -y install --no-install-recommends ca-certificates \
     git \
     jq \
     maven \
     curl \
     gnupg \
     lsb-release \
     python3 \
     python3-pip \
 && update-ca-certificates \
 && update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# Install docker CLI suite
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      docker-ce-cli \
      docker-buildx-plugin \
      docker-compose-plugin \
 && rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN curl -s -LO ${K8S_URL}/v${KUBECTL_VERSION}/bin/linux/$(dpkg --print-architecture)/kubectl && \
    mv kubectl /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    kubectl version --client

# Install helm3
RUN curl -sL https://get.helm.sh/helm-v${HELM_VERSION}-linux-$(dpkg --print-architecture).tar.gz |tar xvz && \
    mv linux-$(dpkg --print-architecture)/helm /usr/bin/helm && \
    chmod +x /usr/bin/helm && \
    rm -rf linux-$(dpkg --print-architecture) && \
    helm plugin install --version master https://github.com/sonatype-nexus-community/helm-nexus-push.git && \
    helm version
# Patch nexus plugin to prevent undeclared vars
RUN sed -ri 's/^(declare (USERNAME|PASSWORD))$/\1=""/g' $HOME/.local/share/helm/plugins/helm-nexus-push.git/push.sh

# Install trivy
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then TRIVY_ARCH="64bit"; elif [ "$ARCH" = "arm64" ]; then TRIVY_ARCH="ARM64"; else TRIVY_ARCH="$ARCH"; fi && \
    curl -sL "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${TRIVY_ARCH}.tar.gz" | tar xzf - -C /usr/bin trivy && \
    chmod +x /usr/bin/trivy && \
    trivy --version

# Install E2J2
RUN pip install --no-cache-dir e2j2==${E2J2_VERSION}

# Install ArgoWorkflows
RUN curl -sLO  https://github.com/argoproj/argo-workflows/releases/download/v${ARGO_VERSION}/argo-linux-$(dpkg --print-architecture).gz && \
    gunzip argo-linux-$(dpkg --print-architecture).gz && \
    mv argo-linux-$(dpkg --print-architecture) /usr/bin/argo && \
    chmod a+x /usr/bin/argo && \
    argo version

# Install pluto (https://github.com/FairwindsOps/pluto/releases)
RUN curl -sL https://github.com/FairwindsOps/pluto/releases/download/v${PLUTO_VERSION}/pluto_${PLUTO_VERSION}_linux_$(dpkg --print-architecture).tar.gz | tar xvz pluto && \
    mv pluto /usr/bin/pluto && \
    chmod a+x /usr/bin/pluto && \
    rm -f LICENSE README.md && \
    pluto version

HEALTHCHECK --interval=15s --timeout=5s --retries=5 CMD echo up
CMD ["/bin/bash"]
