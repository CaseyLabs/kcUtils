#!/bin/sh
set -e

# --- Install system packages as root

# Import shell helper functions
scriptUrl="https://raw.githubusercontent.com/CaseyLabs/kcUtils/main/utils/kcShell/kcshell.sh"
curl -s ${scriptUrl} > kcshell.sh
. ./kcshell.sh

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
  sudo \
  unzip \
  wget \
  zip \
  zsh

kc os clean

rm ./kcshell.sh
