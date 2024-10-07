#!/bin/sh
set -e

#| install.sh
#| ---
#| Installs the tooling needed to run the ./src source code

# Since we are running a Go app, we'll need to install in the container locally:
echo "Installing Golang using mise-cli (https://mise.jdx.dev/)"

mkdir -p ~/.local/bin
curl https://mise.jdx.dev/mise-latest-linux-x64 > ~/.local/bin/mise
chmod +x ~/.local/bin/mise

alias mise="$HOME/.local/bin/mise"
mise use -g go@latest