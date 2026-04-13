#!/bin/sh
set -e

# --- Install system packages as root

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
	apt-transport-https \
	build-essential \
	ca-certificates \
	curl \
	eza \
	git \
	jq \
	libssl-dev \
	net-tools \
	unzip \
	zip \
	zsh
rm -rf /var/lib/apt/lists/*
