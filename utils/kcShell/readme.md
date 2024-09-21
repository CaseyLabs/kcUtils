# kcShell
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

## Available Functions
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
Usage: kc check [file/folder/command/variable]
Examples:
- `kc check /path/to/file`

- `kc check /path/to/folder`

- `kc check commandName`

- `kc check variableName`


```
> kc check UID
Shell var exists: UID

> kc check pwd
Command exists: pwd
```
### `kc os`
Commands for Linux system package managers, such as apt, yum, pacman, apk
Usage: `kc os [update/upgrade/install/remove/clean/info]`
```
kc os install curl
kc os remove wget
kc os upgrade # upgrade all system packages
```
### `kc edit`
Edits a file (with sudo automatically if neeeded) and saves a backup 
(Default backup retention: 5)
Usage: `kc edit /path/to/file`
### `kc help`
Displays this help text.
## Demo  
![Image of kcShell running](./demo.gif)  
