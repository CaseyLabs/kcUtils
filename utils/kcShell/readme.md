# kcShell  
  
A collection of shell script helper functions to simplify common commands and script writing.  
  
## Install  
  
Local setup:  
```sh
. /path/to/kcshell.sh
```  
  
Remote setup:    
```sh
. <(curl -s https://raw.githubusercontent.com/CaseyLabs/kcUtils/main/utils/kcShell/kcshell.sh)
```    
  
## Usage  
`kc [command] [args]`  
## Functions  
List of `kc` commands:  
### `kc check`  
Checks if a file, folder, command, or variable exists.  
- `kc check /path/to/file`  
- `kc check /path/to/folder`  
- `kc check commandName`  
- `kc check variableName`  
### `kc os`  
Operating system related functions.  
- `kc os install [package]`: installs a package  
- `kc os remove [package]`: removes a package  
- `kc os upgrade`: upgrades all system pacakages  
- `kc os info`: displays the OS name (kcOS) and architecture (kcArch)  
