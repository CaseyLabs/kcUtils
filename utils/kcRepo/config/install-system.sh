#!/bin/sh
set -e

# --- Install system packages as root

# add kcShell helper functions
kcScriptUrl="https://raw.githubusercontent.com/CaseyLabs/kcUtils/main/utils/kcShell/kcshell.sh"
curl -s ${kcScriptUrl} > kc
chmod +x kc && mv kc /usr/local/bin/

# package list
kc os install \
  apt-transport-https \
  build-essential \
  ca-certificates \
  git \
  jq \
  libssl-dev \
  unzip \
  zip

kc os clean
