#!/bin/sh
set -e

# --- Install system packages as root

# kcShell helper functions
kcScriptUrl="https://raw.githubusercontent.com/CaseyLabs/kcUtils/main/utils/kcShell/kcshell.sh"
curl -s ${kcScriptUrl} > kc
chmod +x kc && mv kc /usr/local/bin/

# system packages
kc os install \
  apt-transport-https \
  build-essential \
  ca-certificates \
  git \
  gnupg \
  jq \
  libssl-dev \
  net-tools \
  software-properties-common \
  unzip \
  wget \
  zip \
  zsh

kc os clean
