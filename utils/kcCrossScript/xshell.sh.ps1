#!/usr/bin/env sh

# kcCrossScript
# -------------
# A cross-platform script template that will run in any Linux/MacOS Terminal shell, or in Windows PowerShell.
#
# Inspired by Jeff Hykin on Stack Overflow: https://stackoverflow.com/a/67292076
#
# This script can be used to run any command that is not OS or shell specific (such as commands like "npm install", "go build", "docker build", etc).
#
# This allows for a single build script that can be run on any Linux, MacOS, or Windows host.
#
# Add your commands to the "BEGIN_SCRIPT_COMMANDS" section below.

echo --% >/dev/null;: ' | out-null

<#'
: <<'END_SCRIPT_COMMANDS'

## --- Add your end-user script commands here ---
# BEGIN_SCRIPT_COMMANDS
# ---------------------

echo "this is my first command example"
echo "this is my second command example"

# Below are examples of other commands that can be used:
# npm install
# go build
# docker build .

# ---------------------
END_SCRIPT_COMMANDS

# --- Do not edit below this line ---

# POSIX Shell Parsing
echo "Running Shell script..."
echo ""

# Read commands between BEGIN_SCRIPT_COMMANDS and END_SCRIPT_COMMANDS markers
sed -n '/^: <<'"'"'END_SCRIPT_COMMANDS'"'"'$/,/^END_SCRIPT_COMMANDS$/p' "$0" | sed '1d;$d' | while IFS= read -r line; do
	if [ -n "$line" ] && [ "${line#\#}" = "$line" ]; then
		eval "$line"
		command_status=$?
		if [ "$command_status" -ne 0 ]; then
			exit "$command_status"
		fi
	fi
done
command_status=$?
if [ "$command_status" -ne 0 ]; then
	exit "$command_status"
fi

echo ""
echo "Finished running shell script."

exit 0
# shellcheck disable=SC2317
: <<'POWERSHELL_SCRIPT'
#>

# --- PowerShell Script Parsing

echo "Running PowerShell script..."
echo ""

$ErrorActionPreference = 'Stop'
$scriptLines = Get-Content -Path $PSCommandPath
$scriptCommands = @()
$found = $false
foreach ($line in $scriptLines) {
  if ($line -eq 'END_SCRIPT_COMMANDS') {
    break
  }
  if ($found -and $line -match '\S') {
    if (-not $line.TrimStart().StartsWith('#')) {
      $scriptCommands += $line
    }
  }
  if ($line -eq ": <<'END_SCRIPT_COMMANDS'") {
    $found = $true
  }
}
foreach ($cmd in $scriptCommands) {
  Invoke-Expression $cmd
  if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

echo ""
echo "Finished running PowerShell script."

exit
POWERSHELL_SCRIPT
