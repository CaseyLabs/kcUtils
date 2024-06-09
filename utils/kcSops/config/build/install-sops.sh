#!/bin/bash

## `misc/install-sops.sh`
##
## - Shell script to install Mozilla `sops`
## - uses `sudo`` if not running as root

function run_as_root() {
    if [ "$EUID" -ne 0 ]; then
        sudo "$@"
    else
        "$@"
    fi
}

# Determine OS and architecture
os=$(uname -s | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)
case $arch in
    x86_64)
        arch="amd64"
        ;;
    aarch64 | arm64)
        arch="arm64"
        ;;
    *)
        echo "Unsupported architecture: $arch"
        exit 1
        ;;
esac

## Gets the latest release tag from GitHub
## SOPS Github full URL: https://github.com/getsops/sops/
github_repo="getsops/sops"

echo "Fetching the latest release from GitHub..."

latest_release=$(curl -Ls https://api.github.com/repos/${github_repo}/releases/latest | sed 's/[()",{}]/ /g; s/ /\n/g' | grep "https.*releases/download" | grep "${os}.${arch}" | grep -v ".spdx.sbom.json" | head -n 1)

echo "Downloading: $latest_release"

run_as_root curl -Lo /usr/local/bin/sops $latest_release
run_as_root chmod +x /usr/local/bin/sops

# Verify installation
/usr/local/bin/sops --version
