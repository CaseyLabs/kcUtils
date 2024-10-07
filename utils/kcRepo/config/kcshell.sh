#!/bin/sh

#| `kcShell`
#| A collection of POSIX-compatible shell helper functions, designed to simplify shell script writing.

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
#| Available commands:
#|   log
#|   check
#|   os
#|   edit
#|   help
#|   version
#|
#| ## Demo
#| ![Image of kcShell running](./demo.gif)

kcScriptVersion="v24.10.06"

# -- Vars

# Detect the OS and architecture
kcShell=${0##*/}
kcOS=$(grep '^ID=' /etc/os-release | cut -f2 -d'=' 2>/dev/null || uname)
kcOSLIKE=$(grep '^ID_LIKE=' /etc/os-release | cut -f2 -d'=' 2>/dev/null || uname)
kcArch=$(uname -m)

# Check if we are root
if [ "$(id -u)" -ne 0 ]; then
  sudo="sudo"
else
  sudo=""
fi

#| ## Available Functions

kc_log() {
  #| ### `kc log`
  #| Simple logging function that logs messages to stdout/stderr.
  #| Usage: `kc log [event type] [event message]`
  #| Example: 
  #| ```
  #| > kc log info "This is an info message"
  #| 2024-09-20T10:25:36Z | laptop | [info] This is an info message
  #| 
  #| > kc log error "This is an error message that goes to stderr"
  #| 2024-09-20T10:25:36Z | laptop | [error] This is an error message that goes to stderr
  #| ```
  
  if [ "$1" = "help" ]; then
    kc_help "log"
    return 0
  fi

  if [ $# -lt 2 ]; then
    echo ""
    echo "[error] Incorrect number of arguments." >&2
    echo "Run 'kc log help' for more info"
    return 1
  fi
  
  timestamp=$(date +"%Y-%m-%dT%H:%M:%SZ")
  eventType=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  eventMessage="$2"

  logPrefix="$timestamp | $HOSTNAME | [$eventType]"

  case "$eventType" in
    debug)
      [ -z "$DEBUG" ] && return
      echo "$logPrefix $eventMessage"
      ;;
    error)
      echo "$logPrefix $eventMessage" >&2
      ;;
    info|warning)
      echo "$logPrefix $eventMessage"
      ;;
    *)
      echo "$logPrefix Unknown event type: $eventType - $eventMessage"
      ;;
  esac
}

kc_check() {
  #| ### `kc check`
  #| Checks if a file, folder, command, or variable exists.
  #| Usage: `kc check [file/folder/command/variable]`
  #| Examples:
  #| ```
  #| kc check /path/to/file
  #| kc check /path/to/folder
  #| kc check commandName
  #| kc check variableName
  #| ```
  
  if [ "$1" = "help" ]; then
    kc_help "check"
    return 0
  fi

  if [ $# -ne 1 ]; then
    echo ""
    echo "[error] Incorrect number of arguments." >&2
    echo 'Run "kc check help" for more info'
    return 1
  fi

  if [ -e "$1" ]; then
    printf "File or folder exists: %s\n" "$1"
    return 0
  elif command -v "$1" >/dev/null 2>&1; then
    printf "Command exists: %s\n" "$1"
    return 0
  elif [ -n "$(printenv "$1")" ]; then
    printf "Env var exists: %s\n" "$1"
    return 0
  else
    printf "Could not find: %s\n" "$1"
    return 1
  fi
}

kc_os() {
  #| ### `kc os`
  #| Commands for Linux system package managers, such as apt, yum, pacman, apk
  #| Usage: kc os [install/remove/clean/info/upgrade]
  #| Examples:
  #| ```
  #| kc os install wget
  #| kc os install wget curl
  #| kc os install packages.cfg
  #| kc os install ./config/packages.cfg
  #| kc os remove wget
  #| kc os info
  #| kc os upgrade # upgrade all system packages (WARNING: AUTOMATIC, DOES NOT PROMPT!)
  #| ```

  if [ "$1" = "help" ]; then
    kc_help "os"
    return 0
  fi

  if [ $# -lt 1 ]; then
    echo ""
    echo "[error] Incorrect number of arguments." >&2
    echo 'Run "kc os help" for more info'
    return 1
  fi

  check_package() {
    local package=$1
    case "${kcOS}|${kcOSLIKE}" in
      *ubuntu*|*debian*)
        dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "ok installed"
        ;;
      *centos*|*rhel*|*fedora*|*amazon*)
        rpm -q "$package" >/dev/null 2>&1
        ;;
      *alpine*)
        apk info -e "$package" >/dev/null 2>&1
        ;;
      *arch*|*manjaro*)
        pacman -Qi "$package" >/dev/null 2>&1
        ;;
      *)
        return 1
        ;;
    esac
  }

  case "${kcOS}|${kcOSLIKE}" in
    *ubuntu*|*debian*)
      export DEBIAN_FRONTEND=noninteractive
      install_cmd="apt-get install -y"
      remove_cmd="apt-get remove -y"
      upgrade_cmd="apt-get update && apt-get upgrade -y"
      clean_cmd="apt-get clean && apt-get autoremove -y"
      ;;
    *centos*|*rhel*|*fedora*|*amazon*)
      install_cmd="yum install -y"
      remove_cmd="yum remove -y"
      upgrade_cmd="yum upgrade -y"
      clean_cmd="yum clean all"
      ;;
    *alpine*)
      install_cmd="apk add"
      remove_cmd="apk del"
      upgrade_cmd="apk update && apk upgrade"
      clean_cmd="apk cache clean"
      ;;
    *arch*|*manjaro*)
      install_cmd="pacman -S --noconfirm"
      remove_cmd="pacman -R --noconfirm"
      upgrade_cmd="pacman -Syu --noconfirm"
      clean_cmd="pacman -Sc --noconfirm"
      ;;
    *)
      printf "Unsupported operating system: %s\n" "$kcOS"
      return 1
      ;;
  esac

  case "$1" in
    upgrade)
      if ! $sudo sh -c "$upgrade_cmd"; then
        kc_log error "Failed to upgrade system packages"
        return 1
      fi
      ;;
    install)
      shift
      if [ "$#" -eq 0 ]; then
        echo "Usage: kc os install [package...] or [config_file]"
        return 1
      fi
      
      packages_to_install=""
      for arg in "$@"; do
        if [ -f "$arg" ]; then
          # Read packages from file, ignoring comments and empty lines
          file_packages=$(grep -v '^\s*#' "$arg" | grep -v '^\s*$' | tr '\n' ' ')
          for pkg in $file_packages; do
            if ! check_package "$pkg"; then
              packages_to_install="$packages_to_install $pkg"
            else
              kc_log info "Package $pkg is already installed, skipping."
            fi
          done
        else
          if ! check_package "$arg"; then
            packages_to_install="$packages_to_install $arg"
          else
            kc_log info "Package $arg is already installed, skipping."
          fi
        fi
      done
      
      # Trim leading/trailing whitespace and remove duplicate packages
      packages_to_install=$(echo "$packages_to_install" | xargs -n1 | sort -u | xargs)
      
      if [ -n "$packages_to_install" ]; then
        kc_log info "Installing packages: $packages_to_install"
        if ! $sudo sh -c "$install_cmd $packages_to_install"; then
          kc_log error "Failed to install packages: $packages_to_install"
          return 1
        fi
      else
        kc_log info "No new packages to install."
      fi
      ;;
    remove)
      shift
      if [ "$#" -eq 0 ]; then
        echo "Usage: kc os remove [package...]"
        return 1
      fi
      if ! $sudo $remove_cmd "$@"; then
        kc_log error "Failed to remove packages: $*"
        return 1
      fi
      ;;
    clean)
      if ! $sudo sh -c "$clean_cmd"; then
        kc_log error "Failed to clean package manager cache"
        return 1
      fi
      ;;
    info)
      printf "Operating System: kcOS = %s\n" "$kcOS"
      printf "Architecture: kcArch = %s\n" "$kcArch"
      printf "OS Like: kcOSLIKE = %s\n" "$kcOSLIKE"
      ;;
    *)
      printf "Unknown command: %s\n" "$1"
      return 1
      ;;
  esac 
}

kc_edit() {
  #| ### `kc edit`
  #| Edits a file (with sudo automatically if needed) and saves a backup 
  #| Files saved in: `./path/to/target/.kc_backups/`
  #| (Default backup retention: 5)
  #| Usage: `kc edit /path/to/file`
  #| Example: `kc edit /etc/hosts`
  
  if [ "$1" = "help" ]; then
    kc_help "edit"
    return 0
  fi

  if [ $# -eq 0 ]; then
    echo ""
    echo "[error] Incorrect number of arguments." >&2
    echo 'Run "kc os edit" for more info'
    return 1
  fi

  backup_limit=5

  # Use a more portable method to get the absolute path
  abs_path=$(cd "$(dirname "$1")" && pwd -P)/$(basename "$1")

  if [ ! -r "$abs_path" ] && ! $sudo test -r "$abs_path"; then
    kc_log error "File does not exist or is not readable: $abs_path"
    return 1
  fi

  backup_dir="${abs_path%/*}/.kc_backups"
  run_with_sudo() {
    if $sudo -n true 2>/dev/null; then
      $sudo "$@"
    else
      "$@"
    fi
  }

  # Ensure backup directory exists with proper permissions
  if [ ! -d "$backup_dir" ]; then
    if ! run_with_sudo mkdir -p "$backup_dir"; then
      kc_log error "Failed to create backup directory: $backup_dir"
      return 1
    fi
    run_with_sudo chmod 700 "$backup_dir"
  fi

  # Create a temporary backup before editing
  temp_backup="$backup_dir/$(basename "$abs_path").temp"
  if ! run_with_sudo cp -a "$abs_path" "$temp_backup"; then
    kc_log error "Failed to create temporary backup: $temp_backup"
    return 1
  fi

  # Edit file
  editor="${EDITOR:-$(command -v nano || command -v vi)}"
  if ! run_with_sudo "$editor" "$abs_path"; then
    kc_log error "Failed to edit file: $abs_path"
    return 1
  fi

  # Check if the file has changed and move the temp backup if so
  if ! cmp -s "$abs_path" "$temp_backup"; then
    timestamp=$(date +%s)
    backup_file="$backup_dir/$(basename "$abs_path").$timestamp"
    if run_with_sudo mv "$temp_backup" "$backup_file"; then
      kc_log info "Backup created: $backup_file"
    else
      kc_log error "Failed to create backup: $backup_file"
    fi
  else
    run_with_sudo rm "$temp_backup"  # Remove temp backup if no changes
  fi

  # Cleanup old backups
  find "$backup_dir" -name "$(basename "$abs_path").*" -type f | sort -r | tail -n +$((backup_limit+1)) | xargs -r run_with_sudo rm
}

kc_help() {
  #| ### `kc help`
  #| Shows the available `kc` commands
  #| Usage: `kc help`
  if [ -n "$1" ]; then
    if command -v "kc_$1" >/dev/null 2>&1; then
      printf "Help for 'kc %s':\n" "$1"
      sed -n "/^kc_$1()/,/^}/p" "$0" | 
        grep -E '^  #\|' | 
        sed -E 's/^  #\| ?//' |
        sed -E 's/^### `kc [a-z]+`//' |
        sed -E 's/`//g' |
        awk '{
          if ($0 ~ /^Usage:/) print $0;
          else if ($0 ~ /^Example:/) print "\n" $0;
          else if ($0 ~ /^[A-Za-z]/) print $0;
          else print $0;
        }' |
        sed -E '/^\s*$/N;/^\n$/D'
    else
      printf "[kc] No help available for '%s'.\n" "$1"
    fi
  else
    echo "kcShell - POSIX-compatible shell script helper functions"
    echo
    echo "Usage: kc [command] [args]"
    echo
    echo "Available commands:"
    grep -E '^kc_[a-zA-Z_]+\(\)' "$0" | sed -E 's/kc_([a-zA-Z_]+)\(\).*/\1/' | while read -r cmd; do
      echo "  $cmd"
    done
    echo
    echo "Run 'kc help [command]' for more details on each command."
  fi
}

kc_version() {
  #| ### `kc version`
  #| Prints the current version of kcShell
  #| Usage: `kc version`
  echo "kcShell $kcScriptVersion"
}

# Main execution block
if [ $# -eq 0 ]; then
  kc_help
  exit 0
fi

case "$1" in
  help)
    kc_help "$2"
    ;;
  version)
    kc_version
    ;;
  update)
    kc_update
    ;;
  list)
    kc_list
    ;;
  *)
    if command -v "kc_$1" >/dev/null 2>&1; then
      command="kc_$1"
      shift
      $command "$@"
    else
      kc_log error "Unknown command: $1"
      kc_help
      exit 1
    fi
    ;;
esac

exit $?