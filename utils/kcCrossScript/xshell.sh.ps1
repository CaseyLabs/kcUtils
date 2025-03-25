#!/usr/bin/env bash 

## crossShell 
## ----------
## A cross-platform script template that will run in any Linux/MacOS Terminal (sh/bash/zsh) or in Windows PowerShell.
##
## Inspired by Jeff Hykin on Stackoverflow: https://stackoverflow.com/a/67292076
##
## This script can be used to run any command that is not OS or shell specific (such as commands like "npm install", "go build", "docker build", etc).
## This allows for a single build script that can be ran on any Linux, MacOS, or Windows host.
##
## Add your commands to the "BEGIN_SCRIPT_COMMANDS" section below.

echo --% >/dev/null;: ' | out-null

<#'
: <<'END_SCRIPT_COMMANDS'

# BEGIN_SCRIPT_COMMANDS
# --------------------------------------------------------

echo "this is my first command example"
echo "this is my second command example"

# Below are examples of other commands that can be used:
# npm install
# go build
# docker build .

# --------------------------------------------------------
END_SCRIPT_COMMANDS

# --- Shell function (bash/zsh/etc)

shell_name=$(basename "$SHELL")
echo "Running $shell_name shell script..."
echo ""

# Read commands between BEGIN_SCRIPT_COMMANDS and END_SCRIPT_COMMANDS markers
commands=$(sed -n '/^: <<'"'"'END_SCRIPT_COMMANDS'"'"'$/,/^END_SCRIPT_COMMANDS$/p' "$0" | sed '1d;$d')
while IFS= read -r line; do
  if [ -n "$line" ]; then
    eval "$line"
  fi
done <<< "$commands"

echo ""
echo "Finished running shell script."

exit 0 #>

# --- PowerShell function

echo "Running PowerShell script..."
echo ""

$scriptLines = Get-Content -Path $PSCommandPath
$commands = @()
$found = $false
foreach ($line in $scriptLines) {
  if ($line -eq 'END_SCRIPT_COMMANDS') {
    break
  }
  if ($found -and $line -match '\S') {
    $commands += $line
  }
  if ($line -eq ": <<'END_SCRIPT_COMMANDS'") {
    $found = $true
  }
}
foreach ($cmd in $commands) {
  Invoke-Expression $cmd
}

echo ""
echo "Finished running PowerShell script."

exit