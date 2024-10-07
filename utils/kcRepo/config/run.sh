#!/bin/sh
set -e

#| run.sh
#| ---
#| Commands required to run ./src source code in the container

echo "Let's run a helloWorld app written in Go:"

alias mise="$HOME/.local/bin/mise"
mise exec golang@latest -- go run main.go

echo "App run completed!"
