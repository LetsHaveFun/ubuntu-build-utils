# ubuntu-build-utils

Create an Ubuntu resolute (26.04 LTS) based image for CI/CD pipelines.
The following tools are included:
- kubectl
- helm3
- pluto
- e2j2
- trivy
- argoworkflows

## Usage

Pull the public container image from GitHub Container Registry:

```bash
docker pull ghcr.io/letshavefun/ubuntu-build-utils:latest
```

## Configuration

Update the following variables if necessary.

```bash
ENV KUBECTL_VERSION=1.37.2
ENV HELM_VERSION=3.22.1
ENV E2J2_VERSION=0.9.0
ENV PLUTO_VERSION=5.24.5
ENV ARGO_VERSION=4.1.6
ENV TRIVY_VERSION=0.76.1
```
