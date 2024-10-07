# `kcShell`

A collection of POSIX-compatible shell helper functions, designed to simplify shell script writing.

## Install  

```sh
kcScriptUrl="https://raw.githubusercontent.com/CaseyLabs/kcUtils/main/utils/kcShell/kcshell.sh"
curl -s ${kcScriptUrl} > kc
chmod +x kc
sudo cp kc /usr/local/bin/
```    

## Usage  

`kc [command] [args]`

```
Available commands:
  log
  check
  os
  edit
  help
  version
```

## Demo

![Image of kcShell running](./demo.gif)

## Script Commands

### `kc log`

Simple logging function that logs messages to stdout/stderr.

Usage: `kc log [event type] [event message]`

Example: 
```
> kc log info "This is an info message"
2024-09-20T10:25:36Z | laptop | [info] This is an info message

> kc log error "This is an error message that goes to stderr"
2024-09-20T10:25:36Z | laptop | [error] This is an error message that goes to stderr
```

### `kc check`

Checks if a file, folder, command, or variable exists.
Usage: `kc check [file/folder/command/variable]`

Examples:
```
kc check /path/to/file
kc check /path/to/folder
kc check commandName
kc check variableName
```

### `kc os`

Commands for Linux system package managers, such as _apt, yum, pacman, apk_

Usage: `kc os [install/remove/clean/info/upgrade]`

Examples:
```
kc os install wget
kc os install wget curl
kc os install packages.cfg
kc os install ./config/packages.cfg
kc os remove wget
kc os info
kc os upgrade # upgrade all system packages (WARNING: AUTOMATIC, DOES NOT PROMPT!)
```

### `kc edit`

Edits a file (with sudo automatically if needed) and saves a backup 
- Files saved in: `./path/to/target/.kc_backups/`
- Default backup retention: 5 copies

Usage: `kc edit /path/to/file`
Example: `kc edit /etc/hosts`

### `kc help`

Shows the available `kc` commands
Usage: `kc help`

### `kc version`

Prints the current version of kcShell
Usage: `kc version`
