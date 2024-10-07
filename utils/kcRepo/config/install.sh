#!/bin/sh
set -eu

echo "Installing Golang using mise-cli (https://mise.jdx.dev/)"

mkdir -p ~/.local/bin
curl https://mise.jdx.dev/mise-latest-linux-x64 > ~/.local/bin/mise
chmod +x ~/.local/bin/mise

alias mise="$HOME/.local/bin/mise"
mise use -g go@latest