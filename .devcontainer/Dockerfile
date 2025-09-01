FROM mcr.microsoft.com/devcontainers/base:ubuntu

# System Update und grundlegende Tools
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    telnet \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# kubectl installieren
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/kubectl

# Helm installieren
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Kind installieren
RUN curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64 \
    && chmod +x ./kind \
    && mv ./kind /usr/local/bin/kind

# k9s installieren
RUN curl -Lo ./k9s.tar.gz https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz \
    && tar -xzf k9s.tar.gz \
    && mv k9s /usr/local/bin/k9s \
    && rm k9s.tar.gz
