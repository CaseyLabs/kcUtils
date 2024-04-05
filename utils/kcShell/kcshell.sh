#!/bin/sh

#| # kcShell
#| A collection of POSIX-compatible shell script helper functions, designed to simplify common commands and script writing.
#| 
#| ## Install
#|
#| ```sh
#| kcScriptUrl="https://raw.githubusercontent.com/CaseyLabs/kcUtils/main/utils/kcShell/kcshell.sh"
#| curl -s ${kcScriptUrl} > kc
#| chmod +x kc
#| sudo cp kc /usr/local/bin/
#| ```  
#|
#| ## Usage
#| `kc [command] [args]`
#|
#| ## Demo
#| ![Image of kcShell running](./demo.gif)

# -- Vars

# Detect the OS and architecture
kcOS=`grep '^ID=' /etc/os-release | cut -f2 -d'='`
kcArch=`uname -m`

# Check if we are root
if [ "`id | cut -d'=' -f2 | cut -d'(' -f1`" -ne 0 ]; then
  sudo_cmd=sudo
else
  sudo_cmd=
fi

#| ## Available Functions

kc_check() {
  #| ### `kc check`
  #| Checks if a file, folder, command, or variable exists.
  #| - `kc check /path/to/file`
  #| - `kc check /path/to/folder`
  #| - `kc check commandName`
  #| - `kc check variableName`
  if [ -e "$1" ]; then
    printf "File or folder exists: %s\n" "$1"
  elif command -v "$1" >/dev/null 2>&1; then
    printf "Command exists: %s\n" "$1"
  elif [ -n "$(printenv $1)" ]; then
    printf "Env var exists: %s\n" "$1"
  else
    case "$1" in
      "UID") 
        if [ -n "$UID" ]; then
          printf "Shell var exists: %s\n" "$1"
        else
          printf "Could not find: %s\n" "$1"
          return 1
        fi
        ;;
      *)
        printf "Could not find: %s\n" "$1"
        return 1
        ;;
    esac
  fi
}

kc_os() {
  #| ### `kc os`
  #| Operating system related functions.
  #| - `kc os update`: updates the package manager cache (Debian systems only)
  #| - `kc os install [package]`: installs a package
  #| - `kc os remove [package]`: removes a package
  #| - `kc os upgrade`: upgrades all system pacakages
  #| - `kc os clean`: cleans up the package manager cache
  #| - `kc os info`: displays the OS name (kcOS) and architecture (kcArch)

  if [ -z "$1" ]; then
    printf "You must provide a command (upgrade, install, remove, info)\n"
    return 1
  fi

  case "$kcOS" in
    ubuntu|debian)
      export DEBIAN_FRONTEND=noninteractive
      update_cmd="apt-get update"
      install_cmd="apt-get install -y"
      remove_cmd="apt-get remove -y"
      upgrade_cmd="apt-get upgrade -y"
      clean_cmd="apt-get clean; apt-get autoremove -y; rm -rf /var/lib/apt/lists/*"
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
      printf "Unsupported operating system: %s\n" "$kcOS"
      return 1
      ;;
  esac

  case "$1" in
   update)
    # Debian/Ubuntu: Check if the package metadata is outdated
    if [ "$kcOS" = "ubuntu" ] || [ "$kcOS" = "debian" ]; then
      metadata_dir="/var/lib/apt/lists/"
      current_time=$(date +%s)
      latest_timestamp=$(find "$metadata_dir" -name "Release" -exec stat -c %Y {} + | sort -nr | head -n 1)
      if [ "$latest_timestamp" -lt "$current_time" ]; then
        $sudo_cmd $update_cmd
      fi
    fi
    ;;
    
   upgrade)
      $sudo_cmd $upgrade_cmd
      ;;

    install)
      shift
      pkg="$1"
      while [ "$pkg" != "" ]
      do
        if [ "$kcOS" = "ubuntu" ] || [ "$kcOS" = "debian" ]; then
          $sudo_cmd sh -c "$update_cmd; $install_cmd $pkg"
        else
          $sudo_cmd $install_cmd $pkg
        fi
        shift
        pkg="$1"
      done
      ;;

    remove)
      $sudo_cmd $remove_cmd $2
      ;;

    clean)
      $sudo_cmd eval $clean_cmd
      ;;

    info)
      printf "Operating System: %s\n" "$kcOS"
      printf "Architecture: %s\n" "$kcArch"
      ;;

    *)
      printf "Unknown command: %s\n" "$1"
      return 1
      ;;
  esac
}

case "$1" in
  check)
    shift
    kc_check "$@"
    ;;
  os)
    shift
    kc_os "$@"
    ;;
  *)
    printf "Unknown command: %s\n" "$1"
    exit 1
    ;;
esac