#!/bin/sh
set -e

echo "Let's test a helloWorld app, written in Go:"

alias mise="$HOME/.local/bin/mise"
mise exec golang@latest -- go run main.go

ls -la
