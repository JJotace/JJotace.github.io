#!/usr/bin/env bash
# Installs kind v0.33.0 and kubectl v1.37.0 into ~/.local/bin after verifying checksums.
set -euo pipefail

KIND_VERSION=v0.33.0
KUBECTL_VERSION=v1.37.0
BIN="$HOME/.local/bin"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$BIN"
cd "$TMP"

curl -fsSLo kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"
curl -fsSLo kind.sha256 "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64.sha256sum"
echo "$(cut -d' ' -f1 kind.sha256)  kind" | sha256sum -c

curl -fsSLo kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
curl -fsSLo kubectl.sha256 "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum -c

install -m 0755 kind kubectl "$BIN/"
"$BIN/kind" version
"$BIN/kubectl" version --client
