#!/bin/bash

set -euo pipefail

## `config/build/install-sops.sh`
##
## - Shell script to install SOPS from the official getsops/sops GitHub releases
## - uses `sudo` if not running as root

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

case $os in
linux | darwin)
	;;
*)
	echo "Unsupported OS: $os"
	exit 1
	;;
esac

echo "Fetching the latest release from GitHub..."

latest_release_url=$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/getsops/sops/releases/latest)
latest_release=${latest_release_url##*/}
if [ -z "$latest_release" ] || [ "$latest_release" = "latest" ]; then
	echo "Failed to determine the latest SOPS release."
	exit 1
fi

sops_url="https://github.com/getsops/sops/releases/download/${latest_release}/sops-${latest_release}.${os}.${arch}"

echo "Downloading: $sops_url"

run_as_root curl -fLo /usr/local/bin/sops "$sops_url"
run_as_root chmod +x /usr/local/bin/sops

# Verify installation
/usr/local/bin/sops --version
