# kcCrossScript

## Overview

A simple cross-platform script template that will run in any Linux/MacOS terminal shell (`sh/bash/zsh`) or in Windows PowerShell.

Inspired by Jeff Hykin's comment on Stack Overflow: https://stackoverflow.com/a/67292076

This script can be used to run any command that is not OS or shell specific (such as commands like "npm install", "go build", "docker build", etc).

This allows for the creation of a single build script that can be distributed and run on any Linux, MacOS, or Windows host.

## Why?

Why not? 😆 Honestly, I just wanted to prove to myself it could be done. This is not a real-world production workflow recommendation.

## Setup

- Git clone this repo: `git clone --depth 1 https://github.com/CaseyLabs/kcUtils.git`

- Go to this utility: `cd kcUtils/kcCrossScript`

- Edit `xshell.sh.ps1`

- Find the `BEGIN_SCRIPT_COMMANDS` section

- Add your build commands there. For example:

```shell
# BEGIN_SCRIPT_COMMANDS
# --------------------------------------------------------

echo "this is my first command example"
echo "this is my second command example"

# --------------------------------------------------------
END_SCRIPT_COMMANDS
```

## Usage

Run the script in a Terminal or PowerShell session.

**Terminal (Linux/MacOS):** 

```shell
./xshell.sh.ps1
```

Example output:

```shell
Running shell script...

this is my first command example
this is my second command example

Finished running shell script.
```

**PowerShell (Windows):** 

```powershell
.\xshell.sh.ps1
```

Example output:

```powershell
Running PowerShell script...

this is my first command example
this is my second command example

Finished running PowerShell script.
```
