#| # kcShell
#|
#| A collection of shell script helper functions to simplify common commands and script writing.
#|
#| ## Install
#|
#| Local setup:
#| ```sh
#| . /path/to/kcshell.sh
#| ```
#| 
#| Remote setup:  
#| ```sh
#| . <(curl -s https://raw.githubusercontent.com/CaseyLabs/kcUtils/main/utils/kcShell/kcshell.sh)
#| ```  
#|
#| ## Usage
#| `kc [command] [args]`

# -- Vars

# Detect the OS and architecture
. /etc/os-release
export kcOS=$ID
export kcArch=$(uname -m)

# Check if we are root
if [ "$(id -u)" -ne 0 ]; then
  export sudo_cmd=sudo
else
  export sudo_cmd=
fi

#| ## Functions
#| List of `kc` commands:

kc() {
  local cmd="kc_$1"
  echo "Running command: $cmd"  # Debugging line
  type $cmd >/dev/null 2>&1

  if [ $? -eq 0 ]; then
    shift  # Remove the first argument ("kc") passed to the functions
    $cmd "$@"
  else
    echo "Unknown command: $1"
    return 1
  fi
}

kc_check() {
  #| ### `kc check`
  #| Checks if a file, folder, command, or variable exists.
  #| - `kc check /path/to/file`
  #| - `kc check /path/to/folder`
  #| - `kc check commandName`
  #| - `kc check variableName`
  if [ -e "$1" ]; then
    echo "File or folder exists: $1"
  elif command -v "$1" >/dev/null 2>&1; then
    echo "Command exists: $1"
  elif [ -n "$1" ] && [ -n "${!1}" ]; then
    echo "Env var exists: $1"
  else
    echo "Could not find: $1"
    return 1
  fi
}

kc_os() {
  #| ### `kc os`
  #| Operating system related functions.
  #| - `kc os install [package]`: installs a package
  #| - `kc os remove [package]`: removes a package
  #| - `kc os upgrade`: upgrades all system pacakages
  #| - `kc os clean`: cleans up the package manager cache
  #| - `kc os info`: displays the OS name (kcOS) and architecture (kcArch)

  if [ -z "$1" ]; then
    echo "You must provide a command (upgrade, install, remove, info)"
    return 1
  fi

  # Determine package manager and commands
  case "$kcOS" in
    ubuntu|debian)
      export DEBIAN_FRONTEND=noninteractive
      update_cmd="apt-get update"
      install_cmd="apt-get install -y"
      remove_cmd="apt-get remove -y"
      upgrade_cmd="apt-get upgrade -y"
      clean_cmd="apt-get clean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*"
      ;;
    centos|rhel|fedora)
      install_cmd="yum install -y"
      remove_cmd="yum remove -y"
      upgrade_cmd="yum upgrade -y"
      ;;
    alpine)
      install_cmd="apk add"
      remove_cmd="apk del"
      upgrade_cmd="apk upgrade"
      ;;
    *)
      echo "Unsupported operating system: $kcOS"
      return 1
      ;;
  esac

  # Execute command
  case "$1" in
    upgrade)
      if [ "$kcOS" = "ubuntu" ] || [ "$kcOS" = "debian" ]; then
        $sudo_cmd sh -c "$update_cmd; $upgrade_cmd"
      else
        $sudo_cmd $upgrade_cmd
      fi
      ;;
    install)
      if [ "$kcOS" = "ubuntu" ] || [ "$kcOS" = "debian" ]; then
        $sudo_cmd sh -c "$update_cmd; $install_cmd $2"
      else
        $sudo_cmd $install_cmd $2
      fi
      ;;
    remove)
      $sudo_cmd $remove_cmd $2
      ;;
    clean)
      $sudo_cmd $clean_cmd
      ;;
    info)
      echo "Operating System: $kcOS"
      echo "Architecture: $kcArch"
      ;;
    *)
      echo "Unknown command: $1"
      return 1
      ;;
  esac
}