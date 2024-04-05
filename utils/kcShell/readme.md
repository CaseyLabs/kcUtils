# kcShell  
A collection of POSIX-compatible shell script helper functions, designed to simplify common commands and script writing.  
  
## Install  
  
```sh
kcScriptUrl="https://raw.githubusercontent.com/CaseyLabs/kcUtils/main/utils/kcShell/kcshell.sh"
curl -s ${kcScriptUrl} > kc
chmod +x kc
sudo cp kc /usr/local/bin/
```    
  
## Usage  
`kc [command] [args]`  
  
## Demo  
![Image of kcShell running](./demo.gif)  
## Available Functions  
### `kc check`  
Checks if a file, folder, command, or variable exists.  
- `kc check /path/to/file`  
- `kc check /path/to/folder`  
- `kc check commandName`  
- `kc check variableName`  
### `kc os`  
Operating system related functions.  
- `kc os update`: updates the package manager cache (Debian systems only)  
- `kc os install [package]`: installs a package  
- `kc os remove [package]`: removes a package  
- `kc os upgrade`: upgrades all system pacakages  
- `kc os clean`: cleans up the package manager cache  
- `kc os info`: displays the OS name (kcOS) and architecture (kcArch)  
